const ScreenID = UInt16
const ZIndex = Int
# ID, Area, clear, is visible, background color
const ScreenArea = Tuple{ScreenID, Scene}

function renderloop end

"""
## Renderloop

* `renderloop = GLMakie.renderloop`: Sets a function `renderloop(::GLMakie.Screen)` which starts a renderloop for the screen.

!!! warning
    The keyword arguments below are not effective if `renderloop` isn't set to `GLMakie.renderloop`, unless implemented in a custom renderloop function:

* `pause_renderloop = false`: If `true`, creates a screen with a paused renderloop. The renderloop can be started with `GLMakie.start_renderloop!(screen)` and paused again with `GLMakie.pause_renderloop!(screen)`.
* `vsync = false`: Whether to enable vsync for the window.
* `render_on_demand = true`: If `true`, the scene will only be rendered if something has changed in it.
* `framerate = 30.0`: Sets the currently rendered frames per second.
* `px_per_unit = automatic`: Sets the ratio between the number of rendered pixels and the `Makie` resolution. It defaults to the value of `scalefactor` but may be any positive real number.

## GLFW window attributes
* `float = false`: Whether the window should float above other windows.
* `focus_on_show = false`: If `true`, focuses the window when newly opened.
* `decorated = true`: Whether or not to show window decorations.
* `title::String = "Makie"`: Sets the window title.
* `fullscreen = false`: Whether to start the window in fullscreen mode.
* `debugging = false`: If `true`, starts the GLFW.Window/OpenGL context with debug output.
* `monitor::Union{Nothing, GLFW.Monitor} = nothing`: Sets the monitor on which the window should be opened. If set to `nothing`, GLFW will decide which monitor to use.
* `visible = true`: Whether or not the window should be visible when first created.
* `scalefactor = automatic`: Sets the window scaling factor, such as `2.0` on HiDPI/Retina displays. It is set automatically based on the display, but may be any positive real number.

## Rendering constants & Postprocessor
* `oit = false`: Whether to enable order independent transparency for the window.
* `fxaa = true`: Whether to enable fxaa (anti-aliasing) for the window.
* `ssao = true`: Whether to enable screen space ambient occlusion, which simulates natural shadowing at inner edges and crevices.
* `transparency_weight_scale = 1000f0`: Adjusts a factor in the rendering shaders for order independent transparency.
    This should be the same for all of them (within one rendering pipeline) otherwise depth "order" will be broken.
* `max_lights = 64`: The maximum number of lights with `shading = MultiLightShading`
* `max_light_parameters = 5 * N_lights`: The maximum number of light parameters that can be uploaded. These include everything other than the light color (i.e. position, direction, attenuation, angles) in terms of scalar floats.
"""
mutable struct ScreenConfig
    # Renderloop
    renderloop::Function
    pause_renderloop::Bool
    vsync::Bool
    render_on_demand::Bool
    framerate::Float64
    px_per_unit::Union{Nothing, Float32}

    # GLFW window attributes
    float::Bool
    focus_on_show::Bool
    decorated::Bool
    title::String
    fullscreen::Bool
    debugging::Bool
    monitor::Union{Nothing, GLFW.Monitor}
    visible::Bool
    scalefactor::Union{Nothing, Float32}

    # Render Constants & Postprocessor
    oit::Bool
    fxaa::Bool
    ssao::Bool
    transparency_weight_scale::Float32
    max_lights::Int
    max_light_parameters::Int

    function ScreenConfig(
            # Renderloop
            renderloop::Union{Makie.Automatic, Function},
            pause_renderloop::Bool,
            vsync::Bool,
            render_on_demand::Bool,
            framerate::Number,
            px_per_unit::Union{Makie.Automatic, Number},
            # GLFW window attributes
            float::Bool,
            focus_on_show::Bool,
            decorated::Bool,
            title::AbstractString,
            fullscreen::Bool,
            debugging::Bool,
            monitor::Union{Nothing, GLFW.Monitor},
            visible::Bool,
            scalefactor::Union{Makie.Automatic, Number},

            # Preprocessor
            oit::Bool,
            fxaa::Bool,
            ssao::Bool,
            transparency_weight_scale::Number,
            max_lights::Int,
            max_light_parameters::Int)
        return new(
            # Renderloop
            renderloop isa Makie.Automatic ? GLMakie.renderloop : renderloop,
            pause_renderloop,
            vsync,
            render_on_demand,
            framerate,
            px_per_unit isa Makie.Automatic ? nothing : Float32(px_per_unit),
            # GLFW window attributes
            float,
            focus_on_show,
            decorated,
            title,
            fullscreen,
            debugging,
            monitor,
            visible,
            scalefactor isa Makie.Automatic ? nothing : Float32(scalefactor),
            # Preproccessor
            # Preprocessor
            oit,
            fxaa,
            ssao,
            transparency_weight_scale,
            max_lights,
            max_light_parameters)
    end
