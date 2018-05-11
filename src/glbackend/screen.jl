const ScreenID = UInt8
const ZIndex = Int
const ScreenArea = Tuple{ScreenID, Node{IRect2D}, Node{Bool}, Node{RGBAf0}}

mutable struct Screen <: AbstractScreen
    glscreen::GLFW.Window
    framebuffer::GLWindow.GLFramebuffer
    rendertask::RefValue{Task}
    screen2scene::Dict{WeakRef, ScreenID}
    screens::Vector{ScreenArea}
    renderlist::Vector{Tuple{ZIndex, ScreenID, RenderObject}}
    cache::Dict{UInt64, RenderObject}
    cache2plot::Dict{UInt16, AbstractPlot}
    function Screen(
            glscreen::GLFW.Window,
            framebuffer::GLWindow.GLFramebuffer,
            rendertask::RefValue{Task},
            screen2scene::Dict{WeakRef, ScreenID},
            screens::Vector{ScreenArea},
            renderlist::Vector{Tuple{ZIndex, ScreenID, RenderObject}},
            cache::Dict{UInt64, RenderObject},
            cache2plot::Dict{UInt16, AbstractPlot},
        )
        obj = new(glscreen, framebuffer, rendertask, screen2scene, screens, renderlist, cache, cache2plot)
        jl_finalizer(obj) do obj
            # save_print("Freeing screen")
            empty!.((obj.renderlist, obj.screens, obj.cache, obj.screen2scene, obj.cache2plot))
            return
        end
        obj
    end
end
GeometryTypes.widths(x::Screen) = size(x.framebuffer.color)


function colorbuffer(screen::Screen)
    GLFW.PollEvents()
    yield()
    render_frame(screen) # let it render
    GLFW.SwapBuffers(to_native(screen))
    glFinish() # block until opengl is done rendering
    buffer = gpu_data(screen.framebuffer.color)
    buffer .= Images.clamp01nan.(buffer)
    return buffer
end

"""
Selection of random objects on the screen is realized by rendering an
object id + plus an arbitrary index into the framebuffer.
The index can be used for e.g. instanced geometries.
"""
struct SelectionID{T <: Integer} <: FieldVector{2, T}
    id::T
    index::T
end

function getscreen(scene::Scene)
    isempty(scene.current_screens) && return nothing
    scene.current_screens[1]
end


Base.isopen(x::Screen) = isopen(x.glscreen)
function Base.push!(screen::Screen, scene::Scene, robj)
    filter!(screen.screen2scene) do k, v
        k.value != nothing
    end
    screenid = get!(screen.screen2scene, WeakRef(scene)) do
        id = length(screen.screens) + 1
        push!(screen.screens, (id, scene.px_area, Node(true), scene.theme[:backgroundcolor]))
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

function Screen(scene::Scene; kw_args...)
    if !isempty(gl_screens)
        for elem in gl_screens
            isopen(elem) && destroy!(elem)
        end
        empty!(gl_screens)
    end
    window = GLFW.Window(name = "Makie", resolution = widths(scene.px_area[]), kw_args...)
    # tell GLAbstraction that we created a new context.
    # This is important for resource tracking, and only needed for the first context
    GLAbstraction.new_context()
    GLAbstraction.empty_shader_cache!()
    # else
    #     # share OpenGL Context
    #     create_glcontext("Makie"; parent = first(gl_screens), kw_args...)
    # end
    push!(gl_screens, window)
    GLFW.MakeContextCurrent(window)
    GLFW.SwapInterval(0)
    fb = GLWindow.GLFramebuffer(map(widths, scene.events.window_area))
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
    register_callbacks(scene, to_native(screen))
    push!(scene.current_screens, screen)
    screen
end


function pick_native(scene::Scene, xy::VecTypes{2}, sid = Base.RefValue{SelectionID{UInt16}}())
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

pick(scene::Scene, xy...) = pick(scene, Float64.(xy))

function pick(scene::Scene, xy::VecTypes{2})
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
function mouse_selection_native(scene::Scene)
    function query_mouse()
        screen = getscreen(scene)
        screen == nothing && return SelectionID{Int}(0, 0)
        window_size = widths(screen)
        fb = screen.framebuffer
        buff = fb.objectid
        glReadBuffer(GL_COLOR_ATTACHMENT1)
        xy = scene.events.mouseposition[]
        x, y = Int.(floor.(xy))
        w, h = window_size
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
function mouse_selection(scene::Scene)
    sid = mouse_selection_native(scene)
    screen = getscreen(scene)
    if screen != nothing && haskey(screen.cache2plot, sid.id)
        plot = screen.cache2plot[sid.id]
        return (plot, sid.index)
    end
    return (nothing, 0)
end
function mouseover(scene::Scene, plots::AbstractPlot...)
    p, idx = mouse_selection(scene)
    p in plots
end

function onpick(f, scene::Scene, plots::AbstractPlot...)
    map_once(scene.events.mouseposition) do mp
        p, idx = mouse_selection(scene, mp)
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
