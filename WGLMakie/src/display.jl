struct ThreeDisplay
    session::JSServe.Session
end

JSServe.session(td::ThreeDisplay) = td.session
Base.empty!(::ThreeDisplay) = nothing # TODO implement


function Base.close(screen::ThreeDisplay)
    # TODO implement
end

function Base.size(screen::ThreeDisplay)
    # look at d.qs().clientWidth for displayed width
    js = js"[document.querySelector('canvas').width, document.querySelector('canvas').height]"
    width, height = round.(Int, JSServe.evaljs_value(screen.session, js; time_out=100))
    return (width, height)
end

function JSServe.jsrender(session::Session, scene::Scene)
    three, canvas, on_init = three_display(session, scene)
    c = Channel{ThreeDisplay}(1)
    put!(c, three)
    screen = Screen(c, true, scene)
    screen.session = session
    Makie.push_screen!(scene, screen)
    on(on_init) do i
        mark_as_displayed!(screen, scene)
    end
    return canvas
end

function JSServe.jsrender(session::Session, fig::Makie.FigureLike)
    Makie.update_state_before_display!(fig)
    return JSServe.jsrender(session, Makie.get_scene(fig))
end

const WEB_MIMES = (
    MIME"text/html",
    MIME"application/vnd.webio.application+html",
    MIME"application/prs.juno.plotpane+html",
    MIME"juliavscode/html")

"""
* `framerate = 30`: Set framerate (frames per second) to a higher number for smoother animations, or to a lower to use less resources.
"""
struct ScreenConfig
    framerate::Float64 # =30.0
end

"""
    Screen(args...; screen_config...)

# Arguments one can pass via `screen_config`:

$(Base.doc(ScreenConfig))

# Constructors:

$(Base.doc(MakieScreen))
"""
mutable struct Screen <: Makie.MakieScreen
    three::Channel{ThreeDisplay}
    session::Union{Nothing, Session}
    display::Any
    scene::Union{Nothing, Scene}
    displayed_scenes::Set{String}
    function Screen(
            three::Channel{ThreeDisplay},
            display::Any,
            scene::Union{Nothing, Scene})
        return new(three, nothing, display, scene, Set{String}())
    end
end

function Base.isopen(screen::Screen)
    three = get_three(screen)
    return !isnothing(three) && isopen(three.session)
end

function mark_as_displayed!(screen::Screen, scene::Scene)
    push!(screen.displayed_scenes, js_uuid(scene))
    for child_scene in scene.children
        mark_as_displayed!(screen, child_scene)
    end
    return
end

for M in WEB_MIMES
    @eval begin
        function Makie.backend_show(screen::Screen, io::IO, m::$M, scene::Scene)
            inline_display = App() do session::Session
                screen.session = session
                three, canvas, init_obs = three_display(session, scene)
                Makie.push_screen!(scene, screen)
                on(init_obs) do _
                    put!(screen.three, three)
                    mark_as_displayed!(screen, scene)
                    return
                end
                return canvas
            end
            Base.show(io, m, inline_display)
            screen.display = true
            return screen
        end
    end
end

function Makie.backend_showable(::Type{Screen}, ::T) where {T<:MIME}
    return T in WEB_MIMES
end

# TODO implement
Base.close(screen::Screen) = nothing

function Base.size(screen::Screen)
    return size(screen.scene)
end

function get_three(screen::Screen; timeout = 100, error::Union{Nothing, String}=nothing)::Union{Nothing, ThreeDisplay}
    function throw_error(status)
        if !isnothing(error)
            message = "Can't get three: $(status)\n$(error)"
            Base.error(message)
        end
    end
    if screen.display !== true
        throw_error("Screen hasn't displayed yet, so can't get connection to three")
        return nothing
    end
    if isnothing(screen.session)
        throw_error("Screen has no session. Not yet displayed?"); return nothing
    end
    if !(screen.session.status in (JSServe.RENDERED, JSServe.DISPLAYED, JSServe.OPEN))
        throw_error("Screen Session uninitialized. Not yet displayed? Session status: $(screen.session.status)"); return nothing
    end
    tstart = time()
    result = nothing
    while true
        yield()
        if time() - tstart > timeout
            break # we waited LONG ENOUGH!!
        end
        if isready(screen.three)
            result = fetch(screen.three)
            break
        end
    end
    # Throw error if error message specified
    if isnothing(result)
        throw_error("Timed out waiting $(timeout)s for session to get initilize")
    end
    return result
end

function Makie.apply_screen_config!(screen::ThreeDisplay, config::ScreenConfig, args...)
    #TODO implement
    return screen
end
function Makie.apply_screen_config!(screen::Screen, config::ScreenConfig, args...)
    #TODO implement
    return screen
end

# TODO, create optimized screens, forward more options to JS/WebGL
Screen(scene::Scene; kw...) = Screen(Channel{ThreeDisplay}(1), nothing, scene)
Screen(scene::Scene, config::ScreenConfig) = Screen(Channel{ThreeDisplay}(1), nothing, scene)
Screen(scene::Scene, config::ScreenConfig, ::IO, ::MIME) = Screen(scene)
Screen(scene::Scene, config::ScreenConfig, ::Makie.ImageStorageFormat) = Screen(scene)

function Base.empty!(screen::Screen)
    screen.scene = nothing
    screen.display = false
    # TODO, empty state in JS, to be able to reuse screen
end

