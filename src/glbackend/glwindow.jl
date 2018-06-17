import .GLAbstraction: bind

"""
Selection of random objects on the screen is realized by rendering an
object id + plus an arbitrary index into the framebuffer.
The index can be used for e.g. instanced geometries.
"""
struct SelectionID{T <: Integer} <: FieldVector{2, T}
    id::T
    index::T
end


function draw_fullscreen(vao_id)
    glBindVertexArray(vao_id)
    glDrawArrays(GL_TRIANGLES, 0, 3)
    glBindVertexArray(0)
end
struct PostprocessPrerender
end
# function (sp::PostprocessPrerender)()
#     glDepthMask(GL_TRUE)
#     glDisable(GL_DEPTH_TEST)
#     glDisable(GL_BLEND)
#     glDisable(GL_STENCIL_TEST)
#     glStencilMask(0xff)
#     glDisable(GL_CULL_FACE)
#     nothing
# end

const PostProcessROBJ = RenderObject{PostprocessPrerender}

loadshader(name) = joinpath(@__DIR__, "GLVisualize", "assets", "shader", name)


rcpframe(x) = 1f0./Vec2f0(x[1], x[2])

"""
Creates a postprocessing render object.
This will transfer the pixels from the color texture of the Framebuffer
to the screen and while at it, it can do some postprocessing (not doing it right now):
E.g fxaa anti aliasing, color correction etc.
"""
# function postprocess(color, color_luma, framebuffer_size)
#     shader1 = LazyShader(
#         loadshader("fullscreen.vert"),
#         loadshader("postprocess.frag")
#     )
#     data1 = Dict{Symbol, Any}(
#         :color_texture => color
#     )
#     pass1 = RenderObject(data1, shader1, PostprocessPrerender(), nothing)
#     pass1.postrenderfunction = () -> draw_fullscreen(pass1.vertexarray.id)
#     shader2 = LazyShader(
#         loadshader("fullscreen.vert"),
#         loadshader("fxaa.frag")
#     )
#     data2 = Dict{Symbol, Any}(
#         :color_texture => color_luma,
#         :RCPFrame => rcpframe(framebuffer_size)
#     )
#     pass2 = RenderObject(data2, shader2, PostprocessPrerender(), nothing)
#
#     pass2.postrenderfunction = () -> draw_fullscreen(pass2.vertexarray.id)
#
#     shader3 = LazyShader(
#         loadshader("fullscreen.vert"),
#         loadshader("copy.frag")
#     )
#
#     data3 = Dict{Symbol, Any}(
#         :color_texture => color
#     )
#
#     pass3 = RenderObject(data3, shader3, PostprocessPrerender(), nothing)
#
#     pass3.postrenderfunction = () -> draw_fullscreen(pass3.vertexarray.id)
#
#
#     (pass1, pass2, pass3)
# end

# function attach_framebuffer(t::Texture{T, 2}, attachment) where T
#     glFramebufferTexture2D(GL_FRAMEBUFFER, attachment, GL_TEXTURE_2D, t.id, 0)
# end

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
    sfactor = is_apple() ? 2.0 : 1.0
    dpi = Vec(videomode.width * 25.4, videomode.height * 25.4) * sfactor ./ Vec{2, Float64}(physicalsize)
    videomode_supported = GLFW.GetVideoModes(monitor)

    MonitorProperties(name, isprimary, position, physicalsize, videomode, videomode_supported, dpi, monitor)
end

mutable struct GLContext <: AbstractContext
    window::GLFW.Window
    framebuffer::FrameBuffer
    visible::Bool
    cache::Dict
end
GLContext(window, framebuffer, visible) = GLContext(window, framebuffer, visible, Dict())


"""
Sleep is pretty imprecise. E.g. anything under `0.001s` is not guaranteed to wake
up before `0.001s`. So this timer is pessimistic in the way, that it will never
sleep more than `time`.
"""
@inline function sleep_pessimistic(sleep_time)
    st = convert(Float64,sleep_time) - 0.002
    start_time = time()
    while (time() - start_time) < st
        sleep(0.001) # sleep for the minimal amount of time
    end
end
function reactive_run_till_now()
    max_yield = Base.n_avail(Reactive._messages) * 2
    for i=1:max_yield
        if !isready(Reactive._messages)
            break
        end
        yield()
    end
end
function Base.isopen(window::GLFW.Window)
    was_destroyed(window) && return false
    window.handle == C_NULL && return false
    !GLFW.WindowShouldClose(window)
end
