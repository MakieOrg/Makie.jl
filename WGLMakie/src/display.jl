"""
* `framerate = 30`: Set framerate (frames per second) to a higher number for smoother animations, or to a lower to use less resources.
* `resize_to = nothing`: Resize the canvas to the parent element with `resize_to=:parent`, or to the body if `resize_to = :body`. The default `nothing`, will resize nothing.
    A tuple is allowed too, with the same values just for width/height.
"""
struct ScreenConfig
    framerate::Float64 # =30.0
    resize_to::Any # nothing
    # We use nothing, since that serializes correctly to nothing in JS, which is important since that's where we calculate the defaults!
    # For the theming, we need to use Automatic though, since that's the Makie meaning for gets calculated somewhere else
    px_per_unit::Union{Nothing, Float64} # nothing, a.k.a the browser px_per_unit (devicePixelRatio)
    scalefactor::Union{Nothing, Float64}
    resize_to_body::Bool
    function ScreenConfig(
            framerate::Number, resize_to::Any, px_per_unit::Union{Number, Automatic, Nothing},
            scalefactor::Union{Number, Automatic, Nothing}, resize_to_body::Union{Nothing, Bool}
        )
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
        if !(resize_to isa Union{ResizeType, Tuple{ResizeType, ResizeType}})
            error("Only nothing, :parent, or :body allowed, or a tuple of those for width/height.")
        end
        return new(framerate, resize_to, px_per_unit, scalefactor)
    end
end
"""
    Screen(args...; screen_config...)

# Arguments one can pass via `screen_config`:

$(Base.doc(ScreenConfig))

# Constructors:

$(Base.doc(MakieScreen))
"""
mutable struct Screen <: Makie.MakieScreen
    plot_initialized::Channel{Any}
    session::Union{Nothing, Session}
    scene::Union{Nothing, Scene}
    displayed_scenes::Set{String}
    config::ScreenConfig
    canvas::Union{Nothing, Bonito.HTMLElement}
    tick_clock::Makie.BudgetedTimer
    lock::ReentrantLock
    function Screen(scene::Union{Nothing, Scene}, config::ScreenConfig)
        timer = Makie.BudgetedTimer(1.0 / 30.0)
        return new(Channel{Any}(1), nothing, scene, Set{String}(), config, nothing, timer, Base.ReentrantLock())
    end
end

function Makie.px_per_unit(s::Screen)::Float64
    return something(s.config.px_per_unit, 1.0)
end

Bonito.needs_post_notify(x::Makie.FigureLike) = true
function Bonito.post_notify_callback(x::Makie.FigureLike)
    scene = Makie.get_scene(x)
    return () -> poll_all_plots(scene)
end

function Screen(; config...)
    config = Makie.merge_screen_config(ScreenConfig, Dict{Symbol, Any}(config))
    return Screen(nothing, config)
end


function scene_already_displayed(screen::Screen, scene = screen.scene)
    scene === nothing && return false
    screen.scene === scene || return false
    screen.canvas === nothing && return false
    return !isnothing(screen.session) &&
        isready(screen.session) && isready(screen.plot_initialized) &&
        js_uuid(screen.scene) in screen.displayed_scenes
end

function poll_all_plots(scene)
    return Makie.for_each_atomic_plot(scene) do p
        pp = Makie.parent_scene(p)
        pp.visible[] || return # Skip invisible scenes
        if haskey(p, :wgl_renderobject)
            try
                # Skip updating invisible renderobjects
                # This is basically `if is_visible || was_visible`, which makes
                # sure the robj updates on state change. (i.e. hides and redisplays)
                computed = p[:wgl_renderobject]
                if p.visible[] || computed.value[][:visible]
                    computed[]
                end
            catch e
                @error "Failed to update renderobject - skipping update" exception = (e, catch_backtrace())
                # Mark the output as resolved so we don't repeatedly pull in errors
                # TODO: Is there a better way to handle this? One that allows us to
                # shortcut mark_dirty!() (i.e. preserve parentdirty implying children dirty)
                ComputePipeline.mark_resolved!(p.attributes[:wgl_renderobject])
            end
        end
    end
end

