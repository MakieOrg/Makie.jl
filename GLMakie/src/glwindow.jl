"""
Selection of random objects on the screen is realized by rendering an
object id + plus an arbitrary index into the framebuffer.
The index can be used for e.g. instanced geometries.
"""
struct SelectionID{T <: Integer} <: FieldVector{2, T}
    id::T
    index::T
end


mutable struct GLFramebuffer
    resolution::Observable{NTuple{2, Int}}
    id::NTuple{2, GLuint}

    buffers::Dict{Symbol, Texture}
    render_buffer_ids::Vector{GLuint}
end

# it's guaranteed, that they all have the same size
Base.size(fb::GLFramebuffer) = size(fb.buffers[:color])


function attach_framebuffer(t::Texture{T, 2}, attachment) where T
    glFramebufferTexture2D(GL_FRAMEBUFFER, attachment, GL_TEXTURE_2D, t.id, 0)
end

function GLFramebuffer(fb_size::NTuple{2, Int})
    # First Framebuffer
    render_framebuffer = glGenFramebuffers()
    glBindFramebuffer(GL_FRAMEBUFFER, render_framebuffer)

    color_buffer = Texture(RGBA{N0f8}, fb_size, minfilter = :nearest, x_repeat = :clamp_to_edge)
    objectid_buffer = Texture(Vec{2, GLuint}, fb_size, minfilter = :nearest, x_repeat = :clamp_to_edge)

    depth_buffer = Texture(
        Ptr{GLAbstraction.DepthStencil_24_8}(C_NULL), fb_size,
        minfilter = :nearest, x_repeat = :clamp_to_edge,
        internalformat = GL_DEPTH24_STENCIL8,
        format = GL_DEPTH_STENCIL
    )

    attach_framebuffer(color_buffer, GL_COLOR_ATTACHMENT0)
    attach_framebuffer(objectid_buffer, GL_COLOR_ATTACHMENT1)
    attach_framebuffer(depth_buffer, GL_DEPTH_ATTACHMENT)
    attach_framebuffer(depth_buffer, GL_STENCIL_ATTACHMENT)

    status = glCheckFramebufferStatus(GL_FRAMEBUFFER)
    @assert status == GL_FRAMEBUFFER_COMPLETE


    # Second Framebuffer
    # postprocessor adds buffers here
    color_luma_framebuffer = glGenFramebuffers()
    glBindFramebuffer(GL_FRAMEBUFFER, color_luma_framebuffer)

    @assert status == GL_FRAMEBUFFER_COMPLETE

    glBindFramebuffer(GL_FRAMEBUFFER, 0)
    fb_size_node = Observable(fb_size)

    buffers = Dict(
        :color => color_buffer,
        :objectid => objectid_buffer,
        :depth => depth_buffer
    )

    return GLFramebuffer(
        fb_size_node,
        (render_framebuffer, color_luma_framebuffer),
        buffers,
        [GL_COLOR_ATTACHMENT0, GL_COLOR_ATTACHMENT1]
    )
end

function Base.resize!(fb::GLFramebuffer, window_size)
    ws = Int.((window_size[1], window_size[2]))
    if ws != size(fb) && all(x-> x > 0, window_size)
        for (name, buffer) in fb.buffers
            resize_nocopy!(buffer, ws)
        end
        fb.resolution[] = ws
    end
    nothing
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

function windowsize(nw::GLFW.Window)
    was_destroyed(nw) && return (0, 0)
    size = GLFW.GetFramebufferSize(nw)
    return (size.width, size.height)
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
