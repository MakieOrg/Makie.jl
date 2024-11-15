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
    constructor::Any
end

function empty_postprocessor(args...; kwargs...)
    PostProcessor(RenderObject[], (args...) -> nothing, empty_postprocessor)
end


function OIT_postprocessor(framebuffer, shader_cache)
    @debug "Creating OIT postprocessor"

    # Based on https://jcgt.org/published/0002/02/09/, see #1390
    # OIT setup
    shader = LazyShader(
        shader_cache,
        loadshader("postprocessing/fullscreen.vert"),
        loadshader("postprocessing/OIT_blend.frag")
    )
    data = Dict{Symbol, Any}(
        # :opaque_color => framebuffer[:color][2],
        :sum_color => framebuffer[:HDR_color][2],
        :transmittance => framebuffer[:OIT_weight][2],
    )
    pass = RenderObject(
        data, shader,
        () -> begin
            glDepthMask(GL_TRUE)
            glDisable(GL_DEPTH_TEST)
            glDisable(GL_CULL_FACE)
            glEnable(GL_BLEND)
            # prepare:
            #   sum_color = 0
            #   transmittance = 1
            # main render + blend: (w/o clamping)
            #   weight = alpha * (factor) * (1 - z)^3
            #   sum_color  += (weight * rgb, weight)
            #   transmittance *= (1 - alpha)
            # postprocessor shader:
            #   out = (sum_color.rgb / sum_color.w * (1 - transmittance), tranmittance)
            # blending (here)
            #   src = out = (pre-multiplied color, transmittance)
            #   dst = (pre-multiplied color, transmittance) (from non-OIT draw)
            #   src.rgb + src.a * dst.rgb, src.a * dst.a
            glBlendFuncSeparate(GL_ONE, GL_SRC_ALPHA, GL_ZERO, GL_SRC_ALPHA)
        end,
        nothing
    )
    pass.postrenderfunction = () -> draw_fullscreen(pass.vertexarray.id)

    color_id = framebuffer[:color][1]
    full_render = screen -> begin
        # Blend transparent onto opaque
        wh = size(screen.framebuffer)
        glViewport(0, 0, wh[1], wh[2])
        glDrawBuffer(color_id)
        GLAbstraction.render(pass)
    end

    PostProcessor(RenderObject[pass], full_render, OIT_postprocessor)
end




function ssao_postprocessor(framebuffer, shader_cache)
    @debug "Creating SSAO postprocessor"

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
        shader_cache,
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
        shader_cache,
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

    full_render = (screen, ssao, projection) -> begin
        wh = size(screen.framebuffer)
        glViewport(0, 0, wh[1], wh[2])

        glDrawBuffer(normal_occ_id)  # occlusion buffer
        data1[:projection] = projection
        data1[:bias] = ssao.bias[]
        data1[:radius] = ssao.radius[]
        GLAbstraction.render(pass1)

        glDrawBuffer(color_id)  # color buffer
        data2[:blur_range] = ssao.blur[]
        GLAbstraction.render(pass2)
    end

    PostProcessor(RenderObject[pass1, pass2], full_render, ssao_postprocessor)
end

"""
    fxaa_postprocessor(framebuffer, shader_cache)

Returns a PostProcessor that handles fxaa.
"""
function fxaa_postprocessor(framebuffer, shader_cache)
    @debug "Creating FXAA postprocessor"

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
        shader_cache,
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
        shader_cache,
        loadshader("postprocessing/fullscreen.vert"),
        loadshader("postprocessing/fxaa.frag")
    )
    data2 = Dict{Symbol, Any}(
        :color_texture => getfallback(framebuffer, :color_luma, :HDR_color)[2],
        :RCPFrame => lift(rcpframe, framebuffer.resolution),
    )
    pass2 = RenderObject(data2, shader2, () -> begin
        glDepthMask(GL_TRUE)
        glDisable(GL_DEPTH_TEST)
        glDisable(GL_CULL_FACE)
        glEnable(GL_BLEND)
        # keep transmittance from dst
        glBlendFuncSeparate(GL_ONE, GL_ZERO, GL_ZERO, GL_ONE)
    end, nothing)
    pass2.postrenderfunction = () -> draw_fullscreen(pass2.vertexarray.id)

    color_id = framebuffer[:color][1]
    full_render = screen -> begin
        # TODO: make scissor explicit?
        wh = size(screen.framebuffer)
        glViewport(0, 0, wh[1], wh[2])

        # FXAA - calculate LUMA
        glDrawBuffer(luma_id)
        # necessary with negative SSAO bias...
        glClearColor(1, 1, 1, 1)
        glClear(GL_COLOR_BUFFER_BIT)
        GLAbstraction.render(pass1)

        # FXAA - perform anti-aliasing
        glDrawBuffer(color_id)  # color buffer
        GLAbstraction.render(pass2)
    end

    PostProcessor(RenderObject[pass1, pass2], full_render, fxaa_postprocessor)
