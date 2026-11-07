# Utilities:
struct PostprocessPrerender end

function (sp::PostprocessPrerender)()
    glDepthMask(GL_TRUE)
    glDisable(GL_DEPTH_TEST)
    glDisable(GL_BLEND)
    glDisable(GL_CULL_FACE)
    return
end

rcpframe(x) = 1.0f0 ./ Vec2f(x[1], x[2])

"""
    PostProcessRenderObject(screen, inputs, shader; kwargs...)

Creates a `RenderObject` with some default settings useful for post-processors.

## Default Keyword Arguments:

- `prerender = PostprocessPrerender()`: turns off depth testing, blending and face culling
- `postrender = EmptyPostrender()`: does nothing
- `primitive = GL_TRIANGLES`: render OpenGL triangles
- `indices = 3`: Renders 4 vertices, 2 triangles (`(0, 1, 2), (1, 2, 3)`)
- `instances = nothing`: No instanced rendering
"""
function PostProcessRenderObject(
        screen, inputs::Dict{Symbol, Any}, shader;
        prerender = PostprocessPrerender(),
        postrender = GLAbstraction.EmptyPostrender(),
        indices = 3, instances = nothing, primitive = GLAbstraction.GL_TRIANGLES
    )
    get!(inputs, :indices, indices)
    get!(inputs, :instances, instances)
    get!(inputs, :gl_primitive, primitive)
    robj = RenderObject(screen.glscreen, inputs)
    add_instructions!(robj, :main, shader, pre = prerender, post = postrender)
    return robj
end

# or maybe Task? Stage?
"""
    GLRenderStage

Represents a task or stage that needs to run when rendering a frame. These
tasks are collected in the RenderGraph.

Each task may implement:
- `prepare_stage(screen, glscene, stage)`: Initialize the task.
- `run_stage(screen, glscenes, stage)`: Run the task.
- `destroy!(stage)`: Cleanup of the object. This defaults to calling `destroy!(stage.robj)`.
- `on_resize(stage, width, height)`: Called when buffer should resize.

Initialization is grouped together and runs before all run stages. If you need
to initialize just before your run, bundle it with the run.

A render stage is constructed from a `Makie.RenderStage` using
`construct(::Val{stage.name}, screen, framebuffer, inputs, parent)`. The `inputs`
are the buffers/textures that feed into this stage according to the render pipeline.
The `parent` is the `Makie.RenderStage` which may contain additional settings/uniforms.
The framebuffer is specifically created for this stage, containing the outputs
specified in the render pipeline in the same order and with the same names.

Optionally, `reconstruct(old_stage, screen, framebuffer, inputs, parent)` can be
used to construct a stage from a previous version. This can be used to avoid a
full destruction and re-creation of a stage when the pipeline gets replaced.

Stages that draw scene content (clearing, plot rendering and the post processing
directly tied to it like OIT and SSAO) set `runs_per_scene(stage) = true` and
implement `run_stage(screen, glscene::GLScene, stage)` instead. Consecutive
per-scene stages run scene by scene, see `run_stages!`.
"""
abstract type GLRenderStage end
run_stage(screen, glscenes, ::GLRenderStage) = nothing
runs_per_scene(::GLRenderStage) = false

function destroy!(stage::T) where {T <: GLRenderStage}
    @debug "Default destructor of $T"
    hasfield(T, :robj) && destroy!(stage.robj)
    return
end

function reconstruct(old::T, screen, framebuffer, inputs, parent::Makie.RenderStage) where {T <: GLRenderStage}
    # @debug "reconstruct() not defined for $T, calling construct()"
    destroy!(old)
    return construct(Val(parent.name), screen, framebuffer, inputs, parent)
end

on_resize(::GLRenderStage, w, h) = nothing

# convenience
Broadcast.broadcastable(x::GLRenderStage) = Ref(x)


"""
    GLRenderGraph(pipeline::Makie.RenderGraph, stages::Vector{GLRenderStage})

Creates a `GLRenderGraph`. The pipeline mostly acts as a collection of stages
which run in sequence when calling `render_frame!(screen, scene, pipeline)`.
"""
struct GLRenderGraph
    parent::Makie.LoweredRenderGraph
    stages::Vector{GLRenderStage}
