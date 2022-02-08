# Utilities:
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

rcpframe(x) = 1f0 ./ Vec2f(x[1], x[2])

struct PostProcessor{F}
    robjs::Vector{RenderObject}
    render::F
end

function empty_postprocessor(args...; kwargs...)
    PostProcessor(RenderObject[], screen -> nothing)
end


function OIT_postprocessor(framebuffer)
    # Based on https://jcgt.org/published/0002/02/09/, see #1390
    # OIT setup
    shader = LazyShader(
        loadshader("postprocessing/fullscreen.vert"),
        loadshader("postprocessing/OIT_blend.frag")
    )
    data = Dict{Symbol, Any}(
        # :opaque_color => framebuffer[:color][2],
        :sum_color => framebuffer[:HDR_color][2],
        :prod_alpha => framebuffer[:OIT_weight][2],
    )
    pass = RenderObject(
        data, shader,
        () -> begin
            glDepthMask(GL_TRUE)
            glDisable(GL_DEPTH_TEST)
            glDisable(GL_CULL_FACE)
            glEnable(GL_BLEND)
            # shader computes:
            # src.rgb = sum_color / sum_weight * (1 - prod_alpha)
            # src.a = prod_alpha
            # blending: (assumes opaque.a = 1)
            # opaque.rgb = 1 * src.rgb + src.a * opaque.rgb
            # opaque.a   = 0 * src.a   + 1 * opaque.a
            glBlendFuncSeparate(GL_ONE, GL_SRC_ALPHA, GL_ZERO, GL_ONE)
        end,
        nothing
    )
    pass.postrenderfunction = () -> draw_fullscreen(pass.vertexarray.id)

    color_id = framebuffer[:color][1]
    full_render = screen -> begin
        fb = screen.framebuffer
        w, h = size(fb)

        # Blend transparent onto opaque
        glDrawBuffer(color_id)
        glViewport(0, 0, w, h)
        glDisable(GL_STENCIL_TEST)
        GLAbstraction.render(pass)
    end

    PostProcessor(RenderObject[pass], full_render)
end




function ssao_postprocessor(framebuffer)
    # Add missing buffers
    if !haskey(framebuffer, :position)
        glBindFramebuffer(GL_FRAMEBUFFER, framebuffer.id[1])
        position_buffer = Texture(
            Vec3f, size(framebuffer), minfilter = :nearest, x_repeat = :clamp_to_edge
        )
        pos_id = attach_colorbuffer!(framebuffer, :position, position_buffer)
        push!(framebuffer.render_buffer_ids, pos_id)
    end
    if !haskey(framebuffer, :normal)
        if !haskey(framebuffer, :HDR_color)
            glBindFramebuffer(GL_FRAMEBUFFER, framebuffer.id[1])
            normal_occlusion_buffer = Texture(
                Vec4{Float16}, size(framebuffer), minfilter = :nearest, x_repeat = :clamp_to_edge
            )
            normal_occ_id = attach_colorbuffer!(framebuffer, :normal_occlusion, normal_occlusion_buffer)
        else
            normal_occ_id = framebuffer[:HDR_color][1]
        end
        push!(framebuffer.render_buffer_ids, normal_occ_id)
    end

    # SSAO setup
    N_samples = 64
    lerp_min = 0.1f0
    lerp_max = 1.0f0
    kernel = map(1:N_samples) do i
        n = normalize([2.0rand() .- 1.0, 2.0rand() .- 1.0, rand()])
        scale = lerp_min + (lerp_max - lerp_min) * (i / N_samples)^2
        v = Vec3f(scale * rand() * n)
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
        :position_buffer => framebuffer[:position][2],
        :normal_occlusion_buffer => getfallback(framebuffer, :normal_occlusion, :HDR_color)[2],
        :kernel => kernel,
        :noise => Texture(
            [normalize(Vec2f(2.0rand(2) .- 1.0)) for _ in 1:4, __ in 1:4],
            minfilter = :nearest, x_repeat = :repeat
        ),
        :noise_scale => map(s -> Vec2f(s ./ 4.0), framebuffer.resolution),
        :projection => Observable(Mat4f(I)),
        :bias => 0.025f0,
        :radius => 0.5f0
    )
    pass1 = RenderObject(data1, shader1, PostprocessPrerender(), nothing)
    pass1.postrenderfunction = () -> draw_fullscreen(pass1.vertexarray.id)


    # blur occlusion and combine with color
    shader2 = LazyShader(
        loadshader("postprocessing/fullscreen.vert"),
        loadshader("postprocessing/SSAO_blur.frag")
    )
    data2 = Dict{Symbol, Any}(
        :normal_occlusion => getfallback(framebuffer, :normal_occlusion, :HDR_color)[2],
        :color_texture => framebuffer[:color][2],
        :ids => framebuffer[:objectid][2],
        :inv_texel_size => lift(rcpframe, framebuffer.resolution),
        :blur_range => Int32(2)
    )
    pass2 = RenderObject(data2, shader2, PostprocessPrerender(), nothing)
    pass2.postrenderfunction = () -> draw_fullscreen(pass2.vertexarray.id)
    color_id = framebuffer[:color][1]

    full_render = screen -> begin
        fb = screen.framebuffer
        w, h = size(fb)

        # Setup rendering
        # SSAO - calculate occlusion
        glDrawBuffer(normal_occ_id)  # occlusion buffer
        glViewport(0, 0, w, h)
        glDisable(GL_STENCIL_TEST)
        glEnable(GL_SCISSOR_TEST)

        for (screenid, scene) in screen.screens
            # Select the area of one leaf scene
            # This should be per scene because projection may vary between
            # scenes. It should be a leaf scene to avoid repeatedly shading
            # the same region (though this is not guaranteed...)
            isempty(scene.children) || continue
            a = pixelarea(scene)[]
            glScissor(minimum(a)..., widths(a)...)
            # update uniforms
            data1[:projection] = scene.camera.projection[]
            data1[:bias] = scene.ssao.bias[]
            data1[:radius] = scene.ssao.radius[]
            GLAbstraction.render(pass1)
        end

        # SSAO - blur occlusion and apply to color
        glDrawBuffer(color_id)  # color buffer
        for (screenid, scene) in screen.screens
            # Select the area of one leaf scene
            isempty(scene.children) || continue
            a = pixelarea(scene)[]
            glScissor(minimum(a)..., widths(a)...)
            # update uniforms
            data2[:blur_range] = scene.ssao.blur
            GLAbstraction.render(pass2)
        end
        glDisable(GL_SCISSOR_TEST)
    end

    PostProcessor(RenderObject[pass1, pass2], full_render)
