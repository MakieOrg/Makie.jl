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
    width, height = round.(Int, JSServe.evaljs_value(screen.session, js; timeout=100))
    return (width, height)
end

function render_with_init(screen, session, scene)
    screen.session = session
    three, canvas, on_init = three_display(screen, session, scene)
    screen.display = true
    Makie.push_screen!(scene, screen)
    on(session, on_init) do i
        if !isready(screen.three)
            put!(screen.three, three)
        end
        mark_as_displayed!(screen, scene)
        return
    end
    return three, canvas, on_init
end

function JSServe.jsrender(session::Session, scene::Scene)
    screen = Screen(scene)
    three, canvas, on_init = render_with_init(screen, session, scene)
    return canvas
end

function JSServe.jsrender(session::Session, fig::Makie.FigureLike)
    Makie.update_state_before_display!(fig)
    return JSServe.jsrender(session, Makie.get_scene(fig))
end

"""
* `framerate = 30`: Set framerate (frames per second) to a higher number for smoother animations, or to a lower to use less resources.
"""
struct ScreenConfig
    framerate::Float64 # =30.0
    resize_to::Any # nothing
    # We use nothing, since that serializes correctly to nothing in JS, which is important since that's where we calculate the defaults!
    # For the theming, we need to use Automatic though, since that's the Makie meaning for gets calculated somewhere else
    px_per_unit::Union{Nothing,Float64} # nothing, a.k.a the browser px_per_unit (devicePixelRatio)
    scalefactor::Union{Nothing,Float64}
    resize_to_body::Bool
    function ScreenConfig(
            framerate::Number, resize_to::Any, px_per_unit::Union{Number, Automatic, Nothing},
            scalefactor::Union{Number, Automatic, Nothing}, resize_to_body::Union{Nothing, Bool})

        if px_per_unit isa Automatic
            px_per_unit = nothing
        end
        if scalefactor isa Automatic
            scalefactor = nothing
        end
        if resize_to_body isa Bool
            @warn("`resize_to_body` is deprecated, use `resize_to = :body` instead")
            if !(resize_to isa Nothing)
                @warn("Setting `resize_to_body` and `resize_to` at the same time, only use resize_to")
            else
                resize_to = resize_to_body ? :body : nothing
            end
        end
        ResizeType = Union{Nothing, Symbol}
        if !(resize_to isa Union{ResizeType,Tuple{ResizeType,ResizeType}})
            error("Only nothing, :parent, or :body allowed, or a tuple of those for width/height.")
        end
        return new(framerate, resize_to, px_per_unit, scalefactor)
    end
end


"""
    WithConfig(fig::Makie.FigureLike; screen_config...)

Allows to pass a screenconfig to a figure, inside a JSServe.App.
This circumvents using `WGLMakie.activate!(; screen_config...)` inside an App, which modifies these values globally.
Example:

```julia
App() do
    f1 = scatter(1:4)
    f2 = scatter(1:4; figure=(; backgroundcolor=:gray))
    wc = WGLMakie.WithConfig(f2; resize_to=:parent)
    DOM.div(f1, DOM.div(wc; style="height: 200px; width: 50%"))
end
```
"""
struct WithConfig
    fig::Makie.FigureLike
    config::ScreenConfig
end

function WithConfig(fig::Makie.FigureLike; kw...)
    config = Makie.merge_screen_config(ScreenConfig, Dict{Symbol,Any}(kw))
    return WithConfig(fig, config)
end

function JSServe.jsrender(session::Session, wconfig::WithConfig)
    fig = wconfig.fig
    Makie.update_state_before_display!(fig)
    scene = Makie.get_scene(fig)
    screen = Screen(scene, wconfig.config)
    three, canvas, on_init = render_with_init(screen, session, scene)
    return canvas
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
    config::ScreenConfig
    function Screen(
            three::Channel{ThreeDisplay},
            display::Any,
            scene::Union{Nothing, Scene}, config::ScreenConfig)
        return new(three, nothing, display, scene, Set{String}(), config)
    end
end

function Base.show(io::IO, screen::Screen)
    c = screen.config
    ppu = c.px_per_unit
    sf = c.scalefactor
    print(io, """WGLMakie.Screen(
        framerate = $(c.framerate),
        resize_to = $(c.resize_to),
        px_per_unit = $(isnothing(ppu) ? :automatic : ppu),
        scalefactor = $(isnothing(sf) ? :automatic : sf)
    )""")
end

# Resizing the scene is enough for WGLMakie
Base.resize!(::WGLMakie.Screen, w, h) = nothing

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

for M in Makie.WEB_MIMES
    @eval begin
        function Makie.backend_show(screen::Screen, io::IO, m::$M, scene::Scene)
            inline_display = App() do session::Session
                three, canvas, init_obs = render_with_init(screen, session, scene)
                return canvas
            end
            Base.show(io, m, inline_display)
            screen.display = true
            return screen
        end
    end
end

function Makie.backend_showable(::Type{Screen}, ::T) where {T<:MIME}
    return T in Makie.WEB_MIMES
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
function Screen(scene::Scene; kw...)
    config = Makie.merge_screen_config(ScreenConfig, Dict{Symbol, Any}(kw))
    return Screen(Channel{ThreeDisplay}(1), nothing, scene, config)
end
Screen(scene::Scene, config::ScreenConfig) = Screen(Channel{ThreeDisplay}(1), nothing, scene, config)
Screen(scene::Scene, config::ScreenConfig, ::IO, ::MIME) = Screen(scene, config)
Screen(scene::Scene, config::ScreenConfig, ::Makie.ImageStorageFormat) = Screen(scene, config)

