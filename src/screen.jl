const ScreenID = UInt8
const ZIndex = Int
# ID, Area, clear, is visible, background color
const ScreenArea = Tuple{ScreenID, Node{IRect2D}, Node{Bool}, Node{Bool}, Node{RGBAf0}}


abstract type GLScreen <: AbstractScreen end

mutable struct Screen <: GLScreen
    glscreen::GLFW.Window
    framebuffer::GLFramebuffer
    rendertask::RefValue{Task}
    screen2scene::Dict{WeakRef, ScreenID}
    screens::Vector{ScreenArea}
    renderlist::Vector{Tuple{ZIndex, ScreenID, RenderObject}}
    cache::Dict{UInt64, RenderObject}
    cache2plot::Dict{UInt16, AbstractPlot}
    framecache::Tuple{Matrix{RGB{N0f8}}, Matrix{RGB{N0f8}}}
    displayed_scene::Union{Scene, Nothing}
    function Screen(
            glscreen::GLFW.Window,
            framebuffer::GLFramebuffer,
            rendertask::RefValue{Task},
            screen2scene::Dict{WeakRef, ScreenID},
            screens::Vector{ScreenArea},
            renderlist::Vector{Tuple{ZIndex, ScreenID, RenderObject}},
            cache::Dict{UInt64, RenderObject},
            cache2plot::Dict{UInt16, AbstractPlot},
        )
        s = size(framebuffer)
        obj = new(
            glscreen, framebuffer, rendertask, screen2scene,
            screens, renderlist, cache, cache2plot,
            (Matrix{RGB{N0f8}}(undef, s), Matrix{RGB{N0f8}}(undef, reverse(s))),
            nothing
        )
        finalizer(obj) do obj
            # save_print("Freeing screen")
            empty!.((obj.renderlist, obj.screens, obj.cache, obj.screen2scene, obj.cache2plot))
            return
        end
        obj
    end
end
GeometryTypes.widths(x::Screen) = size(x.framebuffer.color)

Base.wait(x::Screen) = isassigned(x.rendertask) && wait(x.rendertask[])
Base.wait(scene::Scene) = wait(global_gl_screen()) # TODO per scene screen
Base.show(io::IO, screen::Screen) = print(io, "GLMakie.Screen(...)")
Base.size(x::Screen) = size(x.framebuffer)

function insertplots!(screen::GLScreen, scene::Scene)
    for elem in scene.plots
        insert!(screen, scene, elem)
    end
    foreach(s-> insertplots!(screen, s), scene.children)
end

function Base.empty!(screen::GLScreen)
    empty!(screen.renderlist)
    empty!(screen.screen2scene)
    empty!(screen.screens)
end

function destroy!(screen::Screen)
    empty!(screen)
    empty!(screen.cache)
    empty!(screen.cache2plot)
    destroy!(screen.glscreen)
end

function Base.resize!(window::GLFW.Window, resolution...)
    if isopen(window)
        retina_scale = retina_scaling_factor(window)
        w, h = resolution ./ retina_scale
        GLFW.SetWindowSize(window, round(Int, w), round(Int, h))
    end
end

function Base.resize!(screen::Screen, w, h)
    nw = to_native(screen)
    resize!(nw, w, h)
    fb = screen.framebuffer
    resize!(fb, (w, h))
end

function AbstractPlotting.backend_display(screen::Screen, scene::Scene)
    empty!(screen)
    register_callbacks(scene, to_native(screen))
    GLFW.PollEvents()
    insertplots!(screen, scene)
    GLFW.PollEvents()
    screen.displayed_scene = scene
    return
end


function to_jl_layout!(A, B)
    ind1, ind2 = axes(A)
    n = first(ind2) + last(ind2)
    for i in ind1
        @simd for j in ind2
            @inbounds B[n-j, i] = ImageCore.clamp01nan(A[i, j])
        end
    end
    return B
end

