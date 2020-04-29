################################################################################
#                             Lines, LineSegments                              #
################################################################################

function draw_atomic(scene::Scene, screen::CairoScreen, primitive::Union{Lines, LineSegments})
    fields = @get_attribute(primitive, (color, linewidth, linestyle))
    linestyle = AbstractPlotting.convert_attribute(linestyle, AbstractPlotting.key"linestyle"())
    ctx = screen.context
    model = primitive[:model][]
    positions = primitive[1][]

    isempty(positions) && return

    # workaround for a LineSegments object created from a GLNormalMesh
    # the input argument is a view of points using faces, which results in
    # a vector of tuples of two points. we convert those to a list of points
    # so they don't trip up the rest of the pipeline
    # TODO this shouldn't be necessary anymore!
    if positions isa SubArray{<:Point3, 1, P, <:Tuple{Array{<:AbstractFace}}} where P
        positions = let
            pos = Point3f0[]
            for tup in positions
                push!(pos, tup[1])
                push!(pos, tup[2])
            end
            pos
        end
    end

    projected_positions = project_position.(Ref(scene), positions, Ref(model))

    if color isa AbstractArray{<: Number}
        color = numbers_to_colors(color, primitive)
    end

    # color is now a color or an array of colors
    # if it's an array of colors, each segment must be stroked separately

    # linestyle can be set globally
    !isnothing(linestyle) && Cairo.set_dash(ctx, linestyle)

    if color isa AbstractArray || linewidth isa AbstractArray
        # stroke each segment separately, this means disjointed segments with probably
        # wonky dash patterns if segments are short

        # we can hide the gaps by setting the line cap to round
        Cairo.set_line_cap(ctx, Cairo.CAIRO_LINE_CAP_ROUND)
        draw_multi(primitive, ctx, projected_positions, color, linewidth)
    else
        # stroke the whole line at once if it has only one color
        # this allows correct linestyles and line joins as well and will be the
        # most common case
        Cairo.set_line_width(ctx, linewidth)
        Cairo.set_source_rgba(ctx, red(color), green(color), blue(color), alpha(color))
        draw_single(primitive, ctx, projected_positions)
    end
    nothing
end

function draw_single(primitive::Lines, ctx, positions)
    Cairo.move_to(ctx, positions[1]...)
    for i in 2:length(positions)
        if isnan(positions[i])
            i == length(positions) && break
            Cairo.move_to(ctx, positions[i+1]...)
        else
            Cairo.line_to(ctx, positions[i]...)
        end
    end
    Cairo.stroke(ctx)
end

function draw_single(primitive::LineSegments, ctx, positions)
    @assert iseven(length(positions))
    Cairo.move_to(ctx, positions[1]...)
    for i in 2:length(positions)
        if iseven(i)
            Cairo.line_to(ctx, positions[i]...)
        else
            Cairo.move_to(ctx, positions[i]...)
        end
    end
    Cairo.stroke(ctx)
end

# if linewidth is not an array
function draw_multi(primitive, ctx, positions, colors::AbstractArray, linewidth)
    draw_multi(primitive, ctx, positions, colors, [linewidth for c in colors])
end

# if color is not an array
function draw_multi(primitive, ctx, positions, color, linewidths::AbstractArray)
    draw_multi(primitive, ctx, positions, [color for l in linewidths], linewidths)
end

function draw_multi(primitive::Union{Lines, LineSegments}, ctx, positions, colors::AbstractArray, linewidths::AbstractArray)
    if primitive isa LineSegments
        @assert iseven(length(positions))
    end
    @assert length(positions) == length(colors)
    @assert length(linewidths) == length(colors)

    iterator = if primitive isa Lines
        1:length(positions)-1
    elseif primitive isa LineSegments
        1:2:length(positions)
    end

    for i in iterator
        if isnan(positions[i+1]) || isnan(positions[i])
            continue
        end
        Cairo.move_to(ctx, positions[i]...)

        Cairo.line_to(ctx, positions[i+1]...)
        if linewidths[i] != linewidths[i+1]
            error("Cairo doesn't support two different line widths ($(linewidths[i]) and $(linewidths[i+1])) at the endpoints of a line.")
        end
        Cairo.set_line_width(ctx, linewidths[i])
        c1 = colors[i]
        c2 = colors[i+1]
        # we can avoid the more expensive gradient if the colors are the same
        # this happens if one color was given for each segment
        if c1 == c2
            Cairo.set_source_rgba(ctx, red(c1), green(c1), blue(c1), alpha(c1))
            Cairo.stroke(ctx)
        else
            pat = Cairo.pattern_create_linear(positions[i]..., positions[i+1]...)
            Cairo.pattern_add_color_stop_rgba(pat, 0, red(c1), green(c1), blue(c1), alpha(c1))
            Cairo.pattern_add_color_stop_rgba(pat, 1, red(c2), green(c2), blue(c2), alpha(c2))
            Cairo.set_source(ctx, pat)
            Cairo.stroke(ctx)
            Cairo.destroy(pat)
        end
    end
end

################################################################################
#                                   Scatter                                    #
################################################################################


