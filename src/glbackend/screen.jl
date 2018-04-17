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
    function Screen(
            glscreen::GLFW.Window,
            framebuffer::GLWindow.GLFramebuffer,
            rendertask::RefValue{Task},
            screen2scene::Dict{WeakRef, ScreenID},
            screens::Vector{ScreenArea},
            renderlist::Vector{Tuple{ZIndex, ScreenID, RenderObject}},
            cache::Dict{UInt64, RenderObject},
        )
        obj = new(glscreen, framebuffer, rendertask, screen2scene, screens, renderlist, cache)
        jl_finalizer(obj) do obj
            # save_print("Freeing screen")
            empty!.((obj.renderlist, obj.screens, obj.cache, obj.screen2scene))
            return
        end
        obj
    end
end

const io_lock = ReentrantLock()

function save_print(args...)
    @async begin
        lock(io_lock)
        println(args...)
        unlock(io_lock)
    end
end



Base.isopen(x::Screen) = isopen(x.glscreen)
function Base.push!(screen::Screen, scene::Scene, robj)
    filter!(screen.screen2scene) do k, v
        k.value != nothing
    end
    screenid = get!(screen.screen2scene, WeakRef(scene)) do
        id = 1#length(screen.screens) + 1
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
        Dict{UInt64, RenderObject}()
    )
    screen.rendertask[] = @async(renderloop(screen))
    register_callbacks(scene, to_native(screen))
    push!(scene.current_screens, screen)
    screen
end
