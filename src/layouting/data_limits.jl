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

"""
    data_limits(plot::AbstractPlot)

Returns the bounding box of a plot based on just its position data.

See also: [`boundingbox`](@ref)
"""
function data_limits(plot::AbstractPlot)
    # Assume primitive plot
    if isempty(plot.plots)
        return Rect3d(point_iterator(plot))
    end

    # Assume combined plot
    bb_ref = Base.RefValue(data_limits(plot.plots[1]))
    for i in 2:length(plot.plots)
        update_boundingbox!(bb_ref, data_limits(plot.plots[i]))
    end

    return bb_ref[]
end

# A few overloads for performance
function data_limits(plot::Surface)
    mini_maxi = extrema_nan.((plot.x[], plot.y[], plot.z[]))
    mini = first.(mini_maxi)
    maxi = last.(mini_maxi)
    return Rect3d(mini, maxi .- mini)
end

function data_limits(plot::Union{Heatmap, Image})
    mini_maxi = extrema_nan.((plot.x[], plot.y[]))
    mini = Vec3d(first.(mini_maxi)..., 0)
    maxi = Vec3d(last.(mini_maxi)..., 0)
    return Rect3d(mini, maxi .- mini)
end

function data_limits(x::Volume)
    axes = (x[1][], x[2][], x[3][])
    extremata = extrema.(axes)
    return Rect3d(first.(extremata), last.(extremata) .- first.(extremata))
end

function data_limits(plot::Text)
    if plot.space[] == plot.markerspace[]
        return string_boundingbox(plot)
    else
        return Rect3d(point_iterator(plot))
    end
end

function data_limits(plot::Scatter)
    if plot.space[] == plot.markerspace[]
        scale, offset = marker_attributes(
            get_texture_atlas(),
            plot.marker[],
            plot.markersize[],
            get(plot.attributes, :font, Observable(Makie.defaultfont())),
            plot
        )
        rotations = convert_attribute(to_value(get(plot, :rotation, 0)), key"rotation"())
        marker_offsets = convert_attribute(plot.marker_offset[], key"marker_offset"(), key"scatter"())

        bb = Rect3d()
        for (i, p) in enumerate(point_iterator(plot))
            marker_pos = to_ndim(Point3d, p, 0) + sv_getindex(marker_offsets, i)
            quad_origin = to_ndim(Vec3d, sv_getindex(offset[], i), 0)
            quad_size = Vec2d(sv_getindex(scale[], i))
            quad_rotation = sv_getindex(rotations, i)

            quad_origin = quad_rotation * quad_origin
            quad_v1 = quad_rotation * Vec3d(quad_size[1], 0, 0)
            quad_v2 = quad_rotation * Vec3d(0, quad_size[2], 0)

            bb = update_boundingbox(bb, marker_pos + quad_origin)
            bb = update_boundingbox(bb, marker_pos + quad_origin + quad_v1)
            bb = update_boundingbox(bb, marker_pos + quad_origin + quad_v2)
            bb = update_boundingbox(bb, marker_pos + quad_origin + quad_v1 + quad_v2)
        end
        return bb
    else
        return Rect3d(point_iterator(plot))
    end
end

function data_limits(plot::Voxels)
    xyz = to_value.(plot.converted[1:3])
    return Rect3d(minimum.(xyz), maximum.(xyz) .- minimum.(xyz))
end

# includes markersize and rotation
function data_limits(plot::MeshScatter)
    # TODO: avoid mesh generation here if possible
    @get_attribute plot (marker, markersize, rotation)
    marker_bb = Rect3d(marker)
    positions = point_iterator(plot)
    scales = markersize
    # fast path for constant markersize
    if scales isa VecTypes{3} && rotation isa Quaternion
        bb = Rect3d(positions)
        marker_bb = rotation * (marker_bb * scales)
        return Rect3d(minimum(bb) + minimum(marker_bb), widths(bb) + widths(marker_bb))
    else
        # TODO: optimize const scale, var rot and var scale, const rot
        return limits_with_marker_transforms(positions, scales, rotation, marker_bb)
    end
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
