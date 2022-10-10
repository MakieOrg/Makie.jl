const ScreenID = UInt8
const ZIndex = Int
# ID, Area, clear, is visible, background color
const ScreenArea = Tuple{ScreenID, Scene}

function renderloop end

"""
## Renderloop

* `renderloop = GLMakie.renderloop`: sets a function `renderloop(::GLMakie.Screen)` which starts a renderloop for the screen.


    !!! warning
    The below are not effective if renderloop isn't set to `GLMakie.renderloop`, unless implemented in custom renderloop:


* `pause_renderloop = false`: creates a screen with paused renderlooop. Can be started with `GLMakie.start_renderloop!(screen)` or paused again with `GLMakie.pause_renderloop!(screen)`.
* `vsync = false`: enables vsync for the window.
* `framerate = 30.0`: sets the currently rendered frames per second.

## GLFW window attributes
* `float = false`: Lets the opened window float above anything else.
* `focus_on_show = false`: Focusses the window when newly opened.
* `decorated = true`: shows the window decorations or not.
* `title::String = "Makie"`: Sets the window title.
* `fullscreen = false`: Starts the window in fullscreen.
* `debugging = false`: Starts the GLFW.Window/OpenGL context with debug output.
* `monitor::Union{Nothing, GLFW.Monitor} = nothing`: Sets the monitor on which the Window should be opened.

## Preproccessor
* `oit = true`: Enles order independent transparency for the window.
* `fxaa = true`: Enables fxaa (anti-aliasing) for the window.
* `ssao = true`: Enables screen space occlusion, which gives 3D meshes a soft shadow towards their edges.

"""
mutable struct ScreenConfig
    # Renderloop
    renderloop::Function # GLMakie.renderloop,
    pause_renderloop::Bool
    vsync::Bool# = false,
    framerate::Float64# = 30.0,

    # GLFW window attributes
    float::Bool# = false,
    focus_on_show::Bool# = false,
    decorated::Bool# = true,
    title::String# = "Makie",
    fullscreen::Bool# = false,
    debugging::Bool# = false,
    monitor::Union{Nothing, GLFW.Monitor}# = nothing,

    # Preproccessor
    oit::Bool# = true,
    fxaa::Bool# = true,
    ssao::Bool# = true
    transparency_weight_scale::Float32

    function ScreenConfig(
            # Renderloop
            renderloop::Union{Makie.Automatic, Function},
            pause_renderloop::Bool,
            vsync::Bool,
            framerate::Number,
            # GLFW window attributes
            float::Bool,
            focus_on_show::Bool,
            decorated::Bool,
            title::AbstractString,
            fullscreen::Bool,
            debugging::Bool,
            monitor::Union{Nothing, GLFW.Monitor},
            # Preproccessor
            oit::Bool,
            fxaa::Bool,
            ssao::Bool,
            transparency_weight_scale::Number)

        return new(
            # Renderloop
            renderloop isa Makie.Automatic ? GLMakie.renderloop : renderloop,
            pause_renderloop,
            vsync,
            framerate,
            # GLFW window attributes
            float,
            focus_on_show,
            decorated,
            title,
            fullscreen,
            debugging,
            monitor,
            # Preproccessor
            oit,
            fxaa,
            ssao,
            transparency_weight_scale)
    end
end

"""
    GLMakie.activate!(; screen_config...)

Sets GLMakie as the currently active backend and also allows to quickly set the `screen_config`.
Note, that the `screen_config` can also be set via permanently via `Makie.set_theme!(GLMakie=(screen_config...,))`.

# Arguments one can pass via `screen_config`:

$(Base.doc(ScreenConfig))
"""
function activate!(; screen_config...)
    if haskey(screen_config, :pause_rendering)
        error("pause_rendering got renamed to pause_renderloop.")
    end
    Makie.set_screen_config!(GLMakie, screen_config)
    Makie.set_active_backend!(GLMakie)
    Makie.set_glyph_resolution!(Makie.High)
    return
end


