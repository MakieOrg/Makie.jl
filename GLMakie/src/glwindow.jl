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
    size::Tuple{Int, Int}
    buffer_key2idx::Dict{Symbol, Int} # TODO: temp, should be unnamed collection
    buffers::Vector{Texture}
    core_buffers::Dict{Symbol, Texture} # Not managed by render pipeline
    children::Vector{GLFramebuffer} # TODO: how else can we handle resizing?
end

# it's guaranteed, that they all have the same size
# TODO: forwards... for now
Base.size(fb::FramebufferFactory) = fb.size
Base.haskey(fb::FramebufferFactory, key::Symbol) = haskey(fb.buffer_key2idx, key)
function GLAbstraction.get_buffer(fb::FramebufferFactory, key::Symbol)
    if haskey(fb.core_buffers, key)
        return fb.core_buffers[key]
    else
        return fb.buffers[fb.buffer_key2idx[key]]
    end
end
GLAbstraction.get_buffer(fb::FramebufferFactory, idx::Int) = fb.buffers[idx]
# GLAbstraction.bind(fb::FramebufferFactory) = GLAbstraction.bind(fb.fb)

Makie.@noconstprop function FramebufferFactory(context, fb_size::NTuple{2, Int})
    ShaderAbstractions.switch_context!(context)
    require_context(context)

    # Buffers we always need
    # Holds the image that eventually gets displayed
    color_buffer = Texture(
        context, RGBA{N0f8}, fb_size, minfilter = :nearest, x_repeat = :clamp_to_edge
    )
    # Holds a (plot id, element id) for point picking
    objectid_buffer = Texture(
        context, Vec{2, GLuint}, fb_size, minfilter = :nearest, x_repeat = :clamp_to_edge
    )
    # holds depth and stencil values
    depth_buffer = Texture(
        context, Ptr{GLAbstraction.DepthStencil_24_8}(C_NULL), fb_size,
        minfilter = :nearest, x_repeat = :clamp_to_edge,
        internalformat = GL_DEPTH24_STENCIL8,
        format = GL_DEPTH_STENCIL
    )
    # Order Independent Transparency
    HDR_color_buffer = Texture(
        context, RGBA{Float16}, fb_size, minfilter = :linear, x_repeat = :clamp_to_edge
    )
    OIT_weight_buffer = Texture(
        context, N0f8, fb_size, minfilter = :nearest, x_repeat = :clamp_to_edge
    )

    name2idx = Dict(:color => 1, :objectid => 2, :HDR_color => 3, :OIT_weight => 4)
    buffers = [color_buffer, objectid_buffer, HDR_color_buffer, OIT_weight_buffer]

    return FramebufferFactory(fb_size, name2idx, buffers, Dict(:depth_stencil => depth_buffer), GLFramebuffer[])
end

function Base.resize!(fb::FramebufferFactory, w::Int, h::Int)
    foreach(tex -> GLAbstraction.resize_nocopy!(tex, (w, h)), fb.buffers)
    foreach(tex -> GLAbstraction.resize_nocopy!(tex, (w, h)), values(fb.core_buffers))
    # resize!(fb.fb, w, h)
    fb.size = (w, h)
    filter!(fb -> fb.id != 0, fb.children) # TODO: is this ok?
    foreach(fb -> resize!(fb, w, h), fb.children)
    return
end

function unsafe_empty!(factory::FramebufferFactory)
    empty!(factory.buffer_key2idx)
    empty!(factory.buffers)
    empty!(factory.children)
    return factory
end

# TODO: temporary
function Base.push!(factory::FramebufferFactory, kv::Pair{Symbol, <: Texture})
    if haskey(factory.buffer_key2idx, kv[1])
        @error("Pushed buffer $(kv[1]) already assigned.")
        return
    end
    push!(factory, kv[2])
    push!(factory.buffer_key2idx, kv[1] => length(factory.buffers))
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
    attach_depthstencilbuffer(fb, :depth_stencil, factory.core_buffers[:depth_stencil])

    for (idx, name) in idx2name
        haskey(fb, name) && error("Can't add duplicate buffer $lookup => $name")
        # in(lookup, [:depth, :stencil]) && error("Depth and stencil always exist under the same name.")
        attach_colorbuffer(fb, name, factory.buffers[idx])
    end

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
