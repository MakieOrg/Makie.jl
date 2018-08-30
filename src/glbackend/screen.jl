const ScreenID = UInt8
const ZIndex = Int
const ScreenArea = Tuple{ScreenID, Node{IRect2D}, Node{Bool}, Node{RGBAf0}}

mutable struct Screen <: AbstractScreen
    glscreen::GLFW.Window
    framebuffer::GLFramebuffer
    rendertask::RefValue{Task}
    screen2scene::Dict{WeakRef, ScreenID}
    screens::Vector{ScreenArea}
    renderlist::Vector{Tuple{ZIndex, ScreenID, RenderObject}}
    cache::Dict{UInt64, RenderObject}
    cache2plot::Dict{UInt16, AbstractPlot}
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
        obj = new(glscreen, framebuffer, rendertask, screen2scene, screens, renderlist, cache, cache2plot)
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

function insertplots!(screen::Screen, scene::Scene)
    for elem in scene.plots
        insert!(screen, scene, elem)
    end
    foreach(s-> insertplots!(screen, s), scene.children)
end

function Base.empty!(screen::Screen)
    empty!(screen.renderlist)
    empty!(screen.screen2scene)
    empty!(screen.screens)
    empty!(screen.cache)
    empty!(screen.cache2plot)
end

function Base.resize!(window::GLFW.Window, resolution...)
    if isopen(window)
        retina_scale = retina_scaling_factor(window)
        w, h = resolution ./ retina_scale
        GLFW.SetWindowSize(window, round(Int, w), round(Int, h))
    end
end

Base.resize!(screen::Screen, w, h) = resize!(screen.glscreen, w, h)

function Base.display(screen::Screen, scene::Scene)
    empty!(screen)
    resize!(screen, widths(AbstractPlotting.pixelarea(scene)[])...)
    register_callbacks(scene, to_native(screen))
    insertplots!(screen, scene)
    force_update!()
    return
end

function colorbuffer(screen::Screen)
    if isopen(screen)
        force_update!()
        GLFW.PollEvents()
        yield()
        render_frame(screen) # let it render
        GLFW.SwapBuffers(to_native(screen))
        glFinish() # block until opengl is done rendering
        buffer = gpu_data(screen.framebuffer.color)
        return rotl90(ImageCore.clamp01nan.(RGB{N0f8}.(buffer)))
    else
        error("Screen not open!")
    end
end


Base.isopen(x::Screen) = isopen(x.glscreen)
function Base.push!(screen::Screen, scene::Scene, robj)
    filter!(screen.screen2scene) do (k, v)
        k.value != nothing
    end
    screenid = get!(screen.screen2scene, WeakRef(scene)) do
        id = length(screen.screens) + 1
        bg = map(to_color, scene.theme[:backgroundcolor])
        push!(screen.screens, (id, scene.px_area, Node(true), bg))
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

function Screen(;resolution = (10, 10), visible = true, kw_args...)
    if !isempty(gl_screens)
        for elem in gl_screens
            isopen(elem) && destroy!(elem)
        end
        empty!(gl_screens)
    end

    window = GLFW.Window(
        name = "Makie", resolution = (10, 10), # 10, because smaller sizes seem to error on some platforms
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
            (GLFW.AUX_BUFFERS,  0)
        ],
        visible = false,
        kw_args...
    )
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
    screen.rendertask[] = @async(renderloop(screen))
    if visible
        GLFW.ShowWindow(window)
    else
        GLFW.HideWindow(window)
    end
    screen
end

function global_gl_screen()
    if isassigned(_global_gl_screen) && isopen(_global_gl_screen[])
        _global_gl_screen[]
    else
        _global_gl_screen[] = Screen()
        _global_gl_screen[]
    end
end

# TODO per scene screen
getscreen(scene) = global_gl_screen()

function pick_native(scene::SceneLike, xy::VecTypes{2}, sid = Base.RefValue{SelectionID{UInt16}}())
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

function pick(scene::SceneLike, xy::VecTypes{2})
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
    p in plots
end

function onpick(f, scene::SceneLike, plots::AbstractPlot...)
    map_once(events(scene).mouseposition) do mp
        p, idx = mouse_selection(scene)
        (p in plots) && f(idx)
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
