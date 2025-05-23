#=
Hierarchy:
- boundingbox falls back on points_iterator of primitives
- points_iterator falls back on data_limits
- data_limits uses points_iterator for a few specific primitive plots

So overload both `data_limits` and `boundingbox`. You can use:
- `points_iterator(::Rect)` to decompose the Rect
- `_boundingbox(plot, ::Rect)` to transform the Rect using the plots transformations
=#

################################################################################
### data_limits
################################################################################

"""
    data_limits(scenelike[, exclude = plot -> false])

Returns the combined data limits of all plots collected under `scenelike` for
which `exclude(plot) == false`. This is solely based on the positional data of
a plot and thus does not include any transformations.

See also: [`boundingbox`](@ref)
"""
function data_limits(scenelike, exclude::Function = (p)-> false)
    bb_ref = Base.RefValue(Rect3d())
    foreach_plot(scenelike) do plot
        if !exclude(plot)
            update_boundingbox!(bb_ref, data_limits(plot))
        end
    end
    return bb_ref[]
end

# include bbox from scaled markers
function limits_with_marker_transforms(positions, scales, rotation, element_bbox)
    isempty(positions) && return Rect3d()
    first_scale = attr_broadcast_getindex(scales, 1)
    first_rot = attr_broadcast_getindex(rotation, 1)
    full_bbox = Ref(first_rot * (element_bbox * first_scale) + to_ndim(Point3d, first(positions), 0))
    for (i, pos) in enumerate(positions)
        scale, rot = attr_broadcast_getindex(scales, i), attr_broadcast_getindex(rotation, i)
        transformed_bbox = rot * (element_bbox * scale) + to_ndim(Point3d, pos, 0)
        update_boundingbox!(full_bbox, transformed_bbox)
    end

    return full_bbox[]
end


################################################################################
### point_iterator
################################################################################


function point_iterator(plot::Union{Scatter, MeshScatter, Lines, LineSegments})
    return plot.positions[]
end

point_iterator(plot::Text) = point_iterator(plot.plots[1])
function point_iterator(plot::Text{<: Tuple{<: Union{GlyphCollection, AbstractVector{GlyphCollection}}}})
    return plot.position[]
end

point_iterator(mesh::GeometryBasics.AbstractMesh) = decompose(Point, mesh)
point_iterator(plot::Mesh) = point_iterator(plot.mesh[])

# Fallback for other primitive plots, used in boundingbox
point_iterator(plot::AbstractPlot) = point_iterator(data_limits(plot))

# For generic usage
point_iterator(bbox::Rect) = unique(decompose(Point3d, bbox))


################################################################################
### Utilities
################################################################################


isfinite_rect(x::Rect) = all(isfinite, x.origin) &&  all(isfinite, x.widths)
function isfinite_rect(x::Rect{N}, dim::Int) where N
    if 0 < dim <= N
        return isfinite(origin(x)[dim]) && isfinite(widths(x)[dim])
    else
        return false
    end
end
_isfinite(x) = isfinite(x)
_isfinite(x::VecTypes) = all(isfinite, x)

finite_min(a, b) = isfinite(a) ? (isfinite(b) ? min(a, b) : a) : (isfinite(b) ? b : a)
finite_min(a, b, c) = finite_min(finite_min(a, b), c)
finite_min(a, b, rest...) = finite_min(finite_min(a, b), rest...)

finite_max(a, b) = isfinite(a) ? (isfinite(b) ? max(a, b) : a) : (isfinite(b) ? b : a)
finite_max(a, b, c) = finite_max(finite_max(a, b), c)
finite_max(a, b, rest...) = finite_max(finite_max(a, b), rest...)

finite_minmax(a, b) = isfinite(a) ? (isfinite(b) ? minmax(a, b) : (a, a)) : (isfinite(b) ? (b, b) : (a, b))
finite_minmax(a, b, c) = finite_minmax(finite_minmax(a, b), c)
finite_minmax(a, b, rest...) = finite_minmax(finite_minmax(a, b), rest...)

scalarmax(x::Union{Tuple, AbstractArray}, y::Union{Tuple, AbstractArray}) = max.(x, y)
scalarmax(x, y) = max(x, y)
scalarmin(x::Union{Tuple, AbstractArray}, y::Union{Tuple, AbstractArray}) = min.(x, y)
scalarmin(x, y) = min(x, y)

extrema_nan(itr::Pair) = (itr[1], itr[2])
extrema_nan(itr::ClosedInterval) = (minimum(itr), maximum(itr))

function extrema_nan(itr)
    vs = iterate(itr)
    vs === nothing && return (NaN, NaN)
    v, s = vs
    vmin = vmax = v
    # find first finite value
    while vs !== nothing && !_isfinite(v)
        v, s = vs
        vmin = vmax = v
        vs = iterate(itr, s)
    end
    while vs !== nothing
        x, s = vs
        vs = iterate(itr, s)
        _isfinite(x) || continue
        vmax = scalarmax(x, vmax)
        vmin = scalarmin(x, vmin)
    end
    return (vmin, vmax)
end

# used in colorsampler.jl, datashader.jl
function distinct_extrema_nan(x)
    lo, hi = extrema_nan(x)
    lo == hi ? (lo - 0.5f0, hi + 0.5f0) : (lo, hi)
end

# TODO: Consider deprecating Ref versions (performance is the same)
function update_boundingbox!(bb_ref::Base.RefValue, point)
    bb_ref[] = update_boundingbox(bb_ref[], point)
end
function update_boundingbox(bb::Rect{N, T1}, point::VecTypes{M, T2}) where {N, T1, M, T2}
    p = to_ndim(Vec{N, promote_type(T1, T2)}, point, 0.0)
    mini = finite_min.(minimum(bb), p)
    maxi = finite_max.(maximum(bb), p)
    return Rect{N}(mini, maxi - mini)
end

function update_boundingbox!(bb_ref::Base.RefValue, bb::Rect)
    bb_ref[] = update_boundingbox(bb_ref[], bb)
end

function update_boundingbox(a::Rect{N}, b::Rect{N}) where N
    mini = finite_min.(minimum(a), minimum(b))
    maxi = finite_max.(maximum(a), maximum(b))
    return Rect{N}(mini, maxi - mini)
end

@deprecate _update_rect(rect, point) update_boundingbox(rect, point) false


foreach_plot(f, s::Scene) = foreach_plot(f, s.plots)
# foreach_plot(f, s::Figure) = foreach_plot(f, s.scene)
# foreach_plot(f, s::FigureAxisPlot) = foreach_plot(f, s.figure)
foreach_plot(f, list::AbstractVector) = foreach(f, list)
function foreach_plot(f, plot::Plot)
    if isempty(plot.plots)
        f(plot)
    else
        foreach_plot(f, plot.plots)
    end
end
