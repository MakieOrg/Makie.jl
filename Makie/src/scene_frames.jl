function connect_frame_attribute!(scene::Scene, target::Observable, value)
    if value isa Union{Observable, Computed}
        map!(identity, scene, target, value)
    else
        target[] = value
    end
    return target
end

frame_translation(v::VecTypes{2}) = Mat3f(1, 0, 0, 0, 1, 0, v[1], v[2], 1)

function frame_rotation(angle::Real, center::VecTypes{2} = Vec2f(0))
    s, c = sincos(Float32(angle))
    rotation = Mat3f(c, s, 0, -s, c, 0, 0, 0, 1)
    return frame_translation(center) * rotation * frame_translation(-center)
end

function frame_scaling(factor::VecTypes{2}, center::VecTypes{2} = Vec2f(0))
    return frame_translation(center) * Mat3f(factor[1], 0, 0, 0, factor[2], 0, 0, 0, 1) * frame_translation(-center)
end
frame_scaling(factor::Real, center::VecTypes{2} = Vec2f(0)) = frame_scaling(Vec2f(factor), center)

function cumulative_frame_transform(scene::Scene)
    local_transform = scene.frame_transform[]
    return isroot(scene) ? local_transform : cumulative_frame_transform(parent(scene)) * local_transform
end

function viewport_to_figure_px(viewport::Rect2)
    origin = minimum(viewport)
    half = widths(viewport) ./ 2
    return Mat3f(half[1], 0, 0, 0, half[2], 0, origin[1] + half[1], origin[2] + half[2], 1)
end

function figure_px_to_ndc(screen_size)
    return Mat3f(2 / screen_size[1], 0, 0, 0, 2 / screen_size[2], 0, -1, -1, 1)
end

function affine2d_to_clipspace(G::Mat3f)
    return Mat4f(
        G[1, 1], G[2, 1], 0, 0,
        G[1, 2], G[2, 2], 0, 0,
        0, 0, 1, 0,
        G[1, 3], G[2, 3], 0, 1
    )
end

"""
    scene_frame_matrix(scene)

Maps the clip space of `scene` (as if its viewport were the whole render target)
to the clip space of the root scene, including all frame transforms of `scene`
and its ancestors. Acting on homogeneous clip coordinates keeps perspective
projections and depth intact.
"""
function scene_frame_matrix(scene::Scene)
    screen_size = widths(viewport(root(scene))[])
    G = figure_px_to_ndc(screen_size) * cumulative_frame_transform(scene) *
        viewport_to_figure_px(Rect2f(viewport(scene)[]))
    return affine2d_to_clipspace(G)
end

function figure_px_to_scene_px(scene::Scene, p::VecTypes{2})
    q = inv(cumulative_frame_transform(scene)) * Vec3f(p[1], p[2], 1)
    return Point2f(q[1], q[2])
end

has_identity_frame(scene::Scene) = cumulative_frame_transform(scene) ≈ Mat3f(I)

function triangle_corners(shape)
    mesh = GeometryBasics.triangle_mesh(shape)
    positions = decompose(Point2f, mesh)
    return [positions[i] for face in faces(mesh) for i in face]
end

clip_shape_corners(::Automatic, widths) = triangle_corners(Rect2f(0, 0, widths...))
clip_shape_corners(points::AbstractVector{<:VecTypes{2}}, widths) = triangle_corners(Polygon(Point2f.(points)))
clip_shape_corners(shape, widths) = triangle_corners(shape)

"""
    clip_triangles(scene)::Union{Nothing, Vector{Point2f}}

Triangle corners of the clip region of `scene` in its local clip space, or
`nothing` if the scene does not clip.
"""
function clip_triangles(scene::Scene)
    shape = scene.clip[]
    isnothing(shape) && return nothing
    w = widths(viewport(scene)[])
    any(iszero, w) && return Point2f[]
    return map(p -> Point2f(2 .* p ./ w .- 1), clip_shape_corners(shape, w))
end

zorder(scene::Scene) = scene.zorder[]
zorder(plot::AbstractPlot) = haskey(plot.attributes, :zorder) ? Float32(plot.zorder[]) : 0.0f0

"""
    render_order(scene)

Plots and child scenes of `scene` in the order they should be drawn: insertion
order, stably sorted by `zorder`. A scene is a stacking context, so the `zorder`
of its descendants never reorders them relative to the scene's siblings.
"""
function render_order(scene::Scene)
    members = Base.IdSet{Any}(scene.plots)
    union!(members, scene.children)
    items = Union{AbstractPlot, Scene}[x for x in scene.draw_order if x in members]
    listed = Base.IdSet{Any}(items)
    for x in Iterators.flatten((scene.plots, scene.children))
        x in listed || push!(items, x)
    end
    return sort!(items; by = zorder, alg = Base.Sort.DEFAULT_STABLE)
end

function render_order(plot::AbstractPlot)
    return sort(plot.plots; by = zorder, alg = Base.Sort.DEFAULT_STABLE)
end
