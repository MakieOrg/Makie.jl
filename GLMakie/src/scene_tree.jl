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
    # `Makie.render_order` of scenes and recipe plots, emptied on structural or zorder changes
    orders::IdDict{Any, Vector{Union{AbstractPlot, Scene}}}
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
    orders = IdDict{Any, Vector{Union{AbstractPlot, Scene}}}()
    return SceneTreeRender(framebuffer, fill, composite, GLFramebuffer[], orders)
end

n_render_items(scene::Scene) = length(scene.plots) + length(scene.children)
n_render_items(plot::AbstractPlot) = length(plot.plots)

# The length check catches scenes added or removed without a plot insertion,
# zorder changes and plot insertions/deletions invalidate explicitly
function render_order(stage::SceneTreeRender, x::Union{Scene, AbstractPlot})
    order = get(stage.orders, x, nothing)
    if isnothing(order) || length(order) != n_render_items(x)
        order = convert(Vector{Union{AbstractPlot, Scene}}, Makie.render_order(x))
        stage.orders[x] = order
    end
    return order
end

invalidate_render_order!(::GLRenderStage) = nothing
invalidate_render_order!(stage::SceneTreeRender) = empty!(stage.orders)
function invalidate_render_order!(screen::Screen)
    foreach(invalidate_render_order!, screen.render_pipeline.stages)
    return
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

const NO_PIXELS = Rect2i(0, 0, 0, 0)

isempty_px(r::Rect2i) = any(<=(0), widths(r))

function intersect_px(a::Rect2i, b::Rect2i)
    lo = max.(minimum(a), minimum(b))
    hi = min.(maximum(a), maximum(b))
    return Rect2i(lo, max.(hi .- lo, 0))
end

function union_px(a::Rect2i, b::Rect2i)
    isempty_px(a) && return b
    isempty_px(b) && return a
    lo = min.(minimum(a), minimum(b))
    return Rect2i(lo, max.(maximum(a), maximum(b)) .- lo)
end

# `outer` contains `inner`
covers_px(outer::Rect2i, inner::Rect2i) = isempty_px(inner) || (all(minimum(outer) .<= minimum(inner)) && all(maximum(inner) .<= maximum(outer)))

set_scissor!(r::Rect2i) = glScissor(minimum(r)..., widths(r)...)

"""
    device_bounds(scene, rect, ppu)

Device pixel bounds of `rect` (viewport relative figure pixels of `scene`) after
the scene's frame transform. The second return value is true if the transformed
rect is exactly that pixel aligned rectangle, i.e. clipping to it needs nothing
but the scissor. Otherwise the bounds are grown by a pixel for antialiasing.
"""
function device_bounds(scene::Scene, rect::Rect2, ppu)
    M = Makie.cumulative_frame_transform(scene)
    origin = Vec2f(minimum(Makie.viewport(scene)[]))
    to_device(p) = (q = M * Vec3f((origin .+ p)..., 1); Vec2f(ppu * q[1], ppu * q[2]))
    (x0, y0), (x1, y1) = minimum(rect), maximum(rect)
    corners = (to_device(Vec2f(x0, y0)), to_device(Vec2f(x1, y0)), to_device(Vec2f(x0, y1)), to_device(Vec2f(x1, y1)))
    lo = reduce((a, b) -> min.(a, b), corners)
    hi = reduce((a, b) -> max.(a, b), corners)
    on_pixel_edge(x) = abs(x - round(x)) < 1.0f-3
    exact = iszero(M[1, 2]) && iszero(M[2, 1]) && all(on_pixel_edge, lo) && all(on_pixel_edge, hi)
    lo_px = exact ? round.(Int, lo) : floor.(Int, lo) .- 1
    hi_px = exact ? round.(Int, hi) : ceil.(Int, hi) .+ 1
    return Rect2i(lo_px, max.(hi_px .- lo_px, 0)), exact
end

