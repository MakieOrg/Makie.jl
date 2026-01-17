@recipe SDFScatter (positions::Vector{<:Point3},) begin
    marker = :Sphere
    markersize = 1.0
    color = @inherit markercolor
    rotation = 0.0
    mode = :additive
    smudge_range = 0.0 # name?

    mixin_generic_plot_attributes()...
    mixin_shading_attributes()...
    mixin_colormap_attributes()...
end

conversion_trait(::Type{<:SDFScatter}) = PointBased()

function register_sdfscatter_boundingbox!(attr)
    # TODO:
    map!(attr, :marker, :raw_marker_bbox) do marker
        return Rect3f(-1, -1, -1, 2, 2, 2)
    end

    map!(
        attr,
        [:raw_marker_bbox, :positions_transformed_f32c, :markersize, :rotation],
        [:marker_bbox, :N_elements]
    ) do bboxes, positions, scales, rotations
        bbs = makie_broadcast(bboxes, positions, scales, rotations) do bb, pos, scale, rot
            # TODO: to_x is non-primitive compat (use convert_attribute)
            return to_rotation(rot) * (bb * to_3d_scale(scale)) + pos
        end
        return bbs, length(bbs)
    end

    map!(attr, :marker_bbox, :boundingbox) do bbs
        return reduce(update_boundingbox, bbs, init = Rect3f())
    end

    # TODO:
    ComputePipeline.alias!(attr, :boundingbox, :data_limits)

    return
end

function calculated_attributes!(::Type{SDFScatter}, plot::Plot)
    attr = plot.attributes
    # TODO: non-primitive compat (use convert_attribute)
    map!(to_color, attr, :color, :converted_color)
    register_colormapping!(attr, :converted_color)
    register_position_transforms!(attr)
    register_sdfscatter_boundingbox!(attr)
    return
end

# TODO: temp stuff to deal with the plot not officially being primitive
function plot!(plot::SDFScatter)
    register_camera!(parent_scene(plot), plot)
    return
end