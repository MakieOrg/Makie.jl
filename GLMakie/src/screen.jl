const ScreenID = UInt16
const ZIndex = Int
# ID, Area, clear, is visible, background color
const ScreenArea = Tuple{ScreenID, Scene}

function renderloop end

"""
## Renderloop

* `renderloop = GLMakie.renderloop`: sets a function `renderloop(::GLMakie.Screen)` which starts a renderloop for the screen.


!!! warning
    The keyword arguments below are not effective if `renderloop` isn't set to `GLMakie.renderloop`, unless implemented in a custom renderloop function:

* `pause_renderloop = false`: If `true`, creates a screen with a paused renderloop. The renderloop can be started with `GLMakie.start_renderloop!(screen)` and paused again with `GLMakie.pause_renderloop!(screen)`.
* `vsync = false`: Whether to enable vsync for the window.
* `render_on_demand = true`: If `true`, the scene will only be rendered if something has changed in it.
* `framerate = 30.0`: Sets the currently rendered frames per second.

## GLFW window attributes
* `float = false`: Whether the window should float above other windows.
* `focus_on_show = false`: If `true`, focuses the window when newly opened.
* `decorated = true`: Whether or not to show window decorations.
* `title::String = "Makie"`: Sets the window title.
* `fullscreen = false`: Whether to start the window in fullscreen mode.
* `debugging = false`: If `true`, starts the GLFW.Window/OpenGL context with debug output.
* `monitor::Union{Nothing, GLFW.Monitor} = nothing`: Sets the monitor on which the window should be opened. If set to `nothing`, GLFW will decide which monitor to use.
* `visible = true`: Whether or not the window should be visible when first created.

## Postprocessor
* `oit = false`: Whether to enable order independent transparency for the window.
* `fxaa = true`: Whether to enable fxaa (anti-aliasing) for the window.
* `ssao = true`: Whether to enable screen space ambient occlusion, which simulates natural shadowing at inner edges and crevices.
* `transparency_weight_scale = 1000f0`: Adjusts a factor in the rendering shaders for order independent transparency.
    This should be the same for all of them (within one rendering pipeline) otherwise depth "order" will be broken.
"""
mutable struct ScreenConfig
    # Renderloop
    renderloop::Function
    pause_renderloop::Bool
    vsync::Bool
    render_on_demand::Bool
    framerate::Float64

    # GLFW window attributes
    float::Bool
    focus_on_show::Bool
    decorated::Bool
    title::String
    fullscreen::Bool
    debugging::Bool
    monitor::Union{Nothing, GLFW.Monitor}
    visible::Bool

    # Postprocessor
    oit::Bool
    fxaa::Bool
    ssao::Bool
    transparency_weight_scale::Float32

    function ScreenConfig(
            # Renderloop
            renderloop::Union{Makie.Automatic, Function},
            pause_renderloop::Bool,
            vsync::Bool,
            render_on_demand::Bool,
            framerate::Number,
            # GLFW window attributes
            float::Bool,
            focus_on_show::Bool,
            decorated::Bool,
            title::AbstractString,
            fullscreen::Bool,
            debugging::Bool,
            monitor::Union{Nothing, GLFW.Monitor},
            visible::Bool,

            # Preprocessor
            oit::Bool,
            fxaa::Bool,
            ssao::Bool,
            transparency_weight_scale::Number)
        return new(
            # Renderloop
            renderloop isa Makie.Automatic ? GLMakie.renderloop : renderloop,
            pause_renderloop,
            vsync,
            render_on_demand,
            framerate,
            # GLFW window attributes
            float,
            focus_on_show,
            decorated,
            title,
            fullscreen,
            debugging,
            monitor,
            visible,
            # Preprocessor
            oit,
            fxaa,
            ssao,
            transparency_weight_scale)
    end
end

const LAST_INLINE = Ref(false)

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
    config::Union{Nothing, ScreenConfig}
    stop_renderloop::Bool
    rendertask::Union{Task, Nothing}

    screen2scene::Dict{WeakRef, ScreenID}
    screens::Vector{ScreenArea}
    renderlist::Vector{Tuple{ZIndex, ScreenID, RenderObject}}
    postprocessors::Vector{PostProcessor}
    cache::Dict{UInt64, RenderObject}
    cache2plot::Dict{UInt32, AbstractPlot}
    framecache::Matrix{RGB{N0f8}}
    render_tick::Observable{Nothing}
    window_open::Observable{Bool}

    root_scene::Union{Scene, Nothing}
    reuse::Bool
    close_after_renderloop::Bool
    # To trigger rerenders that aren't related to an existing renderobject.
    requires_update::Bool

    function Screen(
            glscreen::GLWindow,
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
            glscreen, shader_cache, framebuffer,
            config, stop_renderloop, rendertask,
            screen2scene,
            screens, renderlist, postprocessors, cache, cache2plot,
            Matrix{RGB{N0f8}}(undef, s), Observable(nothing),
            Observable(true), nothing, reuse, true, false
        )
        push!(ALL_SCREENS, screen) # track all created screens
        return screen
    end