"""
    Screen(; screen_config...)

# Arguments one can pass via `screen_config`:

$(Base.doc(ScreenConfig))

# Constructors:

$(Base.doc(MakieScreen))
"""
mutable struct Screen{GLWindow} <: MakieScreen
    glscreen::GLWindow
    shader_cache::GLAbstraction.ShaderCache
    framebuffer::GLFramebuffer
    config::ScreenConfig
    stop_renderloop::Bool
    rendertask::RefValue{Task}

    screen2scene::Dict{WeakRef, ScreenID}
    screens::Vector{ScreenArea}
    renderlist::Vector{Tuple{ZIndex, ScreenID, RenderObject}}
    postprocessors::Vector{PostProcessor}
    cache::Dict{UInt64, RenderObject}
    cache2plot::Dict{UInt32, AbstractPlot}
    framecache::Matrix{RGB{N0f8}}
    render_tick::Observable{Nothing}
    window_open::Observable{Bool}

    function Screen(
            glscreen::GLWindow,
            shader_cache::GLAbstraction.ShaderCache,
            framebuffer::GLFramebuffer,
            config::ScreenConfig,
            stop_renderloop::Bool,
            rendertask::RefValue{Task},

            screen2scene::Dict{WeakRef, ScreenID},
            screens::Vector{ScreenArea},
            renderlist::Vector{Tuple{ZIndex, ScreenID, RenderObject}},
            postprocessors::Vector{PostProcessor},
            cache::Dict{UInt64, RenderObject},
            cache2plot::Dict{UInt32, AbstractPlot},
        ) where {GLWindow}

        s = size(framebuffer)
        return new{GLWindow}(
            glscreen, shader_cache, framebuffer,
            config, stop_renderloop, rendertask,
            screen2scene,
            screens, renderlist, postprocessors, cache, cache2plot,
            Matrix{RGB{N0f8}}(undef, s), Observable(nothing),
            Observable(true)
        )
    end
end

