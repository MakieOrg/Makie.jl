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


"""
    FramebufferManager(context, size)

Creates a `FramebufferManager` which is responsible for producing framebuffers
for the render pipeline using `generate_framebuffer()`. For this it manages
framebuffer attachments.

All the framebuffers are kept track of in the manager to allow resizing and
deletion from a central location. The output color, objectid and depth buffers
are collected in a separate framebuffer in the manager to simplify access for
picking and `colorbuffer()`.
"""
mutable struct FramebufferManager
    context::GLAbstraction.GLContext
    size::NTuple{2, Int}

    buffers::Vector{Texture}
    # TODO: Consider removing this and handling resize and deletion in framebuffer.
    # This might be useful to allow half-resolution rendering for example.
    children::Vector{GLFramebuffer}
end

Makie.@noconstprop function FramebufferManager(context, fb_size::NTuple{2, Int})
    return FramebufferManager(context, fb_size, Texture[], GLFramebuffer[])
end

Base.size(manager::FramebufferManager) = manager.size
Base.isempty(manager::FramebufferManager) = isempty(manager.children)
GLAbstraction.get_buffer(fb::FramebufferManager, idx::Int) = fb.buffers[idx]
GLAbstraction.bind(fb::FramebufferManager) = GLAbstraction.bind(fb.children[end])
display_framebuffer(fb::FramebufferManager) = last(fb.children)

function Base.resize!(manager::FramebufferManager, w::Int, h::Int)
    gl_switch_context!(manager.context)
    manager.size = (w, h)
    return
end

# destroys everything
function destroy!(manager::FramebufferManager)
    ctx = manager.context
    ShaderAbstractions.switch_context!(ctx)
    # avoid try .. catch at call site, and allow cleanup to run
    GLAbstraction.require_context_no_error(ctx)

    GLAbstraction.free.(manager.buffers)
    GLAbstraction.free.(manager.children)
    empty!(manager.buffers)
    empty!(manager.children)
    return
end

function Base.push!(manager::FramebufferManager, tex::Texture)
    push!(manager.buffers, tex)
    return manager
end

"""
    generate_framebuffer(manager, name_to_index)

Creates a `GLFramebuffer` using attachments present in the manager. The
attachments are referenced to by index and named with a Symbol via
`name_to_index = [name1 => index1, ...]`.

This function is mainly meant to be used with the inputs or outputs of a
`stage::LoweredStage`. For example: `generate_buffers(manager, stage.inputs)`.
"""
Makie.@noconstprop function generate_framebuffer(manager::FramebufferManager, name2idx::Vector{Pair{Symbol, Int64}})
    filter!(fb -> fb.id != 0, manager.children) # cleanup?

    fb = GLFramebuffer(manager.context, size(manager))

    for (name, idx) in name2idx
        haskey(fb, name) && error("Can't add duplicate buffer $name")

        buffer = manager.buffers[idx]

        if buffer.format == GL_DEPTH_STENCIL
            attach_depthstencilbuffer(fb, name, buffer)
        elseif buffer.format == GL_DEPTH_COMPONENT
            attach_depthbuffer(fb, name, buffer)
        elseif buffer.format == GL_STENCIL
            attach_stencilbuffer(fb, name, buffer)
        else
            attach_colorbuffer(fb, name, buffer)
        end
    end

    push!(manager.children, fb)

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
