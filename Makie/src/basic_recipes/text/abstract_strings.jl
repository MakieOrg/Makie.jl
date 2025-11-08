is_layouter_compatible(::AbstractString, _) = false
is_layouter_compatible(string::AbstractString, ::DefaultStringLayouter) = true

default_layouter(::AbstractString) = DefaultStringLayouter()

function layouted_string_plotspecs(inputs, ::DefaultStringLayouter, id)
    @info "Default drawing!"
    glyph_inputs = (;
        (
            i => sv_getindex(inputs[i], id) for i in [
                :unwrapped_text,
                :selected_font,
                :fontsize,
                :align,
                :lineheight,
                :justification,
                :word_wrap_width,
                :rotation,
                :computed_color,
                :strokecolor,
                :strokewidth,
            ]
        )...
    )
    position = to_3d_offset(sv_getindex(inputs.positions, id))
    offset = sv_getindex(inputs.offset, id)

    glyphinfos = to_glyphinfos(glyph_inputs...)
    return [PlotSpec(:Glyphs, glyphinfos; position=position, offset=offset)]
end

function to_glyphinfos(
    string,
    font,
    fontsize,
    align,
    lineheight,
    justification,
    word_wrap_width,
    rotation,
    color,
    strokecolor,
    strokewidth,
)
    isempty(string) && return []

    halign, valign = align

    # collect information about every character in the string
    charinfos = broadcast((c for c in string), font, fontsize) do char, _font, scale
        font = find_font_for_char(char, _font)
        (
            char=char,
            font=font,
            scale=scale,
            lineheight=Float32(font.height / font.units_per_EM * lineheight * last(scale)),
            extent=GlyphExtent(font, char),
        )
    end

    # split the character info vector into lines after every \n
    lineinfos, xs = create_lineinfos(charinfos, word_wrap_width)

    # calculate linewidths as the last origin plus hadvance for each line
    linewidths = map(lineinfos, xs) do line, xx
        nchars = length(line)
        # if the last and not the only character is \n, take the previous one
        # to compute the width
        i = (nchars > 1 && line[end].char == '\n') ? nchars - 1 : nchars
        xx[i] + line[i].extent.hadvance * first(line[i].scale)
    end

    # the maximum width is needed for justification
    maxwidth = maximum(linewidths)

    # how much each line differs from the maximum width for justification correction
    width_differences = maxwidth .- linewidths

    # shift all x values by the justification amount needed for each line
    # if justification is automatic it depends on alignment
    float_justification = justification2float(justification, halign)

    xs_justified = map(xs, width_differences) do xsgroup, wd
        xsgroup .+ wd * float_justification
    end

    # each character carries a "lineheight" metric given its font and scale and a lineheight scaling factor
    # make each line's height the maximum of these values in the line
    lineheights = map(lineinfos) do line
        maximum(l -> l.lineheight, line)
    end

    # compute y values by adding up lineheights in negative y direction
    ys = cumsum([0.0; -lineheights[2:end]])

    # compute x values after left/center/right alignment
    halign = halign2num(halign)
    xs_aligned = [xsgroup .- halign * maxwidth for xsgroup in xs_justified]

    # for y alignment, we need the largest ascender of the first line
    # and the largest descender of the last line
    first_line_ascender = maximum(lineinfos[1]) do l
        last(l.scale) * l.extent.ascender
    end

    last_line_descender = minimum(lineinfos[end]) do l
        last(l.scale) * l.extent.descender
    end

    # compute the height of all lines together
    overall_height = first_line_ascender - ys[end] - last_line_descender

    # compute y values after top/center/bottom/baseline alignment
    ys_aligned = if valign === :baseline
        ys .- first_line_ascender .+ overall_height .+ last_line_descender
    else
        va = valign2num(
            valign,
            "Invalid valign $valign. Valid values are <:Number, :bottom, :baseline, :top, and :center.",
        )
        ys .- first_line_ascender .+ (1 - va) .* overall_height
    end

    # compute the origins for each character by rotating each character around the common origin
    # which is the alignment anchor and now [0, 0]
    # use 3D coordinates already because later they will be required in that format anyway
    charorigins = [Ref(rotation) .* Point3f.(xsgroup, y, 0) for (xsgroup, y) in zip(xs_aligned, ys_aligned)]
    charorigins = reduce(vcat, charorigins)
    @show charorigins

    scales = per_character(to_2d_scale(fontsize), charinfos) # TODO: convert_attribute?
    rotations = per_character(rotation, charinfos)

    colors = per_character(color, charinfos)
    strokecolors = per_character(strokecolor, charinfos)
    strokewidths = per_character(strokewidth, charinfos)

    return map(
        charinfos, charorigins, scales, rotations, colors, strokecolors, strokewidths
    ) do charinfo, charorigin, scale, rotation, color, strokecolor, strokewidth
        GlyphInfo(
            glyph_index(charinfo.font, charinfo.char),
            charinfo.font,
            charorigin,
            charinfo.extent,
            scale,
            rotation,
            color,
            strokecolor,
            strokewidth,
        )
    end
end

function per_character(data, characters)
    block_length = length(characters)
    if isscalar(data)
        return fill(data, block_length)
    else
        return data
    end
end