Makie.wait_for_display(screen::Screen) = get_three(screen)

function Base.display(screen::Screen, scene::Scene; kw...)
    Makie.push_screen!(scene, screen)
    # Reference to three object which gets set once we serve this to a browser
    app = App() do session, request
        screen.session = session
        three, canvas, done_init = three_display(session, scene)
        on(done_init) do _
            put!(screen.three, three)
            mark_as_displayed!(screen, scene)
            return
        end
        return canvas
    end
    display(app)
    screen.display = true
    # wait for plot to be full initialized, so that operations don't get racy (e.g. record/RamStepper & friends)
    get_three(screen)
    return screen
end

function Base.delete!(td::Screen, scene::Scene, plot::AbstractPlot)
    delete!(get_three(td), scene, plot)
end

function session2image(session::Session, scene::Scene)
    to_data = js"""function (){
        return $(scene).then(scene => {
            const {renderer} = scene.screen
            WGLMakie.render_scene(scene)
            const img = renderer.domElement.toDataURL()
            return img
        })
    }()
    """
    picture_base64 = JSServe.evaljs_value(session, to_data; timeout=100)
    picture_base64 = replace(picture_base64, "data:image/png;base64," => "")
    bytes = JSServe.Base64.base64decode(picture_base64)
    return PNGFiles.load(IOBuffer(bytes))
end

function Makie.colorbuffer(screen::Screen)
    if screen.display !== true
        Base.display(screen, screen.scene)
    end
    three = get_three(screen; error="Not able to show scene in a browser")
    return session2image(three.session, screen.scene)
end

function Base.insert!(screen::Screen, scene::Scene, plot::Combined)
    disp = get_three(screen; error="Plot needs to be displayed to insert additional plots")
    if js_uuid(scene) in screen.displayed_scenes
        plot_data = serialize_plots(scene, [plot])
        JSServe.evaljs_value(disp.session, js"""
        $(WGL).then(WGL=> {
            WGL.insert_plot($(js_uuid(scene)), $plot_data);
        })""")
    else
        # Newly created scene gets inserted!
        # This must be a child plot of some parent, otherwise a plot wouldn't be inserted via `insert!(screen, ...)`
        parent = scene.parent
        @assert parent !== scene
        if isnothing(parent)
            # This shouldn't happen, since insert! only gets called for scenes, that already got displayed on a screen
            error("Scene has no parent, but hasn't been displayed yet")
        end
        # We serialize the whole scene (containing `plot` as well),
        # since, we should only get here if scene is newly created and this is the first plot we insert!
        @assert scene.plots[1] == plot
        scene_ser = serialize_scene(scene)
        parent_uuid = js_uuid(parent)
        err = "Cant find scene js_uuid(scene) == $(parent_uuid)"
        evaljs_value(disp.session, js"""
        $(WGL).then(WGL=> {
            const parent = WGL.find_scene($(parent_uuid));
            if (!parent) {
                throw new Error($(err))
            }
            const new_scene = WGL.deserialize_scene($scene_ser, parent.screen);
            parent.scene_children.push(new_scene);
        })
        """)
        mark_as_displayed!(screen, scene)
    end
    return
end

struct LockfreeQueue{T, F}
    # Double buffering to be lock free
    queue1::Vector{T}
    queue2::Vector{T}
    current_queue::Threads.Atomic{Int}
    task::Base.RefValue{Union{Nothing, Task}}
    execute_job::F
end

function LockfreeQueue{T}(execute_job::F) where {T, F}
    return LockfreeQueue{T, F}(
        T[],
        T[],
        Threads.Atomic{Int}(1),
        Base.RefValue{Union{Nothing, Task}}(nothing),
        execute_job
    )
end

function run_jobs!(queue::LockfreeQueue)
    # already running:
    !isnothing(queue.task[]) && !istaskdone(queue.task[]) && return

    queue.task[] = @async while true
        q = nothing
        if !isempty(queue.queue1)
            queue.current_queue[] = 1
            q = queue.queue1
        elseif !isempty(queue.queue2)
            queue.current_queue[] = 2
            q = queue.queue2
        end
        if !isnothing(q)
            while !isempty(q)
                item = pop!(q)
                queue.execute_job(item...)
            end
        end
        sleep(0.1)
    end
end

function Base.push!(queue::LockfreeQueue, item)
    run_jobs!(queue)
    # Push to unused queue:
    if queue.current_queue[] == 1
        push!(queue.queue2, item)
    else
        push!(queue.queue1, item)
    end
end

function delete_plot!(td::Screen, scene::String, uuids::Vector{String})
    three = get_three(td)
    isnothing(three) && return # if no session we haven't displayed and dont need to delete
    isready(three.session) || return
    JSServe.evaljs(three.session, js"""
    $(WGL).then(WGL=> {
        WGL.delete_plots($(scene), $(uuids));
    })""")
    return
end

const DISABLE_JS_FINALZING = Base.RefValue(false)
const DELETE_QUEUE = LockfreeQueue{Tuple{Screen,String,Vector{String}}}(delete_plot!)

function Base.delete!(screen::Screen, scene::Scene, plot::Combined)
    atomics = Makie.flatten_plots(plot) # delete all atomics
    # only queue atomics to actually delete on js
    if !DISABLE_JS_FINALZING[]
        push!(DELETE_QUEUE, (screen, js_uuid(scene), js_uuid.(atomics)))
    end
    return
end
