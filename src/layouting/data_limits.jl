_isfinite(x) = isfinite(x)
_isfinite(x::VecTypes) = all(isfinite, x)
isfinite_rect(x::Rect) = all(isfinite, x.origin) &&  all(isfinite, x.widths)
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

function distinct_extrema_nan(x)
    lo, hi = extrema_nan(x)
    lo == hi ? (lo - 0.5f0, hi + 0.5f0) : (lo, hi)
end

function point_iterator(plot::Union{Scatter, MeshScatter, Lines, LineSegments})
    return plot.positions[]
end

# TODO?
function data_limits(text::Text{<: Tuple{<: Union{GlyphCollection, AbstractVector{GlyphCollection}}}})
    if is_data_space(text.markerspace[])
        return boundingbox(text)
    else
        if text.position[] isa VecTypes
            return Rect3f(text.position[])
        else
            # TODO: is this branch necessary?
            return Rect3f(convert_arguments(PointBased(), text.position[])[1])
        end
    end
end

function data_limits(text::Text)
    return data_limits(text.plots[1])
end

point_iterator(mesh::GeometryBasics.Mesh) = decompose(Point, mesh)

function point_iterator(list::AbstractVector)
    if length(list) == 1
        # save a copy!
        return point_iterator(list[1])
    else
        points = Point3f[]
        for elem in list
            for point in point_iterator(elem)
                push!(points, to_ndim(Point3f, point, 0))
            end
        end
        return points
    end
end

point_iterator(plot::Mesh) = point_iterator(plot.mesh[])

function br_getindex(vector::AbstractVector, idx::CartesianIndex, dim::Int)
    return vector[Tuple(idx)[dim]]
end

function br_getindex(matrix::AbstractMatrix, idx::CartesianIndex, dim::Int)
    return matrix[idx]
end

function point_iterator(plot::Union{Image, Heatmap, Surface})
    rect = data_limits(plot)
    return unique(decompose(Point3f, rect))
end

function point_iterator(x::Volume)
    axes = (x[1], x[2], x[3])
    extremata = map(extrema∘to_value, axes)
    minpoint = Point3f(first.(extremata)...)
    widths = last.(extremata) .- first.(extremata)
    rect = Rect3f(minpoint, Vec3f(widths))
    return unique(decompose(Point, rect))
end

function foreach_plot(f, s::Scene)
    foreach_plot(f, s.plots)
    foreach(sub-> foreach_plot(f, sub), s.children)
end

foreach_plot(f, s::Figure) = foreach_plot(f, s.scene)
foreach_plot(f, s::FigureAxisPlot) = foreach_plot(f, s.figure)
foreach_plot(f, list::AbstractVector) = foreach(f, list)
function foreach_plot(f, plot::Plot)
    if isempty(plot.plots)
        f(plot)
    else
        foreach_plot(f, plot.plots)
    end
end

function foreach_transformed(f, point_iterator, model, trans_func)
    for point in point_iterator
        point_t = apply_transform(trans_func, point)
        point_m = project(model, point_t)
        f(point_m)
    end
    return
end

function foreach_transformed(f, plot)
    points = point_iterator(plot)
    t = transformation(plot)
    model = model_transform(t)
    trans_func = t.transform_func[]
    # use function barrier since trans_func is Any
    foreach_transformed(f, points, model, identity)
end

function iterate_transformed(plot)
    points = point_iterator(plot)
    t = transformation(plot)
    model = model_transform(t)
    # TODO: without this, axes with log scales error.  Why?
    trans_func = identity # transform_func(t)
    # trans_func = identity
    iterate_transformed(points, model, to_value(get(plot, :space, :data)), trans_func)
end

function iterate_transformed(points, model, space, trans_func)
    (to_ndim(Point3f, project(model, apply_transform(trans_func, point, space)), 0f0) for point in points)
end

function update_boundingbox!(bb_ref, point)
    if all(isfinite, point)
        vec = to_ndim(Vec3f, point, 0.0)
        bb_ref[] = update(bb_ref[], vec)
    end
end

