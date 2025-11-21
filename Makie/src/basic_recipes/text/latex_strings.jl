is_layouter_compatible(::LaTeXString, _) = false
is_layouter_compatible(::LaTeXString, ::DefaultStringLayouter) = false
is_layouter_compatible(::LaTeXString, ::LaTeXStringLayouter) = true

default_layouter(string::LaTeXString) = LaTeXStringLayouter()

function layouted_string_plotspecs(inputs, ::LaTeXStringLayouter, id)
    glyph_inputs = (;
        (
            i => sv_getindex(inputs[i], id) for i in [
                    :unwrapped_text,
                    :selected_font,
                    :fontsize,
                    :align,
                    :rotation,
                    :color,
                    :strokecolor,
                    :strokewidth,
                    :word_wrap_width,
                ]
        )...,
    )

    glyphinfos, line_data = glyphinfos_and_lines(glyph_inputs...)

    position = to_3d_offset(sv_getindex(inputs.positions, id))
    offset = sv_getindex(inputs.offset, id)

    linesegments_shifted = if isempty(line_data.linesegments)
        Point3f[]
    else
        map(line_data.linesegments) do seg
            return seg + offset + sv_getindex(inputs.markerspace_positions, id)
        end
    end

    return [
        PlotSpec(:Glyphs, glyphinfos; position = position, offset = offset, markerspace = inputs.markerspace),
        # TODO: this should be in :pixel space, however, when getting the boundingbox, the values can be (when plotting text!)
        # treated as if in data space, causing very large plotareas.
        PlotSpec(
            :LineSegments,
            linesegments_shifted;
            linewidth = line_data.linewidths,
            color = line_data.linecolors,
            space = inputs.markerspace
        ),
    ]
end

function glyphinfos_and_lines(
        string, font, fontsize, align, rotation, color, strokecolor, strokewidth, word_wrap_width
    )
    old_texfont = get_texfont_family()
    set_texfont_family!(font)

    halign, valign = align

    all_els = generate_tex_elements(string)

    # preparing the glyphs
    els = filter(x -> x[1] isa TeXChar, all_els)

    # hacky, but attr per char needs to be fixed
    fs = Vec2f(first(fontsize))

    scales_2d = [Vec2f(x[3] * Vec2f(fs)) for x in els]

    texchars = [x[1] for x in els]
    glyphindices = [FreeTypeAbstraction.glyph_index(texchar) for texchar in texchars]
    fonts = [texchar.font for texchar in texchars]
    extents = GlyphExtent.(texchars)

    bboxes = map(extents, scales_2d) do ext, scale
        unscaled_hi_bb = height_insensitive_boundingbox_with_advance(ext)
        return Rect2f(origin(unscaled_hi_bb) * scale, widths(unscaled_hi_bb) * scale)
    end

    basepositions = [to_ndim(Vec3f, fs, 0) .* to_ndim(Point3f, x[2], 0) for x in els]

    if word_wrap_width > 0
        last_space_idx = 0
        last_newline_idx = 1
        newline_offset = Point3f(basepositions[1][1], 0.0f0, 0)

        for i in eachindex(texchars)
            basepositions[i] -= newline_offset
            if texchars[i].represented_char == ' ' || i == length(texchars)
                right_pos = basepositions[i][1] + width(bboxes[i])
                if last_space_idx != 0 && right_pos > word_wrap_width
                    section_offset = basepositions[last_space_idx + 1][1]
                    lineheight = maximum((height(bb) for bb in bboxes[last_newline_idx:last_space_idx]))
                    last_newline_idx = last_space_idx + 1
                    newline_offset += Point3f(section_offset, lineheight, 0)

                    # TODO: newlines don't really need to represented at all?
                    # chars[last_space_idx] = '\n'
                    for j in (last_space_idx + 1):i
                        basepositions[j] -= Point3f(section_offset, lineheight, 0)
                    end
                end
                last_space_idx = i
            elseif texchars[i].represented_char == '\n'
                last_space_idx = 0
            end
        end
    end

    bb = isempty(bboxes) ? BBox(0, 0, 0, 0) : begin
            mapreduce(union, zip(bboxes, basepositions)) do (b, pos)
                Rect2f(Rect3f(b) + pos)
        end
        end

    xshift = get_xshift(minimum(bb)[1], maximum(bb)[1], halign)
    yshift = get_yshift(minimum(bb)[2], maximum(bb)[2], valign; default = 0.0f0)

    shift = Vec3f(xshift, yshift, 0)
    positions = basepositions .- Ref(shift)
    positions .= Ref(rotation) .* positions

    glyph_infos =
        map(glyphindices, fonts, positions, extents, scales_2d) do glyphindex, font, position, extent, scale
        GlyphInfo(glyphindex, font, position, extent, scale, rotation, color, strokecolor, strokewidth)
    end
    set_texfont_family!(old_texfont)

    tex_offset = Point2f(xshift, yshift)
    # preparing the lines
    els = filter(x -> x[1] isa MathTeXEngine.HLine, all_els)

    linesegments = Point3f[]
    linewidths = Float32[]
    linecolors = RGBAf[]
    for (element, position, _) in els
        h = element
        x, y = position
        p0 = rotation * to_ndim(Point3f, fontsize .* Point2f(x, y) .- tex_offset, 0)
        p1 = rotation * to_ndim(Point3f, fontsize .* Point2f(x + h.width, y) .- tex_offset, 0)
        push!(linesegments, p0, p1)
        push!(linewidths, fontsize * h.thickness, fontsize * h.thickness)
        push!(linecolors, color, color)
    end

    return glyph_infos, (; linesegments, linewidths, linecolors)
end

iswhitespace(l::LaTeXString) = iswhitespace(replace(l.s, '$' => ""))

function to_font(string::LaTeXString, _, font)
    return try
        FontFamily(font)
    catch
        get_texfont_family()
    end
end