end


"""
    compose_postprocessor(framebuffer, shader_cache, default_id = nothing)

Creates a Postprocessor for merging the finished render of a scene with the
composition buffer which will eventually include all scenes.
"""
function compose_postprocessor(framebuffer, shader_cache)
    @debug "Creating compose postprocessor"

    # draw color buffer
    shader = LazyShader(
        shader_cache,
        loadshader("postprocessing/fullscreen.vert"),
        loadshader("postprocessing/copy.frag")
    )
    data = Dict{Symbol, Any}(
        :color_texture => framebuffer[:color][2]
    )
    pass = RenderObject(data, shader, () -> begin
        glDepthMask(GL_TRUE)
        glDisable(GL_DEPTH_TEST)
        glDisable(GL_CULL_FACE)
        glEnable(GL_BLEND)
        # src format = (a1 * rgb1, 1-a1)
        # dst format = (a2 * rgb2, 1-a2)
        # blended = (a1 * rgb1 + (1-a1) * a2 * rgb2, (1-a1) * (1-a2))
        glBlendFuncSeparate(GL_ONE, GL_SRC_ALPHA, GL_ZERO, GL_SRC_ALPHA)
    end, nothing)
    pass.postrenderfunction = () -> draw_fullscreen(pass.vertexarray.id)

    composition_buffer_id = framebuffer[:composition][1]
    full_render = (screen, x, y, w, h) -> begin
        glDrawBuffer(composition_buffer_id)
        wh = size(screen.framebuffer)
        glViewport(0, 0, wh[1], wh[2]) # :color buffer is ful screen
        glScissor(x, y, w, h) # but we only care about the active section
        GLAbstraction.render(pass) # copy postprocess
    end

    PostProcessor(RenderObject[pass], full_render, to_screen_postprocessor)
end

"""
    to_screen_postprocessor(framebuffer, shader_cache, default_id = nothing)

Creates a Postprocessor which maps the composed render of all scenes to the
screen. Used as a final step for displaying the screen. The argument
`screen_fb_id` can be used to pass in a reference to the framebuffer ID of the
screen. If `nothing` is used (the default), 0 is used.
"""
function to_screen_postprocessor(framebuffer, shader_cache, screen_fb_id = nothing)
    @debug "Creating to screen postprocessor"

    # draw color buffer
    shader = LazyShader(
        shader_cache,
        loadshader("postprocessing/fullscreen.vert"),
        loadshader("postprocessing/copy.frag")
    )
    data = Dict{Symbol, Any}(
        :color_texture => framebuffer[:composition][2]
    )
    pass = RenderObject(data, shader, () -> begin
        glDepthMask(GL_TRUE)
        glDisable(GL_DEPTH_TEST)
        glDisable(GL_CULL_FACE)
        glEnable(GL_BLEND)
        # incoming texture is in format src = (a * c, 1-a)
        # destination is in format      dst = (bg, 1)
        # blends to (src.rgb + src.a * dst.rgb, 1 * dst.a) = (a * c + (1-a) * bg, 1)
        glBlendFuncSeparate(GL_ONE, GL_SRC_ALPHA, GL_ZERO, GL_ONE)
    end, nothing)
    pass.postrenderfunction = () -> draw_fullscreen(pass.vertexarray.id)

    full_render = (screen) -> begin
        # TODO: Is this an observable? Can this be static?
        # GLFW uses 0, Gtk uses a value that we have to probe at the beginning of rendering
        OUTPUT_FRAMEBUFFER_ID = isnothing(screen_fb_id) ? 0 : screen_fb_id[]

        # Set target
        glBindFramebuffer(GL_FRAMEBUFFER, OUTPUT_FRAMEBUFFER_ID)
        glViewport(0, 0, framebuffer_size(screen)...)
        # glScissor(0, 0, wh[1], wh[2])

        # clear target
        # TODO: Could be skipped if glscenes[1] clears to opaque (maybe use dedicated shader?)
        # TODO: Should this be cleared if we don't own the target?
        glClearColor(1,1,1,1)
        glClear(GL_COLOR_BUFFER_BIT)

        # transfer everything to the screen
        GLAbstraction.render(pass) # copy postprocess
    end

    PostProcessor(RenderObject[pass], full_render, to_screen_postprocessor)
end

function destroy!(pp::PostProcessor)
    @debug "Destroying postprocessor"
    while !isempty(pp.robjs)
        destroy!(pop!(pp.robjs))
    end
    return
end