function draw_atomic(scene::Scene, screen::CairoScreen, primitive::Scatter)
    fields = @get_attribute(primitive, (color, markersize, strokecolor, strokewidth, marker, marker_offset))
    @get_attribute(primitive, (transform_marker,))

    cmap = get(primitive, :colormap, nothing) |> to_value |> to_colormap
    crange = get(primitive, :colorrange, nothing) |> to_value
    ctx = screen.context
    model = primitive[:model][]
    positions = primitive[1][]
    isempty(positions) && return
    size_model = transform_marker ? model : Mat4f0(I)

    font = AbstractPlotting.defaultfont()

    broadcast_foreach(primitive[1][], fields...) do point, c, markersize, strokecolor, strokewidth, marker, mo

        # if we give size in pixels, the size is always equal to that value
        scale = if markersize isa AbstractPlotting.Pixel
            [markersize.value, markersize.value]
        else
            # otherwise calculate a scaled size
            project_scale(scene, markersize, size_model)
        end
        pos = project_position(scene, point, model)

        Cairo.set_source_rgba(ctx, extract_color(cmap, crange, c)...)
        m = convert_attribute(marker, key"marker"(), key"scatter"())
        if m isa Char
            draw_marker(ctx, m, font, pos, scale, strokecolor, strokewidth)
        else
            draw_marker(ctx, m, pos, scale, strokecolor, strokewidth)
        end
    end
    nothing
end

function draw_marker(ctx, marker, pos, scale, strokecolor, strokewidth)
    pos += Point2f0(scale[1] / 2, -scale[2] / 2)
    Cairo.arc(ctx, pos[1], pos[2], scale[1] / 2, 0, 2*pi)
    Cairo.fill(ctx)
    sc = to_color(strokecolor)
    if strokewidth > 0.0
        Cairo.set_source_rgba(ctx, red(sc), green(sc), blue(sc), alpha(sc))
        Cairo.set_line_width(ctx, Float64(strokewidth))
        Cairo.stroke(ctx)
    end
end

function draw_marker(ctx, marker::Char, font, pos, scale, strokecolor, strokewidth)

    cairoface = set_ft_font(ctx, font)

    charextent = AbstractPlotting.FreeTypeAbstraction.internal_get_extent(font, marker)
    inkbb = AbstractPlotting.FreeTypeAbstraction.inkboundingbox(charextent)

    # scale normalized bbox by font size
    inkbb_scaled = FRect2D(origin(inkbb) .* scale, widths(inkbb) .* scale)

    # flip y for the centering shift of the character because in Cairo y goes down
    centering_offset = [1, -1] .* (-origin(inkbb_scaled) .- 0.5 .* widths(inkbb_scaled))
    # this is the origin where we actually have to place the glyph so it's centered
    charorigin = pos .+ centering_offset

    Cairo.move_to(ctx, charorigin...)
    mat = scale_matrix(scale...)
    set_font_matrix(ctx, mat)
    Cairo.text_path(ctx, string(marker))
    Cairo.fill_preserve(ctx)
    Cairo.set_line_width(ctx, strokewidth)
    Cairo.set_source_rgba(ctx, rgbatuple(strokecolor)...)
    Cairo.stroke(ctx)

    # if we use set_ft_font we should destroy the pointer it returns
    cairo_font_face_destroy(cairoface)

end


function draw_marker(ctx, marker::Union{Rect, Type{<: Rect}}, pos, scale, strokecolor, strokewidth)
    s2 = Point2f0(scale[1], -scale[2])
    Cairo.rectangle(ctx, pos..., s2...)
    Cairo.fill(ctx);
    if strokewidth > 0.0
        sc = to_color(strokecolor)
        Cairo.set_source_rgba(ctx, red(sc), green(sc), blue(sc), alpha(sc))
        Cairo.set_line_width(ctx, Float64(strokewidth))
        Cairo.stroke(ctx)
    end
end

################################################################################
#                                     Text                                     #
################################################################################

function draw_atomic(scene::Scene, screen::CairoScreen, primitive::Text)
    ctx = screen.context
    @get_attribute(primitive, (textsize, color, font, align, rotation, model, justification, lineheight))
    txt = to_value(primitive[1])
    position = primitive.attributes[:position][]
    N = length(txt)
    atlas = AbstractPlotting.get_texture_atlas()
    if position isa StaticArrays.StaticArray # one position to place text
        position = AbstractPlotting.layout_text(
            txt, position, textsize,
            font, align, rotation, model, justification, lineheight
        )
    end
    stridx = 1
    broadcast_foreach(1:N, position, textsize, color, font, rotation) do i, p, ts, cc, f, r
        Cairo.save(ctx)
        char = txt[stridx]

        stridx = nextind(txt, stridx)
        pos = project_position(scene, p, model)
        scale = project_scale(scene, ts, model)
        Cairo.move_to(ctx, pos[1], pos[2])
        Cairo.set_source_rgba(ctx, red(cc), green(cc), blue(cc), alpha(cc))
        cairoface = set_ft_font(ctx, f)

        mat = scale_matrix(scale...)
        set_font_matrix(ctx, mat)

        # TODO this only works in 2d
        Cairo.rotate(ctx, -AbstractPlotting.quaternion_to_2d_angle(r))

        if !(char in ('\r', '\n'))
            Cairo.show_text(ctx, string(char))
        end

        cairo_font_face_destroy(cairoface)

        Cairo.restore(ctx)
    end
    nothing
end