function Base.empty!(screen::Screen)
    screen.scene = nothing
    screen.display = false
    # TODO, empty state in JS, to be able to reuse screen
end

Makie.wait_for_display(screen::Screen) = get_three(screen)

function Base.display(screen::Screen, scene::Scene; unused...)
    Makie.push_screen!(scene, screen)
    # Reference to three object which gets set once we serve this to a browser
    app = App() do session
        screen.session = session
        three, canvas, done_init = three_display(screen, session, scene)
        on(session, done_init) do _
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

function session2image(session::Session, scene::Scene)
    to_data = js"""function (){
        return $(scene).then(scene => {
            const {renderer} = scene.screen
            WGL.render_scene(scene)
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

function insert_scene!(disp, screen::Screen, scene::Scene)
    if js_uuid(scene) in screen.displayed_scenes
        return true
    else
        if !(js_uuid(scene.parent) in screen.displayed_scenes)
            # Parents serialize their child scenes, so we only need to
            # serialize & update the parent scene
            return insert_scene!(disp, screen, scene.parent)
        end
        scene_ser = serialize_scene(scene)
        parent = scene.parent
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
        return false
    end
end

function insert_plot!(disp::ThreeDisplay, scene::Scene, @nospecialize(plot::Plot))
    plot_data = serialize_plots(scene, [plot])
    plot_sub = Session(disp.session)
    JSServe.init_session(plot_sub)
    plot.__wgl_session = plot_sub
    js = js"""
    $(WGL).then(WGL=> {
        WGL.insert_plot($(js_uuid(scene)), $plot_data);
    })"""
    JSServe.evaljs_value(plot_sub, js; timeout=50)
    return
end

function Base.insert!(screen::Screen, scene::Scene, @nospecialize(plot::Plot))
    disp = get_three(screen; error="Plot needs to be displayed to insert additional plots")
    if js_uuid(scene) in screen.displayed_scenes
        insert_plot!(disp, scene, plot)
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
        insert_scene!(disp, screen, scene)
    end
    return
end

function delete_js_objects!(screen::Screen, plot_uuids::Vector{String},
                            session::Union{Nothing,Session})
    three = get_three(screen)
    isnothing(three) && return # if no session we haven't displayed and dont need to delete
    isready(three.session) || return
    JSServe.evaljs(three.session, js"""
    $(WGL).then(WGL=> {
        WGL.delete_plots($(plot_uuids));
    })""")
    !isnothing(session) && close(session)
    return
end

function all_plots_scenes(scene::Scene; scene_uuids=String[], plots=Plot[])
    push!(scene_uuids, js_uuid(scene))
    append!(plots, scene.plots)
    for child in scene.children
        all_plots_scenes(child; plots=plots, scene_uuids=scene_uuids)
    end
    return scene_uuids, plots
end

function delete_js_objects!(screen::Screen, scene::Scene)
    three = get_three(screen)
    isnothing(three) && return # if no session we haven't displayed and dont need to delete
    isready(three.session) || return
    scene_uuids, plots = all_plots_scenes(scene)
    for plot in plots
        if haskey(plot, :__wgl_session)
            session = plot.__wgl_session[]
            close(session)
        end
    end
    JSServe.evaljs(three.session, js"""
    $(WGL).then(WGL=> {
        WGL.delete_scenes($scene_uuids, $(js_uuid.(plots)));
    })""")
    return
end


struct LockfreeQueue{T,F}
    # Double buffering to be lock free
    queue1::Vector{T}
    queue2::Vector{T}
    current_queue::Threads.Atomic{Int}
    task::Base.RefValue{Union{Nothing,Task}}
    execute_job::F
end

function LockfreeQueue{T}(execute_job::F) where {T,F}
    return LockfreeQueue{T,F}(T[],
                              T[],
                              Threads.Atomic{Int}(1),
                              Base.RefValue{Union{Nothing,Task}}(nothing),
                              execute_job)
end

function run_jobs!(queue::LockfreeQueue)
    # already running:
    !isnothing(queue.task[]) && !istaskdone(queue.task[]) && return

    return queue.task[] = @async while true
        try
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
                    Base.invokelatest(queue.execute_job, item...)
                end
            end
            sleep(0.1)
        catch e
            if !(e isa EOFError)
                @warn "error while running JS objects" exception = (e, Base.catch_backtrace())
            end
        end
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

const DISABLE_JS_FINALZING = Base.RefValue(false)
const DELETE_QUEUE = LockfreeQueue{Tuple{Screen, Vector{String}, Union{Session, Nothing}}}(delete_js_objects!)
const SCENE_DELETE_QUEUE = LockfreeQueue{Tuple{Screen,Scene}}(delete_js_objects!)

function Base.delete!(screen::Screen, scene::Scene, plot::Plot)
    # only queue atomics to actually delete on js
    if !DISABLE_JS_FINALZING[]
        plot_uuids = map(js_uuid, Makie.collect_atomic_plots(plot))
        session = to_value(get(plot, :__wgl_session, nothing))
        push!(DELETE_QUEUE, (screen, plot_uuids, session))
    end
    return
end

function Base.delete!(screen::Screen, scene::Scene)
    if !DISABLE_JS_FINALZING[]
        push!(SCENE_DELETE_QUEUE, (screen, scene))
    end
    delete!(screen.displayed_scenes, js_uuid(scene))
    return
end