function start_polling_loop!(screen, scene)
    scene.isclosed = false
    return Makie.async_tracked() do isrunning
        while !Makie.isclosed(scene) && isrunning[]
            try
                poll_all_plots(scene)
            catch e
                @error "Error in polling loop" exception = (e, catch_backtrace())
            end
            sleep(1 / 100)
        end
        try
            close(screen; from_close = true)
        catch e
            @error "Error closing screen in polling loop" exception = (e, catch_backtrace())
        end
    end
end

function render_with_init(screen::Screen, session::Session, scene::Scene)
    # Reference to three object which gets set once we serve this to a browser
    # Make sure it's a new Channel, since we may reuse the screen.
    screen.plot_initialized = Channel{Any}(1)
    screen.session = session
    Makie.push_screen!(scene, screen)
    try
        canvas, on_init = three_display(screen, session, scene)
        screen.canvas = canvas
        on(session, on_init) do initialized
            if isready(screen.plot_initialized)
                # plot_initialized contains already an item
                # This should not happen, but lets check anyways, so it errors and doesn't hang forever
                error("Plot initialized multiple times?")
            end
            if initialized == true
                put!(screen.plot_initialized, true)
                mark_as_displayed!(screen, scene)
                start_polling_loop!(screen, scene)
                connect_post_init_events(screen, scene)
            else
                # Will be an error from WGLMakie.js
                put!(screen.plot_initialized, initialized)
            end
            return
        end
        on(session, session.on_close) do closed
            if closed == true
                scene.events.window_open[] = false
            end
            return
        end
        return canvas
    catch e
        put!(screen.plot_initialized, e)
        rethrow(e)
    end
end

function Bonito.jsrender(session::Session, scene::Scene)
    screen = Screen()
    screen.scene = scene
    return render_with_init(screen, session, scene)
end

function Bonito.jsrender(session::Session, fig::Makie.FigureLike)
    Makie.update_state_before_display!(fig)
    return Bonito.jsrender(session, Makie.get_scene(fig))
end