end

const LAST_INLINE = Ref{Union{Makie.Automatic, Bool}}(false)

"""
    GLMakie.activate!(; screen_config...)

Sets GLMakie as the currently active backend and also optionally modifies the screen configuration using `screen_config` keyword arguments.
Note that the `screen_config` can also be set permanently via `Makie.set_theme!(GLMakie=(screen_config...,))`.

# Arguments one can pass via `screen_config`:

$(Base.doc(ScreenConfig))
"""
function activate!(; inline=LAST_INLINE[], screen_config...)
    if haskey(screen_config, :pause_rendering)
        error("pause_rendering got renamed to pause_renderloop.")
    end
    Makie.inline!(inline)
    LAST_INLINE[] = inline
    Makie.set_screen_config!(GLMakie, screen_config)
    Makie.set_active_backend!(GLMakie)
    return
end

const unimplemented_error = "GLMakie doesn't own screen.glscreen! If you're embedding GLMakie with a custom window type you must specialize this function for your window type."

"""
    Screen(; screen_config...)

# Arguments one can pass via `screen_config`:

$(Base.doc(ScreenConfig))

# Constructors:

$(Base.doc(MakieScreen))
"""
mutable struct Screen{GLWindow} <: MakieScreen
    glscreen::GLWindow
    owns_glscreen::Bool
    shader_cache::GLAbstraction.ShaderCache
    framebuffer::GLFramebuffer
    config::Union{Nothing, ScreenConfig}
    stop_renderloop::Threads.Atomic{Bool}
    rendertask::Union{Task, Nothing}
    timer::BudgetedTimer
    px_per_unit::Observable{Float32}

    screen2scene::Dict{WeakRef, ScreenID}
    screens::Vector{ScreenArea}
    renderlist::Vector{Tuple{ZIndex, ScreenID, RenderObject}}
    postprocessors::Vector{PostProcessor}
    cache::Dict{UInt64, RenderObject}
    cache2plot::Dict{UInt32, Plot}
    framecache::Matrix{RGB{N0f8}}
    render_tick::Observable{Makie.TickState} # listeners must not Consume(true)
    window_open::Observable{Bool}
    scalefactor::Observable{Float32}

    scene::Union{Scene, Nothing}
    reuse::Bool
    close_after_renderloop::Bool
    # To trigger rerenders that aren't related to an existing renderobject.
    requires_update::Bool

    function Screen(
            glscreen::GLWindow,
            owns_glscreen::Bool,
            shader_cache::GLAbstraction.ShaderCache,
            framebuffer::GLFramebuffer,
            config::Union{Nothing, ScreenConfig},
            stop_renderloop::Bool,
            rendertask::Union{Nothing, Task},

            screen2scene::Dict{WeakRef, ScreenID},
            screens::Vector{ScreenArea},
            renderlist::Vector{Tuple{ZIndex, ScreenID, RenderObject}},
            postprocessors::Vector{PostProcessor},
            cache::Dict{UInt64, RenderObject},
            cache2plot::Dict{UInt32, AbstractPlot},
            reuse::Bool
        ) where {GLWindow}

        s = size(framebuffer)
        screen = new{GLWindow}(
            glscreen, owns_glscreen, shader_cache, framebuffer,
            config, Threads.Atomic{Bool}(stop_renderloop), rendertask, BudgetedTimer(1.0 / 30.0),
            Observable(0f0), screen2scene,
            screens, renderlist, postprocessors, cache, cache2plot,
            Matrix{RGB{N0f8}}(undef, s), Observable(Makie.UnknownTickState),
            Observable(true), Observable(0f0), nothing, reuse, true, false
        )
        push!(ALL_SCREENS, screen) # track all created screens
        return screen
    end
end

framebuffer_size(screen::Screen) = screen.framebuffer.resolution[]

Makie.isvisible(screen::Screen) = screen.config.visible

# for e.g. closeall, track all created screens
# gets removed in destroy!(screen)
const ALL_SCREENS = Set{Screen}()