function fast_color_data!(dest::Array{RGB{N0f8}, 2}, source::Texture{T, 2}) where T
    GLAbstraction.bind(source)
    glPixelStorei(GL_PACK_ALIGNMENT, 1)
    glGetTexImage(source.texturetype, 0, GL_RGB, GL_UNSIGNED_BYTE, dest)
    GLAbstraction.bind(source, 0)
    nothing
end


function AbstractPlotting.colorbuffer(screen::Screen)
    if isopen(screen)
        GLFW.PollEvents()
        render_frame(screen) # let it render
        GLFW.SwapBuffers(to_native(screen))
        glFinish() # block until opengl is done rendering
        ctex = screen.framebuffer.color
        if size(ctex) != size(screen.framecache[1])
            s = size(ctex)
            screen.framecache = (Matrix{RGB{N0f8}}(undef, s), Matrix{RGB{N0f8}}(undef, reverse(s)))
        end
        fast_color_data!(screen.framecache[1], ctex)
        to_jl_layout!(screen.framecache...)
        return screen.framecache[2]
    else
        error("Screen not open!")
    end
end


Base.isopen(x::Screen) = isopen(x.glscreen)
function Base.push!(screen::GLScreen, scene::Scene, robj)
    filter!(screen.screen2scene) do (k, v)
        k.value != nothing
    end
    screenid = get!(screen.screen2scene, WeakRef(scene)) do
        id = length(screen.screens) + 1
        bg = lift(to_color, scene.theme[:backgroundcolor])
        clear = lift(identity, scene.theme[:clear])
        visible = lift(identity, scene.theme[:visible])
        push!(screen.screens, (id, scene.px_area, clear, visible, bg))
        id
    end
    push!(screen.renderlist, (0, screenid, robj))
    return robj
end

to_native(x::Screen) = x.glscreen
const gl_screens = GLFW.Window[]


"""
OpenGL shares all data containers between shared contexts, but not vertexarrays -.-
So to share a robjs between a context, we need to rewrap the vertexarray into a new one for that
specific context.
"""
function rewrap(robj::RenderObject{Pre}) where Pre
    RenderObject{Pre}(
        robj.main,
        robj.uniforms,
        GLVertexArray(robj.vertexarray),
        robj.prerenderfunction,
        robj.postrenderfunction,
        robj.boundingbox,
    )
end

const _global_gl_screen = Ref{Screen}()

# will get overloaded later
function renderloop end

# TODO a global is not very nice, but it's the simplest way right now to swap out
# the rendering loop
const opengl_renderloop = Ref{Function}(renderloop)


"""
Julia 1.0.3 doesn't have I:J, so we copy the implementation from 1.1 under a new name:
"""
function irange(I::CartesianIndex{N}, J::CartesianIndex{N}) where N
    CartesianIndices(map((i,j) -> i:j, Tuple(I), Tuple(J)))
end


"""
Loads the makie loading icon and embedds it in an image the size of resolution
"""
function get_loading_image(resolution)
    icon = Matrix{N0f8}(undef, 192, 192)
    open(GLMakie.assetpath("loading.bin")) do io
        read!(io, icon)
    end
    img = zeros(RGBA{N0f8}, resolution...)
    center = resolution .÷ 2
    center_icon = size(icon) .÷ 2
    start = CartesianIndex(max.(center .- center_icon, 1))
    I1 = CartesianIndex(1, 1)
    stop = min(start + CartesianIndex(size(icon)) - I1, CartesianIndex(resolution))
    for idx in irange(start, stop)
        gray = icon[idx - start + I1]
        img[idx] = RGBA{N0f8}(gray, gray, gray, 1.0)
    end
    return img
end

