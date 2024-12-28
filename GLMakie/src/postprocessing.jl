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

struct GLRenderPipeline
    parent::Makie.Pipeline
    steps::Vector{AbstractRenderStep}
end
GLRenderPipeline() = GLRenderPipeline(Makie.Pipeline(), AbstractRenderStep[])

function render_frame(screen, glscene, pipeline::GLRenderPipeline)
    for step in pipeline.steps
        run_step(screen, glscene, step)
    end
    return
end


# TODO: temporary, we should get to the point where this is not needed
struct EmptyRenderStep <: AbstractRenderStep end



struct SortPlots <: AbstractRenderStep end

function run_step(screen, glscene, ::SortPlots)
    function sortby(x)
        robj = x[3]
        plot = screen.cache2plot[robj.id]
        # TODO, use actual boundingbox
        # ~7% faster than calling zvalue2d doing the same thing?
        return Makie.transformationmatrix(plot)[][3, 4]
        # return Makie.zvalue2d(plot)
    end

    sort!(screen.renderlist; by=sortby)
    return
end



@enum FilterOptions begin
    FilterFalse = 0
    FilterTrue = 1
    FilterAny = 2
end
compare(val::Bool, filter::FilterOptions)    = (filter == FilterAny) || (val == Int(filter))
compare(val::Integer, filter::FilterOptions) = (filter == FilterAny) || (val == Int(filter))

struct RenderPlots <: AbstractRenderStep
    framebuffer::GLFramebuffer
    clear::Vector{Pair{Int, Vec4f}} # target index -> color

    ssao::FilterOptions
    transparency::FilterOptions
    fxaa::FilterOptions
end

function RenderPlots(screen, framebuffer, inputs, stage)
    if stage === :SSAO
        return RenderPlots(framebuffer,  [3 => Vec4f(0), 4 => Vec4f(0)], FilterTrue, FilterFalse, FilterAny)
    elseif stage === :FXAA
        return RenderPlots(framebuffer, Pair{Int, Vec4f}[], FilterFalse, FilterFalse, FilterAny)
    elseif stage === :OIT
        # HDR_color containing sums clears to 0
        # OIT_weight containing products clears to 1
        clear = [1 => Vec4f(0), 3 => Vec4f(1)]
        return RenderPlots(framebuffer, clear, FilterAny, FilterTrue, FilterAny)
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
            # TODO: Hacky
            idx <= step.framebuffer.counter || continue
            glDrawBuffer(step.framebuffer.attachments[idx])
            glClearColor(color...)
            glClear(GL_COLOR_BUFFER_BIT)
        end

        set_draw_buffers(step.framebuffer)

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
    robj::RenderObject
end



