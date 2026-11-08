"""
    SceneTreeRender <: GLRenderStage

Renders the scene tree depth first in `Makie.render_order`. Every scene's
content is drawn into the full-size target with `scene_frame` mapping the
scene's clip space to the target, so frame transforms never resample pixels.
Clip shapes are written to the stencil buffer as nesting levels. Scenes with
`alpha < 1` render into an offscreen layer which is composited afterwards.
Layers share the depth-stencil buffer of the main framebuffer and are reused
by siblings, so at most one layer per nesting depth of alpha scenes exists.
"""
mutable struct SceneTreeRender <: GLRenderStage
    framebuffer::GLFramebuffer
    fill::RenderObject
    composite::RenderObject
    layers::Vector{GLFramebuffer}
end

const FULLSCREEN_TRIANGLES = Point2f[(-1, -1), (1, -1), (1, 1), (-1, -1), (1, 1), (-1, 1)]

function triangle_robj(screen, fragment_shader, uniforms::Dict{Symbol, Any})
    shader = LazyShader(
        screen.shader_cache,
        loadshader("scene_tree/clip.vert"),
        loadshader(fragment_shader)
    )
    data = Dict{Symbol, Any}(
        :position => GLBuffer(screen.glscreen, FULLSCREEN_TRIANGLES),
        :scene_frame => Mat4f(I),
        :depth => 0.0f0,
        :indices => length(FULLSCREEN_TRIANGLES),
        :gl_primitive => GL_TRIANGLES,
    )
    merge!(data, uniforms)
    robj = RenderObject(screen.glscreen, data)
    add_instructions!(robj, :main, shader, pre = () -> nothing)
    return robj
end

function construct(::Val{:Render}, screen, framebuffer, inputs, parent)
    fill = triangle_robj(screen, "scene_tree/fill.frag", Dict{Symbol, Any}(:color => Vec4f(1)))
    composite = triangle_robj(
        screen, "scene_tree/composite.frag",
        Dict{Symbol, Any}(:alpha => 1.0f0, :layer_color => nothing, :layer_objectid => nothing)
    )
    return SceneTreeRender(framebuffer, fill, composite, GLFramebuffer[])
end

function on_resize(stage::SceneTreeRender, w, h)
    resize!(stage.framebuffer, w, h)
    foreach(layer -> resize!(layer, w, h), stage.layers)
    return
end

function destroy!(stage::SceneTreeRender)
    destroy!(stage.fill)
    destroy!(stage.composite)
    for layer in stage.layers
        foreach(GLAbstraction.free, layer.buffers[1:2])
        GLAbstraction.free(layer)
    end
    empty!(stage.layers)
    return
end

function new_layer(stage::SceneTreeRender)
    main = stage.framebuffer
    context = main.context
    layer = GLFramebuffer(context, size(main))
    color = Texture(context, RGBA{N0f8}, size(main), minfilter = :nearest, x_repeat = :clamp_to_edge)
    objectid = Texture(context, Vec{2, UInt32}, size(main), minfilter = :nearest, x_repeat = :clamp_to_edge)
    attach_colorbuffer(layer, :color, color)
    attach_colorbuffer(layer, :objectid, objectid)
    attach_depthstencilbuffer(layer, :depth, get_buffer(main, :depth))
    return layer
end

function layer!(stage::SceneTreeRender, depth::Int)
    while length(stage.layers) < depth
        push!(stage.layers, new_layer(stage))
    end
    return stage.layers[depth]
end

function bind_target(fb::GLFramebuffer)
    GLAbstraction.bind(fb)
    glDrawBuffers(2, fb.attachments[1:2])
    glViewport(0, 0, size(fb)...)
    return
end

function enable_scene_blending()
    glEnable(GL_BLEND)
    glBlendEquation(GL_FUNC_ADD)
    # premultiplied "over" for alpha so offscreen layers accumulate coverage
    glBlendFuncSeparate(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA, GL_ONE, GL_ONE_MINUS_SRC_ALPHA)
    glDisablei(GL_BLEND, 1)
    return
end

function draw_triangles!(robj::RenderObject, corners::Vector{Point2f}, frame::Mat4f)
    GLAbstraction.update!(robj.buffers[:position], corners)
    robj.indices = length(corners)
    robj[:scene_frame] = frame
    render(robj)
    return
end

function stencil_test(level::Int, op::GLenum = GL_KEEP)
    glStencilFunc(GL_EQUAL, level, 0xff)
    glStencilOp(GL_KEEP, GL_KEEP, op)
    return
end

