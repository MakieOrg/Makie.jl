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

"""
    AnnularSector(center, radii, angles)

A clip shape covering the ring between `radii = (rmin, rmax)` around `center`,
limited to the angular range `angles = (θmin, θmax)` (radians, counterclockwise
from +x). Coordinates are viewport-relative pixels. A full circle is
`AnnularSector(center, (0, r), (0, 2pi))`.
"""
struct AnnularSector
    center::Point2f
    radii::Vec2f
    angles::Vec2f
    AnnularSector(center, radii, angles) = new(Point2f(center), Vec2f(radii), Vec2f(angles))
end

function triangle_corners(shape)
    mesh = GeometryBasics.triangle_mesh(shape)
    positions = decompose(Point2f, mesh)
    return [positions[i] for face in faces(mesh) for i in face]
end

# viewports and rect clips are triangulated every frame, skip the generic mesh path
function triangle_corners(r::Rect2)
    (x0, y0), (x1, y1) = minimum(r), maximum(r)
    return Point2f[(x0, y0), (x1, y0), (x1, y1), (x0, y0), (x1, y1), (x0, y1)]
end

function sector_polygon(s::AnnularSector, n = 120)
    θs = LinRange(s.angles..., n)
    on_circle(r, θ) = s.center + r * Point2f(cos(θ), sin(θ))
    outer = on_circle.(s.radii[2], θs)
    inner = s.radii[1] > 0 ? on_circle.(s.radii[1], reverse(θs)) : [s.center]
    return Polygon(vcat(outer, inner))
end

clip_region(::Automatic, widths) = Rect2f(0, 0, widths...)
clip_region(c::Circle, widths) = AnnularSector(origin(c), (0, radius(c)), (0, 2pi))
clip_region(shape, widths) = shape

is_analytic_clip(::Union{Rect2, AnnularSector}) = true
is_analytic_clip(_) = false

clip_shape_corners(r::Rect2, widths) = triangle_corners(Rect2f(r))
clip_shape_corners(s::AnnularSector, widths) = triangle_corners(sector_polygon(s))
clip_shape_corners(points::AbstractVector{<:VecTypes{2}}, widths) = triangle_corners(Polygon(Point2f.(points)))
clip_shape_corners(shapes::MultiPolygon, widths) = reduce(vcat, (triangle_corners(p) for p in shapes.polygons); init = Point2f[])
clip_shape_corners(shape, widths) = triangle_corners(shape)

clip_bounds(r::Rect2) = Rect2f(r)
clip_bounds(s::AnnularSector) = Rect2f(s.center .- s.radii[2], Vec2f(2 * s.radii[2]))
clip_bounds(shape) = Rect2f(coordinates(shape))

"""
    clip_region(scene)

The clip shape of `scene` in viewport-relative pixels (`nothing` if the scene
does not clip). `Rect2` and `AnnularSector` regions can be clipped
analytically (antialiased), other shapes fall back to a polygon mask.
"""
function clip_region(scene::Scene)
    shape = scene.clip[]
    isnothing(shape) && return nothing
    return clip_region(shape, widths(viewport(scene)[]))
end

to_scene_ndc(points, widths) = map(p -> Point2f(2 .* p ./ widths .- 1), points)

"""
    clip_triangles(region, scene)::Vector{Point2f}

Triangle corners covering `region` in the scene's clip space, for a polygon mask.
"""
function clip_triangles(region, scene::Scene)
    w = widths(viewport(scene)[])
    any(iszero, w) && return Point2f[]
    return to_scene_ndc(clip_shape_corners(region, w), w)
end

"""
    clip_cover_triangles(region, scene; pad)

Triangles in the scene's clip space covering the bounds of `region`, grown by
`pad` pixels so antialiased edges are rasterized on both sides.
"""
function clip_cover_triangles(region, scene::Scene; pad = 2)
    w = widths(viewport(scene)[])
    any(iszero, w) && return Point2f[]
    bounds = clip_bounds(region)
    return to_scene_ndc(triangle_corners(Rect2f(minimum(bounds) .- pad, widths(bounds) .+ 2pad)), w)
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
    return sort_by_zorder(items)
end

render_order(plot::AbstractPlot) = sort_by_zorder(copy(plot.plots))

# `zorder` goes through the compute graph, so look it up once per item, not per comparison
function sort_by_zorder(items::AbstractVector)
    keys = map(zorder, items)
    allequal(keys) && return items
    return items[sortperm(keys; alg = Base.Sort.DEFAULT_STABLE)]
end