function display_loading_image(screen::Screen)
    fb = screen.framebuffer
    fbsize = size(fb.color)
    image = get_loading_image(fbsize)
    if size(image) == fbsize
        nw = to_native(screen)
        fb.color[1:size(image, 1), 1:size(image, 2)] = image # transfer loading image to gpu framebuffer
        GLAbstraction.is_context_active(nw) || return
        w, h = fbsize
        glBindFramebuffer(GL_FRAMEBUFFER, 0) # transfer back to window
        glViewport(0, 0, w, h)
        glClearColor(0, 0, 0, 0)
        glClear(GL_COLOR_BUFFER_BIT)
        GLAbstraction.render(fb.postprocess[3]) # copy postprocess
        GLFW.SwapBuffers(nw)
    else
        error("loading_image needs to be Matrix{RGBA{N0f8}} with size(loading_image) == resolution")
    end

end

function Screen(;
        resolution = (10, 10), visible = false, title = "Makie",
        kw_args...
    )
    if !isempty(gl_screens)
        for elem in gl_screens
            isopen(elem) && destroy!(elem)
        end
        empty!(gl_screens)
    end

    window = GLFW.Window(
        name = title, resolution = (10, 10), # 10, because smaller sizes seem to error on some platforms
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
            # (GLFW.RESIZABLE, GL_TRUE)
        ],
        visible = false,
        kw_args...
    )
    GLFW.SetWindowIcon(window , AbstractPlotting.icon())

    # tell GLAbstraction that we created a new context.
    # This is important for resource tracking, and only needed for the first context
    GLAbstraction.switch_context!(window)
    GLAbstraction.empty_shader_cache!()
    push!(gl_screens, window)

    GLFW.SwapInterval(0)

    # Retina screens on osx have a different scaling!
    retina_scale = retina_scaling_factor(window)
    resolution = round.(Int, retina_scale .* resolution)
    # Set the resolution for real now!
    GLFW.SetWindowSize(window, resolution...)
    fb = GLFramebuffer(Int.(resolution))

    screen = Screen(
        window, fb,
        RefValue{Task}(),
        Dict{WeakRef, ScreenID}(),
        ScreenArea[],
        Tuple{ZIndex, ScreenID, RenderObject}[],
        Dict{UInt64, RenderObject}(),
        Dict{UInt16, AbstractPlot}(),
    )

    GLFW.SetWindowRefreshCallback(window, window -> begin
        render_frame(screen)
        GLFW.SwapBuffers(window)
    end)

    if visible
        GLFW.ShowWindow(window)
    else
        GLFW.HideWindow(window)
    end
    screen.rendertask[] = @async((opengl_renderloop[])(screen))
    screen
end

function global_gl_screen()
    screen = if isassigned(_global_gl_screen) && isopen(_global_gl_screen[])
        _global_gl_screen[]
    else
        _global_gl_screen[] = Screen()
        _global_gl_screen[]
    end
    return screen
end

function global_gl_screen(resolution::Tuple, visibility::Bool, tries = 1)
    # ugly but easy way to find out if we create new screen.
    # could just be returned by global_gl_screen, but dont want to change the API
    isold = isassigned(_global_gl_screen) && isopen(_global_gl_screen[])
    screen = global_gl_screen()
    GLFW.set_visibility!(to_native(screen), visibility)
    resize!(screen, resolution...)
    new_size = GLFW.GetWindowSize(to_native(screen))
    # I'm not 100% sure, if there are platforms where I'm never
    # able to resize the screen (opengl might just allow that).
    # so, we guard against that with just trying another resize one time!
    if ((new_size.width, new_size.height) != resolution) && tries == 1
        # resize failed. This may happen when screen was previously
        # enlarged to fill screen. WE NEED TO DESTROY!! (I think)
        destroy!(screen)
        # try again
        return global_gl_screen(resolution, visibility, 2)
    end
    # show loading image on fresh screen
    isold || display_loading_image(screen)
    screen
end

# TODO per scene screen
getscreen(scene) = global_gl_screen()