function Screen(;
        resolution = (10, 10),
        visible = true,
        start_renderloop = true,
        screen_config...
    )
    # Screen config is managed by the current active theme, so managed by Makie
    config = Makie.merge_screen_config(ScreenConfig, screen_config)

    # Somehow this constant isn't wrapped by glfw
    GLFW_FOCUS_ON_SHOW = 0x0002000C

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
        (GLFW_FOCUS_ON_SHOW, config.focus_on_show),
        (GLFW.DECORATED, config.decorated),
        (GLFW.FLOATING, config.float),
        # (GLFW.TRANSPARENT_FRAMEBUFFER, true)
    ]

    window = try
        GLFW.Window(
            resolution = resolution,
            windowhints = windowhints,
            visible = false,
            # from config
            name = config.title,
            focus = config.focus_on_show,
            fullscreen = config.fullscreen,
            debugging = config.debugging,
            monitor = config.monitor
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

    GLFW.SetWindowIcon(window, Makie.icon())

    # tell GLAbstraction that we created a new context.
    # This is important for resource tracking, and only needed for the first context
    ShaderAbstractions.switch_context!(window)
    shader_cache = GLAbstraction.ShaderCache(window)
    push!(GLFW_WINDOWS, window)

    resize_native!(window, resolution...)

    fb = GLFramebuffer(resolution)
    postprocessors = [
        config.ssao ? ssao_postprocessor(fb, shader_cache) : empty_postprocessor(),
        config.oit ? OIT_postprocessor(fb, shader_cache) : empty_postprocessor(),
        config.fxaa ? fxaa_postprocessor(fb, shader_cache) : empty_postprocessor(),
        to_screen_postprocessor(fb, shader_cache)
    ]

    screen = Screen(
        window, shader_cache, fb,
        config, !start_renderloop,
        RefValue{Task}(),
        Dict{WeakRef, ScreenID}(),
        ScreenArea[],
        Tuple{ZIndex, ScreenID, RenderObject}[],
        postprocessors,
        Dict{UInt64, RenderObject}(),
        Dict{UInt32, AbstractPlot}(),
    )

    GLFW.SetWindowRefreshCallback(window, window -> refreshwindowcb(window, screen))

    if start_renderloop
        start_renderloop!(screen)
    end

    # display window if visible!
    if visible
        GLFW.ShowWindow(window)
    else
        GLFW.HideWindow(window)
    end

    return screen
end

function pollevents(screen::Screen)
    ShaderAbstractions.switch_context!(screen.glscreen)
    notify(screen.render_tick)
    GLFW.PollEvents()
end

Base.wait(x::Screen) = isassigned(x.rendertask) && wait(x.rendertask[])
Base.wait(scene::Scene) = wait(Makie.getscreen(scene))

Base.show(io::IO, screen::Screen) = print(io, "GLMakie.Screen(...)")

Base.isopen(x::Screen) = isopen(x.glscreen)
Base.size(x::Screen) = size(x.framebuffer)

function Makie.insertplots!(screen::Screen, scene::Scene)
    ShaderAbstractions.switch_context!(screen.glscreen)
    get!(screen.screen2scene, WeakRef(scene)) do
        id = length(screen.screens) + 1
        push!(screen.screens, (id, scene))
        return id
    end
    for elem in scene.plots
        insert!(screen, scene, elem)
    end
    foreach(s-> insertplots!(screen, s), scene.children)
end

function Base.delete!(screen::Screen, scene::Scene)
    for child in scene.children
        delete!(screen, child)
    end
    for plot in scene.plots
        delete!(screen, scene, plot)
    end

    if haskey(screen.screen2scene, WeakRef(scene))
        deleted_id = pop!(screen.screen2scene, WeakRef(scene))

        # TODO: this should always find something but sometimes doesn't...
        i = findfirst(id_scene -> id_scene[1] == deleted_id, screen.screens)
        i !== nothing && deleteat!(screen.screens, i)

        # Remap scene IDs to a continuous range by replacing the largest ID
        # with the one that got removed
        if deleted_id-1 != length(screen.screens)
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
    for (k, v) in rob.uniforms
        if v isa Observable
            for input in v.inputs
                off(input)
            end
        elseif v isa GPUArray
            GLAbstraction.free(v)
        end
    end
    for obs in rob.observables
        for input in obs.inputs
            off(input)
        end
    end
    GLAbstraction.free(rob.vertexarray)
end

function Base.delete!(screen::Screen, scene::Scene, plot::AbstractPlot)
    if !isempty(plot.plots)
        # this plot consists of children, so we flatten it and delete the children instead
        for cplot in Makie.flatten_plots(plot)
            delete!(screen, scene, cplot)
        end
    else
        # I think we can double delete renderobjects, so this may be ok
        # TODO, is it?
        renderobject = get(screen.cache, objectid(plot), nothing)
        if !isnothing(renderobject)
            destroy!(renderobject)
            filter!(x-> x[3] !== renderobject, screen.renderlist)
        end
    end
end

function Base.empty!(screen::Screen)
    empty!(screen.render_tick.listeners)
    empty!(screen.window_open.listeners)
    empty!(screen.renderlist)
    empty!(screen.screen2scene)
    empty!(screen.screens)
    empty!(screen.cache)
    empty!(screen.cache2plot)
end

const GLFW_WINDOWS = GLFW.Window[]
const SINGLETON_SCREEN = Screen[]
const SINGLETON_SCREEN_NO_RENDERLOOP = Screen[]

function singleton_screen(resolution; visible=true, start_renderloop=true)
    screen_ref = if start_renderloop
        SINGLETON_SCREEN
    else
        SINGLETON_SCREEN_NO_RENDERLOOP
    end

    screen = if length(screen_ref) == 1 && isopen(screen_ref[1])
        screen = screen_ref[1]
        resize!(screen, resolution...)
        screen
    else
        if !isempty(screen_ref)
            closeall(screen_ref)
        end
        screen = Screen(; resolution=resolution, visible=visible, start_renderloop=start_renderloop)
        push!(screen_ref, screen)
        screen
    end
    ShaderAbstractions.switch_context!(screen.glscreen)
    return screen
end

function destroy!(screen::Screen)
    screen.window_open[] = false
    empty!(screen)
    filter!(win -> win != screen.glscreen, GLFW_WINDOWS)
    destroy!(screen.glscreen)
end

Base.close(screen::Screen) = destroy!(screen)
function closeall(windows=GLFW_WINDOWS)
    if !isempty(windows)
        for elem in windows
            isopen(elem) && destroy!(elem)
        end
        empty!(windows)
    end
end

function resize_native!(window::GLFW.Window, resolution...)
    if isopen(window)
        ShaderAbstractions.switch_context!(window)
        oldsize = windowsize(window)
        retina_scale = retina_scaling_factor(window)
        w, h = resolution ./ retina_scale
        if oldsize == (w, h)
            return
        end
        GLFW.SetWindowSize(window, round(Int, w), round(Int, h))
    end
end

function Base.resize!(screen::Screen, w, h)
    nw = to_native(screen)
    resize_native!(nw, w, h)
    fb = screen.framebuffer
    resize!(fb, (w, h))
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
Gets the depth buffer of screen.
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
    # GLFW.PollEvents()
    # keep current buffer size to allows larger-than-window renders
    render_frame(screen, resize_buffers=false) # let it render
    glFinish() # block until opengl is done rendering
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

"""
Loads the makie loading icon and embedds it in an image the size of resolution
"""
function get_loading_image(resolution)
    icon = Matrix{N0f8}(undef, 192, 192)
    open(joinpath(GL_ASSET_DIR, "loading.bin")) do io
        read!(io, icon)
    end
    img = zeros(RGBA{N0f8}, resolution...)
    center = resolution .÷ 2
    center_icon = size(icon) .÷ 2
    start = CartesianIndex(max.(center .- center_icon, 1))
    I1 = CartesianIndex(1, 1)
    stop = min(start + CartesianIndex(size(icon)) - I1, CartesianIndex(resolution))
    for idx in start:stop
        gray = icon[idx - start + I1]
        img[idx] = RGBA{N0f8}(gray, gray, gray, 1.0)
    end
    return img
end

function display_loading_image(screen::Screen)
    fb = screen.framebuffer
    fbsize = size(fb)
    image = get_loading_image(fbsize)
    if size(image) == fbsize
        nw = to_native(screen)
        # transfer loading image to gpu framebuffer
        fb.buffers[:color][1:size(image, 1), 1:size(image, 2)] = image
        ShaderAbstractions.is_context_active(nw) || return
        w, h = fbsize
        glBindFramebuffer(GL_FRAMEBUFFER, 0) # transfer back to window
        glViewport(0, 0, w, h)
        glClearColor(0, 0, 0, 0)
        glClear(GL_COLOR_BUFFER_BIT)
        # GLAbstraction.render(fb.postprocess[end]) # copy postprocess
        GLAbstraction.render(screen.postprocessors[end].robjs[1])
        GLFW.SwapBuffers(nw)
    else
        error("loading_image needs to be Matrix{RGBA{N0f8}} with size(loading_image) == resolution")
    end
end

function renderloop_running(screen::Screen)
    return !screen.stop_renderloop && isassigned(screen.rendertask) && !istaskdone(screen.rendertask[])
end

function start_renderloop!(screen::Screen)
    if renderloop_running(screen)
        screen.config.pause_renderloop = false
        return
    else
        screen.stop_renderloop = false
        task = @async screen.config.renderloop(screen)
        yield()
        if istaskstarted(task)
            screen.rendertask[] = task
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

function stop_renderloop!(screen::Screen)
    screen.stop_renderloop = true
    wait(screen.rendertask[]) # Make sure we quit!
end

function set_framerate!(screen::Screen, fps=30)
    screen.config.framerate = fps
end

function refreshwindowcb(window, screen)
    screen.render_tick[] = nothing
    render_frame(screen)
    GLFW.SwapBuffers(window)
    return
end

# Open an interactive window
Screen(scene::Scene; screen_config...) = singleton_screen(size(scene); visible=true, start_renderloop=true)

# Screen to save a png/jpeg to file or io
function Screen(scene::Scene, io_or_path::Union{Nothing, String, IO}, typ::MIME; screen_config...)
    return singleton_screen(size(scene); visible=false, start_renderloop=false)
end

# Screen that is efficient for `colorbuffer(screen)`
function Screen(scene::Scene, ::Makie.ImageStorageFormat; screen_config...)
    return singleton_screen(size(scene); visible=false, start_renderloop=false)
end

# TODO add render_tick event to scene events
function vsynced_renderloop(screen)
    while isopen(screen) && !screen.stop_renderloop
        if screen.config.pause_renderloop
            pollevents(screen); sleep(0.1)
            continue
        end
        pollevents(screen) # GLFW poll
        render_frame(screen)
        GLFW.SwapBuffers(to_native(screen))
        yield()
    end
end

function fps_renderloop(screen::Screen)
    while isopen(screen) && !screen.stop_renderloop
        if screen.config.pause_renderloop
            pollevents(screen); sleep(0.1)
            continue
        end
        time_per_frame = 1.0 / screen.config.framerate
        t = time_ns()
        pollevents(screen) # GLFW poll
        render_frame(screen)
        GLFW.SwapBuffers(to_native(screen))
        t_elapsed = (time_ns() - t) / 1e9
        diff = time_per_frame - t_elapsed
        if diff > 0.001 # can't sleep less than 0.001
            sleep(diff)
        else # if we don't sleep, we still need to yield explicitely to other tasks
            yield()
        end
    end
end

function renderloop(screen)
    isopen(screen) || error("Screen most be open to run renderloop!")
    try
        if screen.config.vsync
            GLFW.SwapInterval(1)
            vsynced_renderloop(screen)
        else
            GLFW.SwapInterval(0)
            fps_renderloop(screen)
        end
    catch e
        showerror(stderr, e, catch_backtrace())
        println(stderr)
        rethrow(e)
    finally
        destroy!(screen)
    end
end
