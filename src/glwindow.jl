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
    return
end

struct PostprocessPrerender end

function (sp::PostprocessPrerender)()
    glDepthMask(GL_TRUE)
    glDisable(GL_DEPTH_TEST)
    glDisable(GL_BLEND)
    glDisable(GL_CULL_FACE)
    return
end

const PostProcessROBJ = RenderObject{PostprocessPrerender}

mutable struct GLFramebuffer
    resolution::Node{NTuple{2, Int}}
    id::NTuple{2, GLuint}

    color::Texture{RGBA{N0f8}, 2}
    objectid::Texture{Vec{2, GLushort}, 2}
    depth::Texture{GLAbstraction.DepthStencil_24_8, 2}
    position::Texture{Vec4f0, 2}
    normal::Texture{Vec3f0, 2}
    ssao_noise::Texture{Vec2f0, 2}
    occlusion::Texture{Float32, 2}

    color_luma::Texture{RGBA{N0f8}, 2}

    postprocess::NTuple{5, PostProcessROBJ}
end

Base.size(fb::GLFramebuffer) = size(fb.color) # it's guaranteed, that they all have the same size

loadshader(name) = joinpath(@__DIR__, "GLVisualize", "assets", "shader", name)

rcpframe(x) = 1f0 ./ Vec2f0(x[1], x[2])

"""
Creates a postprocessing render object.
This will transfer the pixels from the color texture of the Framebuffer
to the screen and while at it, it can do some postprocessing (not doing it right now):
E.g fxaa anti aliasing, color correction etc.
"""
function postprocess(
        color, position, normal, ssao_noise, occlusion, objectid, color_luma,
        framebuffer_size
    )

    # SSAO setup
    N_samples = 64
    lerp_min = 0.1f0
    lerp_max = 1.0f0
    kernel = map(1:N_samples) do i
        n = normalize([2.0rand() .- 1.0, 2.0rand() .- 1.0, rand()])
        scale = lerp_min + (lerp_max - lerp_min) * (i / N_samples)^2
        v = Vec3f0(scale * rand() * n)
    end

    # compute occlusion
    shader1 = LazyShader(
        loadshader("postprocessing/fullscreen.vert"),
        loadshader("postprocessing/SSAO.frag"),
        view = Dict(
            "N_samples" => "$N_samples"
        )
    )
    data1 = Dict{Symbol, Any}(
        :position_buffer => position,
        :normal_buffer => normal,
        :kernel => kernel,
        :noise => ssao_noise,
        :noise_scale => map(s -> Vec2f0(s ./ 4.0), framebuffer_size),
        :projection => Node(Mat4f0(I)),
        :bias => Node(0.025f0),
        :radius => Node(0.5f0)
    )
    pass1 = RenderObject(data1, shader1, PostprocessPrerender(), nothing)
    pass1.postrenderfunction = () -> draw_fullscreen(pass1.vertexarray.id)


    # blur occlusion and combine with color
    shader2 = LazyShader(
        loadshader("postprocessing/fullscreen.vert"),
        loadshader("postprocessing/SSAO_blur.frag")
    )
    data2 = Dict{Symbol, Any}(
        :occlusion => occlusion,
        :color_texture => color,
        :ids => objectid,
        :inv_texel_size => map(t -> Vec2f0(1f0/t[1], 1f0/t[2]), framebuffer_size),
        :blur_range => Node(Int32(2))
    )
    pass2 = RenderObject(data2, shader2, PostprocessPrerender(), nothing)
    pass2.postrenderfunction = () -> draw_fullscreen(pass2.vertexarray.id)


    # calculate luma for FXAA
    shader3 = LazyShader(
        loadshader("postprocessing/fullscreen.vert"),
        loadshader("postprocessing/postprocess.frag")
    )
    data3 = Dict{Symbol, Any}(
        :color_texture => color
    )
    pass3 = RenderObject(data3, shader3, PostprocessPrerender(), nothing)
    pass3.postrenderfunction = () -> draw_fullscreen(pass3.vertexarray.id)


    # perform FXAA
    shader4 = LazyShader(
        loadshader("postprocessing/fullscreen.vert"),
        loadshader("postprocessing/fxaa.frag")
    )
    data4 = Dict{Symbol, Any}(
        :color_texture => color_luma,
        :RCPFrame => lift(rcpframe, framebuffer_size),
    )
    pass4 = RenderObject(data4, shader4, PostprocessPrerender(), nothing)
    pass4.postrenderfunction = () -> draw_fullscreen(pass4.vertexarray.id)


    # draw color buffer
    shader5 = LazyShader(
        loadshader("postprocessing/fullscreen.vert"),
        loadshader("postprocessing/copy.frag")
    )
    data5 = Dict{Symbol, Any}(
        :color_texture => color
    )
    pass5 = RenderObject(data5, shader5, PostprocessPrerender(), nothing)
    pass5.postrenderfunction = () -> draw_fullscreen(pass5.vertexarray.id)


    return (pass1, pass2, pass3, pass4, pass5)