clip_device_bounds(scene::Scene, region::Rect2, ppu) = device_bounds(scene, region, ppu)
clip_device_bounds(scene::Scene, region, ppu) = (first(device_bounds(scene, Makie.clip_bounds(region), ppu)), false)

mutable struct TreeTraversal
    target::GLFramebuffer
    stencil_level::Int
    layer_depth::Int
    clips::ClipStack
    ppu::Float32
    # Device pixels all draws are restricted to: the bounds of the enclosing clips.
    # Rect clips that are exactly pixel aligned are applied by the scissor alone.
    scissor::Rect2i
    # Conservative device pixel bounds of the depth values written since the last reset
    depth_dirty::Rect2i
end

# Every enclosing clip is applied by the scissor, so clearing a rect inside the
# scissor touches exactly the pixels a clipped quad would cover
scissor_only(state::TreeTraversal) = state.clips.count == 0 && state.stencil_level == 0

function cleared_depth!(state::TreeTraversal, r::Rect2i)
    covers_px(r, state.depth_dirty) && (state.depth_dirty = NO_PIXELS)
    return
end

function clear_rect!(state::TreeTraversal, r::Rect2i; color = nothing)
    set_scissor!(r)
    glDepthMask(GL_TRUE)
    glClearBufferfv(GL_DEPTH, 0, Float32[1])
    if !isnothing(color)
        glColorMask(GL_TRUE, GL_TRUE, GL_TRUE, GL_TRUE)
        glClearBufferfv(GL_COLOR, 0, Float32[red(color), green(color), blue(color), alpha(color)])
        glClearBufferuiv(GL_COLOR, 1, UInt32[0, 0, 0, 0])
    end
    set_scissor!(state.scissor)
    cleared_depth!(state, r)
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

# `bounds` are the device pixel bounds of `corners`, `exact` if `corners` cover exactly `bounds`
function fill_background!(stage, state, corners, frame, color, bounds::Rect2i, exact::Bool)
    if exact && scissor_only(state) && alpha(color) == 1
        clear_rect!(state, intersect_px(bounds, state.scissor); color)
    else
        enable_scene_blending()
        stage.fill[:color] = Vec4f(red(color), green(color), blue(color), alpha(color))
        fill_far_depth!(stage, state, corners, frame)
    end
    return
end

