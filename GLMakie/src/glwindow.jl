"""
Selection of random objects on the screen is realized by rendering an
object id + plus an arbitrary index into the framebuffer.
The index can be used for e.g. instanced geometries.
"""
struct SelectionID{T <: Integer}
    id::T
    index::T
end
Base.convert(::Type{SelectionID{T}}, s::SelectionID) where {T} = SelectionID{T}(T(s.id), T(s.index))
Base.zero(::Type{GLMakie.SelectionID{T}}) where {T} = SelectionID{T}(T(0), T(0))



mutable struct FramebufferFactory
    fb::GLFramebuffer # core framebuffer (more or less for #4150)
    # holding depth, stencil, objectid[, output_color]

    buffers::Vector{Texture}
    children::Vector{GLFramebuffer} # TODO: how else can we handle resizing?
end

Base.size(fb::FramebufferFactory) = size(fb.fb)
GLAbstraction.get_buffer(fb::FramebufferFactory, idx::Int) = fb.buffers[idx]
GLAbstraction.bind(fb::FramebufferFactory) = GLAbstraction.bind(fb.fb)

Makie.@noconstprop function FramebufferFactory(context, fb_size::NTuple{2, Int})
    return FramebufferFactory(create_main_framebuffer(context, fb_size), Texture[], GLFramebuffer[])
end

function reset_main_framebuffer!(factory::FramebufferFactory)
    @assert factory.fb.id == 0 "Main framebuffer must be destroyed before being reset"
    factory.fb = create_main_framebuffer(factory.fb.context, factory.fb.size)
    return factory
end

function create_main_framebuffer(context, fb_size)
    gl_switch_context!(context)
    require_context(context)

    # holds depth and stencil values
    depth_buffer = Texture(
        context, Ptr{GLAbstraction.DepthStencil_24_8}(C_NULL), fb_size,
        minfilter = :nearest, x_repeat = :clamp_to_edge,
        internalformat = GL_DEPTH24_STENCIL8,
        format = GL_DEPTH_STENCIL
    )

    fb = GLFramebuffer(context, fb_size)
    attach_depthstencilbuffer(fb, :depth_stencil, depth_buffer)
    return fb
end

function Base.resize!(fb::FramebufferFactory, w::Int, h::Int)
    gl_switch_context!(first(values(fb.buffers)).context)
    foreach(tex -> GLAbstraction.resize_nocopy!(tex, (w, h)), fb.buffers)
    resize!(fb.fb, w, h)
    filter!(fb -> fb.id != 0, fb.children) # TODO: is this ok for cleanup?
    foreach(fb -> resize!(fb, w, h), fb.children)
    return
end

# destroys everything
function destroy!(factory::FramebufferFactory)
    ctx = factory.fb.context
    ShaderAbstractions.switch_context!(ctx)
    # avoid try .. catch at call site, and allow cleanup to run
    GLAbstraction.require_context_no_error(ctx)

    GLAbstraction.free.(factory.buffers)
    GLAbstraction.free.(factory.children)
    # make sure depth, stencil get cleared too (and maybe core color buffers in the future)
    GLAbstraction.free.(factory.fb.buffers)
    GLAbstraction.free(factory.fb)
    empty!(factory.buffers)
    empty!(factory.children)
    return
end

function Base.push!(factory::FramebufferFactory, tex::Texture)
    push!(factory.buffers, tex)
    return factory
end

function generate_framebuffer(factory::FramebufferFactory, args...)
    parse_arg(name::Symbol) = name => name
    parse_arg(p::Pair{Symbol, Symbol}) = p
    parse_arg(x::Any) = error("$x not accepted")

    return generate_framebuffer(factory, parse_arg.(args)...)
end