end

function attach_framebuffer(t::Texture{T, 2}, attachment) where T
    glFramebufferTexture2D(GL_FRAMEBUFFER, attachment, GL_TEXTURE_2D, t.id, 0)
end

function GLFramebuffer(fb_size::NTuple{2, Int})
    # First Framebuffer
    render_framebuffer = glGenFramebuffers()
    glBindFramebuffer(GL_FRAMEBUFFER, render_framebuffer)

    color_buffer = Texture(RGBA{N0f8}, fb_size, minfilter = :nearest, x_repeat = :clamp_to_edge)
    objectid_buffer = Texture(Vec{2, GLushort}, fb_size, minfilter = :nearest, x_repeat = :clamp_to_edge)
    position_buffer = Texture(Vec4f0, fb_size, minfilter = :nearest, x_repeat = :clamp_to_edge)
    normal_buffer = Texture(Vec4f0, fb_size, minfilter = :nearest, x_repeat = :clamp_to_edge)
    occlusion = Texture(Float32, fb_size, minfilter=:nearest, x_repeat=:clamp_to_edge)

    depth_buffer = Texture(
        Ptr{GLAbstraction.DepthStencil_24_8}(C_NULL), fb_size,
        minfilter = :nearest, x_repeat = :clamp_to_edge,
        internalformat = GL_DEPTH24_STENCIL8,
        format = GL_DEPTH_STENCIL
    )

    ssao_noise = Texture(
        [normalize(Vec2f0(2.0rand(2) .- 1.0)) for _ in 1:4, __ in 1:4],
        minfilter = :nearest, x_repeat = :repeat
    )

    attach_framebuffer(color_buffer, GL_COLOR_ATTACHMENT0)
    attach_framebuffer(objectid_buffer, GL_COLOR_ATTACHMENT1)
    attach_framebuffer(position_buffer, GL_COLOR_ATTACHMENT2)
    attach_framebuffer(normal_buffer, GL_COLOR_ATTACHMENT3)
    attach_framebuffer(occlusion, GL_COLOR_ATTACHMENT4)
    attach_framebuffer(depth_buffer, GL_DEPTH_ATTACHMENT)
    attach_framebuffer(depth_buffer, GL_STENCIL_ATTACHMENT)

    status = glCheckFramebufferStatus(GL_FRAMEBUFFER)
    @assert status == GL_FRAMEBUFFER_COMPLETE


    # Second Framebuffer
    color_luma_framebuffer = glGenFramebuffers()
    glBindFramebuffer(GL_FRAMEBUFFER, color_luma_framebuffer)

    color_luma = Texture(RGBA{N0f8}, fb_size, minfilter=:linear, x_repeat=:clamp_to_edge)
    attach_framebuffer(color_luma, GL_COLOR_ATTACHMENT0)

    @assert status == GL_FRAMEBUFFER_COMPLETE

    glBindFramebuffer(GL_FRAMEBUFFER, 0)
    fb_size_node = Node(fb_size)

    p = postprocess(
        color_buffer, position_buffer, normal_buffer, ssao_noise, occlusion,
        objectid_buffer, color_luma,
        fb_size_node
    )

    return GLFramebuffer(
        fb_size_node,
        (render_framebuffer, color_luma_framebuffer),
        color_buffer, objectid_buffer, depth_buffer,
        position_buffer, normal_buffer, ssao_noise, occlusion,
        color_luma,
        p
    )
end

function Base.resize!(fb::GLFramebuffer, window_size)
    ws = Int.((window_size[1], window_size[2]))
    if ws != size(fb) && all(x-> x > 0, window_size)
        resize_nocopy!(fb.color, ws)
        resize_nocopy!(fb.objectid, ws)
        resize_nocopy!(fb.depth, ws)
        resize_nocopy!(fb.position, ws)
        resize_nocopy!(fb.normal, ws)
        resize_nocopy!(fb.occlusion, ws)
        resize_nocopy!(fb.color_luma, ws)
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
        GLFW.DestroyWindow(nw)
        GLFW.PollEvents()
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
