
################################################################################
### boundingbox
################################################################################


"""
    boundingbox(scenelike[, exclude = plot -> false])

Returns the combined world space bounding box of all plots collected under
`scenelike`. This include `plot.transformation`, i.e. the `transform_func` and
the `model` matrix. Plots with `exclude(plot) == true` are excluded.

See also: [`data_limits`](@ref)
"""
function boundingbox(scenelike, exclude = (p)-> false)
    bb_ref = Base.RefValue(Rect3d())
    foreach_plot(scenelike) do plot
        if !exclude(plot)
            update_boundingbox!(bb_ref, future_boundingbox(plot))
        end
    end
    return bb_ref[]
end

"""
    boundingbox(plot::AbstractPlot)

Returns the world space bounding box of a plot. This include `plot.transformation`,
i.e. the `transform_func` and the `model` matrix.

See also: [`data_limits`](@ref)
"""
boundingbox(plot::AbstractPlot) = _boundingbox(plot)

# TODO: This only exists to deprecate boundingbox(::Text) more smoothly. Once
#       that is fully removed this should be boundingbox(plot).
function _boundingbox(plot::AbstractPlot)
    # Assume primitive plot
    if isempty(plot.plots)
        return Rect3d(iterate_transformed(plot))
    end

    # Assume combined plot
    bb_ref = Base.RefValue(future_boundingbox(plot.plots[1]))
    for i in 2:length(plot.plots)
        update_boundingbox!(bb_ref, future_boundingbox(plot.plots[i]))
    end

    return
end
# Replace future_boundingbox with just boundingbox once boundingbox(::Text) is
# no longer in pixel space
@inline future_boundingbox(plot::AbstractPlot) = boundingbox(plot)
@inline future_boundingbox(plot::Text) = _boundingbox(plot)
_boundingbox(plot::Text) = Rect3d(iterate_transformed(plot))

# for convenience
function transform_bbox(scenelike, lims::Rect)
    return Rect3d(iterate_transformed(scenelike, point_iterator(lims)))
end



################################################################################
### transformed point iterator
################################################################################


@inline iterate_transformed(plot) = iterate_transformed(plot, point_iterator(plot))

function iterate_transformed(plot, points)
    t = transformation(plot)
    model = Mat4d(model_transform(t)) # TODO: make model matrix Float64?
    trans_func = transform_func(t)
    return iterate_transformed(points, model, to_value(get(plot, :space, :data)), trans_func)
end

function iterate_transformed(points::AbstractVector{<: VecTypes{N, T}}, model, space, trans_func) where {N, T}
    output = similar(points, Point3d)
    @inbounds for i in eachindex(points)
        transformed = apply_transform(trans_func, points[i], space)
        p4d = project(model, transformed)
        output[i] = p4d[Vec(1, 2, 3)]
    end
    return output
end

function iterate_transformed(points::T, model, space, trans_func) where T
    @warn "iterate_transformed with $T"
    [to_ndim(Point3f, project(model, apply_transform(trans_func, point, space))) for point in points]
end


################################################################################
### Special cases
################################################################################


# includes markersize and rotation
function boundingbox(plot::MeshScatter)
    # TODO: avoid mesh generation here if possible
    @get_attribute plot (marker, markersize, rotations)
    marker_bb = Rect3d(marker)
    positions = iterate_transformed(plot)
    scales = markersize
    # fast path for constant markersize
    if scales isa VecTypes{3} && rotations isa Quaternion
        bb = Rect3d(positions)
        marker_bb = rotations * (marker_bb * scales)
        return Rect3d(minimum(bb) + minimum(marker_bb), widths(bb) + widths(marker_bb))
    else
        # TODO: optimize const scale, var rot and var scale, const rot
        return limits_from_transformed_points(positions, scales, rotations, marker_bb)
    end
end

# include bbox from scaled markers
function limits_from_transformed_points(positions, scales, rotations, element_bbox)
    isempty(positions) && return Rect3d()

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