Makie.@noconstprop function empty_screen(debugging::Bool; reuse=true, window=nothing)
    return empty_screen(debugging, reuse, window)
end

Makie.@noconstprop function empty_screen(debugging::Bool, reuse::Bool, window)
    owns_glscreen = isnothing(window)
    initial_resolution = (10, 10)

    if isnothing(window)
        windowhints = [
            (GLFW.SAMPLES,      0),
            (GLFW.DEPTH_BITS,   0),

            # SETTING THE ALPHA BIT IS REALLY IMPORTANT ON OSX, SINCE IT WILL JUST KEEP SHOWING A BLACK SCREEN
            # WITHOUT ANY ERROR -.-
            (GLFW.ALPHA_BITS,   8),
            (GLFW.RED_BITS,     8),
            (GLFW.GREEN_BITS,   8),
            (GLFW.BLUE_BITS,    8),

            (GLFW.STENCIL_BITS, 0),
            (GLFW.AUX_BUFFERS,  0),

            (GLFW.SCALE_TO_MONITOR, true),  # Windows & X11
            (GLFW.SCALE_FRAMEBUFFER, true), # OSX & Wayland
        ]
        window = try
            GLFW.Window(
                resolution = initial_resolution,
                windowhints = windowhints,
                visible = false,
                focus = false,
                fullscreen = false,
                debugging = debugging,
            )
        catch e
            @warn("""
                GLFW couldn't create an OpenGL window.
                This likely means, you don't have an OpenGL capable Graphic Card,
                or you don't have an OpenGL 3.3 capable video driver installed.
                Have a look at the troubleshooting section in the GLMakie readme:
                https://github.com/MakieOrg/Makie.jl/tree/master/GLMakie#troubleshooting-opengl.
            """)
            rethrow(e)
        end

        # GLFW doesn't support setting the icon on OSX
        GLFW.SetWindowIcon(window, Makie.icon())
    end

    # tell GLAbstraction that we created a new context.
    # This is important for resource tracking, and only needed for the first context
    ShaderAbstractions.switch_context!(window)
    shader_cache = GLAbstraction.ShaderCache(window)
    fb = GLFramebuffer(initial_resolution)
    postprocessors = [
        empty_postprocessor(),
        empty_postprocessor(),
        empty_postprocessor(),
        to_screen_postprocessor(fb, shader_cache)
    ]

    screen = Screen(
        window, owns_glscreen, shader_cache, fb,
        nothing, false,
        nothing,
        Dict{WeakRef, ScreenID}(),
        ScreenArea[],
        Tuple{ZIndex, ScreenID, RenderObject}[],
        postprocessors,
        Dict{UInt64, RenderObject}(),
        Dict{UInt32, AbstractPlot}(),
        reuse,
    )

    if owns_glscreen
        GLFW.SetWindowRefreshCallback(window, refreshwindowcb(screen))
        GLFW.SetWindowContentScaleCallback(window, scalechangecb(screen))
    end

    return screen
end

const SCREEN_REUSE_POOL = Set{Screen}()

function reopen!(screen::Screen)
    if !screen.owns_glscreen
        error(unimplemented_error)
    end

    @debug("reopening screen")
    gl = screen.glscreen
    @assert !was_destroyed(gl)
    if GLFW.WindowShouldClose(gl)
        GLFW.SetWindowShouldClose(gl, false)
    end
    @assert isempty(screen.window_open.listeners)
    screen.window_open[] = true
    on(scalechangeobs(screen), screen.scalefactor)
    @assert isopen(screen)
    return screen
end

function screen_from_pool(debugging; window=nothing)
    screen = if isempty(SCREEN_REUSE_POOL)
        @debug("create empty screen for pool")
        empty_screen(debugging; window)
    else
        @debug("get old screen from pool")
        pop!(SCREEN_REUSE_POOL)
    end
    return reopen!(screen)
end

const SINGLETON_SCREEN = Screen[]

function singleton_screen(debugging::Bool)
    if !isempty(SINGLETON_SCREEN)
        @debug("reusing singleton screen")
        screen = SINGLETON_SCREEN[1]
        stop_renderloop!(screen; close_after_renderloop=false)
        empty!(screen)
    else
        @debug("new singleton screen")
        # reuse=false, because we "manually" re-use the singleton screen!
        screen = empty_screen(debugging; reuse=false)
        push!(SINGLETON_SCREEN, screen)
    end
    return reopen!(screen)
