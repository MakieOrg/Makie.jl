
"""
Calculates the exact boundingbox of a Scene/Plot, without considering any transformation
"""
function raw_boundingbox(x::Atomic)
    bb = data_limits(x)
end
rootparent(x) = rootparent(parent(x))
rootparent(x::Scene) = x

function raw_boundingbox(x::Annotations)
    bb = raw_boundingbox(x.plots)
    inv(modelmatrix(rootparent(x))) * bb
end
function raw_boundingbox(x::Combined)
    raw_boundingbox(x.plots)
end
function boundingbox(x)
    raw_boundingbox(x)
end

function combined_modelmatrix(x)
    m = Mat4f0(I)
    while true
        m = modelmatrix(x) * m
        if parent(x) !== nothing && parent(x) isa Combined
            x = parent(x)
        else
            break
        end
    end
    m
end

function modelmatrix(x)
    t = transformation(x)
    transformationmatrix(t.translation[], t.scale[], t.rotation[])
end

function boundingbox(x::Atomic)
    bb = raw_boundingbox(x)
    combined_modelmatrix(x) * bb
end

boundingbox(scene::Scene) = raw_boundingbox(scene)
function raw_boundingbox(scene::Scene)
    if scene[Axis] !== nothing
        return raw_boundingbox(scene[Axis])
    elseif scene.limits[] !== automatic
        return scene_limits(scene)
    elseif cameracontrols(scene) == EmptyCamera()
        # Empty camera means this is a parent scene that itself doesn't display anything
        return raw_boundingbox(scene.children)
    else
        plots = plots_from_camera(scene)
        children = filter(scene.children) do child
            child.camera == scene.camera
        end
        return raw_boundingbox([plots; children])
    end
end

function raw_boundingbox(plots::Vector)
    isempty(plots) && return FRect3D()
    plot_idx = iterate(plots)
    bb = FRect3D()
    while plot_idx !== nothing
        plot, idx = plot_idx
        plot_idx = iterate(plots, idx)
        # isvisible(plot) || continue
        bb2 = boundingbox(plot)
        isfinite(bb) || (bb = bb2)
        isfinite(bb2) || continue
        bb = union(bb, bb2)
    end
    bb
end

function project_widths(matrix, vec)
    pr = project(matrix, vec)
    zero = project(matrix, zeros(typeof(vec)))
    pr - zero
end

function boundingbox(x::Text, text::String)
    position = to_value(x[:position])
    @get_attribute x (textsize, font, align, rotation)
    bb = boundingbox(text, position, textsize, font, align, rotation, modelmatrix(x))
    pm = inv(transformationmatrix(parent(x))[])
    wh = widths(bb)
    whp = project_widths(pm, wh)
    aoffset = whp .* to_ndim(Vec3f0, align, 0f0)
    return FRect3D(minimum(bb) .- aoffset, whp)
end

boundingbox(x::Text) = boundingbox(x, to_value(x[1]))

function boundingbox(
        text::String, position, textsize;
        font = "default", align = (:left, :bottom), rotation = 0.0
    )
    return boundingbox(
        text, position, textsize,
        to_font(font), to_align(align), to_rotation(rotation)
    )
end

# function boundingbox(
#         text::String, position, textsize, fonts,
#         align, rotation, model = Mat4f0(I)
#     )
#     isempty(text) && return FRect3D()
#     pos_per_char = !isa(position, VecTypes)
#
#     start_pos = Vec(pos_per_char ? first(position) : position)
#     start_pos3d = project(model, to_ndim(Vec3f0, start_pos, 0.0))
#     bb = FRect3D(start_pos3d, Vec3f0(0))
#
#     if pos_per_char
#         broadcast_foreach(position, textsize, fonts, collect(text)) do pos, scale, font, char
#             rect, extent = FreeTypeAbstraction.metrics_bb(char, font, scale)
#             bb = union(FRect3D(rect) + to_ndim(Vec3f0, pos, 0.0), bb)
#             @show pos scale
#         end
#     else
#         y_advance = 0.0
#         line_advance = FreeTypeAbstraction.get_extent(fonts, 'x').advance[2]
#         for line in split(text, r"(\r\n|\r|\n)")
#             rectangles = FreeTypeAbstraction.glyph_rects(line, fonts, textsize)
#             bb2d = reduce(union, rectangles)
#             bb2d = bb2d + Vec2f0(0, y_advance)
#             bb = union(bb, FRect3D(bb2d))
#             y_advance += line_advance
#             @show y_advance
#         end
#     end
#     return bb
# end

rectmult(rect, m) = Rect(origin(rect) .* m, widths(rect) .* m)
rectshift(rect, vec) = Rect(origin(rect) .+ vec, widths(rect))

to_ndim(type, rect, default = 0) = Rect(to_ndim(type, origin(rect), default), to_ndim(type, widths(rect), default))

"""
Calculate the tight rectangle around a 2D rectangle rotated by `angle` radians.
"""
function rotatedrect(rect::HyperRectangle{2}, angle)
    ox, oy = rect.origin
    wx, wy = rect.widths
    points = @SMatrix([
        ox oy;
        ox oy+wy;
        ox+wx oy;
        ox+wx oy+wy;
    ])
    mrot = @SMatrix([
        cos(angle) -sin(angle);
        sin(angle) cos(angle);
    ])
    rotated = mrot * points'

    rmins = minimum(rotated, dims = 2)
    rmaxs = maximum(rotated, dims = 2)

    newrect = Rect2D(rmins..., (rmaxs .- rmins)...)
end

function boundingbox(
        text::String, position, textsize, font,
        align, rotation, model = Mat4f0(I)
    )
    atlas = get_texture_atlas()
    N = length(text)
    ctext_state = iterate(text)
    ctext_state === nothing && return FRect3D()

    # call the layouting algorithm to find out where all the glyphs end up
    # this is kind of a doubling, maybe it could be avoided if at creation all
    # positions would be populated in the text object, but that seems convoluted
    if position isa VecTypes
        position, _ = layout_text(text, position, textsize, font, align, rotation, model)
    end

    bbox = nothing

    broadcast_foreach(1:N, rotation, font, textsize) do i, rotation, font, scale
        c, text_state = ctext_state
        ctext_state = iterate(text, text_state)
        # TODO fix center + align + rotation
        if !(c in ('\r', '\n'))
            raw_bb = inkboundingbox(FreeTypeAbstraction.internal_get_extent(font, c))
            scaled_bb = rectmult(raw_bb, scale / 64)

            # TODO this only works in 2d
            rot_2d_radians = 2acos(rotation[4])
            rotated_bb = rotatedrect(scaled_bb, rot_2d_radians)

            # bb = rectdiv(bb, 1.5)
            shifted_bb = rectshift(to_ndim(Vec3f0, rotated_bb, 0), position[i])
            if isnothing(bbox)
                bbox = shifted_bb
            else
                bbox = union(bbox, shifted_bb)
            end
        end
    end
    return bbox
end
