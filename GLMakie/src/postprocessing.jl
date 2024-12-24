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


# or maybe Task? Stage?
"""
    AbstractRenderStep

Represents a task or step that needs to run when rendering a frame. These
tasks are collected in the RenderPipeline.

Each task may implement:
- `prepare_step(screen, glscene, step)`: Initialize the task.
- `run_step(screen, glscene, step)`: Run the task.

Initialization is grouped together and runs before all run steps. If you need
to initialize just before your run, bundle it with the run.
"""
abstract type AbstractRenderStep end
prepare_step(screen, glscene, ::AbstractRenderStep) = nothing
run_step(screen, glscene, ::AbstractRenderStep) = nothing

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


@enum FilterOptions begin
    FilterFalse = 0
    FilterTrue = 1
    FilterAny = 2
end
compare(val::Bool, filter::FilterOptions)    = (filter == FilterAny) || (val == Int(filter))
compare(val::Integer, filter::FilterOptions) = (filter == FilterAny) || (val == Int(filter))

struct RenderPlots <: AbstractRenderStep
    framebuffer::GLFramebuffer
    targets::Vector{GLuint}
    clear::Vector{Pair{Int, Vec4f}} # target index -> color

    ssao::FilterOptions
    transparency::FilterOptions
    fxaa::FilterOptions
end

function RenderPlots(screen, stage)
    fb = screen.framebuffer
    if stage === :SSAO
        return RenderPlots(
            fb.fb, fb.render_buffer_ids, [3 => Vec4f(0), 4 => Vec4f(0)],
            FilterTrue, FilterFalse, FilterAny)
    elseif stage === :FXAA
        return RenderPlots(
            fb.fb, get_attachment.(Ref(fb), [:color, :objectid]), Pair{Int, Vec4f}[],
            FilterFalse, FilterFalse, FilterAny)
    elseif stage === :OIT
        targets = get_attachment.(Ref(fb), [:HDR_color, :objectid, :OIT_weight])
        # HDR_color containing sums clears to 0
        # OIT_weight containing products clears to 1
        clear = [1 => Vec4f(0), 3 => Vec4f(1)]
        return RenderPlots(fb.fb, targets, clear, FilterAny, FilterTrue, FilterAny)
    else
        error("Incorrect stage = $stage given. Should be :SSAO, :FXAA or :OIT.")
    end
end

function id2scene(screen, id1)
    # TODO maybe we should use a different data structure
    for (id2, scene) in screen.screens
        id1 == id2 && return true, scene
    end
    return false, nothing
end

function run_step(screen, glscene, step::RenderPlots)
    # Somehow errors in here get ignored silently!?
    try
        GLAbstraction.bind(step.framebuffer)

        for (idx, color) in step.clear
            idx <= length(step.targets) || continue
            glDrawBuffer(step.targets[idx])
            glClearColor(color...)
            glClear(GL_COLOR_BUFFER_BIT)
        end

        glDrawBuffers(length(step.targets), step.targets)

        for (zindex, screenid, elem) in screen.renderlist
            should_render = elem.visible &&
                compare(elem[:ssao][], step.ssao) &&
                compare(elem[:transparency][], step.transparency) &&
                compare(elem[:fxaa][], step.fxaa)
            should_render || continue

            found, scene = id2scene(screen, screenid)
            (found && scene.visible[]) || continue

            ppu = screen.px_per_unit[]
            a = viewport(scene)[]
            glViewport(round.(Int, ppu .* minimum(a))..., round.(Int, ppu .* widths(a))...)
            render(elem)
        end
    catch e
        @error "Error while rendering!" exception = e
        rethrow(e)
    end
    return
end




# TODO: maybe call this a PostProcessor?
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
        :color_texture => get_buffer(framebuffer, :color),
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
    glDrawBuffer(get_attachment(step.framebuffer, step.renames[:normal_occlusion]))  # occlusion buffer
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
        data1[:projection] = Mat4f(scene.camera.projection[])
        data1[:bias] = scene.ssao.bias[]
        data1[:radius] = scene.ssao.radius[]
        data1[:noise_scale] = Vec2f(0.25f0 .* size(step.framebuffer))
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
        data2[:inv_texel_size] = rcpframe(size(step.framebuffer))
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



# TODO: Could also handle integration with Gtk, CImGui, etc with a dedicated struct
struct BlitToScreen <: AbstractRenderStep
    framebuffer::GLFramebuffer
    screen_framebuffer_id::Int

    # Screen not available yet
    function BlitToScreen(screen, screen_framebuffer_id::Integer = 0)
        @debug "Creating to screen postprocessor"
        return new(screen.framebuffer.fb, screen_framebuffer_id)
    end
end

function run_step(screen, ::Nothing, step::BlitToScreen)
    # Set source
    glBindFramebuffer(GL_READ_FRAMEBUFFER, step.framebuffer.id)
    glReadBuffer(get_attachment(step.framebuffer, :color)) # for safety

    # TODO: Is this an observable? Can this be static?
    # GLFW uses 0, Gtk uses a value that we have to probe at the beginning of rendering
    glBindFramebuffer(GL_DRAW_FRAMEBUFFER, step.screen_framebuffer_id)

    src_w, src_h = framebuffer_size(screen)
    if isnothing(screen.scene)
        trg_w, trg_h = src_w, src_h
    else
        trg_w, trg_h = widths(screen.scene.viewport[])
    end

    glBlitFramebuffer(
        0, 0, src_w, src_h,
        0, 0, trg_w, trg_h,
        GL_COLOR_BUFFER_BIT, GL_LINEAR
    )

    return
end