end

function Makie.apply_screen_config!(screen::Screen, config::ScreenConfig, scene::Scene, args...)
    apply_config!(screen, config)
end

function apply_config!(screen::Screen, config::ScreenConfig; start_renderloop::Bool=true)
    @debug("Applying screen config! to existing screen")
    glw = screen.glscreen

    if screen.owns_glscreen
        ShaderAbstractions.switch_context!(glw)
        GLFW.SetWindowAttrib(glw, GLFW.FOCUS_ON_SHOW, config.focus_on_show)
        GLFW.SetWindowAttrib(glw, GLFW.DECORATED, config.decorated)
        GLFW.SetWindowTitle(glw, config.title)
        if GLFW.GetPlatform() != GLFW.PLATFORM_WAYLAND
            GLFW.SetWindowAttrib(glw, GLFW.FLOATING, config.float)
        end
        if !isnothing(config.monitor)
            GLFW.SetWindowMonitor(glw, config.monitor)
        end
    end

    screen.scalefactor[] = !isnothing(config.scalefactor) ? config.scalefactor : scale_factor(glw)
    screen.px_per_unit[] = !isnothing(config.px_per_unit) ? config.px_per_unit : screen.scalefactor[]
    function replace_processor!(postprocessor, idx)
        fb = screen.framebuffer
        shader_cache = screen.shader_cache
        post = screen.postprocessors[idx]
        if post.constructor !== postprocessor
            destroy!(screen.postprocessors[idx])
            screen.postprocessors[idx] = postprocessor(fb, shader_cache)
        end
        return
    end

    replace_processor!(config.ssao ? ssao_postprocessor : empty_postprocessor, 1)
    replace_processor!(config.oit ? OIT_postprocessor : empty_postprocessor, 2)
    replace_processor!(config.fxaa ? fxaa_postprocessor : empty_postprocessor, 3)

    # TODO: replace shader programs with lighting to update N_lights & N_light_parameters

    # Set the config
    screen.config = config
    if start_renderloop
        start_renderloop!(screen)
    else
        stop_renderloop!(screen)
    end
    if !isnothing(screen.scene)
        resize!(screen, size(screen.scene)...)
    end
    set_screen_visibility!(screen, config.visible)
    return screen
end

function Screen(;
        resolution::Union{Nothing, Tuple{Int, Int}} = nothing,
        start_renderloop = true,
        window = nothing,
        screen_config...
    )
    # Screen config is managed by the current active theme, so managed by Makie
    config = Makie.merge_screen_config(ScreenConfig, Dict{Symbol, Any}(screen_config))
    screen = screen_from_pool(config.debugging; window)
    apply_config!(screen, config; start_renderloop=start_renderloop)
    if !isnothing(resolution)
        resize!(screen, resolution...)
    end
    return screen
end

function set_screen_visibility!(screen::Screen, visible::Bool)
    if !screen.owns_glscreen
        error(unimplemented_error)
    end

    set_screen_visibility!(screen.glscreen, visible)
end

function set_screen_visibility!(nw::GLFW.Window, visible::Bool)
    @assert nw.handle !== C_NULL
    GLFW.set_visibility!(nw, visible)
end

function display_scene!(screen::Screen, scene::Scene)
    @debug("display scene on screen")
    resize!(screen, size(scene)...)
    insertplots!(screen, scene)
    Makie.push_screen!(scene, screen)
    connect_screen(scene, screen)
    screen.scene = scene
    return
end

Makie.@noconstprop function Screen(scene::Scene; start_renderloop=true, screen_config...)
    config = Makie.merge_screen_config(ScreenConfig, Dict{Symbol, Any}(screen_config))
    return Screen(scene, config; start_renderloop=start_renderloop)
end

# Open an interactive window
Makie.@noconstprop function Screen(scene::Scene, config::ScreenConfig; visible=nothing,
                                     start_renderloop=true)
    screen = singleton_screen(config.debugging)
    !isnothing(visible) && (config.visible = visible)
    apply_config!(screen, config; start_renderloop=start_renderloop)
    display_scene!(screen, scene)
    return screen
end

# Screen to save a png/jpeg to file or io
Makie.@noconstprop function Screen(scene::Scene, config::ScreenConfig, io::Union{Nothing,String,IO},
                                     typ::MIME; visible=nothing, start_renderloop=false)
    screen = singleton_screen(config.debugging)
    !isnothing(visible) && (config.visible = visible)
    apply_config!(screen, config; start_renderloop=start_renderloop)
    display_scene!(screen, scene)
    return screen
