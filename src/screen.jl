const ScreenID = UInt8
const ZIndex = Int
# ID, Area, clear, is visible, background color
const ScreenArea = Tuple{ScreenID, Scene}

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
    end
end

GeometryTypes.widths(x::Screen) = size(x.framebuffer.color)

Base.wait(x::Screen) = isassigned(x.rendertask) && wait(x.rendertask[])
Base.wait(scene::Scene) = wait(AbstractPlotting.getscreen(scene))
Base.show(io::IO, screen::Screen) = print(io, "GLMakie.Screen(...)")
Base.size(x::Screen) = size(x.framebuffer)

function insertplots!(screen::GLScreen, scene::Scene)
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

function Base.delete!(screen::Screen, scene::Scene, plot::AbstractPlot)
    if !isempty(plot.plots)
        # this plot consists of children, so we flatten it and delete the children instead
        delete!.(Ref(screen), Ref(scene), AbstractPlotting.flatten_plots(plot))
    else
        renderobject = get(screen.cache, objectid(plot)) do
            error("Could not find $(typeof(subplot)) in current GLMakie screen!")
        end
        filter!(x-> x[3] !== renderobject, screen.renderlist)
    end
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
        oldsize = windowsize(window)
        retina_scale = retina_scaling_factor(window)
        w, h = resolution ./ retina_scale
        if oldsize == (w, h)
            return
        end
        GLFW.SetWindowSize(window, round(Int, w), round(Int, h))
        # There is a problem, that window size update seems to take an arbitrary
        # amount of time - GLFW.WaitEvents() / a single GLFW.PollEvent()
        # doesn't help, so we try it a couple of times, to make sure
        # we have the desired size in the end
        for i in 1:100
            isopen(window) || return
            newsize = windowsize(window)
            # we aren't guaranteed to get exactly w & h, since the window
            # manager is allowed to restrict the size...
            # So we can only test, if the size changed, but not if it matches
            # the desired size!
            newsize != oldsize && return
            # There is a bug here, were without `sleep` it doesn't update the size
            # Not sure who's fault it is, but PollEvents/yield both dont work - only sleep!
            GLFW.PollEvents()
            sleep(0.001)
        end
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
            @inbounds c = A[i, j]
            c = mapc(c) do channel
                x = clamp(channel, 0.0, 1.0)
                return ifelse(isfinite(x), x, 0.0)
            end
            @inbounds B[n-j, i] = c
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


function render_colorbuffer(screen)
    nw = to_native(screen)
    GLAbstraction.is_context_active(nw) || return
    fb = screen.framebuffer
    w, h = size(fb)
    glEnable(GL_STENCIL_TEST)
    #prepare for geometry in need of anti aliasing
    glBindFramebuffer(GL_FRAMEBUFFER, fb.id[1]) # color framebuffer
    glDrawBuffers(2, [GL_COLOR_ATTACHMENT0, GL_COLOR_ATTACHMENT1])
    glEnable(GL_STENCIL_TEST)
    glStencilOp(GL_KEEP, GL_KEEP, GL_REPLACE)
    glStencilMask(0xff)
    glClearStencil(0)
    glClearColor(0,0,0,0)
    glClear(GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT | GL_COLOR_BUFFER_BIT)
    setup!(screen)

    glColorMask(GL_TRUE, GL_TRUE, GL_TRUE, GL_TRUE)
    glStencilOp(GL_KEEP, GL_KEEP, GL_REPLACE)
    glStencilMask(0x00)
    GLAbstraction.render(screen, true)
    glDisable(GL_STENCIL_TEST)

    # transfer color to luma buffer and apply fxaa
    glBindFramebuffer(GL_FRAMEBUFFER, fb.id[2]) # luma framebuffer
    glDrawBuffer(GL_COLOR_ATTACHMENT0)
    glViewport(0, 0, w, h)
    glClearColor(0,0,0,0)
    glClear(GL_COLOR_BUFFER_BIT)
    GLAbstraction.render(fb.postprocess[1]) # add luma and preprocess

    glBindFramebuffer(GL_FRAMEBUFFER, fb.id[1]) # transfer to non fxaa framebuffer
    glViewport(0, 0, w, h)
    glDrawBuffer(GL_COLOR_ATTACHMENT0)
    GLAbstraction.render(fb.postprocess[2]) # copy with fxaa postprocess

    #prepare for non anti aliased pass
    glDrawBuffers(2, [GL_COLOR_ATTACHMENT0, GL_COLOR_ATTACHMENT1])

    glEnable(GL_STENCIL_TEST)
    glStencilOp(GL_KEEP, GL_KEEP, GL_REPLACE)
    glStencilMask(0x00)
    GLAbstraction.render(screen, false)
    glDisable(GL_STENCIL_TEST)
    glBindFramebuffer(GL_FRAMEBUFFER, 0) # transfer back to window
    glViewport(0, 0, w, h)
    glClearColor(0, 0, 0, 0)
    glClear(GL_COLOR_BUFFER_BIT)
    GLAbstraction.render(fb.postprocess[3]) # copy postprocess
