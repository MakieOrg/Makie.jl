
################################################################################
### boundingbox
################################################################################

# TODO: differentiate input space (plot.converted) and :world space (after
# transform_func and model) more clearly.
"""
    boundingbox(scenelike[, exclude = plot -> false])

Returns the combined world space bounding box of all plots collected under
`scenelike`. This include `plot.transformation`, i.e. the `transform_func` and
the `model` matrix. Plots with `exclude(plot) == true` are excluded.

See also: [`data_limits`](@ref)
"""
function boundingbox(scenelike, exclude::Function = (p)-> false, space::Symbol = :data)
    bb_ref = Base.RefValue(Rect3d())
    foreach_plot(scenelike) do plot
        if !exclude(plot)
            update_boundingbox!(bb_ref, boundingbox(plot, space))
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
function boundingbox(plot::AbstractPlot, space::Symbol = :data)
    # Assume primitive plot
    if isempty(plot.plots)
        return Rect3d(iterate_transformed(plot))
    end

    # Assume combined plot
    bb_ref = Base.RefValue(boundingbox(plot.plots[1], space))
    for i in 2:length(plot.plots)
        update_boundingbox!(bb_ref, boundingbox(plot.plots[i], space))
    end

    return bb_ref[]
end

# for convenience
function transform_bbox(scenelike, lims::Rect)
    return Rect3d(iterate_transformed(scenelike, point_iterator(lims)))
end

# same as data_limits except using iterate_transformed
function boundingbox(plot::MeshScatter, space::Symbol = :data)
    # TODO: avoid mesh generation here if possible
    @get_attribute plot (marker, markersize, rotation)
    marker_bb = Rect3d(marker)
    positions = iterate_transformed(plot)
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

function boundingbox(plot::Scatter)
    if plot.space[] == plot.markerspace[]
        scale, offset = marker_attributes(
            get_texture_atlas(),
            plot.marker[],
            plot.markersize[],
            get(plot.attributes, :font, Observable(Makie.defaultfont())),
            plot.marker_offset[],
            plot
        )
        rotations = convert_attribute(to_value(get(plot, :rotation, 0)), key"rotation"())
        model = plot.model[]
        model33 = model[Vec(1,2,3), Vec(1,2,3)]
        transform_marker = to_value(get(plot, :transform_marker, false))::Bool

        bb = Rect3d()
        for (i, p) in enumerate(point_iterator(plot))
            marker_pos = apply_transform_and_model(plot, p)
            quad_origin = to_ndim(Vec3d, sv_getindex(offset[], i), 0)
            quad_size = Vec2d(sv_getindex(scale[], i))
            quad_rotation = sv_getindex(rotations, i)

            if transform_marker
                p4d = model * to_ndim(Point4d, quad_origin, 1)
                quad_origin = quad_rotation * p4d[Vec(1,2,3)] / p4d[4]
                quad_v1 = quad_rotation * (model33 * Vec3d(quad_size[1], 0, 0))
                quad_v2 = quad_rotation * (model33 * Vec3d(0, quad_size[2], 0))
            else
                quad_origin = quad_rotation * quad_origin
                quad_v1 = quad_rotation * Vec3d(quad_size[1], 0, 0)
                quad_v2 = quad_rotation * Vec3d(0, quad_size[2], 0)
            end

            bb = update_boundingbox(bb, marker_pos + quad_origin)
            bb = update_boundingbox(bb, marker_pos + quad_origin + quad_v1)
            bb = update_boundingbox(bb, marker_pos + quad_origin + quad_v2)
            bb = update_boundingbox(bb, marker_pos + quad_origin + quad_v1 + quad_v2)
        end
        return bb

    else
        return Rect3d(iterate_transformed(plot))
    end
end



################################################################################
### transformed point iterator
################################################################################


@inline iterate_transformed(plot) = iterate_transformed(plot, point_iterator(plot))

function iterate_transformed(plot, points::AbstractArray{<: VecTypes})
    return apply_transform_and_model(plot, points)
end

# TODO: Can this be deleted?
function iterate_transformed(plot, points::T) where T
    @warn "iterate_transformed with $T"
    t = transformation(plot)
    model = model_transform(t) # will auto-promote if points if Float64
    trans_func = transform_func(t)
    [to_ndim(Point3d, project(model, apply_transform(trans_func, point, space))) for point in points]
end