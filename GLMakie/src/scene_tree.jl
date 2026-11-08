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
        loadshader(fragment_shader),
        loadshader("scene_tree/clip_coverage.frag")
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

function construct(::Val{:SceneTree}, screen, framebuffer, inputs, parent)
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

const MAX_SCENE_CLIPS = 4

"""
Analytic clips of the scenes enclosing the current draw. The vectors have a
fixed length and are shared by reference with every render object's uniforms,
so pushing and popping only changes `count`.
"""
mutable struct ClipStack
    count::Int32
    frames::Vector{Mat3f}
    shapes::Vector{Vec4f}
    params::Vector{Vec4f}
end
ClipStack() = ClipStack(0, fill(Mat3f(I), MAX_SCENE_CLIPS), zeros(Vec4f, MAX_SCENE_CLIPS), zeros(Vec4f, MAX_SCENE_CLIPS))

isfull(stack::ClipStack) = stack.count >= MAX_SCENE_CLIPS

function Base.push!(stack::ClipStack, frame::Mat3f, shape::Vec4f, params::Vec4f)
    stack.count += 1
    stack.frames[stack.count] = frame
    stack.shapes[stack.count] = shape
    stack.params[stack.count] = params
    return stack
end
Base.pop!(stack::ClipStack) = (stack.count -= 1; stack)

function set_clip_uniforms!(robj::RenderObject, stack::ClipStack)
    robj[:scene_clip_count] = stack.count
    robj[:scene_clip_frames] = stack.frames
    robj[:scene_clip_shapes] = stack.shapes
    robj[:scene_clip_params] = stack.params
    return
end

const SECTOR_FULL_CIRCLE = Float32(pi) + 1.0f0

function clip_shape_uniforms(r::Rect2)
    return Vec4f((minimum(r) .+ widths(r) ./ 2)..., (widths(r) ./ 2)...), 0.0f0, 0.0f0, 0.0f0
end

function clip_shape_uniforms(s::Makie.AnnularSector)
    θmin, θmax = extrema(s.angles)
    half_angle = (θmax - θmin) / 2
    half_angle = half_angle >= pi - 1.0e-4 ? SECTOR_FULL_CIRCLE : Float32(half_angle)
    return Vec4f(s.center..., s.radii...), Float32((θmin + θmax) / 2), half_angle, 1.0f0
end

function push_analytic_clip!(stack::ClipStack, scene::Scene, region, ppu)
    M = Makie.cumulative_frame_transform(scene)
    origin = Vec2f(minimum(Makie.viewport(scene)[]))
    device_to_local = Makie.frame_translation(-origin) * inv(M) * Makie.frame_scaling(1 / ppu)
    px_scale = Float32(ppu * sqrt(abs(M[1, 1] * M[2, 2] - M[1, 2] * M[2, 1])))
    shape, θcenter, half_angle, kind = clip_shape_uniforms(region)
    return push!(stack, Mat3f(device_to_local), shape, Vec4f(θcenter, half_angle, kind, px_scale))
end

"""
Inverse of the scene's cumulative frame transform expressed in device pixels,
so `gl_FragCoord / px_per_unit` after it gives untransformed figure pixels.
"""
function device_px_inverse_frame(scene::Scene, ppu)
    M = Makie.cumulative_frame_transform(scene)
    return Mat3f(Makie.frame_scaling(ppu) * inv(M) * Makie.frame_scaling(1 / ppu))
end

mutable struct TreeTraversal
    target::GLFramebuffer
    stencil_level::Int
    layer_depth::Int
    clips::ClipStack
    ppu::Float32
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
    stage.fill[:scene_clip_count] = Int32(0)
    draw_triangles!(stage.fill, corners, frame)
    glColorMask(GL_TRUE, GL_TRUE, GL_TRUE, GL_TRUE)
    stencil_test(op == GL_INCR ? level + 1 : level - 1)
    return
end

function fill_far_depth!(stage, state, corners, frame)
    glEnable(GL_DEPTH_TEST)
    glDepthFunc(GL_ALWAYS)
    glDepthMask(GL_TRUE)
    stage.fill[:depth] = 1.0f0
    set_clip_uniforms!(stage.fill, state.clips)
    draw_triangles!(stage.fill, corners, frame)
    stage.fill[:depth] = 0.0f0
    glDepthFunc(GL_LEQUAL)
    return
end