function RenderPass{:OIT}(screen, framebuffer, inputs)
    @debug "Creating OIT postprocessor"

    # Based on https://jcgt.org/published/0002/02/09/, see #1390
    # OIT setup
    shader = LazyShader(
        screen.shader_cache,
        loadshader("postprocessing/fullscreen.vert"),
        loadshader("postprocessing/OIT_blend.frag")
    )
    # TODO: rename in shader
    data = Dict{Symbol, Any}(
        :sum_color  => inputs[:weighted_color_sum],
        :prod_alpha => inputs[:alpha_product],
    )
    robj = RenderObject(
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
    robj.postrenderfunction = () -> draw_fullscreen(robj.vertexarray.id)

    return RenderPass{:OIT}(framebuffer, robj)
end

function run_step(screen, glscene, step::RenderPass{:OIT})
    # Blend transparent onto opaque
    wh = size(step.framebuffer)
    set_draw_buffers(step.framebuffer)
    glViewport(0, 0, wh[1], wh[2])
    GLAbstraction.render(step.robj)
    return
end

function RenderPass{:SSAO1}(screen, framebuffer, inputs)
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
    shader = LazyShader(
        screen.shader_cache,
        loadshader("postprocessing/fullscreen.vert"),
        loadshader("postprocessing/SSAO.frag"),
        view = Dict(
            "N_samples" => "$N_samples"
        )
    )
    data = Dict{Symbol, Any}(
        :position_buffer         => inputs[:position],
        :normal_buffer => inputs[:normal],
        :kernel => kernel,
        :noise => Texture(
            shader_cache.context, [normalize(Vec2f(2.0rand(2) .- 1.0)) for _ in 1:4, __ in 1:4],
            minfilter = :nearest, x_repeat = :repeat
        ),
        :noise_scale => Vec2f(0.25f0 .* size(screen)),
        :projection => Observable(Mat4f(I)),
        :bias => 0.025f0,
        :radius => 0.5f0
    )
    robj = RenderObject(data, shader, PostprocessPrerender(), nothing, shader_cache.context)
    robj.postrenderfunction = () -> draw_fullscreen(robj.vertexarray.id)

    return RenderPass{:SSAO1}(framebuffer, robj)
end

function RenderPass{:SSAO2}(screen, framebuffer, inputs)
    # blur occlusion and combine with color
    shader = LazyShader(
        screen.shader_cache,
        loadshader("postprocessing/fullscreen.vert"),
        loadshader("postprocessing/SSAO_blur.frag")
    )
    data = Dict{Symbol, Any}(
        :occlusion => inputs[:occlusion],
        :color_texture    => inputs[:color],
        :ids              => inputs[:objectid],
        :inv_texel_size => rcpframe(size(screen)),
        :blur_range => Int32(2)
    )
    robj = RenderObject(data, shader, PostprocessPrerender(), nothing, shader_cache.context)
    robj.postrenderfunction = () -> draw_fullscreen(robj.vertexarray.id)

    return RenderPass{:SSAO2}(framebuffer, robj)
end

function run_step(screen, glscene, step::RenderPass{:SSAO1})
    set_draw_buffers(step.framebuffer)  # occlusion buffer

    wh = size(step.framebuffer)
    glViewport(0, 0, wh[1], wh[2])
    glEnable(GL_SCISSOR_TEST)
    ppu = (x) -> round.(Int, screen.px_per_unit[] .* x)

    data = step.robj.uniforms
    for (screenid, scene) in screen.screens
        # Select the area of one leaf scene
        # This should be per scene because projection may vary between
        # scenes. It should be a leaf scene to avoid repeatedly shading
        # the same region (though this is not guaranteed...)
        isempty(scene.children) || continue
        a = viewport(scene)[]
        glScissor(ppu(minimum(a))..., ppu(widths(a))...)
        # update uniforms
        data[:projection] = Mat4f(scene.camera.projection[])
        data[:bias] = scene.ssao.bias[]
        data[:radius] = scene.ssao.radius[]
        data[:noise_scale] = Vec2f(0.25f0 .* size(step.framebuffer))
        GLAbstraction.render(step.robj)
    end

    return
end

function run_step(screen, glscene, step::RenderPass{:SSAO2})
    # SSAO - blur occlusion and apply to color
    set_draw_buffers(step.framebuffer)  # color buffer
    ppu = (x) -> round.(Int, screen.px_per_unit[] .* x)
    data = step.robj.uniforms
    for (screenid, scene) in screen.screens
        # Select the area of one leaf scene
        isempty(scene.children) || continue
        a = viewport(scene)[]
        glScissor(ppu(minimum(a))..., ppu(widths(a))...)
        # update uniforms
        data[:blur_range] = scene.ssao.blur
        data[:inv_texel_size] = rcpframe(size(step.framebuffer))
        GLAbstraction.render(step.robj)
    end
    glDisable(GL_SCISSOR_TEST)

    return
end


function RenderPass{:FXAA1}(screen, framebuffer, inputs)
    # calculate luma for FXAA
    shader = LazyShader(
        screen.shader_cache,
        loadshader("postprocessing/fullscreen.vert"),
        loadshader("postprocessing/postprocess.frag")
    )
    data = Dict{Symbol, Any}(
        :color_texture => inputs[:color],
        :object_ids    => inputs[:objectid],
    )
    robj = RenderObject(data, shader, PostprocessPrerender(), nothing, shader_cache.context)
    robj.postrenderfunction = () -> draw_fullscreen(robj.vertexarray.id)

    return RenderPass{:FXAA1}(framebuffer, robj)
end

function RenderPass{:FXAA2}(screen, framebuffer, inputs)
    # perform FXAA
    shader = LazyShader(
        screen.shader_cache,
        loadshader("postprocessing/fullscreen.vert"),
        loadshader("postprocessing/fxaa.frag")
    )
    data = Dict{Symbol, Any}(
        :color_texture => inputs[:color_luma],
        :RCPFrame      => rcpframe(size(framebuffer)),
    )
    robj = RenderObject(data, shader, PostprocessPrerender(), nothing, shader_cache.context)
    robj.postrenderfunction = () -> draw_fullscreen(robj.vertexarray.id)

    return RenderPass{:FXAA2}(framebuffer, robj)
end

function run_step(screen, glscene, step::RenderPass{:FXAA1})
    # FXAA - calculate LUMA
    set_draw_buffers(step.framebuffer)
    # TODO: make scissor explicit?
    wh = size(step.framebuffer)
    glViewport(0, 0, wh[1], wh[2])
    # TODO: is this still true?
    # necessary with negative SSAO bias...
    # glClearColor(1, 1, 1, 1)
    # glClear(GL_COLOR_BUFFER_BIT)
    GLAbstraction.render(step.robj)
    return
end

function run_step(screen, glscene, step::RenderPass{:FXAA2})
    # FXAA - perform anti-aliasing
    set_draw_buffers(step.framebuffer)  # color buffer
    step.robj[:RCPFrame] = rcpframe(size(step.framebuffer))
    GLAbstraction.render(step.robj)
    return
end



# TODO: Could also handle integration with Gtk, CImGui, etc with a dedicated struct
struct BlitToScreen <: AbstractRenderStep
    framebuffer::GLFramebuffer
    attachment::GLuint
    screen_framebuffer_id::Int

    # Screen not available yet
    function BlitToScreen(framebuffer::GLFramebuffer, attachment::GLuint, screen_framebuffer_id::Integer = 0)
        @debug "Creating to screen postprocessor"
        return new(framebuffer, attachment, screen_framebuffer_id)
    end
end

function run_step(screen, ::Nothing, step::BlitToScreen)
    # Set source
    glBindFramebuffer(GL_READ_FRAMEBUFFER, step.framebuffer.id)
    glReadBuffer(step.attachment) # for safety

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