function reset_depth!(stage, state, corners, frame, bounds::Rect2i, exact::Bool)
    dirty = intersect_px(intersect_px(bounds, state.scissor), state.depth_dirty)
    isempty_px(dirty) && return
    if exact && scissor_only(state)
        clear_rect!(state, dirty)
    else
        glColorMask(GL_FALSE, GL_FALSE, GL_FALSE, GL_FALSE)
        fill_far_depth!(stage, state, corners, frame)
        glColorMask(GL_TRUE, GL_TRUE, GL_TRUE, GL_TRUE)
    end
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
    # scenes without plots are not registered by `insert!`, but changes to them
    # (zorder, background, visibility) still need to invalidate and redraw
    add_scene!(screen, scene)
    scene.visible[] || return
    viewport_widths = widths(Makie.viewport(scene)[])
    any(iszero, viewport_widths) && return
    region = Makie.isroot(scene) && scene.clip[] === Makie.automatic ? nothing : Makie.clip_region(scene)

    parent_scissor = state.scissor
    clip_by_scissor = false
    if !isnothing(region)
        clip_bounds, clip_by_scissor = clip_device_bounds(scene, region, state.ppu)
        state.scissor = intersect_px(parent_scissor, clip_bounds)
        # clipped away entirely, e.g. scrolled out of a pane
        if isempty_px(state.scissor)
            state.scissor = parent_scissor
            return
        end
        set_scissor!(state.scissor)
    end

    frame = Mat4f(Makie.scene_frame_matrix(scene))
    device_to_figure_px = device_px_inverse_frame(scene, state.ppu)
    analytic = !isnothing(region) && !clip_by_scissor && Makie.is_analytic_clip(region) && !isfull(state.clips)
    stencil_corners = !isnothing(region) && !clip_by_scissor && !analytic ? Makie.clip_triangles(region, scene) : nothing
    if analytic
        push_analytic_clip!(state.clips, scene, region, state.ppu)
    elseif !isnothing(stencil_corners)
        write_stencil!(stage, stencil_corners, frame, state.stencil_level, GL_INCR)
        state.stencil_level += 1
    end
    if isnothing(region)
        background_cover = viewport_triangles(scene)
        background_bounds, background_exact = device_bounds(scene, Rect2f(0, 0, viewport_widths...), state.ppu)
        composite_cover, composite_frame = FULLSCREEN_TRIANGLES, Mat4f(I)
    else
        cover = isnothing(stencil_corners) ? Makie.clip_cover_triangles(region, scene; pad = 3) : stencil_corners
        background_cover = cover
        background_bounds, background_exact = clip_bounds, clip_by_scissor
        composite_cover, composite_frame = cover, frame
    end

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
        fill_background!(stage, state, background_cover, frame, scene.backgroundcolor[], background_bounds, background_exact)
    elseif isolates_depth
        reset_depth!(stage, state, background_cover, frame, background_bounds, background_exact)
    end

    for child in render_order(stage, scene)
        if child isa Scene
            render_scene_tree!(screen, stage, child, state)
            bind_target(state.target)
            stencil_test(state.stencil_level)
        else
            render_plot_tree!(screen, stage, child, frame, state, device_to_figure_px)
        end
    end

    if isolates_depth
        reset_depth!(stage, state, background_cover, frame, background_bounds, background_exact)
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
    if state.scissor != parent_scissor
        state.scissor = parent_scissor
        set_scissor!(parent_scissor)
    end
    return
end

function render_plot_tree!(screen, stage::SceneTreeRender, plot::Plot, frame::Mat4f, state::TreeTraversal, device_to_figure_px::Mat3f)
    robj = get(screen.cache, objectid(plot), nothing)
    if isnothing(robj)
        for child in render_order(stage, plot)
            render_plot_tree!(screen, stage, child, frame, state, device_to_figure_px)
        end
        return
    end
    (robj.visible && haskey(robj.variants, :forward_render_objectid)) || return
    robj[:px_per_unit] = screen.px_per_unit[]
    robj[:scene_frame] = frame
    robj[:device_to_figure_px] = device_to_figure_px
    set_clip_uniforms!(robj, state.clips)
    StandardPrerender()(robj[:overdraw]::UInt8)
    enable_scene_blending()
    render(robj, robj.variants[:forward_render_objectid])
    state.depth_dirty = union_px(state.depth_dirty, state.scissor)
    return
end

function run_stage(screen, glscene, stage::SceneTreeRender)
    root = screen.scene
    isnothing(root) && return
    require_context(screen.glscreen)
    bind_target(stage.framebuffer)
    glDisable(GL_SCISSOR_TEST)
    glClearColor(1, 1, 1, 1)
    glClearStencil(0)
    glDepthMask(GL_TRUE)
    glClear(GL_COLOR_BUFFER_BIT | GL_STENCIL_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
    glEnable(GL_STENCIL_TEST)
    target_px = Rect2i(0, 0, size(stage.framebuffer)...)
    state = TreeTraversal(stage.framebuffer, 0, 0, ClipStack(), screen.px_per_unit[], target_px, NO_PIXELS)
    glEnable(GL_SCISSOR_TEST)
    set_scissor!(target_px)
    try
        render_scene_tree!(screen, stage, root, state)
    finally
        glDisable(GL_STENCIL_TEST)
        glDisable(GL_SCISSOR_TEST)
        glColorMask(GL_TRUE, GL_TRUE, GL_TRUE, GL_TRUE)
    end
    return
end