function fill_background!(stage, state, corners, frame, color)
    enable_scene_blending()
    stage.fill[:color] = Vec4f(red(color), green(color), blue(color), alpha(color))
    fill_far_depth!(stage, state, corners, frame)
    return
end

function reset_depth!(stage, state, corners, frame)
    glColorMask(GL_FALSE, GL_FALSE, GL_FALSE, GL_FALSE)
    fill_far_depth!(stage, state, corners, frame)
    glColorMask(GL_TRUE, GL_TRUE, GL_TRUE, GL_TRUE)
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

viewport_triangles(scene) = Makie.clip_triangles(Rect2f(0, 0, widths(Makie.viewport(scene)[])...), scene)

function render_scene_tree!(screen, stage::SceneTreeRender, scene::Scene, state::TreeTraversal)
    scene.visible[] || return
    any(iszero, widths(Makie.viewport(scene)[])) && return
    frame = Mat4f(Makie.scene_frame_matrix(scene))
    device_to_figure_px = device_px_inverse_frame(scene, state.ppu)
    region = Makie.isroot(scene) && scene.clip[] === Makie.automatic ? nothing : Makie.clip_region(scene)

    analytic = !isnothing(region) && Makie.is_analytic_clip(region) && !isfull(state.clips)
    stencil_corners = !isnothing(region) && !analytic ? Makie.clip_triangles(region, scene) : nothing
    if analytic
        push_analytic_clip!(state.clips, scene, region, state.ppu)
        cover = Makie.clip_cover_triangles(region, scene; pad = 3)
    elseif !isnothing(stencil_corners)
        write_stencil!(stage, stencil_corners, frame, state.stencil_level, GL_INCR)
        state.stencil_level += 1
        cover = stencil_corners
    end
    background_cover = isnothing(region) ? viewport_triangles(scene) : cover
    composite_cover, composite_frame = isnothing(region) ? (FULLSCREEN_TRIANGLES, Mat4f(I)) : (cover, frame)

    parent_target = state.target
    scene_alpha = scene.alpha[]
    uses_layer = scene_alpha < 1
    if uses_layer
        state.layer_depth += 1
        state.target = layer!(stage, state.layer_depth)
        bind_target(state.target)
        glClearColor(0, 0, 0, 0)
        glClear(GL_COLOR_BUFFER_BIT)
    end
    stencil_test(state.stencil_level)

    isolates_depth = scene.clear_depth[] && !Makie.isroot(scene)
    if scene.clear[]
        fill_background!(stage, state, background_cover, frame, scene.backgroundcolor[])
    elseif isolates_depth
        reset_depth!(stage, state, background_cover, frame)
    end

    for child in Makie.render_order(scene)
        if child isa Scene
            render_scene_tree!(screen, stage, child, state)
            bind_target(state.target)
            stencil_test(state.stencil_level)
        else
            render_plot_tree!(screen, child, frame, state.clips, device_to_figure_px)
        end
    end

    if isolates_depth
        reset_depth!(stage, state, background_cover, frame)
    end

    if uses_layer
        state.target = parent_target
        state.layer_depth -= 1
        bind_target(parent_target)
        stencil_test(state.stencil_level)
        composite_layer!(stage, layer!(stage, state.layer_depth + 1), composite_cover, composite_frame, scene_alpha)
    end

    if analytic
        pop!(state.clips)
    elseif !isnothing(stencil_corners)
        write_stencil!(stage, stencil_corners, frame, state.stencil_level, GL_DECR)
        state.stencil_level -= 1
    end
    return
end

function render_plot_tree!(screen, plot::Plot, frame::Mat4f, clips::ClipStack, device_to_figure_px::Mat3f)
    robj = get(screen.cache, objectid(plot), nothing)
    if isnothing(robj)
        foreach(child -> render_plot_tree!(screen, child, frame, clips, device_to_figure_px), Makie.render_order(plot))
        return
    end
    (robj.visible && haskey(robj.variants, :forward_render_objectid)) || return
    robj[:px_per_unit] = screen.px_per_unit[]
    robj[:scene_frame] = frame
    robj[:device_to_figure_px] = device_to_figure_px
    set_clip_uniforms!(robj, clips)
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
    state = TreeTraversal(stage.framebuffer, 0, 0, ClipStack(), screen.px_per_unit[])
    try
        render_scene_tree!(screen, stage, root, state)
    finally
        glDisable(GL_STENCIL_TEST)
        glColorMask(GL_TRUE, GL_TRUE, GL_TRUE, GL_TRUE)
    end
    return
end