function pick_native(scene::SceneLike, xy::VectorTypes{2}, sid = Base.RefValue{SelectionID{UInt16}}())
    screen = getscreen(scene)
    screen == nothing && return SelectionID{Int}(0, 0)
    window_size = widths(screen)
    fb = screen.framebuffer
    buff = fb.objectid
    glBindFramebuffer(GL_FRAMEBUFFER, fb.id[1])
    glReadBuffer(GL_COLOR_ATTACHMENT1)
    x, y = Int.(floor.(xy))
    w, h = window_size
    if x > 0 && y > 0 && x <= w && y <= h
        glReadPixels(x, y, 1, 1, buff.format, buff.pixeltype, sid)
        return convert(SelectionID{Int}, sid[])
    end
    return SelectionID{Int}(0, 0)
end

pick(scene::SceneLike, xy...) = pick(scene, Float64.(xy))

function pick(scene::SceneLike, xy::VectorTypes{2})
    sid = pick_native(scene, xy)
    screen = getscreen(scene)
    if screen != nothing && haskey(screen.cache2plot, sid.id)
        plot = screen.cache2plot[sid.id]
        return (plot, sid.index)
    end
    return (nothing, 0)
end

# TODO does this actually needs to be a global?
const _mouse_selection_id = Base.RefValue{SelectionID{UInt16}}()
function mouse_selection_native(scene::SceneLike)
    function query_mouse(buff, w, h)
        xy = events(scene).mouseposition[]
        x, y = Int.(floor.(xy))
        if x > 0 && y > 0 && x <= w && y <= h
            glReadPixels(x, y, 1, 1, buff.format, buff.pixeltype, _mouse_selection_id)
        end
        return
    end
    if !(query_mouse in selection_queries)
        push!(selection_queries, query_mouse)
        # TODO, this is not optimal since it does way more
        # than calling query_mouse() on first click,
        # but otherwise it might get into an inconsistent state.
        render_frame(getscreen(scene))
    end
    convert(SelectionID{Int}, _mouse_selection_id[])
end

function mouse_selection(scene::SceneLike)
    sid = mouse_selection_native(scene)
    screen = getscreen(scene)
    if screen != nothing && haskey(screen.cache2plot, sid.id)
        plot = screen.cache2plot[sid.id]
        return (plot, sid.index)
    end
    return (nothing, 0)
end

function mouseover(scene::SceneLike, plots::AbstractPlot...)
    p, idx = mouse_selection(scene)
    p in flatten_plots(plots)
end

function flatten_plots(x::Atomic, plots = AbstractPlot[])
    if isempty(x.plots)
        push!(plots, x)
    else
        flatten_plots(x.plots, plots)
    end
    plots
end

function flatten_plots(x::Combined, plots = AbstractPlot[])
    for elem in x.plots
        flatten_plots(elem, plots)
    end
    plots
end

function flatten_plots(array, plots = AbstractPlot[])
    for elem in array
        flatten_plots(elem, plots)
    end
    plots
end

function onpick(f, scene::SceneLike, plots::AbstractPlot...)
    fplots = flatten_plots(plots)
    map_once(events(scene).mouseposition) do mp
        p, idx = mouse_selection(scene)
        (p in fplots) && f(idx)
        return
    end
end

function pick(screen::Screen, rect::IRect2D)
    window_size = widths(screen)
    buff = screen.framebuffer.objectid
    sid = zeros(SelectionID{UInt16}, widths(rect)...)
    glReadBuffer(GL_COLOR_ATTACHMENT1)
    x, y = minimum(rect)
    rw, rh = widths(rect)
    w, h = window_size
    if x > 0 && y > 0 && x <= w && y <= h
        glReadPixels(x, y, rw, rh, buff.format, buff.pixeltype, sid)
        return map(unique(vec(SelectionID{Int}.(sid)))) do sid
            screen.cache2plot[sid.id], Int(sid.index)
        end
    end
    return SelectionID{Int}[]
end
