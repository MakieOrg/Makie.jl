struct GlyphInfo
    glyph::Int
    font::FreeTypeAbstraction.FTFont
    origin::Point3f
    extent::GlyphExtent
    size::Vec2f
    rotation::Quaternion
    color::RGBAf
    strokecolor::RGBAf
    strokewidth::Float32
end

# Copy constructor, to overwrite a field
function GlyphInfo(
    gi::GlyphInfo;
    glyph=gi.glyph,
    font=gi.font,
    origin=gi.origin,
    extent=gi.extent,
    size=gi.size,
    rotation=gi.rotation,
    color=gi.color,
    strokecolor=gi.strokecolor,
    strokewidth=gi.strokewidth,
)
    return GlyphInfo(glyph, font, origin, extent, size, rotation, color, strokecolor, strokewidth)
end

function calculated_attributes!(::Type{Glyphs}, plot::Plot)
    attr = plot.attributes

    add_constant!(attr, :sdf_marker_shape, Cint(DISTANCEFIELD))
    add_constant!(attr, :atlas, get_texture_atlas())

    map!(attr, [:position, :glyphinfos], :text_positions) do pos, gi
        fill(pos, length(gi))
    end

    map!(attr, [:atlas, :glyphinfos], :sdf_uv) do atlas, gi
        [glyph_uv_width!(atlas, i.glyph, i.font) for i in gi]
    end

    map!(attr, [:glyphinfos, :offset], :marker_offset) do gi, position
        return Point3f[i.origin + position for i in gi]
    end

    map!(attr, [:atlas, :glyphinfos], [:quad_offset, :quad_scale]) do atlas, gi
        quad_offsets = Vec2f[]
        quad_scales = Vec2f[]
        pad = atlas.glyph_padding / atlas.pix_per_glyph
        for i in gi
            i.glyph, i.font, i.size
            # These are tight to the glyph. They do not fill the full space
            # a glyph takes within a string/layout.
            bb = FreeTypeAbstraction.metrics_bb(i.glyph, i.font, i.size)[1]
            quad_offset = Vec2f(minimum(bb) .- i.size .* pad)
            quad_scale = Vec2f(widths(bb) .+ i.size * 2pad)
            push!(quad_offsets, quad_offset)
            push!(quad_scales, quad_scale)
        end

        return (quad_offsets, quad_scales)
    end
    # TODO: remapping positions to be per glyph first generates quite a few
    # redundant transform applications and projections in CairoMakie
    return register_position_transforms!(
        attr; input_name=:text_positions, transformed_name=:positions_transformed
    )
end

function boundingbox(plot::Glyphs, target_space::Symbol)
    # TODO:
    # This is temporary prep work for the future. We should actually consider
    # plot.space, markerspace, textsize, etc when computing the boundingbox in
    # the target_space given to the function.
    # We may also want a cheap version that only considers forward
    # transformations (i.e. drops textsize etc when markerspace is not part of
    # the plot.space -> target_space conversion chain)
    bbox = if target_space == plot.markerspace[]
        glyphs_boundingbox(plot, target_space)
    elseif Makie.is_data_space(target_space)
        _project(plot.model[]::Mat4d, Rect3d(plot.positions_transformed[])::Rect3d)
    else
        error("`target_space = :$target_space` must be either :data or markerspace = :$(plot.markerspace[])")
    end
    return bbox
end

function glyphs_boundingbox(plot, target_space=plot.attrubutes.space[])
    return register_glyphs_boundingbox!(plot, target_space)[]::Rect3d
end

function register_glyphs_boundingbox!(plot, target_space::Symbol)
    bbox_name = Symbol(target_space, :_boundingbox)
    if !haskey(plot.attributes, bbox_name)
        register_raw_glyph_boundingboxes!(plot.attributes)

        # this was fast string boundingboxes, now just one boundingbox.
        map!(
            plot.attributes, [:glyphinfos, :raw_glyph_boundingboxes, :marker_offset], :fast_glyphs_boundingbox
        ) do glyphinfos, bbs, origins
            output = Rect3d()
            for (glyphinfo, bb, orig) in zip(glyphinfos, bbs, origins)
                glyphbb3 = Rect3d(to_ndim(Point3d, origin(bb), 0), to_ndim(Point3d, widths(bb), 0))
                ms_bb = rotate_bbox(glyphbb3, glyphinfo.rotation) + orig
                output = update_boundingbox(output, ms_bb)
            end
            return output
        end

        register_markerspace_positions!(plot)

        # this was string_boundingboxes
        map!(
            plot.attributes, [:fast_glyphs_boundingbox, :markerspace_positions], :glyph_boundingbox
        ) do bb, positions
            if isempty(positions)
                return Rect3d(Point3d(NaN), Vec3d(0))
            else
                return bb + first(positions)
            end
        end

        scene_graph = parent_scene(plot).compute
        map!(plot.attributes, [:markerspace, :glyph_boundingbox], bbox_name) do markerspace, bb
            if markerspace === target_space
                return bb
            else
                proj = get_space_to_space_matrix(scene_graph, markerspace, target_space)
                Rect3d(_project(proj, coordinates(bb)))
            end
        end
    end
    return getproperty(plot, bbox_name)
end

function register_raw_glyph_boundingboxes!(attr)
    # if !haskey(attr, :raw_glyph_boundingboxes)
    map!(attr, :glyphinfos, :raw_glyph_boundingboxes) do glyphinfos
        map(glyphinfos) do glyphinfo
            hi_bb = height_insensitive_boundingbox_with_advance(glyphinfo.extent)
            # TODO c != 0 filters out all non renderables, which is not always desired
            return Rect2d(
                origin(hi_bb) * glyphinfo.size, (glyphinfo.glyph != 0) * widths(hi_bb) * glyphinfo.size
            )
        end
    end
    # end
    return attr.raw_glyph_boundingboxes
end

function register_markerspace_positions!(plot::Glyphs, ::Type{OT}=Point3f; kwargs...) where {OT}
    # Careful, text uses :text_positions as the input to the transformation pipeline
    # We can also skip that part:
    return register_positions_projected!(
        plot,
        OT;
        kwargs...,
        input_name=:positions_transformed_f32c,
        output_name=:markerspace_positions,
        input_space=:space,
        output_space=:markerspace,
        apply_model=true,
        apply_clip_planes=true,
    )
end