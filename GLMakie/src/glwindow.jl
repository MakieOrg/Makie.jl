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

mutable struct GLFramebuffer
    resolution::Observable{NTuple{2, Int}}
    id::GLuint

    buffer_ids::Dict{Symbol, GLuint}
    buffers::Dict{Symbol, Texture}
    render_buffer_ids::Vector{GLuint}
end

# it's guaranteed, that they all have the same size
Base.size(fb::GLFramebuffer) = size(fb.buffers[:color])
Base.haskey(fb::GLFramebuffer, key::Symbol) = haskey(fb.buffers, key)
Base.getindex(fb::GLFramebuffer, key::Symbol) = fb.buffer_ids[key] => fb.buffers[key]

function getfallback(fb::GLFramebuffer, key::Symbol, fallback_key::Symbol)
    return haskey(fb, key) ? fb[key] : fb[fallback_key]
end


function attach_framebuffer(t::Texture{T, 2}, attachment) where {T}
    return glFramebufferTexture2D(GL_FRAMEBUFFER, attachment, GL_TEXTURE_2D, t.id, 0)
end

# attach texture as color attachment with automatic id picking
function attach_colorbuffer!(fb::GLFramebuffer, key::Symbol, t::Texture{T, 2}) where {T}
    if haskey(fb.buffer_ids, key) || haskey(fb.buffers, key)
        error("Key $key already exists.")
    end

    max_color_id = GL_COLOR_ATTACHMENT0
    for id in values(fb.buffer_ids)
        if GL_COLOR_ATTACHMENT0 <= id <= GL_COLOR_ATTACHMENT15 && id > max_color_id
            max_color_id = id
        end
    end
    next_color_id = max_color_id + 0x01
    if next_color_id > GL_COLOR_ATTACHMENT15
        error("Ran out of color buffers.")
    end

    glFramebufferTexture2D(GL_FRAMEBUFFER, next_color_id, GL_TEXTURE_2D, t.id, 0)
    push!(fb.buffer_ids, key => next_color_id)
    push!(fb.buffers, key => t)
    return next_color_id
end