end

# Screen that is efficient for `colorbuffer(screen)`
Makie.@noconstprop function Screen(scene::Scene, config::ScreenConfig, ::Makie.ImageStorageFormat;
                                     start_renderloop=false)
    screen = singleton_screen(config.debugging)
    config.visible = false
    apply_config!(screen, config; start_renderloop=start_renderloop)
    display_scene!(screen, scene)
    return screen
end

function pollevents(screen::Screen, frame_state::Makie.TickState)
    ShaderAbstractions.switch_context!(screen.glscreen)
    GLFW.PollEvents()
    screen.render_tick[] = frame_state
    return
end

Base.wait(x::Screen) = !isnothing(x.rendertask) && wait(x.rendertask)
Base.wait(scene::Scene) = wait(Makie.getscreen(scene))

Base.show(io::IO, screen::Screen) = print(io, "GLMakie.Screen(...)")

Base.isopen(x::Screen) = isopen(x.glscreen)
Base.size(x::Screen) = size(x.framebuffer)

function add_scene!(screen::Screen, scene::Scene)
    get!(screen.screen2scene, WeakRef(scene)) do
        id = length(screen.screens) + 1
        push!(screen.screens, (id, scene))
        screen.requires_update = true
        onany((args...) -> screen.requires_update = true,
              scene,
              scene.visible, scene.backgroundcolor, scene.clear,
              scene.ssao.bias, scene.ssao.blur, scene.ssao.radius, scene.camera.projectionview,
              scene.camera.resolution)
        return id
    end
    return
end

function Makie.insertplots!(screen::Screen, scene::Scene)
    ShaderAbstractions.switch_context!(screen.glscreen)
    add_scene!(screen, scene)
    for elem in scene.plots
        insert!(screen, scene, elem)
    end
    for s in scene.children
        insertplots!(screen, s)
    end
end

function Base.delete!(screen::Screen, scene::Scene)
    for child in scene.children
        delete!(screen, child)
    end
    for plot in scene.plots
        delete!(screen, scene, plot)
    end
    filter!(x -> x !== screen, scene.current_screens)
    if haskey(screen.screen2scene, WeakRef(scene))
        deleted_id = pop!(screen.screen2scene, WeakRef(scene))
        # TODO: this should always find something but sometimes doesn't...
        i = findfirst(id_scene -> id_scene[1] == deleted_id, screen.screens)
        i !== nothing && deleteat!(screen.screens, i)

        # Remap scene IDs to a continuous range by replacing the largest ID
        # with the one that got removed
        if deleted_id - 1 != length(screen.screens)
            key, max_id = first(screen.screen2scene)
            for p in screen.screen2scene
                if p[2] > max_id
                    key, max_id = p
                end
            end

            i = findfirst(id_scene -> id_scene[1] == max_id, screen.screens)::Int
            screen.screens[i] = (deleted_id, screen.screens[i][2])

            screen.screen2scene[key] = deleted_id

            for (i, (z, id, robj)) in enumerate(screen.renderlist)
                if id == max_id
                    screen.renderlist[i] = (z, deleted_id, robj)
                end
            end
        end
    end
    return
end

function destroy!(rob::RenderObject)
    # These need explicit clean up because (some of) the source observables
    # remain when the plot is deleted.
    GLAbstraction.switch_context!(rob.context)
    tex = get_texture!(gl_texture_atlas())
    for (k, v) in rob.uniforms
        if v isa Observable
            Observables.clear(v)
        elseif v isa GPUArray && v !== tex
            # We usually don't share gpu data and it should be hard for users to share buffers..
            # but we do share the texture atlas, so we check v !== tex, since we can't just free shared resources

            # TODO, refcounting, or leaving freeing to GC...
            # GC is a bit tricky with active contexts, so immediate free is preferred.
            # I guess as long as we make it hard for users to share buffers directly, this should be fine!
            GLAbstraction.free(v)
        end
    end
    for obs in rob.observables
        Observables.clear(obs)
    end
    GLAbstraction.free(rob.vertexarray)
end