function update_boundingbox!(bb_ref, bb::Rect)
    # ref is uninitialized, so just set it to the first bb
    if !isfinite_rect(bb_ref[])
        bb_ref[] = bb
        return
    end
    # don't update if not finite
    !isfinite_rect(bb) && return
    # ok, update!
    bb_ref[] = union(bb_ref[], bb)
    return
end

# Default data_limits
function data_limits(plot::AbstractPlot)
    # Assume primitive plot
    if isempty(plot.plots)
        return limits_from_transformed_points(iterate_transformed(plot))
    end

    # Assume Plot Plot
    bb_ref = Base.RefValue(data_limits(plot.plots[1]))
    for i in 2:length(plot.plots)
        update_boundingbox!(bb_ref, data_limits(plot.plots[i]))
    end

    return bb_ref[]
end

function _update_rect(rect::Rect{N, T}, point::VecTypes{N, T}) where {N, T}
    mi = minimum(rect)
    ma = maximum(rect)
    mis_mas = map(mi, ma, point) do _mi, _ma, _p
        (isnan(_mi) ? _p : _p < _mi ? _p : _mi), (isnan(_ma) ? _p : _p > _ma ? _p : _ma)
    end
    new_o = map(first, mis_mas)
    new_w = map(mis_mas) do (mi, ma)
        ma - mi
    end
    typeof(rect)(new_o, new_w)
end

function limits_from_transformed_points(points_iterator)
    isempty(points_iterator) && return Rect3f()
    first, rest = Iterators.peel(points_iterator)
    bb = foldl(_update_rect, rest, init = Rect3f(first, zero(first)))
    return bb
end

# include bbox from scaled markers
function limits_from_transformed_points(positions, scales, rotations, element_bbox)
    isempty(positions) && return Rect3f()

    first_scale = attr_broadcast_getindex(scales, 1)
    first_rot = attr_broadcast_getindex(rotations, 1)
    full_bbox = Ref(first_rot * (element_bbox * first_scale) + first(positions))
    for (i, pos) in enumerate(positions)
        scale, rot = attr_broadcast_getindex(scales, i), attr_broadcast_getindex(rotations, i)
        transformed_bbox = rot * (element_bbox * scale) + pos
        update_boundingbox!(full_bbox, transformed_bbox)
    end

    return full_bbox[]
end

function data_limits(scenelike, exclude=(p)-> false)
    bb_ref = Base.RefValue(Rect3f())
    foreach_plot(scenelike) do plot
        if !exclude(plot)
            update_boundingbox!(bb_ref, data_limits(plot))
        end
    end
    return bb_ref[]
end

# A few overloads for performance
function data_limits(plot::Surface)
    mini_maxi = extrema_nan.((plot.x[], plot.y[], plot.z[]))
    mini = first.(mini_maxi)
    maxi = last.(mini_maxi)
    return Rect3f(mini, maxi .- mini)
end

function data_limits(plot::Heatmap)
    mini_maxi = extrema_nan.((plot.x[], plot.y[]))
    mini = Vec3f(first.(mini_maxi)..., 0)
    maxi = Vec3f(last.(mini_maxi)..., 0)
    return Rect3f(mini, maxi .- mini)
end

function data_limits(plot::Image)
    mini_maxi = extrema_nan.((plot.x[], plot.y[]))
    mini = Vec3f(first.(mini_maxi)..., 0)
    maxi = Vec3f(last.(mini_maxi)..., 0)
    return Rect3f(mini, maxi .- mini)
end

function data_limits(plot::MeshScatter)
    # TODO: avoid mesh generation here if possible
    @get_attribute plot (marker, markersize, rotations)
    marker_bb = Rect3f(marker)
    positions = iterate_transformed(plot)
    scales = markersize
    # fast path for constant markersize
    if scales isa VecTypes{3} && rotations isa Quaternion
        bb = limits_from_transformed_points(positions)
        marker_bb = rotations * (marker_bb * scales)
        return Rect3f(minimum(bb) + minimum(marker_bb), widths(bb) + widths(marker_bb))
    else
        # TODO: optimize const scale, var rot and var scale, const rot
        return limits_from_transformed_points(positions, scales, rotations, marker_bb)
    end
end