function enum_to_error(s)
    s == GL_FRAMEBUFFER_COMPLETE && return
    s == GL_FRAMEBUFFER_UNDEFINED &&
        error("GL_FRAMEBUFFER_UNDEFINED: The specified framebuffer is the default read or draw framebuffer, but the default framebuffer does not exist.")
    s == GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT &&
        error("GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT: At least one of the framebuffer attachment points is incomplete.")
    s == GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT &&
        error("GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT: The framebuffer does not have at least one image attached to it.")
    s == GL_FRAMEBUFFER_INCOMPLETE_DRAW_BUFFER &&
        error("GL_FRAMEBUFFER_INCOMPLETE_DRAW_BUFFER: The value of GL_FRAMEBUFFER_ATTACHMENT_OBJECT_TYPE is GL_NONE for any color attachment point(s) specified by GL_DRAW_BUFFERi.")
    s == GL_FRAMEBUFFER_INCOMPLETE_READ_BUFFER &&
        error("GL_FRAMEBUFFER_INCOMPLETE_READ_BUFFER: GL_READ_BUFFER is not GL_NONE and the value of GL_FRAMEBUFFER_ATTACHMENT_OBJECT_TYPE is GL_NONE for the color attachment point specified by GL_READ_BUFFER.")
    s == GL_FRAMEBUFFER_UNSUPPORTED &&
        error("GL_FRAMEBUFFER_UNSUPPORTED: The combination of internal formats of the attached images violates a driver implementation-dependent set of restrictions. Check your OpenGL driver!")
    s == GL_FRAMEBUFFER_INCOMPLETE_MULTISAMPLE &&
        error("GL_FRAMEBUFFER_INCOMPLETE_MULTISAMPLE: The value of GL_RENDERBUFFER_SAMPLES is not the same for all attached renderbuffers;
if the value of GL_TEXTURE_SAMPLES is not the same for all attached textures; or, if the attached images consist of a mix of renderbuffers and textures,
    the value of GL_RENDERBUFFER_SAMPLES does not match the value of GL_TEXTURE_SAMPLES.
    GL_FRAMEBUFFER_INCOMPLETE_MULTISAMPLE is also returned if the value of GL_TEXTURE_FIXED_SAMPLE_LOCATIONS is not consistent across all attached textures;
        or, if the attached images include a mix of renderbuffers and textures, the value of GL_TEXTURE_FIXED_SAMPLE_LOCATIONS is not set to GL_TRUE for all attached textures.")
    s == GL_FRAMEBUFFER_INCOMPLETE_LAYER_TARGETS &&
        error("GL_FRAMEBUFFER_INCOMPLETE_LAYER_TARGETS: Any framebuffer attachment is layered, and any populated attachment is not layered, or if all populated color attachments are not from textures of the same target.")
    return error("Unknown framebuffer completion error code: $s")
end

function check_framebuffer()
    status = glCheckFramebufferStatus(GL_FRAMEBUFFER)
    return enum_to_error(status)
end

Makie.@noconstprop function GLFramebuffer(context, fb_size::NTuple{2, Int})
    gl_switch_context!(context)
    require_context(context)

    # Create framebuffer
    frambuffer_id = glGenFramebuffers()
    glBindFramebuffer(GL_FRAMEBUFFER, frambuffer_id)

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

    attach_framebuffer(color_buffer, GL_COLOR_ATTACHMENT0)
    attach_framebuffer(objectid_buffer, GL_COLOR_ATTACHMENT1)
    attach_framebuffer(HDR_color_buffer, GL_COLOR_ATTACHMENT2)
    attach_framebuffer(OIT_weight_buffer, GL_COLOR_ATTACHMENT3)
    attach_framebuffer(depth_buffer, GL_DEPTH_ATTACHMENT)
    attach_framebuffer(depth_buffer, GL_STENCIL_ATTACHMENT)

    check_framebuffer()

    fb_size_node = Observable(fb_size)

    # To allow adding postprocessors in various combinations we need to keep
    # track of the buffer ids that are already in use. We may also want to reuse
    # buffers so we give them names for easy fetching.
    buffer_ids = Dict{Symbol, GLuint}(
        :color => GL_COLOR_ATTACHMENT0,
        :objectid => GL_COLOR_ATTACHMENT1,
        :HDR_color => GL_COLOR_ATTACHMENT2,
        :OIT_weight => GL_COLOR_ATTACHMENT3,
        :depth => GL_DEPTH_ATTACHMENT,
        :stencil => GL_STENCIL_ATTACHMENT,
    )
    buffers = Dict{Symbol, Texture}(
        :color => color_buffer,
        :objectid => objectid_buffer,
        :HDR_color => HDR_color_buffer,
        :OIT_weight => OIT_weight_buffer,
        :depth => depth_buffer,
        :stencil => depth_buffer
    )

    return GLFramebuffer(
        fb_size_node, frambuffer_id,
        buffer_ids, buffers,
        [GL_COLOR_ATTACHMENT0, GL_COLOR_ATTACHMENT1]
    )::GLFramebuffer
end

function destroy!(fb::GLFramebuffer)
    fb.id == 0 && return
    @assert !isempty(fb.buffers) "GLFramebuffer was cleared incorrectly (i.e. not by destroy!())"
    ctx = first(values(fb.buffers)).context
    with_context(ctx) do
        for buff in values(fb.buffers)
            GLAbstraction.free(buff)
        end
        empty!(fb.buffers)
        # Only print error if the context is not alive/active
        id = fb.id
        fb.id = 0
        if GLAbstraction.context_alive(ctx) && id > 0
            glDeleteFramebuffers(1, Ref(id))
        end
    end
    return
end

function Base.resize!(fb::GLFramebuffer, w::Int, h::Int)
    (w > 0 && h > 0 && (w, h) != size(fb)) || return
    isempty(fb.buffers) && return # or error?
    gl_switch_context!(first(values(fb.buffers)).context)
    for (name, buffer) in fb.buffers
        resize_nocopy!(buffer, (w, h))
    end
    fb.resolution[] = (w, h)
    return nothing
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