function Base.delete!(screen::Screen, scene::Scene, plot::AbstractPlot)
    if !isempty(plot.plots)
        # this plot consists of children, so we flatten it and delete the children instead
        for cplot in Makie.collect_atomic_plots(plot)
            delete!(screen, scene, cplot)
        end
    else
        # I think we can double delete renderobjects, so this may be ok
        # TODO, is it?
        renderobject = get(screen.cache, objectid(plot), nothing)
        if !isnothing(renderobject)
            destroy!(renderobject)
            filter!(x-> x[3] !== renderobject, screen.renderlist)
            delete!(screen.cache2plot, renderobject.id)
        end
        delete!(screen.cache, objectid(plot))
    end
    screen.requires_update = true
    return
end

function Base.empty!(screen::Screen)
    @debug("empty screen!")
    # we should never just "empty" an already destroyed screen
    @assert !was_destroyed(screen.glscreen)

    for plot in collect(values(screen.cache2plot))
        delete!(screen, Makie.rootparent(plot), plot)
    end

    if !isnothing(screen.scene)
        Makie.disconnect_screen(screen.scene, screen)
        delete!(screen, screen.scene)
        screen.scene = nothing
    end

    @assert isempty(screen.renderlist)
    @assert isempty(screen.cache2plot)
    @assert isempty(screen.cache)

    empty!(screen.screen2scene)
    empty!(screen.screens)
    Observables.clear(screen.px_per_unit)
    Observables.clear(screen.scalefactor)
    Observables.clear(screen.render_tick)
    Observables.clear(screen.window_open)
    GLFW.PollEvents()
    return
end

function destroy!(screen::Screen)
    @debug("Destroy screen!")
    close(screen; reuse=false)
    # wait for rendertask to finish
    # otherwise, during rendertask clean up we may run into a destroyed window
    wait(screen)
    screen.rendertask = nothing
    window = screen.glscreen
    GLFW.SetWindowRefreshCallback(window, nothing)
    GLFW.SetWindowContentScaleCallback(window, nothing)
    destroy!(window)
    # Since those are sets, we can just delete them from there, even if they weren't in there (e.g. reuse=false)
    delete!(SCREEN_REUSE_POOL, screen)
    delete!(ALL_SCREENS, screen)
    if screen in SINGLETON_SCREEN
        empty!(SINGLETON_SCREEN)
    end
    return
end

"""
    close(screen::Screen; reuse=true)

Closes screen and empties it.
Doesn't destroy the screen and instead frees it to be re-used again, if `reuse=true`.
"""
function Base.close(screen::Screen; reuse=true)
    @debug("Close screen!")
    set_screen_visibility!(screen, false)
    if screen.window_open[] # otherwise we trigger an infinite loop of closing
        screen.window_open[] = false
    end
    empty!(screen)
    stop_renderloop!(screen; close_after_renderloop=false)

    if reuse && screen.reuse
        @debug("reusing screen!")
        push!(SCREEN_REUSE_POOL, screen)
    end
    GLFW.SetWindowShouldClose(screen.glscreen, true)
    GLFW.PollEvents()
    # Somehow, on osx, we need to hide the screen a second time!
    set_screen_visibility!(screen, false)
    return
end

function closeall(; empty_shader=true)
    # Since we call closeall to reload any shader
    # We empty the shader source cache here
    if empty_shader
        empty!(LOADED_SHADERS)
        WARN_ON_LOAD[] = false
    end

    while !isempty(ALL_SCREENS)
        screen = pop!(ALL_SCREENS)
        destroy!(screen)
    end
    empty!(SINGLETON_SCREEN)
    empty!(SCREEN_REUSE_POOL)
    return
end

function Base.resize!(screen::Screen, w::Int, h::Int)
    window = to_native(screen)
    (w > 0 && h > 0 && isopen(window)) || return nothing

    if screen.owns_glscreen
        # Resize the window which appears on the user desktop (if necessary).
        #
        # On some platforms(OSX and Wayland), the window size is given in logical dimensions and
        # is automatically scaled by the OS. To support arbitrary scale factors, we must account
        # for the native scale factor when calculating the effective scaling to apply.
        #
        # On others (Windows and X11), scale from the logical size to the pixel size.
        ShaderAbstractions.switch_context!(window)
        winscale = screen.scalefactor[]
        if GLFW.GetPlatform() in (GLFW.PLATFORM_COCOA, GLFW.PLATFORM_WAYLAND)
            winscale /= scale_factor(window)
        end
        winw, winh = round.(Int, winscale .* (w, h))
        if window_size(window) != (winw, winh)
            GLFW.SetWindowSize(window, winw, winh)
        end
    end

    # Then resize the underlying rendering framebuffers as well, which can be scaled
    # independently of the window scale factor.
    fbscale = screen.px_per_unit[]
    fbw, fbh = round.(Int, fbscale .* (w, h))
    resize!(screen.framebuffer, fbw, fbh)
    return nothing
