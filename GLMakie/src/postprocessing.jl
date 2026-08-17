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
- `run_stage(screen, glscene, stage)`: Run the task.
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
"""
abstract type GLRenderStage end
run_stage(screen, glscene, ::GLRenderStage) = nothing

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

# render each stage
function render_frame(screen, glscenes, pipeline::GLRenderGraph)
    for stage in pipeline
        require_context(screen.glscreen)
        run_stage(screen, glscenes, stage)
    end
    return
end

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

function run_stage(screen, glscenes, stage::ClearStage)
    return clear_scenes!(screen, glscenes, stage.framebuffer)
end

function clear_scenes!(screen, glscenes, framebuffer)
    set_draw_buffers(framebuffer, :color)

    # Clear everything for safety (in case top level scene does not clear)
    # (should be at least depth)
    # glDisable(GL_SCISSOR_TEST)
    # glDisable(GL_STENCIL_TEST)
    # wh = size(framebuffer)
    # glViewport(0, 0, wh[1], wh[2])
    # glClearColor(1, 1, 1, 1)
    # glClear(GL_DEPTH_BUFFER_BIT | GL_COLOR_BUFFER_BIT)

    # Draw scene backgrounds for cleared scenes
    glEnable(GL_SCISSOR_TEST)
    ppu = screen.px_per_unit[]
    for glscene in glscenes # back to front
        scene = glscene.scene
        if scene.visible[] && scene.clear[]
            a = viewport(scene)[]
            rt = (round.(Int, ppu .* minimum(a))..., round.(Int, ppu .* widths(a))...)
            glViewport(rt...)
            glScissor(rt...)
            c = scene.backgroundcolor[]
            glClearColor(red(c), green(c), blue(c), alpha(c))
            glClear(GL_COLOR_BUFFER_BIT)
        end
    end
    glDisable(GL_SCISSOR_TEST)
    return
end

struct SortPlots <: GLRenderStage end

construct(::Val{:ZSort}, screen, parent) = SortPlots()

Makie.zvalue2d(@nospecialize(robj::RenderObject)) = robj.zindex
function run_stage(screen, glscenes, ::SortPlots)
    for glscene in glscenes
        sort!(glscene.renderobjects; by = Makie.zvalue2d)
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

function construct(::Val{Symbol("SSAO Render")}, screen, framebuffer, inputs, parent)
    return construct(Val{:Render}(), screen, framebuffer, inputs, parent, :forward_render_objectid_geom)
end

function construct(::Val{Symbol("OIT Render")}, screen, framebuffer, inputs, parent)
    # HDR_color containing sums clears to 0
    # OIT_weight containing products clears to 1
    clear = [1 => Vec4f(0), 3 => Vec4f(1)]
    return RenderPlots(
        framebuffer, clear, FilterAny, FilterTrue, FilterAny,
        :forward_render_objectid_oit, OITPrerender()
    )
end

on_resize(stage::RenderPlots, w, h) = resize!(stage.framebuffer, w, h)

function prepare_stencil!(fb)
    wh = size(fb)
    glDisable(GL_SCISSOR_TEST)
    glDisable(GL_STENCIL_TEST)
    set_draw_buffers(fb)
    glViewport(0, 0, wh[1], wh[2])
    glClearStencil(0)
    glClear(GL_STENCIL_BUFFER_BIT)

    # prepare for stencil being used
    glEnable(GL_STENCIL_TEST)
    glEnable(GL_SCISSOR_TEST)
    glStencilFunc(GL_EQUAL, 0, 0xff)
    return
end

function update_stencil!(screen, glscene, fb)
    GLAbstraction.bind(fb)

    # draw 1 to stencil buffer for every cleared scene viewport
    glEnable(GL_SCISSOR_TEST)
    glEnable(GL_STENCIL_TEST)
    glStencilFunc(GL_ALWAYS, 0, 0xff)
    glClearStencil(1)
    ppu = screen.px_per_unit[]
    scene = glscene.scene
    if scene.visible[] && scene.clear[]
        a = viewport(scene)[]
        rt = (round.(Int, ppu .* minimum(a))..., round.(Int, ppu .* widths(a))...)
        glScissor(rt...)
        glClear(GL_STENCIL_BUFFER_BIT)
    end
    glDisable(GL_SCISSOR_TEST)

    # And reset to a useful stencil function
    glStencilFunc(GL_EQUAL, 0, 0xff)

    return
end

function run_stage(screen, glscenes, stage::RenderPlots)
    # Somehow errors in here get ignored silently!?
    try
        require_context(screen.glscreen)
        GLAbstraction.bind(stage.framebuffer)

        # This is clearing specific to how we render plots, not scene related clearing
        wh = size(stage.framebuffer)
        for (idx, color) in stage.clear
            idx <= stage.framebuffer.counter || continue
            glDrawBuffer(stage.framebuffer.attachments[idx])
            glViewport(0, 0, wh[1], wh[2])
            glScissor(0, 0, wh[1], wh[2])
            glClearColor(color...)
            glClear(GL_COLOR_BUFFER_BIT)
        end

        set_draw_buffers(stage.framebuffer)

        prepare_stencil!(stage.framebuffer)

        ppu = screen.px_per_unit[]

        group_end = length(glscenes)
        while group_end > 0
            # Find groups of scenes that don't clear. Render renderobjects in
            # those groups back to front, while the groups are generated
            # front to back to decrease overdraw
            group_start = group_end + 1
            while group_start > 1
                group_start -= 1
                if glscenes[group_start].scene.clear[]
                    break
                end
            end

            for glscene in view(glscenes, group_start:group_end) # back to front
                scene = glscene.scene
                if isnothing(scene) || !scene.visible[]
                    continue
                end

                a = viewport(scene)[]

                require_context(screen.glscreen)
                glViewport(round.(Int, ppu .* minimum(a))..., round.(Int, ppu .* widths(a))...)
                glScissor(round.(Int, ppu .* minimum(a))..., round.(Int, ppu .* widths(a))...)

                for elem in glscene.renderobjects
                    elem.visible && haskey(elem.variants, stage.target) || continue
                    elem[:px_per_unit] = ppu
                    stage.prerender(elem[:overdraw]::UInt8)
                    render(elem, elem.variants[stage.target])
                end
            end

            # now exclude the cleared scene from the next group
            update_stencil!(screen, glscenes[group_start], stage.framebuffer)

            # And prepare the next group
            group_end = group_start - 1
        end

        glDisable(GL_STENCIL_TEST)
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

function run_stage(screen, glscene, stage::RenderPass{:OIT})
    # Blend transparent onto opaque
    wh = size(stage.framebuffer)
    set_draw_buffers(stage.framebuffer)
    glViewport(0, 0, wh[1], wh[2])
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

    # blur occlusion and combine with color
    shader = LazyShader(
        screen.shader_cache,
        loadshader("postprocessing/fullscreen.vert"),
        loadshader("postprocessing/SSAO_blur.frag")
    )
    inputs[:inv_texel_size] = rcpframe(size(screen))
    inputs[:blur_range] = Int32(2)
    robj = PostProcessRenderObject(screen, inputs, shader)

    return RenderPass{:SSAO2}(framebuffer, robj)
end

function run_stage(screen, glscenes, stage::RenderPass{:SSAO1})
    set_draw_buffers(stage.framebuffer)  # occlusion buffer

    wh = size(stage.framebuffer)
    glViewport(0, 0, wh[1], wh[2])
    glEnable(GL_SCISSOR_TEST)
    ppu = (x) -> round.(Int, screen.px_per_unit[] .* x)

    data = stage.robj.uniforms
    # TODO: Make SSAO a render pipeline setting
    for glscene in reverse(glscenes)
        scene = glscene.scene
        # Select the area of one leaf scene
        # This should be per scene because projection may vary between
        # scenes. It should be a leaf scene to avoid repeatedly shading
        # the same region (though this is not guaranteed...)
        if !isempty(scene.children) || isempty(scene.plots) ||
                !any(p -> to_value(get(p.attributes, :ssao, false)), scene.plots)
            continue
        end
        a = viewport(scene)[]
        glScissor(ppu(minimum(a))..., ppu(widths(a))...)
        # update uniforms
        data[:projection] = Mat4f(scene.camera.projection[])
        data[:bias] = scene.ssao.bias[]
        data[:radius] = scene.ssao.radius[]
        data[:noise_scale] = Vec2f(0.25f0 .* size(stage.framebuffer))
        GLAbstraction.render(stage.robj)
    end

    glDisable(GL_SCISSOR_TEST)

    return
end

function run_stage(screen, glscenes, stage::RenderPass{:SSAO2})
    # TODO: SSAO doesn't copy the full color buffer and writes to a buffer
    #       previously used for normals. Figure out a better solution than this:
    clear_scenes!(screen, glscenes, stage.framebuffer)

    # SSAO - blur occlusion and apply to color
    set_draw_buffers(stage.framebuffer)  # color buffer
    wh = size(stage.framebuffer)
    glViewport(0, 0, wh[1], wh[2])

    glEnable(GL_SCISSOR_TEST)
    ppu = (x) -> round.(Int, screen.px_per_unit[] .* x)
    data = stage.robj.uniforms
    # TODO: require full render pipeline to have consistent SSAO settings?
    for glscene in reverse(glscenes)
        scene = glscene.scene
        # Select the area of one leaf scene
        isempty(scene.children) || continue
        a = viewport(scene)[]
        glScissor(ppu(minimum(a))..., ppu(widths(a))...)
        # update uniforms
        data[:blur_range] = scene.ssao.blur
        data[:inv_texel_size] = rcpframe(size(stage.framebuffer))
        GLAbstraction.render(stage.robj)
    end
    glDisable(GL_SCISSOR_TEST)

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

function run_stage(screen, glscene, stage::RenderPass{:FXAA1})
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

function run_stage(screen, glscene, stage::RenderPass{:FXAA2})
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

function run_stage(screen, glscene, stage::MSAAResolve)
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

function run_stage(screen, glscene, stage::BlitToScreen)
    copy_to_screen(screen, stage.source_framebuffer)
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