end

# for e.g. closeall, track all created screens
# gets removed in destroy!(screen)
const ALL_SCREENS = Set{Screen}()

function empty_screen(debugging::Bool; reuse=true)
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
    ]
    resolution = (10, 10)
    window = try
        GLFW.Window(
            resolution = resolution,
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

    GLFW.SetWindowIcon(window, Makie.icon())

    # tell GLAbstraction that we created a new context.
    # This is important for resource tracking, and only needed for the first context
    ShaderAbstractions.switch_context!(window)
    shader_cache = GLAbstraction.ShaderCache(window)
    fb = GLFramebuffer(resolution)
    postprocessors = [
        empty_postprocessor(),
        empty_postprocessor(),
        empty_postprocessor(),
        to_screen_postprocessor(fb, shader_cache)
    ]

    screen = Screen(
        window, shader_cache, fb,
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
    GLFW.SetWindowRefreshCallback(window, window -> refreshwindowcb(window, screen))
    return screen
end

const SCREEN_REUSE_POOL = Set{Screen}()

function reopen!(screen::Screen)
    @debug("reopening screen")
    gl = screen.glscreen
    @assert !was_destroyed(gl)
    if GLFW.WindowShouldClose(gl)
        GLFW.SetWindowShouldClose(gl, false)
    end
    @assert isempty(screen.window_open.listeners)
    screen.window_open[] = true
    @assert isopen(screen)
    return screen
end

function screen_from_pool(debugging)
    screen = if isempty(SCREEN_REUSE_POOL)
        @debug("create empty screen for pool")
        empty_screen(debugging)
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
        close(screen; reuse=false)
    else
        @debug("new singleton screen")
        # reuse=false, because we "manually" re-use the singleton screen!
        screen = empty_screen(debugging; reuse=false)
        push!(SINGLETON_SCREEN, screen)
    end
    return reopen!(screen)
end

const GLFW_FOCUS_ON_SHOW = 0x0002000C

function Makie.apply_screen_config!(screen::Screen, config::ScreenConfig, scene::Scene, args...)
    apply_config!(screen, config)
end

function apply_config!(screen::Screen, config::ScreenConfig; start_renderloop::Bool=true)
    @debug("Applying screen config! to existing screen")
    glw = screen.glscreen
    ShaderAbstractions.switch_context!(glw)
    GLFW.SetWindowAttrib(glw, GLFW_FOCUS_ON_SHOW, config.focus_on_show)
    GLFW.SetWindowAttrib(glw, GLFW.DECORATED, config.decorated)
    GLFW.SetWindowAttrib(glw, GLFW.FLOATING, config.float)
    GLFW.SetWindowTitle(glw, config.title)

    if !isnothing(config.monitor)
        GLFW.SetWindowMonitor(glw, config.monitor)
    end

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
    # Set the config
    screen.config = config

    if start_renderloop
        start_renderloop!(screen)
    else
        stop_renderloop!(screen)
    end

    set_screen_visibility!(screen, config.visible)
    return screen
end

function Screen(;
        resolution::Union{Nothing, Tuple{Int, Int}} = nothing,
        start_renderloop = true,
        screen_config...
    )
    # Screen config is managed by the current active theme, so managed by Makie
    config = Makie.merge_screen_config(ScreenConfig, screen_config)
    screen = screen_from_pool(config.debugging)
    if !isnothing(resolution)
        resize!(screen, resolution...)
    end
    apply_config!(screen, config; start_renderloop=start_renderloop)
    return screen
end

set_screen_visibility!(screen::Screen, visible::Bool) = set_screen_visibility!(screen.glscreen, visible)
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
    screen.root_scene = scene
    return
end

function Screen(scene::Scene; start_renderloop=true, screen_config...)
    config = Makie.merge_screen_config(ScreenConfig, screen_config)
    return Screen(scene, config; start_renderloop=start_renderloop)
end

# Open an interactive window
function Screen(scene::Scene, config::ScreenConfig; visible=nothing, start_renderloop=true)
    screen = singleton_screen(config.debugging)
    !isnothing(visible) && (config.visible = visible)
    apply_config!(screen, config; start_renderloop=start_renderloop)
    display_scene!(screen, scene)
    return screen
end

# Screen to save a png/jpeg to file or io
function Screen(scene::Scene, config::ScreenConfig, io::Union{Nothing, String, IO}, typ::MIME; visible=nothing, start_renderloop=false)
    screen = singleton_screen(config.debugging)
    !isnothing(visible) && (config.visible = visible)
    apply_config!(screen, config; start_renderloop=start_renderloop)
    display_scene!(screen, scene)
    return screen
end

# Screen that is efficient for `colorbuffer(screen)`
function Screen(scene::Scene, config::ScreenConfig, ::Makie.ImageStorageFormat;  start_renderloop=false)
    screen = singleton_screen(config.debugging)
    config.visible = false
    apply_config!(screen, config; start_renderloop=start_renderloop)
    display_scene!(screen, scene)
    return screen
end

function pollevents(screen::Screen)
    ShaderAbstractions.switch_context!(screen.glscreen)
    notify(screen.render_tick)
    GLFW.PollEvents()
end

Base.wait(x::Screen) = !isnothing(x.rendertask) && wait(x.rendertask)
Base.wait(scene::Scene) = wait(Makie.getscreen(scene))

Base.show(io::IO, screen::Screen) = print(io, "GLMakie.Screen(...)")

Base.isopen(x::Screen) = isopen(x.glscreen)
Base.size(x::Screen) = size(x.framebuffer)

function Makie.insertplots!(screen::Screen, scene::Scene)
    ShaderAbstractions.switch_context!(screen.glscreen)
    get!(screen.screen2scene, WeakRef(scene)) do
        id = length(screen.screens) + 1
        push!(screen.screens, (id, scene))
        screen.requires_update = true
        onany(
            (_, _, _, _, _) -> screen.requires_update = true,
            scene,
            scene.visible, scene.backgroundcolor, 
            scene.ssao.bias, scene.ssao.blur, scene.ssao.radius
        )
        return id
    end
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
    tex = get_texture!(gl_texture_atlas())
    for (k, v) in rob.uniforms
        if v isa Observable
            Observables.clear(v)
        elseif v isa GPUArray && v !== tex
            # We usually don't share gpu data and it should be hard for users to share buffers..
            # but we do share the texture atlas, so we check v !== tex, since we can't just free shared resources

            # TODO, refcounting, or leaving freeing to GC...
            # GC is a bit tricky with active contexts, so immediate free is prefered.
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

    if !isnothing(screen.root_scene)
        Makie.disconnect_screen(screen.root_scene, screen)
        delete!(screen, screen.root_scene)
        screen.root_scene = nothing
    end

    @assert isempty(screen.renderlist)
    @assert isempty(screen.cache2plot)
    @assert isempty(screen.cache)

    empty!(screen.screen2scene)
    empty!(screen.screens)
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
    destroy!(screen.glscreen)
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
    stop_renderloop!(screen; close_after_renderloop=false)
    if screen.window_open[] # otherwise we trigger an infinite loop of closing
        screen.window_open[] = false
    end
    empty!(screen)
    if reuse && screen.reuse
        @debug("reusing screen!")
        push!(SCREEN_REUSE_POOL, screen)
    end
    GLFW.SetWindowShouldClose(screen.glscreen, true)
    GLFW.PollEvents()
    return
end

function closeall()
    while !isempty(SCREEN_REUSE_POOL)
        screen = pop!(SCREEN_REUSE_POOL)
        delete!(ALL_SCREENS, screen)
        destroy!(screen)
    end
    if !isempty(SINGLETON_SCREEN)
        screen = pop!(SINGLETON_SCREEN)
        delete!(ALL_SCREENS, screen)
        destroy!(screen)
    end
    while !isempty(ALL_SCREENS)
        screen = pop!(ALL_SCREENS)
        destroy!(screen)
    end
    return
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
    get_loading_image(resolution)

Loads the makie loading icon, embeds it in an image the size of `resolution`,
and returns the image.
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
    return !screen.stop_renderloop && !isnothing(screen.rendertask) && !istaskdone(screen.rendertask)
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
    screen.stop_renderloop = true
    screen.close_after_renderloop = c

    # stop_renderloop! may be called inside renderloop as part of close
    # in which case we should not wait for the task to finish (deadlock)
    if Base.current_task() != screen.rendertask
        wait(screen)  # handle isnothing(rendertask) in wait(screen)
        # after done, we can set the task to nothing
        screen.rendertask = nothing
    end
    # else, we can't do that much in the rendertask itself
    return
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

function requires_update(screen::Screen)
    if screen.requires_update
        screen.requires_update = false
        return true
    end
    for (_, _, robj) in screen.renderlist
        robj.requires_update && return true
    end
    return false
end

function on_demand_renderloop(screen::Screen)
    while isopen(screen) && !screen.stop_renderloop
        t = time_ns()
        time_per_frame = 1.0 / screen.config.framerate
        pollevents(screen) # GLFW poll

        if !screen.config.pause_renderloop && requires_update(screen)
            render_frame(screen)
            GLFW.SwapBuffers(to_native(screen))
        end

        t_elapsed = (time_ns() - t) / 1e9
        diff = time_per_frame - t_elapsed
        if diff > 0.001 # can't sleep less than 0.001
            sleep(diff)
        else # if we don't sleep, we still need to yield explicitely to other tasks
            yield()
        end
    end
    cause = screen.stop_renderloop ? "stopped renderloop" : "closing window"
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
            @debug("Closing screen after quiting renderloop!")
            close(screen)
        catch e
            @warn "error closing screen" exception=(e, Base.catch_backtrace())
        end
    end
    screen.rendertask = nothing
    return
end

function plot2robjs(screen::Screen, plot)
    plots = Makie.flatten_plots(plot)
    return map(x-> screen.cache[objectid(x)], plots)
end

export plot2robjs