function write_stencil!(stage, corners, frame, level, op)
    glColorMask(GL_FALSE, GL_FALSE, GL_FALSE, GL_FALSE)
    glDepthMask(GL_FALSE)
    glDisable(GL_DEPTH_TEST)
    stencil_test(level, op)
    draw_triangles!(stage.fill, corners, frame)
    glColorMask(GL_TRUE, GL_TRUE, GL_TRUE, GL_TRUE)
    stencil_test(op == GL_INCR ? level + 1 : level - 1)
    return
end

function fill_background!(stage, corners, frame, color)
    enable_scene_blending()
    glEnable(GL_DEPTH_TEST)
    glDepthFunc(GL_ALWAYS)
    glDepthMask(GL_TRUE)
    stage.fill[:color] = Vec4f(red(color), green(color), blue(color), alpha(color))
    stage.fill[:depth] = 1.0f0
    draw_triangles!(stage.fill, corners, frame)
    stage.fill[:depth] = 0.0f0
    return
end

function composite_layer!(stage, layer, corners, frame, scene_alpha)
    enable_scene_blending()
    glBlendFuncSeparate(GL_ONE, GL_ONE_MINUS_SRC_ALPHA, GL_ONE, GL_ONE_MINUS_SRC_ALPHA)
    glDisable(GL_DEPTH_TEST)
    glDepthMask(GL_FALSE)
    stage.composite[:layer_color] = get_buffer(layer, :color)
    stage.composite[:layer_objectid] = get_buffer(layer, :objectid)
    stage.composite[:alpha] = Float32(scene_alpha)
    draw_triangles!(stage.composite, corners, frame)
    return
end

function render_scene_tree!(screen, stage::SceneTreeRender, scene::Scene, target::GLFramebuffer, level::Int, layer_depth::Int)
    scene.visible[] || return
    frame = Mat4f(Makie.scene_frame_matrix(scene))
    clip_corners = Makie.clip_triangles(scene)
    clips = !isnothing(clip_corners)
    clips && isempty(clip_corners) && return
    coverage, coverage_frame = clips ? (clip_corners, frame) : (FULLSCREEN_TRIANGLES, Mat4f(I))

    if clips
        write_stencil!(stage, clip_corners, frame, level, GL_INCR)
        level += 1
    end

    scene_alpha = scene.alpha[]
    uses_layer = scene_alpha < 1
    content_target = target
    if uses_layer
        layer_depth += 1
        content_target = layer!(stage, layer_depth)
        bind_target(content_target)
        glClearColor(0, 0, 0, 0)
        glClear(GL_COLOR_BUFFER_BIT)
    end
    stencil_test(level)

    if scene.clear[]
        fill_background!(stage, coverage, coverage_frame, scene.backgroundcolor[])
    end

    for child in Makie.render_order(scene)
        if child isa Scene
            render_scene_tree!(screen, stage, child, content_target, level, layer_depth)
            bind_target(content_target)
            stencil_test(level)
        else
            render_plot_tree!(screen, child, frame)
        end
    end

    if uses_layer
        bind_target(target)
        stencil_test(level)
        composite_layer!(stage, content_target, coverage, coverage_frame, scene_alpha)
    end

    if clips
        write_stencil!(stage, clip_corners, frame, level, GL_DECR)
    end
    return
end

function render_plot_tree!(screen, plot::Plot, frame::Mat4f)
    robj = get(screen.cache, objectid(plot), nothing)
    if isnothing(robj)
        foreach(child -> render_plot_tree!(screen, child, frame), Makie.render_order(plot))
        return
    end
    (robj.visible && haskey(robj.variants, :forward_render_objectid)) || return
    robj[:px_per_unit] = screen.px_per_unit[]
    robj[:scene_frame] = frame
    StandardPrerender()(robj[:overdraw]::UInt8)
    enable_scene_blending()
    render(robj, robj.variants[:forward_render_objectid])
    return
end

function run_stage(screen, glscene, stage::SceneTreeRender)
    root = screen.scene
    isnothing(root) && return
    require_context(screen.glscreen)
    bind_target(stage.framebuffer)
    glClearColor(1, 1, 1, 1)
    glClearStencil(0)
    glClear(GL_COLOR_BUFFER_BIT | GL_STENCIL_BUFFER_BIT)
    glEnable(GL_STENCIL_TEST)
    try
        render_scene_tree!(screen, stage, root, stage.framebuffer, 0, 0)
    finally
        glDisable(GL_STENCIL_TEST)
        glColorMask(GL_TRUE, GL_TRUE, GL_TRUE, GL_TRUE)
    end
    return
end