end

"""
    fxaa_postprocessor(framebuffer)

Returns a PostProcessor that handles fxaa.
"""
function fxaa_postprocessor(framebuffer)
    # Add missing buffers
    if !haskey(framebuffer, :color_luma)
        if !haskey(framebuffer, :HDR_color)
            glBindFramebuffer(GL_FRAMEBUFFER, framebuffer.id[1])
            color_luma_buffer = Texture(
                RGBA{N0f8}, size(framebuffer), minfilter=:linear, x_repeat=:clamp_to_edge
            )
            luma_id = attach_colorbuffer!(framebuffer, :color_luma, color_luma_buffer)
        else
            luma_id = framebuffer[:HDR_color][1]
        end
    end

    # calculate luma for FXAA
    shader1 = LazyShader(
        loadshader("postprocessing/fullscreen.vert"),
        loadshader("postprocessing/postprocess.frag")
    )
    data1 = Dict{Symbol, Any}(
        :color_texture => framebuffer[:color][2],
        :object_ids => framebuffer[:objectid][2]
    )
    pass1 = RenderObject(data1, shader1, PostprocessPrerender(), nothing)
    pass1.postrenderfunction = () -> draw_fullscreen(pass1.vertexarray.id)

    # perform FXAA
    shader2 = LazyShader(
        loadshader("postprocessing/fullscreen.vert"),
        loadshader("postprocessing/fxaa.frag")
    )
    data2 = Dict{Symbol, Any}(
        :color_texture => getfallback(framebuffer, :color_luma, :HDR_color)[2],
        :RCPFrame => lift(rcpframe, framebuffer.resolution),
    )
    pass2 = RenderObject(data2, shader2, PostprocessPrerender(), nothing)
    pass2.postrenderfunction = () -> draw_fullscreen(pass2.vertexarray.id)

    color_id = framebuffer[:color][1]
    full_render = screen -> begin
        fb = screen.framebuffer
        w, h = size(fb)

        # FXAA - calculate LUMA
        glDrawBuffer(luma_id)
        glViewport(0, 0, w, h)
        # necessary with negative SSAO bias...
        glClearColor(1, 1, 1, 1)
        glClear(GL_COLOR_BUFFER_BIT)
        GLAbstraction.render(pass1)

        # FXAA - perform anti-aliasing
        glDrawBuffer(color_id)  # color buffer
        GLAbstraction.render(pass2)
    end

    PostProcessor(RenderObject[pass1, pass2], full_render)
end


"""
    to_screen_postprocessor(framebuffer)

Sets up a Postprocessor which copies the color buffer to the screen. Used as a
final step for displaying the screen.
"""
function to_screen_postprocessor(framebuffer)
    # draw color buffer
    shader = LazyShader(
        loadshader("postprocessing/fullscreen.vert"),
        loadshader("postprocessing/copy.frag")
    )
    data = Dict{Symbol, Any}(
        :color_texture => framebuffer[:color][2]
    )
    pass = RenderObject(data, shader, PostprocessPrerender(), nothing)
    pass.postrenderfunction = () -> draw_fullscreen(pass.vertexarray.id)

    full_render = screen -> begin
        fb = screen.framebuffer
        w, h = size(fb)

        # transfer everything to the screen
        glBindFramebuffer(GL_FRAMEBUFFER, 0)
        glViewport(0, 0, w, h)
        glClear(GL_COLOR_BUFFER_BIT)
        GLAbstraction.render(pass) # copy postprocess
    end

    PostProcessor(RenderObject[pass], full_render)
end