end

function fast_color_data!(dest::Array{RGB{N0f8}, 2}, source::Texture{T, 2}) where T
    GLAbstraction.bind(source)
    glPixelStorei(GL_PACK_ALIGNMENT, 1)
    glGetTexImage(source.texturetype, 0, GL_RGB, GL_UNSIGNED_BYTE, dest)
    GLAbstraction.bind(source, 0)
    return
end

"""
    depthbuffer(screen::Screen)

Gets the depth buffer of `screen`.  Returns a `Matrix{Float32}` of the dimensions of the screen's `framebuffer`.

A depth buffer is used to determine which plot's contents should be shown at each pixel.
Usage:
```
using Makie, GLMakie
x = scatter(1:4)
screen = display(x)
depth_color = GLMakie.depthbuffer(screen)
# Look at result:
heatmap(depth_color, colormap=:grays)
```
"""
function depthbuffer(screen::Screen)
    ShaderAbstractions.switch_context!(screen.glscreen)
    render_frame(screen, resize_buffers=false) # let it render
    glFinish() # block until opengl is done rendering
    source = screen.framebuffer.buffers[:depth]
    depth = Matrix{Float32}(undef, size(source))
    GLAbstraction.bind(source)
    GLAbstraction.glGetTexImage(source.texturetype, 0, GL_DEPTH_COMPONENT, GL_FLOAT, depth)
    GLAbstraction.bind(source, 0)
    return depth
end

function Makie.colorbuffer(screen::Screen, format::Makie.ImageStorageFormat = Makie.JuliaNative)
    if !isopen(screen)
        error("Screen not open!")
    end
    ShaderAbstractions.switch_context!(screen.glscreen)
    ctex = screen.framebuffer.buffers[:color]
    # polling may change window size, when its bigger than monitor!
    # we still need to poll though, to get all the newest events!
    pollevents(screen, Makie.BackendTick)
    # keep current buffer size to allows larger-than-window renders
    render_frame(screen, resize_buffers=false) # let it render
    if screen.config.visible
        GLFW.SwapBuffers(to_native(screen))
    else
        # SwapBuffers blocks as well, but if we don't call that
        # We need to call glFinish to wait for all OpenGL changes to finish
        glFinish()
    end
    if size(ctex) != size(screen.framecache)
        screen.framecache = Matrix{RGB{N0f8}}(undef, size(ctex))
    end
    fast_color_data!(screen.framecache, ctex)
    if format == Makie.GLNative
        return screen.framecache
    elseif format == Makie.JuliaNative
        img = screen.framecache
        return PermutedDimsArray(view(img, :, size(img, 2):-1:1), (2, 1))
    end
end

function Base.push!(screen::Screen, scene::Scene, robj)
    # filter out gc'ed elements
    filter!(screen.screen2scene) do (k, v)
        k.value !== nothing
    end
    screenid = get!(screen.screen2scene, WeakRef(scene)) do
        id = length(screen.screens) + 1
        push!(screen.screens, (id, scene))
        return id
    end
    push!(screen.renderlist, (0, screenid, robj))
    return robj
end

Makie.to_native(x::Screen) = x.glscreen

function renderloop_running(screen::Screen)
    return !screen.stop_renderloop[] && !isnothing(screen.rendertask) && !istaskdone(screen.rendertask)
end

function start_renderloop!(screen::Screen)
    if renderloop_running(screen)
        screen.config.pause_renderloop = false
        return
    else
        screen.stop_renderloop[] = false
        task = @async screen.config.renderloop(screen)
        yield()
        if istaskstarted(task)
            screen.rendertask = task
        elseif istaskfailed(task)
            fetch(task)
        else
            error("What's up with task $(task)")
        end
    end
end

function pause_renderloop!(screen::Screen)
    screen.config.pause_renderloop = true
end

function stop_renderloop!(screen::Screen; close_after_renderloop=screen.close_after_renderloop)
    # don't double close when stopping renderloop
    c = screen.close_after_renderloop
    screen.close_after_renderloop = close_after_renderloop
    screen.stop_renderloop[] = true
    # stop_renderloop! may be called inside renderloop as part of close
    # in which case we should not wait for the task to finish (deadlock)
    if Base.current_task() != screen.rendertask
        wait(screen)  # handle isnothing(rendertask) in wait(screen)
        # after done, we can set the task to nothing
        screen.rendertask = nothing
    end
    # else, we can't do that much in the rendertask itself
    screen.close_after_renderloop = c
    return