end

function AbstractPlotting.colorbuffer(screen::Screen)
    if isopen(screen)
        ctex = screen.framebuffer.color
        # polling may change window size, when its bigger than monitor!
        # we still need to poll though, to get all the newest events!
        # GLFW.PollEvents()
        # we need to resize the framebuffer to the dimensions before polling
        render_colorbuffer(screen) # let it render
        glFinish() # block until opengl is done rendering
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
    # filter out gc'ed elements
    filter!(screen.screen2scene) do (k, v)
        k.value != nothing
    end
    screenid = get!(screen.screen2scene, WeakRef(scene)) do
        id = length(screen.screens) + 1
        push!(screen.screens, (id, scene))
        return id
    end
    push!(screen.renderlist, (0, screenid, robj))
    return robj
end

to_native(x::Screen) = x.glscreen


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

const GLOBAL_GL_SCREEN = Ref{Screen}()

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

const gl_screens = GLFW.Window[]

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
    # This enum is somehow not wrapped in GLFW
    GLFW_FOCUS_ON_SHOW=0x0002000C
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
            (GLFW_FOCUS_ON_SHOW, false)
            # (GLFW.RESIZABLE, GL_TRUE)
        ],
        visible = false,
        focus = false,
        kw_args...
    )
    GLFW.SetWindowIcon(window, AbstractPlotting.icon())

    # tell GLAbstraction that we created a new context.
    # This is important for resource tracking, and only needed for the first context
    GLAbstraction.switch_context!(window)
    GLAbstraction.empty_shader_cache!()
    push!(gl_screens, window)

    GLFW.SwapInterval(0)

    resize!(window, resolution...)
    fb = GLFramebuffer(resolution)

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
    screen.rendertask[] = @async((opengl_renderloop[])(screen))
    # display window if visible!
    if visible
        GLFW.ShowWindow(window)
    else
        GLFW.HideWindow(window)
    end
    return screen
end

function global_gl_screen()
    screen = if isassigned(GLOBAL_GL_SCREEN) && isopen(GLOBAL_GL_SCREEN[])
        GLOBAL_GL_SCREEN[]
    else
        GLOBAL_GL_SCREEN[] = Screen()
        GLOBAL_GL_SCREEN[]
    end
    return screen
end

function global_gl_screen(resolution::Tuple, visibility::Bool, tries = 1)
    # ugly but easy way to find out if we create new screen.
    # could just be returned by global_gl_screen, but dont want to change the API
    isold = isassigned(GLOBAL_GL_SCREEN) && isopen(GLOBAL_GL_SCREEN[])
    screen = global_gl_screen()
    GLFW.set_visibility!(to_native(screen), visibility)
    resize!(screen, resolution...)
    new_size = windowsize(to_native(screen))
    # I'm not 100% sure, if there are platforms where I'm never
    # able to resize the screen (opengl might just allow that).
    # so, we guard against that with just trying another resize one time!
    if (new_size != resolution) && tries == 1
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

function pick_native(screen::Screen, xy::Vec{2, Float64})
    isopen(screen) || return SelectionID{Int}(0, 0)
    sid = Base.RefValue{SelectionID{UInt16}}()
    window_size = widths(screen)
    fb = screen.framebuffer
    buff = fb.objectid
    glBindFramebuffer(GL_FRAMEBUFFER, fb.id[1])
    glReadBuffer(GL_COLOR_ATTACHMENT1)
    x, y = floor.(Int, xy)
    w, h = window_size
    if x > 0 && y > 0 && x <= w && y <= h
        glReadPixels(x, y, 1, 1, buff.format, buff.pixeltype, sid)
        return convert(SelectionID{Int}, sid[])
    end
    return SelectionID{Int}(0, 0)
end

function AbstractPlotting.pick(scene::SceneLike, screen::Screen, xy::Vec{2, Float64})
    sid = pick_native(screen, xy)
    if haskey(screen.cache2plot, sid.id)
        plot = screen.cache2plot[sid.id]
        return (plot, sid.index)
    else
        return (nothing, 0)
    end
end


function AbstractPlotting.pick(screen::Screen, rect::IRect2D)
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
            (screen.cache2plot[sid.id], sid.index)
        end
    end
    return Tuple{AbstractPlot, Int}[]
end
