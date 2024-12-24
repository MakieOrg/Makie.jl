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

abstract type AbstractRenderStep end
prepare_step(screen, glscene, ::AbstractRenderStep) = nothing
run_step(screen, glscene, ::AbstractRenderStep) = nothing

struct RenderPipeline
    steps::Vector{AbstractRenderStep}
end

function render_frame(screen, glscene, pipeline::RenderPipeline)
    for step in pipeline.steps
        prepare_step(screen, glscene, step)
    end
    for step in pipeline.steps
        run_step(screen, glscene, step)
    end
    return
end

# TODO: temporary, we should get to the point where this is not needed
struct EmptyRenderStep <: AbstractRenderStep end

# Vaguely leaning on Vulkan Terminology
struct RenderPass{Name} <: AbstractRenderStep
    framebuffer::GLFramebuffer
    passes::Vector{RenderObject}
    renames::Dict{Symbol, Symbol} # TODO: temporary until GLFramebuffer not shared
end
function RenderPass{Name}(framebuffer::GLFramebuffer, passes::Vector{RenderObject}) where {Name}
    return RenderPass{Name}(framebuffer, passes, Dict{Symbol, Symbol}())
end

function RenderPass{:OIT}(screen)
    @debug "Creating OIT postprocessor"

    framebuffer = screen.framebuffer

    # Based on https://jcgt.org/published/0002/02/09/, see #1390
    # OIT setup
    shader = LazyShader(
        screen.shader_cache,
        loadshader("postprocessing/fullscreen.vert"),
        loadshader("postprocessing/OIT_blend.frag")
    )
    data = Dict{Symbol, Any}(
        :sum_color  => get_buffer(framebuffer, :HDR_color),
        :prod_alpha => get_buffer(framebuffer, :OIT_weight),
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
        nothing, shader_cache.context
    )
    pass.postrenderfunction = () -> draw_fullscreen(pass.vertexarray.id)

    return RenderPass{:OIT}(framebuffer.fb, RenderObject[pass])
end

function run_step(screen, glscene, step::RenderPass{:OIT})
    # Blend transparent onto opaque
    wh = size(screen.framebuffer)
    glViewport(0, 0, wh[1], wh[2])
    glDrawBuffer(get_attachment(step.framebuffer, :color))
    GLAbstraction.render(step.passes[1])
    return
end


function RenderPass{:SSAO}(screen)
    @debug "Creating SSAO postprocessor"
    framebuffer = screen.framebuffer
    renames = Dict{Symbol, Symbol}()


function ssao_postprocessor(framebuffer, shader_cache)
    ShaderAbstractions.switch_context!(shader_cache.context)
    require_context(shader_cache.context)

    # Add missing buffers
    if !haskey(framebuffer, :position)
        # GLAbstraction.bind(framebuffer)
        position_buffer = Texture(
            shader_cache.context, Vec3f, size(framebuffer), minfilter = :nearest, x_repeat = :clamp_to_edge
        )
        pos_id = attach_colorbuffer(framebuffer, :position, position_buffer)
        push!(framebuffer.render_buffer_ids, pos_id)
    end
    if !haskey(framebuffer, :normal)
        if !haskey(framebuffer, :HDR_color)
            # GLAbstraction.bind(framebuffer)
            normal_occlusion_buffer = Texture(
                shader_cache.context, Vec4{Float16}, size(framebuffer), minfilter = :nearest, x_repeat = :clamp_to_edge
            )
            normal_occ_id = attach_colorbuffer(framebuffer, :normal_occlusion, normal_occlusion_buffer)
            renames[:normal_occlusion] = :normal_occlusion
        else
            normal_occ_id = get_attachment(framebuffer, :HDR_color)
            renames[:normal_occlusion] = :HDR_color
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
        screen.shader_cache,
        loadshader("postprocessing/fullscreen.vert"),
        loadshader("postprocessing/SSAO.frag"),
        view = Dict(
            "N_samples" => "$N_samples"
        )
    )
    data1 = Dict{Symbol, Any}(
        :position_buffer => get_buffer(framebuffer, :position),
        :normal_occlusion_buffer => getfallback_buffer(framebuffer, :normal_occlusion, :HDR_color),
        :kernel => kernel,
        :noise => Texture(
            shader_cache.context, [normalize(Vec2f(2.0rand(2) .- 1.0)) for _ in 1:4, __ in 1:4],
            minfilter = :nearest, x_repeat = :repeat
        ),
        :noise_scale => Vec2f(0.25f0 .* size(framebuffer)),
        :projection => Observable(Mat4f(I)),
        :bias => 0.025f0,
        :radius => 0.5f0
    )
    pass1 = RenderObject(data1, shader1, PostprocessPrerender(), nothing, shader_cache.context)
    pass1.postrenderfunction = () -> draw_fullscreen(pass1.vertexarray.id)


    # blur occlusion and combine with color
    shader2 = LazyShader(
        screen.shader_cache,
        loadshader("postprocessing/fullscreen.vert"),
        loadshader("postprocessing/SSAO_blur.frag")
    )
    data2 = Dict{Symbol, Any}(
        :normal_occlusion => getfallback_buffer(framebuffer, :normal_occlusion, :HDR_color),
        :color_texture => get_output(framebuffer, :color),
        :ids => get_buffer(framebuffer, :objectid),
        :inv_texel_size => rcpframe(size(framebuffer)),
        :blur_range => Int32(2)
    )
    pass2 = RenderObject(data2, shader2, PostprocessPrerender(), nothing, shader_cache.context)
    pass2.postrenderfunction = () -> draw_fullscreen(pass2.vertexarray.id)

    return RenderPass{:SSAO}(framebuffer.fb, [pass1, pass2], renames)
