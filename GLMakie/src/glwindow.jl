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

mutable struct Framebuffer
    fb::GLFramebuffer
    render_buffer_ids::Vector{GLuint}
end

# it's guaranteed, that they all have the same size
# forwards... for now
Base.size(fb::Framebuffer) = size(fb.fb)
Base.haskey(fb::Framebuffer, key::Symbol) = haskey(fb.fb, key)
GLAbstraction.get_attachment(fb::Framebuffer, key::Symbol) = get_attachment(fb.fb, key)
GLAbstraction.get_buffer(fb::Framebuffer, key::Symbol) = get_buffer(fb.fb, key)
GLAbstraction.bind(fb::Framebuffer) = GLAbstraction.bind(fb.fb)
GLAbstraction.attach_colorbuffer(fb::Framebuffer, key, val) = GLAbstraction.attach_colorbuffer(fb.fb, key, val)
function getfallback_attachment(fb::Framebuffer, key::Symbol, fallback_key::Symbol)
    haskey(fb, key) ? get_attachment(fb, key) : get_attachment(fb, fallback_key)
end
function getfallback_buffer(fb::Framebuffer, key::Symbol, fallback_key::Symbol)
    haskey(fb, key) ? get_buffer(fb, key) : get_buffer(fb, fallback_key)
end


Makie.@noconstprop function Framebuffer(context, fb_size::NTuple{2, Int})
    ShaderAbstractions.switch_context!(context)
    require_context(context)

    # Create framebuffer
    fb = GLFramebuffer(fb_size)

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

    # attach buffers
    color_attachment = attach_colorbuffer(fb, :color, color_buffer)
    objectid_attachment = attach_colorbuffer(fb, :objectid, objectid_buffer)
    attach_colorbuffer(fb, :HDR_color, HDR_color_buffer)
    attach_colorbuffer(fb, :OIT_weight, OIT_weight_buffer)
    attach_depthbuffer(fb, :depth, depth_buffer)
    attach_stencilbuffer(fb, :stencil, depth_buffer)

    check_framebuffer()

    return Framebuffer(fb, [color_attachment, objectid_attachment])
end

Base.resize!(fb::Framebuffer, w::Int, h::Int) = resize!(fb.fb, w, h)


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