end

function GLRenderGraph()
    return GLRenderGraph(Makie.LoweredRenderGraph(), GLRenderStage[])
end

# Allow iteration
function Base.iterate(pipeline::GLRenderGraph, idx = 1)
    idx > length(pipeline) && return nothing
    return (pipeline.stages[idx], idx + 1)
end
Base.length(pipeline::GLRenderGraph) = length(pipeline.stages)
Base.eltype(::Type{GLRenderGraph}) = GLRenderStage

function render_frame(screen, glscenes, pipeline::GLRenderGraph)
    return run_stages!(screen, glscenes, pipeline.stages)
end

"""
    run_stages!(screen, glscenes, stages)

Runs the given stages. Consecutive stages with `runs_per_scene(stage) == true`
run scene by scene in back to front order, so each scene is fully drawn
(background, opaque plots, transparent plots, SSAO) before the next one starts.
Together with each scene clearing the depth buffer this makes every scene draw
strictly above the scenes before it. All other stages run once per frame.
"""
function run_stages!(screen, glscenes, stages)
    i = 1
    while i <= length(stages)
        if runs_per_scene(stages[i])
            stop = i
            while stop < length(stages) && runs_per_scene(stages[stop + 1])
                stop += 1
            end
            for glscene in glscenes
                is_drawn(screen, glscene) || continue
                for stage in view(stages, i:stop)
                    require_context(screen.glscreen)
                    run_stage(screen, glscene, stage)
                end
            end
            # Per-frame stages expect to act on the full frame
            glDisable(GL_SCISSOR_TEST)
            i = stop + 1
        else
            require_context(screen.glscreen)
            run_stage(screen, glscenes, stages[i])
            i += 1
        end
    end
    glDisable(GL_SCISSOR_TEST)
    return
end

function scene_pixel_rect(screen, scene::Scene)
    ppu = screen.px_per_unit[]
    area = viewport(scene)[]
    return (round.(Int, ppu .* minimum(area))..., round.(Int, ppu .* widths(area))...)
end

is_drawn(screen, glscene::GLScene) = glscene.scene.visible[] && all(>(0), scene_pixel_rect(screen, glscene.scene)[3:4])

# For drawing plots: map clip space to the scene viewport and cut off everything outside
function set_scene_viewport!(screen, scene::Scene)
    rect = scene_pixel_rect(screen, scene)
    glViewport(rect...)
    glEnable(GL_SCISSOR_TEST)
    glScissor(rect...)
    return
end

# For fullscreen passes: keep the full viewport (uv mapping) but only touch the scene's pixels
function set_scene_scissor!(screen, scene::Scene, framebuffer)
    glViewport(0, 0, size(framebuffer)...)
    glEnable(GL_SCISSOR_TEST)
    glScissor(scene_pixel_rect(screen, scene)...)
    return
end

# Whether a scene has visible render objects for the given render target
has_target(glscene::GLScene, target::Symbol) =
    any(robj -> robj.visible && haskey(robj.variants, target), glscene.renderobjects)

# map framebuffer resize to each stage
# bundled with framebuffer_manager resizes
function Base.resize!(pipeline::GLRenderGraph, w, h)
    for stage in pipeline
        on_resize(stage, w, h)
    end
    return
end

function destroy!(pipeline::GLRenderGraph)
    destroy!.(pipeline.stages)
    empty!(pipeline.stages)
    return
end

################################################################################
### Stages
################################################################################

struct ClearStage <: GLRenderStage
    framebuffer::GLFramebuffer
end

on_resize(stage::ClearStage, w, h) = resize!(stage.framebuffer, w, h)
reconstruct(pass::ClearStage, screen, framebuffer, inputs, stage) = pass
construct(::Val{:SceneClear}, screen, framebuffer, inputs, parent) = ClearStage(framebuffer)
runs_per_scene(::ClearStage) = true