end

function run_step(screen, glscene, step::RenderPass{:SSAO})
    wh = size(screen.framebuffer)

    glViewport(0, 0, wh[1], wh[2])
    glDrawBuffer(get_attachment(step.framebuffer, step.renames[:normal_occ_id]))  # occlusion buffer
    glEnable(GL_SCISSOR_TEST)
    ppu = (x) -> round.(Int, screen.px_per_unit[] .* x)

    data1 = step.passes[1].uniforms
    for (screenid, scene) in screen.screens
        # Select the area of one leaf scene
        # This should be per scene because projection may vary between
        # scenes. It should be a leaf scene to avoid repeatedly shading
        # the same region (though this is not guaranteed...)
        isempty(scene.children) || continue
        a = viewport(scene)[]
        glScissor(ppu(minimum(a))..., ppu(widths(a))...)
        # update uniforms
        data1[:projection] = scene.camera.projection[]
        data1[:bias] = scene.ssao.bias[]
        data1[:radius] = scene.ssao.radius[]
        datas1[:noise_scale] = Vec2f(0.25f0 .* size(step.framebuffer))
        GLAbstraction.render(step.passes[1])
    end

    # SSAO - blur occlusion and apply to color
    glDrawBuffer(get_attachment(step.framebuffer, :color))  # color buffer
    data2 = step.passes[2].uniforms
    for (screenid, scene) in screen.screens
        # Select the area of one leaf scene
        isempty(scene.children) || continue
        a = viewport(scene)[]
        glScissor(ppu(minimum(a))..., ppu(widths(a))...)
        # update uniforms
        data2[:blur_range] = scene.ssao.blur
        data2[:inv_texel_size] = rcpframe(size(framebuffer))
        GLAbstraction.render(step.passes[2])
    end
    glDisable(GL_SCISSOR_TEST)

    return
end