end

function set_framerate!(screen::Screen, fps=30)
    screen.config.framerate = fps
end

function refreshwindowcb(screen, window)
    screen.render_tick[] = Makie.BackendTick
    render_frame(screen)
    GLFW.SwapBuffers(window)
    return
end
refreshwindowcb(screen) = window -> refreshwindowcb(screen, window)

function scalechangecb(screen, window, xscale, yscale)
    sf = min(xscale, yscale)
    if isnothing(screen.config.px_per_unit) && screen.scalefactor[] == screen.px_per_unit[]
        screen.px_per_unit[] = sf
    end
    screen.scalefactor[] = sf
    return
end
scalechangecb(screen) = (window, xscale, yscale) -> scalechangecb(screen, window, xscale, yscale)

function scalechangeobs(screen, _)
    if !isnothing(screen.scene)
        resize!(screen, size(screen.scene)...)
    end
    return nothing
end
scalechangeobs(screen) = scalefactor -> scalechangeobs(screen, scalefactor)


function vsynced_renderloop(screen)
    while isopen(screen) && !screen.stop_renderloop[]
        if screen.config.pause_renderloop
            pollevents(screen, Makie.PausedRenderTick); sleep(0.1)
            continue
        end
        pollevents(screen, Makie.RegularRenderTick) # GLFW poll
        render_frame(screen)
        yield()
        GC.safepoint()
        GLFW.SwapBuffers(to_native(screen))
    end
end

function fps_renderloop(screen::Screen)
    reset!(screen.timer, 1.0 / screen.config.framerate)
    while isopen(screen) && !screen.stop_renderloop[]
        if screen.config.pause_renderloop
            pollevents(screen, Makie.PausedRenderTick)
        else
            pollevents(screen, Makie.RegularRenderTick)
            render_frame(screen)
            GLFW.SwapBuffers(to_native(screen))
        end

        GC.safepoint()
        sleep(screen.timer)
    end
end

function requires_update(screen::Screen)
    if screen.requires_update
        screen.requires_update = false
        return true
    end

    return false
end


# const time_record = sizehint!(Float64[], 100_000)

function on_demand_renderloop(screen::Screen)
    tick_state = Makie.UnknownTickState
    # last_time = time_ns()
    reset!(screen.timer, 1.0 / screen.config.framerate)
    while isopen(screen) && !screen.stop_renderloop[]
        pollevents(screen, tick_state) # GLFW poll

        if !screen.config.pause_renderloop && requires_update(screen)
            tick_state = Makie.RegularRenderTick
            render_frame(screen)
            GLFW.SwapBuffers(to_native(screen))
        else
            tick_state = ifelse(screen.config.pause_renderloop, Makie.PausedRenderTick, Makie.SkippedRenderTick)
        end

        GC.safepoint()
        sleep(screen.timer)

        # t = time_ns()
        # push!(time_record, 1e-9 * (t - last_time))
        # last_time = t
    end
    cause = screen.stop_renderloop[] ? "stopped renderloop" : "closing window"
    @debug("Leaving renderloop, cause: $(cause)")
end

function renderloop(screen)
    isopen(screen) || error("Screen most be open to run renderloop!")
    # Context needs to be current for GLFW.SwapInterval
    ShaderAbstractions.switch_context!(screen.glscreen)
    try
        if screen.config.render_on_demand
            GLFW.SwapInterval(0)
            on_demand_renderloop(screen)
        elseif screen.config.vsync
            GLFW.SwapInterval(1)
            vsynced_renderloop(screen)
        else
            GLFW.SwapInterval(0)
            fps_renderloop(screen)
        end
    catch e
        @warn "error in renderloop" exception=(e, Base.catch_backtrace())
        rethrow(e)
    end
    if screen.close_after_renderloop
        try
            @debug("Closing screen after quitting renderloop!")
            close(screen)
        catch e
            @warn "error closing screen" exception=(e, Base.catch_backtrace())
        end
    end
    screen.rendertask = nothing
    return
end

function plot2robjs(screen::Screen, plot)
    plots = Makie.collect_atomic_plots(plot)
    return map(x-> screen.cache[objectid(x)], plots)
end

export plot2robjs