function run_stage(screen, glscene::GLScene, stage::ClearStage)
    scene = glscene.scene
    fb = stage.framebuffer
    set_draw_buffers(fb, :color)
    set_scene_viewport!(screen, scene)
    glDepthMask(GL_TRUE)
    if scene.clear[]
        c = scene.backgroundcolor[]
        glClearColor(red(c), green(c), blue(c), alpha(c))
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
        # Covered plots are no longer pickable
        if haskey(fb, :objectid)
            set_draw_buffers(fb, :objectid)
            glClearColor(0, 0, 0, 0)
            glClear(GL_COLOR_BUFFER_BIT)
        end
    else
        # Plots of this scene draw strictly above those of previous scenes
        glClear(GL_DEPTH_BUFFER_BIT)
    end
    return
end

struct SortPlots <: GLRenderStage end

construct(::Val{:ZSort}, screen, parent) = SortPlots()

function run_stage(screen, glscenes, ::SortPlots)
    get_zindex(robj::RenderObject) = robj.zindex
    for glscene in glscenes
        sort!(glscene.renderobjects; by = get_zindex)
    end
    return
end


@enum FilterOptions begin
    FilterFalse = 0
    FilterTrue = 1
    FilterAny = 2
end
compare(val::Bool, filter::FilterOptions) = (filter == FilterAny) || (val == Int(filter))
compare(val::Integer, filter::FilterOptions) = (filter == FilterAny) || (val == Int(filter))

"""
    struct RenderPlots <: GLRenderStage

A render pipeline stage which renders plots. This includes filtering options to
distribute plots into, e.g. a pass for OIT.
"""
struct RenderPlots{Pre} <: GLRenderStage
    framebuffer::GLFramebuffer
    clear::Vector{Pair{Int, Vec4f}} # target index -> color

    ssao::FilterOptions
    transparency::FilterOptions
    fxaa::FilterOptions

    target::Symbol
    prerender::Pre
end


# TODO: What's a good place for these?

struct StandardPrerender
end

function enabletransparency()
    glDisable(GL_BLEND)
    glEnablei(GL_BLEND, 0)
    # This does:
    # target.rgb = source.a * source.rgb + (1 - source.a) * target.rgb
    # target.a = 0 * source.a + 1 * target.a
    # the latter is required to keep target.a = 1 for the OIT pass
    glBlendFuncSeparate(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA, GL_ZERO, GL_ONE)
    return
end

function handle_overdraw(overdraw)
    if Bool(overdraw)
        # Disable depth testing if overdrawing
        glDisable(GL_DEPTH_TEST)
    else
        glEnable(GL_DEPTH_TEST)
        glDepthFunc(GL_LEQUAL)
    end
    return
end

function (sp::StandardPrerender)(overdraw::UInt8)
    glDepthMask(GL_TRUE)
    enabletransparency()

    handle_overdraw(overdraw)

    # Disable cullface for now, until all rendering code is corrected!
    glDisable(GL_CULL_FACE)
    # glCullFace(GL_BACK)

    return
end

struct OITPrerender
end

function (pre::OITPrerender)(overdraw::UInt8)
    # disable depth buffer writing
    glDepthMask(GL_FALSE)

    # Blending
    glEnable(GL_BLEND)
    glBlendEquation(GL_FUNC_ADD)

    # buffer 0 contains weight * color.rgba, should do sum
    # destination <- 1 * source + 1 * destination
    glBlendFunci(0, GL_ONE, GL_ONE)

    # buffer 1 is objectid, do nothing
    glDisablei(GL_BLEND, 1)

    # buffer 2 is color.a, should do product
    # destination <- 0 * source + (source) * destination
    glBlendFunci(2, GL_ZERO, GL_SRC_COLOR)

    handle_overdraw(overdraw)

    # Disable cullface for now, until all rendering code is corrected!
    glDisable(GL_CULL_FACE)
    # glCullFace(GL_BACK)

    return
end

function construct(::Val{:Render}, screen, framebuffer, inputs, parent, target = :forward_render_objectid)
    # can't do FilterOptions(::FilterOptions) ???
    ssao = FilterOptions(get(parent.attributes, :ssao, 2))
    fxaa = FilterOptions(get(parent.attributes, :fxaa, 2))
    transparency = FilterOptions(get(parent.attributes, :transparency, 2))
    return RenderPlots(
        framebuffer, [3 => Vec4f(0), 4 => Vec4f(0)], ssao, transparency, fxaa,
        target, StandardPrerender()
    )