function RenderPass{:FXAA}(screen)
    @debug "Creating FXAA postprocessor"
    framebuffer = screen.framebuffer
    renames = Dict{Symbol, Symbol}()

    # Add missing buffers
    if !haskey(framebuffer, :color_luma)
        if !haskey(framebuffer, :HDR_color)
            # GLAbstraction.bind(framebuffer)
            color_luma_buffer = Texture(
                shader_cache.context, RGBA{N0f8}, size(framebuffer), minfilter=:linear, x_repeat=:clamp_to_edge
            )
            luma_id = attach_colorbuffer(framebuffer, :color_luma, color_luma_buffer)
            renames[:color_luma] = :color_luma
        else
            luma_id = get_attachment(framebuffer, :HDR_color)
            renames[:color_luma] = :HDR_color
        end
    end

    # calculate luma for FXAA
    shader1 = LazyShader(
        screen.shader_cache,
        loadshader("postprocessing/fullscreen.vert"),
        loadshader("postprocessing/postprocess.frag")
    )
    data1 = Dict{Symbol, Any}(
        :color_texture => get_buffer(framebuffer, :color),
        :object_ids    => get_buffer(framebuffer, :objectid)
    )
    pass1 = RenderObject(data1, shader1, PostprocessPrerender(), nothing, shader_cache.context)
    pass1.postrenderfunction = () -> draw_fullscreen(pass1.vertexarray.id)

    # perform FXAA
    shader2 = LazyShader(
        screen.shader_cache,
        loadshader("postprocessing/fullscreen.vert"),
        loadshader("postprocessing/fxaa.frag")
    )
    data2 = Dict{Symbol, Any}(
        :color_texture => getfallback_buffer(framebuffer, :color_luma, :HDR_color),
        :RCPFrame      => rcpframe(size(framebuffer)),
    )
    pass2 = RenderObject(data2, shader2, PostprocessPrerender(), nothing, shader_cache.context)
    pass2.postrenderfunction = () -> draw_fullscreen(pass2.vertexarray.id)

    return RenderPass{:FXAA}(framebuffer.fb, RenderObject[pass1, pass2], renames)
end

function run_step(screen, glscene, step::RenderPass{:FXAA})
    # TODO: make scissor explicit?
    wh = size(screen.framebuffer)
    glViewport(0, 0, wh[1], wh[2])

    # FXAA - calculate LUMA
    glDrawBuffer(get_attachment(step.framebuffer, step.renames[:color_luma]))
    # necessary with negative SSAO bias...
    glClearColor(1, 1, 1, 1)
    glClear(GL_COLOR_BUFFER_BIT)
    GLAbstraction.render(step.passes[1])

    # FXAA - perform anti-aliasing
    glDrawBuffer(get_attachment(step.framebuffer, :color))  # color buffer
    step.passes[2][:RCPFrame] = rcpframe(size(step.framebuffer))
    GLAbstraction.render(step.passes[2])

    return
end

struct BlitToScreen <: AbstractRenderStep
    framebuffer::GLFramebuffer
    pass::RenderObject
    screen_framebuffer_id::Int
end

# TODO: replacement for CImGUI?
function BlitToScreen(screen, screen_framebuffer_id = 0)
    @debug "Creating to screen postprocessor"
    framebuffer = screen.framebuffer

    # draw color buffer
    shader = LazyShader(
        screen.shader_cache,
        loadshader("postprocessing/fullscreen.vert"),
        loadshader("postprocessing/copy.frag")
    )
    data = Dict{Symbol, Any}(
        :color_texture => get_buffer(framebuffer, :color)
    )
    pass = RenderObject(data, shader, PostprocessPrerender(), nothing, shader_cache.context)
    pass.postrenderfunction = () -> draw_fullscreen(pass.vertexarray.id)

    return BlitToScreen(framebuffer.fb, pass, screen_framebuffer_id)
end

function run_step(screen, ::Nothing, step::BlitToScreen)
    # TODO: Is this an observable? Can this be static?
    # GLFW uses 0, Gtk uses a value that we have to probe at the beginning of rendering
    glBindFramebuffer(GL_FRAMEBUFFER, step.screen_framebuffer_id)
    glViewport(0, 0, framebuffer_size(screen)...)
    # glScissor(0, 0, wh[1], wh[2])

    # clear target
    # TODO: Could be skipped if glscenes[1] clears to opaque (maybe use dedicated shader?)
    # TODO: Should this be cleared if we don't own the target?
    glClearColor(1,1,1,1)
    glClear(GL_COLOR_BUFFER_BIT)

    # transfer everything to the screen
    GLAbstraction.render(step.pass) # copy postprocess

    return
end

function destroy!(step::T) where {T <: AbstractRenderStep}
    @debug "Default destructor of $T"
    if hasfield(T, :passes)
        while !isempty(step.passes)
            destroy!(pop!(step.passes))
        end
    elseif hasfield(T, :pass)
        destroy!(step.pass)
    end
    return
end