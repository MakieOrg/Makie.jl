const ScreenID = UInt8
const ZIndex = Int
const ScreenArea = Tuple{ScreenID, Node{IRect2D}, Node{Bool}, Node{RGBAf0}}

struct Screen <: AbstractScreen
    glscreen::GLFW.Window
    framebuffer::GLWindow.GLFramebuffer
    rendertask::RefValue{Task}
    screen2scene::Dict{WeakRef, ScreenID}
    screens::Vector{ScreenArea}
    renderlist::Vector{Tuple{ZIndex, ScreenID, RenderObject}}
    cache::Dict{UInt64, RenderObject}
end
Base.isopen(x::Screen) = isopen(x.glscreen)
function Base.push!(screen::Screen, scene::Scene, robj)
    filter!(screen.screen2scene) do kv
        kv[1].value != nothing
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
"""
Function to create a pure GLFW OpenGL window
"""
function create_glcontext(
        name = "Makie";
        resolution = GLWindow.standard_screen_resolution(),
        debugging = false,
        major = 3,
        minor = 3,# this is what GLVisualize needs to offer all features
        windowhints = GLWindow.standard_window_hints(),
        contexthints = GLWindow.standard_context_hints(major, minor),
        visible = true,
        focus = false,
        fullscreen = false,
        monitor = nothing,
        parent = GLFW.Window(C_NULL)
    )
    # we create a new context, so we need to clear the shader cache.
    # TODO, cache shaders in GLAbstraction per GL context
    GLFW.WindowHint(GLFW.VISIBLE, visible)
    GLFW.WindowHint(GLFW.FOCUSED, focus)
    for ch in contexthints
        GLFW.WindowHint(ch[1], ch[2])
    end
    for wh in windowhints
        GLFW.WindowHint(wh[1], wh[2])
    end

    @static if is_apple()
        if debugging
            warn("OpenGL debug message callback not available on osx")
            debugging = false
        end
    end

    GLFW.WindowHint(GLFW.OPENGL_DEBUG_CONTEXT, Cint(debugging))

    monitor = if monitor == nothing
        GLFW.GetPrimaryMonitor()
    elseif isa(monitor, Integer)
        GLFW.GetMonitors()[monitor]
    elseif isa(monitor, GLFW.Monitor)
        monitor
    else
        error("Monitor needs to be nothing, int, or GLFW.Monitor. Found: $monitor")
    end

    window = GLFW.CreateWindow(resolution..., String(name), GLFW.Monitor(C_NULL), parent)

    if fullscreen
        GLFW.SetKeyCallback(window, (_1, button, _2, _3, _4) -> begin
            button == GLFW.KEY_ESCAPE && GLWindow.make_windowed!(window)
        end)
        GLWindow.make_fullscreen!(window, monitor)
    end
    debugging && glDebugMessageCallbackARB(_openglerrorcallback, C_NULL)
    window
end

function Screen(scene::Scene; kw_args...)
    filter!(isopen, gl_screens)
    window = if isempty(gl_screens)
        window = create_glcontext("Makie"; kw_args...)
        # tell GLAbstraction that we created a new context.
        # This is important for resource tracking, and only needed for the first context
        GLAbstraction.new_context()
        GLAbstraction.empty_shader_cache!()
        window
    else
        # share OpenGL Context
        create_glcontext("Makie"; parent = first(gl_screens), kw_args...)
    end
    push!(gl_screens, window)
    GLFW.MakeContextCurrent(window)
    GLFW.SwapInterval(0)
    fb = GLWindow.GLFramebuffer(map(widths, scene.events.window_area))
    screen = Screen(
        window, fb,
        RefValue{Task}(),
        Dict{Scene, ScreenID}(),
        ScreenArea[],
        Tuple{ZIndex, ScreenID, RenderObject}[],
        Dict{UInt64, RenderObject}()
    )
    screen.rendertask[] = @async(renderloop(screen))
    register_callbacks(scene, to_native(screen))
    push!(scene.current_screens, screen)
    screen
end