end

# Render targets of the SSAO and OIT plot render stages. The matching post
# processing stages use these to skip scenes without such plots.
const SSAO_TARGET = :forward_render_objectid_geom
const OIT_TARGET = :forward_render_objectid_oit

function construct(::Val{Symbol("SSAO Render")}, screen, framebuffer, inputs, parent)
    return construct(Val{:Render}(), screen, framebuffer, inputs, parent, SSAO_TARGET)
end

function construct(::Val{Symbol("OIT Render")}, screen, framebuffer, inputs, parent)
    # HDR_color containing sums clears to 0
    # OIT_weight containing products clears to 1
    clear = [1 => Vec4f(0), 3 => Vec4f(1)]
    return RenderPlots(
        framebuffer, clear, FilterAny, FilterTrue, FilterAny,
        OIT_TARGET, OITPrerender()
    )
end

on_resize(stage::RenderPlots, w, h) = resize!(stage.framebuffer, w, h)

runs_per_scene(::RenderPlots) = true

renders_in(robj::RenderObject, stage::RenderPlots) = robj.visible && haskey(robj.variants, stage.target)

function run_stage(screen, glscene::GLScene, stage::RenderPlots)
    # Somehow errors in here get ignored silently!?
    try
        robjs = glscene.renderobjects
        any(robj -> renders_in(robj, stage), robjs) || return

        fb = stage.framebuffer
        GLAbstraction.bind(fb)
        set_scene_viewport!(screen, glscene.scene)

        # Clearing specific to how this stage renders plots (e.g. OIT accumulation
        # buffers), restricted to the scene viewport. Scene clearing happens in ClearStage
        for (idx, color) in stage.clear
            idx <= fb.counter || continue
            glDrawBuffer(fb.attachments[idx])
            glClearColor(color...)
            glClear(GL_COLOR_BUFFER_BIT)
        end
        set_draw_buffers(fb)

        ppu = screen.px_per_unit[]
        for robj in robjs
            renders_in(robj, stage) || continue
            robj[:px_per_unit] = ppu
            stage.prerender(robj[:overdraw]::UInt8)
            render(robj, robj.variants[stage.target])
        end
    catch e
        @error "Error while rendering!" exception = e
        rethrow(e)
    end
    return
end


# TODO: maybe call this a PostProcessor?
# Vaguely leaning on Vulkan Terminology
struct RenderPass{Name} <: GLRenderStage
    framebuffer::GLFramebuffer
    robj::RenderObject
end

on_resize(stage::RenderPass, w, h) = resize!(stage.framebuffer, w, h)

function reconstruct(pass::RP, screen, framebuffer, inputs, ::Makie.RenderStage) where {RP <: RenderPass}
    for (k, v) in inputs
        if haskey(pass.robj.uniforms, k)
            pass.robj.uniforms[k] = v
        else
            @error("Input $k does not exist in recreated RenderPass.")
        end
    end
    return RP(framebuffer, pass.robj)
end

function construct(::Val{:OIT}, screen, framebuffer, inputs, parent)
    @debug "Creating OIT postprocessor"
    require_context(screen.glscreen)

    # Based on https://jcgt.org/published/0002/02/09/, see #1390
    # OIT setup
    shader = LazyShader(
        screen.shader_cache,
        loadshader("postprocessing/fullscreen.vert"),
        loadshader("postprocessing/OIT_blend.frag")
    )
    prerender = () -> begin
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
    end
    robj = PostProcessRenderObject(screen, inputs, shader, prerender = prerender)
    return RenderPass{:OIT}(framebuffer, robj)
end

runs_per_scene(::RenderPass{:OIT}) = true

function run_stage(screen, glscene::GLScene, stage::RenderPass{:OIT})
    # Only scenes with transparent plots accumulated anything to resolve
    has_target(glscene, OIT_TARGET) || return
    # Blend transparent onto opaque
    set_draw_buffers(stage.framebuffer)
    set_scene_scissor!(screen, glscene.scene, stage.framebuffer)
    GLAbstraction.render(stage.robj)
    return
end

