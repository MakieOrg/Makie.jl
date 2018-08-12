
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
    plot_idx = iterate(plots)
    bb = FRect3D()
    while plot_idx !== nothing
        plot, idx = plot_idx
        plot_idx = iterate(plots, idx)
        bb2 = boundingbox(plot)
        isfinite(bb) || (bb = bb2)
        isfinite(bb2) || continue
        bb = union(bb, bb2)
    end
    bb
end


function boundingbox(x::Text, text::String)
    position = value(x[:position])
    @get_attribute x (textsize, font, align, rotation, model)
    boundingbox(text, position, textsize, font, align, rotation, model)
end
boundingbox(x::Text) = boundingbox(x, value(x[1]))

function boundingbox(
        text::String, position, textsize;
        font = "default", align = (:left, :bottom), rotation = 0.0,
        model::Mat4f0 = Mat4f0(I)
    )
    boundingbox(
        text, position, textsize,
        to_font(font), to_align(align), to_rotation(rotation), model
    )

end

function boundingbox(text::String, position, textsize, font, align, rotation, model)
    atlas = get_texture_atlas()
    N = length(text)
    ctext_state = iterate(text)
    ctext_state === nothing && return AABB(Vec3f0(0), Vec3f0(0))
    pos_per_char = !isa(position, VecTypes)
    start_pos = Vec(pos_per_char ? first(position) : position)
    start_pos2D = to_ndim(Point2f0, start_pos, 0.0)
    last_pos = Point2f0(0, 0)
    aoffsetn = to_ndim(Vec3f0, align, 0f0)
    start_pos3d = to_ndim(Vec3f0, start_pos, 0.0)
    bb = AABB(start_pos3d, Vec3f0(0))
    broadcast_foreach(1:N, rotation, font, textsize) do i, rotation, font, scale
        c, text_state = ctext_state
        ctext_state = iterate(text, text_state)
        if c != '\r'
            pos = if pos_per_char
                to_ndim(Vec3f0, position[i], 0.0)
            else
                last_pos = calc_position(last_pos, Point2f0(0, 0), atlas, c, font, scale)
                rotation * (start_pos3d .+ to_ndim(Vec3f0, last_pos, 0.0))
            end
            s = glyph_scale!(atlas, c, font, scale)
            srot = rotation * to_ndim(Vec3f0, s, 0.0)
            bb = GeometryTypes.update(bb, pos)
            bb = GeometryTypes.update(bb, pos .+ srot)
        end
    end
    FRect3D(minimum(bb) .- (widths(bb) .* aoffsetn), widths(bb))
end
