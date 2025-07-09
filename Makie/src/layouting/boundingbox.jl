################################################################################
### boundingbox
################################################################################

# Note: data space boundingboxes should not include float32convert

"""
    boundingbox(scenelike[, exclude = plot -> false])

Returns the combined data space bounding box of all plots collected under
`scenelike`. This include `plot.transformation`, i.e. the `transform_func` and
the `model` matrix. Plots with `exclude(plot) == true` are excluded.

See also: [`data_limits`](@ref)
"""
function boundingbox(scenelike, exclude::Function = (p) -> false, space::Symbol = :data)
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

Returns the data space bounding box of a plot. This include `plot.transformation`,
i.e. the `transform_func` and the `model` matrix.

See also: [`data_limits`](@ref)
"""
function boundingbox(plot::AbstractPlot, space::Symbol = :data)
    # Assume primitive plot
    if isempty(plot.plots)
        raw_bb = apply_transform_and_model(plot, data_limits(plot))
        return apply_clipping_planes(plot.clip_planes[], raw_bb)
    end

    # Assume combined plot
    bb_ref = Base.RefValue(boundingbox(plot.plots[1], space))
    for i in 2:length(plot.plots)
        update_boundingbox!(bb_ref, boundingbox(plot.plots[i], space))
    end

    return bb_ref[]
end

# TODO: implement space
boundingbox(plot::MeshScatter, space::Symbol = :data) = plot.boundingbox[]


function limits_with_marker_transforms(positions, scales, rotation, model, element_bbox)
    isempty(positions) && return Rect3d()
    # translations don't apply to element_bbox, they are already included in positions
    model3 = model[Vec(1, 2, 3), Vec(1, 2, 3)]

    vertices = decompose(Point3d, element_bbox)
    full_bbox = Ref(Rect3d())
    for (i, pos) in enumerate(positions)
        scale = attr_broadcast_getindex(scales, i)
        rot = attr_broadcast_getindex(rotation, i)
        for v in vertices
            p = model3 * (rot * (scale .* v)) + to_ndim(Point3d, pos, 0)
            update_boundingbox!(full_bbox, p)
        end
    end

    return full_bbox[]
end

# Without the extra arg this isn't used in Scene limits
# function boundingbox(plot::Scatter, space::Symbol = plot.space[])
function boundingbox(plot::Scatter)
    space = plot.space[]
    if space == plot.markerspace[]
        scale = plot.quad_scale[]
        offset = plot.quad_offset[]
        rotations = plot.converted_rotation[]
        marker_offsets = plot.marker_offset[]
        model = plot.model[]::Mat4d
        model33 = model[Vec(1, 2, 3), Vec(1, 2, 3)]
        transform_marker = plot.transform_marker[]::Bool
        clip_planes = plot.clip_planes[]::Vector{Plane3f}

        bb = Rect3d()
        for (i, p) in enumerate(plot.positions[])
            marker_pos = apply_transform_and_model(plot, p)
            if is_clipped(clip_planes, marker_pos)
                continue
            end

            marker_offset = sv_getindex(marker_offsets, i)
            quad_origin = to_ndim(Vec3d, sv_getindex(offset, i), 0)
            quad_size = Vec2d(sv_getindex(scale, i))
            quad_rotation = sv_getindex(rotations, i)

            if transform_marker
                marker_pos += model[Vec(1, 2, 3), Vec(1, 2, 3)] * marker_offset
                p4d = model * to_ndim(Point4d, quad_origin, 1)
                quad_origin = quad_rotation * p4d[Vec(1, 2, 3)] / p4d[4]
                quad_v1 = quad_rotation * (model33 * Vec3d(quad_size[1], 0, 0))
                quad_v2 = quad_rotation * (model33 * Vec3d(0, quad_size[2], 0))
            else
                marker_pos += marker_offset
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
        raw_bb = apply_transform_and_model(plot, data_limits(plot))
        return apply_clipping_planes(plot.clip_planes[], raw_bb)
    end
end


################################################################################
### point iterator
################################################################################

function point_iterator(plot::AbstractPlot)
    if haskey(plot, :positions)
        return plot.positions[]
    else
        error("Generic point_iterator has been deprecated, now only plots with `plot.positions` defined implement it.")
    end
end

@inline iterate_transformed(plot) = iterate_transformed(plot, point_iterator(plot))

function iterate_transformed(plot, points::AbstractArray{<:VecTypes})
    return filter(p -> !is_clipped(plot.clip_planes[], p), apply_transform_and_model(plot, points))
end
