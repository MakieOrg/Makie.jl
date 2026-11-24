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
"""
abstract type GLRenderStage end
run_stage(screen, glscenes, ::GLRenderStage) = nothing

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
    scene_stages::UnitRange{Int}
end

function GLRenderGraph(parent::Makie.LoweredRenderGraph, stages::Vector{GLRenderStage})
    return GLRenderGraph(parent, stages, scene_stage_range(parent))
end

function GLRenderGraph()
    return GLRenderGraph(Makie.LoweredRenderGraph(), GLRenderStage[])
end

function scene_stage_range(pipeline)
    isempty(pipeline.stages) && return 1:0
    names = (:SceneClear, :Render, Symbol("OIT Render"), :OIT, Symbol("SSAO Render"), :SSAO1, :SSAO2)
    start = findfirst(stage -> stage.name === :SceneClear, pipeline.stages)
    stop = findlast(stage -> stage.name in names, pipeline.stages)
    isnothing(start) && return 1:0
    stages = start:stop
    # A custom pipeline can interleave these passes with other stages or use
    # different output buffers. Keep its explicit frame-wide order in that case.
    all(i -> pipeline.stages[i].name in names, stages) || return 1:0
    display = Dict(pipeline.stages[end].inputs)
    clear = Dict(pipeline.stages[start].outputs)
    clear_color = get(clear, :color, 0)
    clear_color != 0 || return 1:0
    ssao_passes = filter(i -> pipeline.stages[i].name === :SSAO2, stages)
    if isempty(ssao_passes)
        clear_color == display[:color] || return 1:0
    elseif length(ssao_passes) != 1 || get(Dict(pipeline.stages[only(ssao_passes)].inputs), :color, 0) != clear_color
        return 1:0
    end
    for i in stages
        stage = pipeline.stages[i]
        ssao_source = stage.name in (:SceneClear, Symbol("SSAO Render"))
        for (name, index) in stage.outputs
            if name in (:depth, :objectid, :color)
                target = name === :color && ssao_source ? clear : display
                get(target, name, 0) == index || return 1:0
            end
        end
    end
    return stages
end

# Allow iteration
function Base.iterate(pipeline::GLRenderGraph, idx = 1)
    idx > length(pipeline) && return nothing
    return (pipeline.stages[idx], idx + 1)
end
Base.length(pipeline::GLRenderGraph) = length(pipeline.stages)
Base.eltype(::Type{GLRenderGraph}) = GLRenderStage

# render each stage
function run_frame_stages(screen, glscenes, stages, indices, capture)
    for i in indices
        require_context(screen.glscreen)
        run_stage(screen, glscenes, stages[i])
        capture(i)
    end
    return
end

function render_frame(screen, glscenes, pipeline::GLRenderGraph, capture = Returns(nothing))
    stages = pipeline.stages
    scene_stages = pipeline.scene_stages
    if isempty(scene_stages) || length(glscenes) <= 1
        run_frame_stages(screen, glscenes, stages, eachindex(stages), capture)
    else
        run_frame_stages(screen, glscenes, stages, 1:(first(scene_stages) - 1), capture)
        render_scenes(screen, glscenes, stages, scene_stages, capture)
        run_frame_stages(screen, glscenes, stages, (last(scene_stages) + 1):length(stages), capture)
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

function scene_pixel_viewport(scene, ppu)
    bounds = viewport(scene)[]
    return (round.(Int, ppu .* minimum(bounds))..., round.(Int, ppu .* widths(bounds))...)
end

function render_scenes(screen, glscenes, stages, indices, capture)
    framebuffer = display_framebuffer(screen)
    ppu = screen.px_per_unit[]
    ssao_variant = nothing
    oit_variant = nothing
    for idx in indices
        stage = stages[idx]
        stage isa RenderPlots || continue
        if stage.target === :forward_render_objectid_geom
            ssao_variant = stage.variant
        elseif stage.target === :forward_render_objectid_oit
            oit_variant = stage.variant
        elseif haskey(stage.framebuffer, :depth) && haskey(stage.framebuffer, :objectid)
            framebuffer = stage.framebuffer
        end
    end

    # A full-window clear replaces everything that would have been drawn earlier.
    w, h = size(framebuffer)
    first_scene = findlast(glscenes) do glscene
        scene = glscene.scene
        scene.visible[] && scene.clear[] || return false
        x, y, width, height = scene_pixel_viewport(scene, ppu)
        return x <= 0 && y <= 0 && x + width >= w && y + height >= h
    end
    start = something(first_scene, 1)
    # With only clearing scenes, stencil masking already isolates visible draws.
    draws_without_clear(g) = g.scene.visible[] && !g.scene.clear[] && !isempty(g.renderobjects)
    if start == 1 && ssao_variant === nothing && !any(draws_without_clear, @view glscenes[2:end])
        return run_frame_stages(screen, glscenes, stages, indices, capture)
    end

    glDisable(GL_STENCIL_TEST)
    glEnable(GL_SCISSOR_TEST)
    try
        depth_written = false
        for i in start:length(glscenes)
            glscene = glscenes[i]
            scene = glscene.scene
            scene.visible[] || continue
            area = scene_pixel_viewport(scene, ppu)
            (area[3] <= 0 || area[4] <= 0) && continue
            clear = scene.clear[] || i == 1
            has_plots = !isempty(glscene.renderobjects)
            (clear || has_plots) || continue
            glScissor(area...)

            if clear
                set_draw_buffers(framebuffer)
            elseif depth_written
                GLAbstraction.bind(framebuffer)
            end
            if depth_written
                glDepthMask(GL_TRUE)
                glClear(GL_DEPTH_BUFFER_BIT)
            end
            if clear
                c = scene.clear[] ? scene.backgroundcolor[] : RGBAf(1, 1, 1, 1)
                rgba = (Float32(red(c)), Float32(green(c)), Float32(blue(c)), Float32(alpha(c)))
                glClearBufferfv(GL_COLOR, framebuffer.name2idx[:color] - 1, Ref(rgba))
                if depth_written
                    glClearBufferuiv(GL_COLOR, framebuffer.name2idx[:objectid] - 1, Ref(ntuple(_ -> UInt32(0), 4)))
                end
            end
            depth_written |= has_plots

            ssao = ssao_variant !== nothing && any(obj -> obj.visible && haskey(obj.variants, ssao_variant), glscene.renderobjects)
            oit = oit_variant !== nothing && any(obj -> obj.visible && haskey(obj.variants, oit_variant), glscene.renderobjects)
            scene_pass = (; glscene, area, ppu, ssao, oit)
            for idx in indices
                run_scene_stage(screen, scene_pass, stages[idx])
                capture(idx)
            end
        end
    finally
        glDisable(GL_SCISSOR_TEST)
    end
    return
end

function run_scene_stage(screen, view, stage::ClearStage)
    framebuffer = display_framebuffer(screen)
    if view.ssao && get_buffer(stage.framebuffer, :color) !== get_buffer(framebuffer, :color)
        # SSAO shades a separate color target. Start it with the accumulated
        # color so the scene can blend over the previous scenes.
        glBindFramebuffer(GL_READ_FRAMEBUFFER, framebuffer.id)
        glReadBuffer(get_attachment(framebuffer, :color))
        glBindFramebuffer(GL_DRAW_FRAMEBUFFER, stage.framebuffer.id)
        glDrawBuffer(get_attachment(stage.framebuffer, :color))
        x, y, w, h = view.area
        glBlitFramebuffer(x, y, x + w, y + h, x, y, x + w, y + h, GL_COLOR_BUFFER_BIT, GL_NEAREST)
    end
    return
end

function clear_scenes!(screen, glscenes, framebuffer)
    set_draw_buffers(framebuffer, :color)

    # Standard blending preserves the background alpha, which FXAA uses.
    if !isempty(glscenes) && !first(glscenes).scene.clear[]
        glDisable(GL_SCISSOR_TEST)
        glClearColor(1, 1, 1, 1)
        glClear(GL_COLOR_BUFFER_BIT)
    end

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
    variant::Symbol
    prerender::Pre

    function RenderPlots(framebuffer, clear, ssao, transparency, fxaa, target, prerender::Pre) where {Pre}
        # Multiple passes can use the same shader outputs with disjoint filters.
        variant = Symbol(target, '_', Int(ssao), Int(transparency), Int(fxaa))
        return new{Pre}(framebuffer, clear, ssao, transparency, fxaa, target, variant, prerender)
    end
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
    glEnable(GL_STENCIL_TEST)
    glStencilFunc(GL_ALWAYS, 0, 0xff)
    glClearStencil(1)
    ppu = screen.px_per_unit[]
    if glscene.scene.visible[] && glscene.scene.clear[]
        a = viewport(glscene.scene)[]
        rt = (round.(Int, ppu .* minimum(a))..., round.(Int, ppu .* widths(a))...)
        glScissor(rt...)
        glClear(GL_STENCIL_BUFFER_BIT)
    end
    # And reset to a useful stencil function
    glStencilFunc(GL_EQUAL, 0, 0xff)

    return
end

function clear_plot_buffers!(stage::RenderPlots)
    set_draw_buffers(stage.framebuffer)
    for (idx, color) in stage.clear
        idx <= stage.framebuffer.counter || continue
        glClearBufferfv(GL_COLOR, idx - 1, Ref(Tuple(color)))
    end
    return
end

function draw_plots!(stage::RenderPlots, glscene, ppu)
    for elem in glscene.renderobjects
        elem.visible || continue
        instructions = get(elem.variants, stage.variant, nothing)
        instructions === nothing && continue
        elem[:px_per_unit] = ppu
        stage.prerender(elem[:overdraw]::UInt8)
        render(elem, instructions)
    end
    return
end

function run_scene_stage(screen, view, stage::RenderPlots)
    stage.target === :forward_render_objectid_geom && !view.ssao && return
    stage.target === :forward_render_objectid_oit && !view.oit && return
    isempty(view.glscene.renderobjects) && return
    glViewport(view.area...)
    clear_plot_buffers!(stage)
    draw_plots!(stage, view.glscene, view.ppu)
    return
end

function run_stage(screen, glscenes, stage::RenderPlots)
    # Somehow errors in here get ignored silently!?
    try
        require_context(screen.glscreen)
        # This is clearing specific to how we render plots, not scene related clearing
        glDisable(GL_SCISSOR_TEST)
        clear_plot_buffers!(stage)

        prepare_stencil!(stage.framebuffer)

        ppu = screen.px_per_unit[]

        # Why find blocks of scenes?
        # When rendering back to front, we could draw in regions that are later
        # cleared. These draws are a complete waste. To avoid them, we want to
        # render scenes front to back. Scenes that don't clear, however, should
        # still render back-to-front to have the correct layering.
        # To avoid unnecessary draws but still keep the clearing correct, we
        # search for clear = [true, false, ..., false] blocks of scenes in
        # front-to-back order, draw the scenes of this block in back-to-front
        # order (getting correct layering) and then mark the cleared area with
        # the stencil buffer to avoid lower scenes from drawing there.

        start = length(glscenes) + 1
        while start > 1
            # The first block can start with a non-clearing root scene.
            stop = start - 1
            start = 1
            for i in stop:-1:2
                if glscenes[i].scene.clear[]
                    start = i
                    break
                end
            end

            # Render that block back to front
            for glscene in view(glscenes, start:stop)
                scene = glscene.scene
                scene.visible[] || continue
                a = viewport(scene)[]

                require_context(screen.glscreen)
                glViewport(round.(Int, ppu .* minimum(a))..., round.(Int, ppu .* widths(a))...)
                glScissor(round.(Int, ppu .* minimum(a))..., round.(Int, ppu .* widths(a))...)

                draw_plots!(stage, glscene, ppu)
            end

            update_stencil!(screen, glscenes[start], stage.framebuffer)
        end
        glDisable(GL_SCISSOR_TEST)
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

function run_stage(screen, glscenes, stage::RenderPass{:OIT})
    # Blend transparent onto opaque
    wh = size(stage.framebuffer)
    set_draw_buffers(stage.framebuffer)
    glViewport(0, 0, wh[1], wh[2])
    GLAbstraction.render(stage.robj)
    return
end

function run_scene_stage(screen, view, stage::RenderPass{:OIT})
    view.oit || return
    return run_stage(screen, (), stage)
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
    inputs[:scene_viewport] = Vec4f(0, 0, 1, 1)
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
    inputs[:scene_viewport] = Vec4f(0, 0, 1, 1)
    robj = PostProcessRenderObject(screen, inputs, shader)

    return RenderPass{:SSAO2}(framebuffer, robj)
end

function render_ssao!(stage::RenderPass{:SSAO1}, scene, area)
    set_draw_buffers(stage.framebuffer)  # occlusion buffer
    wh = size(stage.framebuffer)
    glViewport(0, 0, wh[1], wh[2])
    data = stage.robj.uniforms
    data[:projection] = Mat4f(scene.camera.projection[])
    data[:bias] = scene.ssao.bias[]
    data[:radius] = scene.ssao.radius[]
    data[:noise_scale] = Vec2f(0.25f0 .* wh)
    data[:scene_viewport] = Vec4f(area) ./ Vec4f(wh..., wh...)
    GLAbstraction.render(stage.robj)
    return
end

function run_scene_stage(screen, view, stage::RenderPass{:SSAO1})
    view.ssao || return
    return render_ssao!(stage, view.glscene.scene, view.area)
end

function run_stage(screen, glscenes, stage::RenderPass{:SSAO1})
    glEnable(GL_SCISSOR_TEST)
    ppu = (x) -> round.(Int, screen.px_per_unit[] .* x)

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
        area = (ppu(minimum(a))..., ppu(widths(a))...)
        glScissor(area...)
        render_ssao!(stage, scene, area)
    end

    glDisable(GL_SCISSOR_TEST)

    return
end

function render_ssao!(stage::RenderPass{:SSAO2}, scene, area)
    set_draw_buffers(stage.framebuffer)
    wh = size(stage.framebuffer)
    glViewport(0, 0, wh[1], wh[2])
    data = stage.robj.uniforms
    data[:blur_range] = scene.ssao.blur[]
    data[:inv_texel_size] = rcpframe(wh)
    data[:scene_viewport] = Vec4f(area) ./ Vec4f(wh..., wh...)
    GLAbstraction.render(stage.robj)
    return
end

function run_scene_stage(screen, view, stage::RenderPass{:SSAO2})
    view.ssao || return
    return render_ssao!(stage, view.glscene.scene, view.area)
end

function run_stage(screen, glscenes, stage::RenderPass{:SSAO2})
    # TODO: SSAO doesn't copy the full color buffer and writes to a buffer
    #       previously used for normals. Figure out a better solution than this:
    clear_scenes!(screen, glscenes, stage.framebuffer)

    glEnable(GL_SCISSOR_TEST)
    ppu = (x) -> round.(Int, screen.px_per_unit[] .* x)
    # TODO: require full render pipeline to have consistent SSAO settings?
    for glscene in reverse(glscenes)
        scene = glscene.scene
        # Select the area of one leaf scene
        isempty(scene.children) || continue
        a = viewport(scene)[]
        area = (ppu(minimum(a))..., ppu(widths(a))...)
        glScissor(area...)
        render_ssao!(stage, scene, area)
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