function construct(::Val{:SSAO1}, screen, framebuffer, inputs, parent)
    require_context(screen.glscreen)

    # SSAO setup
    kernel = parent.attributes[:kernel]
    noise = parent.attributes[:noise]
    N_samples = length(kernel)

    # compute occlusion
    shader = LazyShader(
        screen.shader_cache,
        loadshader("postprocessing/fullscreen.vert"),
        loadshader("postprocessing/SSAO.frag"),
        view = Dict(
            "N_samples" => "$N_samples"
        )
    )
    inputs[:kernel] = kernel
    inputs[:noise] = Texture(screen.glscreen, noise, minfilter = :nearest, x_repeat = :repeat)
    inputs[:noise_scale] = Vec2f(0.25f0 .* size(screen))
    inputs[:projection] = Mat4f(I)
    inputs[:bias] = 0.025f0
    inputs[:radius] = 0.5f0
    robj = PostProcessRenderObject(screen, inputs, shader)

    return RenderPass{:SSAO1}(framebuffer, robj)
end

function construct(::Val{:SSAO2}, screen, framebuffer, inputs, parent)
    require_context(screen.glscreen)

    # blur occlusion and multiply it onto the color buffer
    shader = LazyShader(
        screen.shader_cache,
        loadshader("postprocessing/fullscreen.vert"),
        loadshader("postprocessing/SSAO_blur.frag")
    )
    inputs[:inv_texel_size] = rcpframe(size(screen))
    inputs[:blur_range] = Int32(2)
    prerender = () -> begin
        glDepthMask(GL_TRUE)
        glDisable(GL_DEPTH_TEST)
        glDisable(GL_CULL_FACE)
        glEnable(GL_BLEND)
        # color.rgb *= occlusion, color.a stays
        glBlendFuncSeparate(GL_ZERO, GL_SRC_COLOR, GL_ZERO, GL_ONE)
    end
    robj = PostProcessRenderObject(screen, inputs, shader, prerender = prerender)

    return RenderPass{:SSAO2}(framebuffer, robj)
end

runs_per_scene(::RenderPass{:SSAO1}) = true
runs_per_scene(::RenderPass{:SSAO2}) = true

function run_stage(screen, glscene::GLScene, stage::RenderPass{:SSAO1})
    has_target(glscene, SSAO_TARGET) || return
    scene = glscene.scene
    set_draw_buffers(stage.framebuffer)  # occlusion buffer
    set_scene_scissor!(screen, scene, stage.framebuffer)

    # per scene because the projection may vary between scenes
    data = stage.robj.uniforms
    data[:projection] = Mat4f(scene.camera.projection[])
    data[:bias] = scene.ssao.bias[]
    data[:radius] = scene.ssao.radius[]
    data[:noise_scale] = Vec2f(0.25f0 .* size(stage.framebuffer))
    GLAbstraction.render(stage.robj)
    return
end

function run_stage(screen, glscene::GLScene, stage::RenderPass{:SSAO2})
    has_target(glscene, SSAO_TARGET) || return
    scene = glscene.scene
    # blur occlusion and multiply it onto the plots of this scene
    set_draw_buffers(stage.framebuffer)  # color buffer
    set_scene_scissor!(screen, scene, stage.framebuffer)

    data = stage.robj.uniforms
    data[:blur_range] = scene.ssao.blur
    data[:inv_texel_size] = rcpframe(size(stage.framebuffer))
    GLAbstraction.render(stage.robj)
    return
end


function construct(::Val{:FXAA1}, screen, framebuffer, inputs, parent)

    filter_fxaa_in_shader = get(parent.attributes, :filter_in_shader, true)

    require_context(screen.glscreen)
    # calculate luma for FXAA
    shader = LazyShader(
        screen.shader_cache,
        loadshader("postprocessing/fullscreen.vert"),
        loadshader("postprocessing/postprocess.frag"),
        view = Dict("FILTER_IN_SHADER" => filter_fxaa_in_shader ? "#define FILTER_IN_SHADER" : "")
    )
    filter_fxaa_in_shader || pop!(inputs, :objectid_buffer)
    robj = PostProcessRenderObject(screen, inputs, shader)

    return RenderPass{:FXAA1}(framebuffer, robj)
