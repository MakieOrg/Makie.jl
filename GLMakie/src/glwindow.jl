"""
Selection of random objects on the screen is realized by rendering an
object id + plus an arbitrary index into the framebuffer.
The index can be used for e.g. instanced geometries.
"""
struct SelectionID{T <: Integer}
    id::T
    index::T
end
Base.convert(::Type{SelectionID{T}}, s::SelectionID) where T = SelectionID{T}(T(s.id), T(s.index))
Base.zero(::Type{GLMakie.SelectionID{T}}) where T = SelectionID{T}(T(0), T(0))

mutable struct FramebufferFactory
    fb::GLFramebuffer # core framebuffer (more or less for #4150)
    # holding depth, stencil, objectid[, output_color]

    buffer_key2idx::Dict{Symbol, Int} # TODO: temp, should be unnamed collection
    buffers::Vector{Texture}
    children::Vector{GLFramebuffer} # TODO: how else can we handle resizing?
end

Base.size(fb::FramebufferFactory) = size(fb.fb)
Base.haskey(fb::FramebufferFactory, key::Symbol) = haskey(fb.buffer_key2idx, key)
GLAbstraction.get_buffer(fb::FramebufferFactory, key::Symbol) = fb.buffers[fb.buffer_key2idx[key]]
GLAbstraction.get_buffer(fb::FramebufferFactory, idx::Int) = fb.buffers[idx]
GLAbstraction.bind(fb::FramebufferFactory) = GLAbstraction.bind(fb.fb)

Makie.@noconstprop function FramebufferFactory(context, fb_size::NTuple{2, Int})
    ShaderAbstractions.switch_context!(context)
    require_context(context)

    # holds depth and stencil values
    depth_buffer = Texture(
        context, Ptr{GLAbstraction.DepthStencil_24_8}(C_NULL), fb_size,
        minfilter = :nearest, x_repeat = :clamp_to_edge,
        internalformat = GL_DEPTH24_STENCIL8,
        format = GL_DEPTH_STENCIL
    )

    fb = GLFramebuffer(fb_size)
    attach_depthstencilbuffer(fb, :depth_stencil, depth_buffer)

    return FramebufferFactory(fb, Dict{Symbol, Int}(), Texture[], GLFramebuffer[])
end

function Base.resize!(fb::FramebufferFactory, w::Int, h::Int)
    foreach(tex -> GLAbstraction.resize_nocopy!(tex, (w, h)), fb.buffers)
    resize!(fb.fb, w, h)
    filter!(fb -> fb.id != 0, fb.children) # TODO: is this ok for cleanup?
    foreach(fb -> resize!(fb, w, h), fb.children)
    return
end

function unsafe_empty!(factory::FramebufferFactory)
    empty!(factory.buffer_key2idx)
    empty!(factory.buffers)
    empty!(factory.children)
    haskey(factory.fb, :color) && GLAbstraction.pop_colorbuffer!(factory.fb)
    haskey(factory.fb, :objectid) && GLAbstraction.pop_colorbuffer!(factory.fb)
    return factory
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

function generate_framebuffer(factory::FramebufferFactory, names::Pair{Symbol, Symbol}...)
    remapped = map(kv -> factory.buffer_key2idx[kv[1]] => kv[2], names)
    return generate_framebuffer(factory, remapped...)
end

function generate_framebuffer(factory::FramebufferFactory, idx2name::Pair{Int, Symbol}...)
    filter!(fb -> fb.id != 0, factory.children) # cleanup?

    fb = GLFramebuffer(size(factory))

    for (idx, name) in idx2name
        haskey(fb, name) && error("Can't add duplicate buffer $lookup => $name")
        # in(lookup, [:depth, :stencil]) && error("Depth and stencil always exist under the same name.")
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

    MonitorProperties(name, isprimary, position, physicalsize, videomode, videomode_supported, dpi, monitor)
end

was_destroyed(nw::GLFW.Window) = nw.handle == C_NULL

function GLContext()
    context = GLFW.GetCurrentContext()
    version = opengl_version_number()
    glsl_version = glsl_version_number()
    return GLContext(context, version, glsl_version, unique_context_counter())
end

function ShaderAbstractions.native_switch_context!(x::GLFW.Window)
    GLFW.MakeContextCurrent(x)
end

function ShaderAbstractions.native_context_alive(x::GLFW.Window)
    GLFW.is_initialized() && !was_destroyed(x)
end

# require_context(ctx, current = nothing) = nothing
function GLAbstraction.require_context(ctx, current = ShaderAbstractions.current_context(); warn = false)
    @assert GLFW.is_initialized() "Context $ctx must be initialized, but is not."
    @assert !was_destroyed(ctx) "Context $ctx must not be destroyed."
    @assert ctx.handle == current.handle "Context $ctx must be current, but $current is."
end

function destroy!(nw::GLFW.Window)
    was_current = ShaderAbstractions.is_current_context(nw)
    if !was_destroyed(nw)
        GLFW.SetWindowShouldClose(nw, true)
        GLFW.PollEvents()
        GLFW.DestroyWindow(nw)
        nw.handle = C_NULL
    end
    was_current && ShaderAbstractions.switch_context!()
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
    was_destroyed(nw) && return 1f0
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
