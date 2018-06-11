
"""
Calculates the exact boundingbox of a Scene/Plot
"""
function boundingbox(x)
    data_limits(x)
end

boundingbox(x::Combined) = boundingbox(x.plots)

boundingbox(scene::Scene) = boundingbox(plots_from_camera(scene))

function boundingbox(plots::Vector)
    isempty(plots) && return FRect3D(Vec3f0(0), Vec3f0(0))
    bb = FRect3D()
    idx = start(plots)
    bb = FRect3D()
    while !done(plots, idx)
        plot, idx = next(plots, idx)
        bb2 = boundingbox(plot)
        isfinite(bb) || (bb = bb2)
        isfinite(bb2) || continue
        bb = union(bb, bb2)
    end
    bb
end


function boundingbox(x::Text)
    text = value(x[1])
    position = value(x[:position])
    @get_attribute x (textsize, font, align, rotation, model)

    atlas = get_texture_atlas()
    N = endof(text)
    pos_per_char = !isa(position, Point)
    start_pos = pos_per_char ? first(position) : position
    last_pos = start_pos
    c = first(text); text_state = start(text)
    c, text_state = next(text, text_state)
    aoffsetn = to_ndim(Vec3f0, align, 0f0)
    start_pos3d = to_ndim(Vec3f0, start_pos, 0.0)
    bb = AABB(start_pos3d, start_pos3d)
    broadcast_foreach(1:N, rotation, font, textsize) do i, rotation, font, scale
        if c != '\r'
            pos = if pos_per_char
                to_ndim(Vec3f0, position[i], 0.0)
            else
                p = calc_position(last_pos, start_pos, atlas, c, font, scale)
                rotation * (to_ndim(Vec3f0, p, 0.0) .+ aoffsetn)
            end
            s = glyph_scale!(atlas, c, font, scale)
            srot = rotation * to_ndim(Vec3f0, s, 0.0)
            bb = GeometryTypes.update(bb, pos)
            bb = GeometryTypes.update(bb, pos .+ srot)
            last_pos = pos
        end
        if !done(text, text_state)
            c, text_state = next(text, text_state)
        end
    end
    bb
end