end

function construct(::Val{:FXAA2}, screen, framebuffer, inputs, parent)
    require_context(screen.glscreen)

    # perform FXAA
    shader = LazyShader(
        screen.shader_cache,
        loadshader("postprocessing/fullscreen.vert"),
        loadshader("postprocessing/fxaa.frag")
    )
    inputs[:RCPFrame] = rcpframe(size(framebuffer))
    robj = PostProcessRenderObject(screen, inputs, shader)

    return RenderPass{:FXAA2}(framebuffer, robj)
end

function run_stage(screen, glscenes, stage::RenderPass{:FXAA1})
    # FXAA - calculate LUMA
    set_draw_buffers(stage.framebuffer)
    # TODO: make scissor explicit?
    wh = size(stage.framebuffer)
    glViewport(0, 0, wh[1], wh[2])
    # TODO: is this still true?
    # necessary with negative SSAO bias...
    # glClearColor(1, 1, 1, 1)
    # glClear(GL_COLOR_BUFFER_BIT)
    GLAbstraction.render(stage.robj)
    return
end

function run_stage(screen, glscenes, stage::RenderPass{:FXAA2})
    # FXAA - perform anti-aliasing
    set_draw_buffers(stage.framebuffer)  # color buffer
    stage.robj[:RCPFrame] = rcpframe(size(stage.framebuffer))
    GLAbstraction.render(stage.robj)
    return
end

struct MSAAResolve <: GLRenderStage
    input_framebuffer::GLFramebuffer
    output_framebuffer::GLFramebuffer
end

function on_resize(stage::MSAAResolve, w, h)
    resize!(stage.input_framebuffer, w, h)
    resize!(stage.output_framebuffer, w, h)
    return
end

function construct(::Val{:MSAAResolve}, screen, stage::Makie.LoweredStage)
    require_context(screen.glscreen)
    manager = screen.framebuffer_manager
    input_framebuffer = generate_framebuffer(manager, stage.inputs)
    output_framebuffer = generate_framebuffer(manager, stage.outputs)
    return MSAAResolve(input_framebuffer, output_framebuffer)
end

function run_stage(screen, glscenes, stage::MSAAResolve)
    w, h = size(stage.output_framebuffer)
    flag = GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT

    for attachment in each_attachment(stage.input_framebuffer)
        glBindFramebuffer(GL_READ_FRAMEBUFFER, stage.input_framebuffer.id)
        glReadBuffer(attachment)
        glBindFramebuffer(GL_DRAW_FRAMEBUFFER, stage.output_framebuffer.id)
        glDrawBuffer(attachment)

        glBlitFramebuffer(0, 0, w, h, 0, 0, w, h, flag, GL_NEAREST)

        # would we be copying the depth and stencil buffers again otherwise?
        flag = GL_COLOR_BUFFER_BIT
    end

    return
end


struct BlitToScreen <: GLRenderStage
    source_framebuffer::GLFramebuffer
end

on_resize(stage::BlitToScreen, w, h) = resize!(stage.source_framebuffer, w, h)

function construct(::Val{:Display}, screen, stage)
    require_context(screen.glscreen)
    framebuffer = generate_framebuffer(screen.framebuffer_manager, stage.inputs)
    return BlitToScreen(framebuffer)
end

function run_stage(screen, glscenes, stage::BlitToScreen)
    return copy_to_screen(screen, stage.source_framebuffer)
end

"""
    copy_to_screen(screen, framebuffer)

Copies the final render to the screen for displaying.

Can be extended for other window types by dispatching on `Screen{WindowType}`
"""
function copy_to_screen(screen, fb)
    glBindFramebuffer(GL_READ_FRAMEBUFFER, fb.id)
    glReadBuffer(get_attachment(fb, :color))

    glBindFramebuffer(GL_DRAW_FRAMEBUFFER, 0)

    src_w, src_h = framebuffer_size(screen)
    trg_w, trg_h = makie_window_size(screen)

    glBlitFramebuffer(
        0, 0, src_w, src_h,
        0, 0, trg_w, trg_h,
        GL_COLOR_BUFFER_BIT, GL_LINEAR
    )

    return
end