Makie.@noconstprop function generate_framebuffer(factory::FramebufferFactory, idx2name::Pair{Int, Symbol}...)
    filter!(fb -> fb.id != 0, factory.children) # cleanup?

    fb = GLFramebuffer(factory.fb.context, size(factory))

    for (idx, name) in idx2name
        haskey(fb, name) && error("Can't add duplicate buffer $lookup => $name")
        attach_colorbuffer(fb, name, factory.buffers[idx])
    end

    attach_depthstencilbuffer(fb, :depth_stencil, get_buffer(factory.fb, :depth_stencil))

    push!(factory.children, fb)

    return fb
end



struct MonitorProperties
    name::String
    isprimary::Bool
    position::Vec{2, Int}
    physicalsize::Vec{2, Int}
    videomode::GLFW.VidMode
    videomode_supported::Vector{GLFW.VidMode}
    dpi::Vec{2, Float64}
    monitor::GLFW.Monitor
end

function MonitorProperties(monitor::GLFW.Monitor)
    name = GLFW.GetMonitorName(monitor)
    isprimary = GLFW.GetPrimaryMonitor() == monitor
    position = Vec{2, Int}(GLFW.GetMonitorPos(monitor)...)
    physicalsize = Vec{2, Int}(GLFW.GetMonitorPhysicalSize(monitor)...)
    videomode = GLFW.GetVideoMode(monitor)
    sfactor = Sys.isapple() ? 2.0 : 1.0
    dpi = Vec(videomode.width * 25.4, videomode.height * 25.4) * sfactor ./ Vec{2, Float64}(physicalsize)
    videomode_supported = GLFW.GetVideoModes(monitor)

    return MonitorProperties(name, isprimary, position, physicalsize, videomode, videomode_supported, dpi, monitor)
end

was_destroyed(nw::GLFW.Window) = nw.handle == C_NULL

function GLContext()
    context = GLFW.GetCurrentContext()
    version = opengl_version_number()
    glsl_version = glsl_version_number()
    return GLContext(context, version, glsl_version, unique_context_counter())
end

function ShaderAbstractions.native_switch_context!(x::GLFW.Window)
    return GLFW.MakeContextCurrent(x)
end

function ShaderAbstractions.native_context_alive(x::GLFW.Window)
    return GLFW.is_initialized() && !was_destroyed(x)
end

function check_context(ctx)
    !GLFW.is_initialized() && return "GLFW is not initialized, and therefore $ctx is invalid."
    was_destroyed(ctx) && return "Context $ctx has been destroyed."
    return nothing
end

function GLAbstraction.require_context_no_error(ctx, current = ShaderAbstractions.current_context())
    msg = check_context(ctx)
    msg !== nothing && return msg
    ctx !== current && return "Context $ctx must be current, but $current is."
    return nothing
end

function destroy!(nw::GLFW.Window)
    was_current = ShaderAbstractions.is_current_context(nw)
    if !was_destroyed(nw)
        GLFW.SetWindowShouldClose(nw, true)
        GLFW.PollEvents()
        GLFW.DestroyWindow(nw)
        nw.handle = C_NULL
    end
    return was_current && gl_switch_context!()
end

function window_size(nw::GLFW.Window)
    was_destroyed(nw) && return (0, 0)
    return Tuple(GLFW.GetWindowSize(nw))
end
function window_position(nw::GLFW.Window)
    was_destroyed(nw) && return (0, 0)
    return Tuple(GLFW.GetWindowPos(window))
end
function framebuffer_size(nw::GLFW.Window)
    was_destroyed(nw) && return (0, 0)
    return Tuple(GLFW.GetFramebufferSize(nw))
end
function scale_factor(nw::GLFW.Window)
    was_destroyed(nw) && return 1.0f0
    return minimum(GLFW.GetWindowContentScale(nw))
end

function Base.isopen(window::GLFW.Window)
    was_destroyed(window) && return false
    try
        return !GLFW.WindowShouldClose(window)
    catch e
        # can't be open if GLFW is already terminated
        e.code == GLFW.NOT_INITIALIZED && return false
        rethrow(e)
    end
end