"""
    WithConfig(fig::Makie.FigureLike; screen_config...)

Allows to pass a screenconfig to a figure, inside a Bonito.App.
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
    config = Makie.merge_screen_config(ScreenConfig, Dict{Symbol, Any}(kw))
    return WithConfig(fig, config)
end

function Bonito.jsrender(session::Session, wconfig::WithConfig)
    fig = wconfig.fig
    Makie.update_state_before_display!(fig)
    scene = Makie.get_scene(fig)
    screen = Screen(scene, wconfig.config)
    return render_with_init(screen, session, scene)
end


function Base.show(io::IO, screen::Screen)
    c = screen.config
    ppu = c.px_per_unit
    sf = c.scalefactor
    three_str = sprint(io -> show(io, MIME"text/plain"(), screen.plot_initialized))
    return print(
        io, """WGLMakie.Screen(
            framerate = $(c.framerate),
            resize_to = $(c.resize_to),
            px_per_unit = $(isnothing(ppu) ? :automatic : ppu),
            scalefactor = $(isnothing(sf) ? :automatic : sf),
            session = $(isnothing(screen.session) ? :nothing : isopen(screen.session)),
            three = $(three_str),
            scene = $(isnothing(screen.scene) ? :nothing : screen.scene),
        )"""
    )
end

# Resizing the scene is enough for WGLMakie
Base.resize!(::WGLMakie.Screen, w, h) = nothing

function Base.isopen(screen::Screen)
    # This function is used as the source of truth for dynamically setting
    # window_open[] = false (as opposed to using close()), so it can't just
    # rely on window_open. Check the session too.
    return !isnothing(screen.scene) && screen.scene.events.window_open[] &&
        !isnothing(screen.session) && isopen(screen.session)
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
            inline_display = App(title = "WGLMakie") do session::Session
                return render_with_init(screen, session, scene)
            end
            Base.show(io, m, inline_display)
            return screen
        end
    end
end

function Makie.backend_showable(::Type{Screen}, ::T) where {T <: MIME}
    return T in Makie.WEB_MIMES
end

function Base.close(screen::Screen; from_close = false)
    return lock(screen.lock) do
        scene = screen.scene
        session = nothing
        if !isnothing(screen.session) && isopen(screen.session) && !from_close
            session = Bonito.root_session(screen.session)
        end
        if !isnothing(screen.scene)
            scene = screen.scene
            filter!(x -> x !== screen, scene.current_screens)
            events(scene).window_open[] = false
            Makie.for_each_atomic_plot(scene) do plot
                delete_wgl_robj!(session, plot)
            end
        end
        Makie.stop!(screen.tick_clock)
        if !screen.tick_clock.running && isnothing(screen.scene) && (isnothing(screen.session) || !isopen(screen.session))
            # If the screen is already closed, we don't need to do anything
            return
        end
        if !isnothing(session) && !isnothing(screen.canvas) && !isnothing(scene)
            evaljs_value(
                session, js"""$(WGL).then(WGL => {
                    const canvas = $(screen.canvas);
                    const screen = canvas?.firstElementChild?.wglmakie_screen
                    if (screen) {
                        console.log("Disposing screen", screen);
                        WGL.dispose_screen(screen)
                    }
                })
                """
            )
        end
        return
    end
end

function Base.size(screen::Screen)
    return size(screen.scene)
end

function get_screen_session(
        screen::Screen; timeout = 100,
        error::Union{Nothing, String} = nothing
    )::Union{Nothing, Session}
    function maybe_throw(status)
        return if !isnothing(error)
            message = "Can't get three: $(status)\n$(error)"
            Base.error(message)
        else
            # @warn "Can't get three: $(status)\n$(error)"
        end
    end
    if isnothing(screen.session)
        maybe_throw("Screen has no session. Not yet displayed?")
        return nothing
    end
    session = screen.session
    if !(session.status in (Bonito.RENDERED, Bonito.DISPLAYED, Bonito.OPEN))
        maybe_throw("Screen Session uninitialized. Not yet displayed? Session status: $(screen.session.status), id: $(session.id)")
        return nothing
    end
    success = Bonito.wait_for_ready(session; timeout = timeout)
    success === :closed && return nothing
    if success !== :success
        maybe_throw("Timed out waiting for session to get ready")
        return nothing
    end
    success = Bonito.wait_for(timeout = timeout) do
        Bonito.isclosed(session) && return :closed
        isready(screen.plot_initialized)
    end
    # session closed inbetween, nothing can be done
    success === :closed && return nothing
    # Throw error if error message specified
    if success !== :success || !isopen(session)
        maybe_throw("Timed out waiting $(timeout)s for session to get initialize")
        return nothing
    end
    value = fetch(screen.plot_initialized)
    if value !== true
        maybe_throw("Error initializing plot: $(value)")
        return nothing
    end
    # At this point we should have a fully initialized plot + session
    return session
end

function Makie.apply_screen_config!(screen::Screen, config::ScreenConfig, args...)
    #TODO implement
    return screen
end

# TODO, create optimized screens, forward more options to JS/WebGL
function Screen(scene::Scene; kw...)
    config = Makie.merge_screen_config(ScreenConfig, Dict{Symbol, Any}(kw))
    screen = Screen(scene, config)
    return screen
end

function Screen(scene::Scene, config::ScreenConfig, ::IO, ::MIME)
    screen = Screen(scene, config)
    return screen
end

function Screen(scene::Scene, config::ScreenConfig, ::Makie.ImageStorageFormat)
    screen = Screen(scene, config)
    return screen
end

function Base.empty!(screen::Screen)
    screen.scene = nothing
    screen.plot_initialized = Channel{Any}(1)
    return
    # TODO, empty state in JS, to be able to reuse screen
end

Makie.wait_for_display(screen::Screen) = get_screen_session(screen)

function Base.display(screen::Screen, scene::Scene; unused...)
    # already displayed!
    if scene_already_displayed(screen, scene)
        return screen
    end
    app = App(title = "WGLMakie") do session
        return render_with_init(screen, session, scene)
    end
    display(app)
    Bonito.wait_for(() -> !isnothing(screen.session))
    Bonito.wait_for_ready(screen.session)
    # wait for plot to be full initialized, so that operations don't get racy (e.g. record/RamStepper & friends)
    get_screen_session(screen; error = "Waiting for plot to be initialized in display")
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
    picture_base64 = Bonito.evaljs_value(session, to_data; timeout = 100)
    picture_base64 = replace(picture_base64, "data:image/png;base64," => "")
    bytes = Bonito.Base64.base64decode(picture_base64)
    return PNGFiles.load(IOBuffer(bytes))
end

function Makie.colorbuffer(screen::Screen)
    if isnothing(screen.session)
        Base.display(screen, screen.scene)
    end
    session = get_screen_session(screen; error = "Not able to show scene in a browser")
    poll_all_plots(screen.scene)
    return session2image(session, screen.scene)
end

function insert_scene!(session::Session, screen::Screen, scene::Scene)
    if js_uuid(scene) in screen.displayed_scenes
        return true
    else
        if !(js_uuid(scene.parent) in screen.displayed_scenes)
            # Parents serialize their child scenes, so we only need to
            # serialize & update the parent scene
            return insert_scene!(session, screen, scene.parent)
        end
        scene_ser = serialize_scene(scene)
        parent = scene.parent
        parent_uuid = js_uuid(parent)
        err = "Cannot find scene js_uuid(scene) == $(parent_uuid)"
        evaljs_value(
            session, js"""
            $(WGL).then(WGL=> {
                const parent = WGL.find_scene($(parent_uuid));
                if (!parent) {
                    throw new Error($(err))
                }
                const new_scene = WGL.deserialize_scene($scene_ser, parent.screen);
                parent.scene_children.push(new_scene);
            })
            """
        )
        mark_as_displayed!(screen, scene)
        return false
    end
end

function insert_plot!(session::Session, scene::Scene, @nospecialize(plot::Plot))
    plot_data = serialize_plots(scene, Plot[plot])
    # serialize + evaljs via sub session, so we can keep track of those observables
    js = js"""
    $(WGL).then(WGL=> {
        WGL.insert_plot($(js_uuid(scene)), $plot_data);
    })"""
    Bonito.evaljs_value(session, js; timeout = 10, error_on_closed = false)
    return
end

function Base.insert!(::Screen, ::Scene, @nospecialize(plot::PlotList))
    return nothing
end

function Base.insert!(screen::Screen, scene::Scene, @nospecialize(plot::Plot))
    session = get_screen_session(screen; error = "Plot needs to be displayed to insert additional plots")
    if js_uuid(scene) in screen.displayed_scenes
        insert_plot!(session, scene, plot)
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
        insert_scene!(session, screen, scene)
    end
    return
end


function all_plots_scenes(scene::Scene; scene_uuids = String[], plots = Plot[])
    push!(scene_uuids, js_uuid(scene))
    append!(plots, scene.plots)
    for child in scene.children
        all_plots_scenes(child; plots = plots, scene_uuids = scene_uuids)
    end
    return scene_uuids, plots
end

function delete_wgl_robj!(session::Union{Nothing, Session}, plot::Plot)
    # Delete the renderobject, so that we can free the memory
    if haskey(plot.attributes, :wgl_renderobject)
        delete!(plot.attributes, :wgl_renderobject, force = true)
    end
    if haskey(plot.attributes, :wgl_update_obs)
        obs = plot.attributes[:wgl_update_obs][]
        delete!(plot.attributes, :wgl_update_obs)
        if !isnothing(session)
            root = Bonito.root_session(session)
            Bonito.delete_cached!(root, root, obs.id)
        end
    end
    return
end


# Can be called from finalizer!
function Base.delete!(screen::Screen, ::Scene, plot::Plot)
    # # only queue atomics to actually delete on js
    atomics = Makie.collect_atomic_plots(plot)
    session = get_screen_session(screen)
    for plot in atomics
        delete_wgl_robj!(session, plot)
    end
    plot_uuids = map(js_uuid, atomics)
    isnothing(session) && return # if no session we haven't displayed and dont need to delete
    # Eval in root session, since main_session might be gone (e.g. getting closed just shortly before freeing the plots)
    root = Bonito.root_session(session)
    isready(root) || return nothing
    Bonito.evaljs(
        root, js"""
        $(WGL).then(WGL=> {
            WGL.delete_plots($(plot_uuids));
        })"""
    )
    return
end


function Base.delete!(screen::Screen, scene::Scene)
    delete!(screen.displayed_scenes, js_uuid(scene))
    session = get_screen_session(screen)
    isnothing(session) && return # if no session we haven't displayed and dont need to delete
    # Eval in root session, since main_session might be gone (e.g. getting closed just shortly before freeing the plots)
    root = Bonito.root_session(session)
    isready(root) || return nothing
    scene_uuids, plots = all_plots_scenes(scene)
    for plot in plots
        delete_wgl_robj!(root, plot)
    end
    Bonito.evaljs_value(
        root, js"""
        $(WGL).then(WGL=> {
            WGL.delete_scenes($scene_uuids, $(js_uuid.(plots)));
        })"""
    )
    return
end
