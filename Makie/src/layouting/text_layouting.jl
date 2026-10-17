using FreeTypeAbstraction: hadvance, leftinkbound, inkwidth, get_extent, ascender, descender

"""
    justification2float(justification, halign)

Resolves `justification` to the fraction of a line's unused width that is added
to its glyph origins. `automatic` follows `halign`, so a text block's alignment
and its justification are resolved together, before layout.
"""
function justification2float(justification, halign)::Float32
    justification === automatic || return halign2num(
        justification,
        "Invalid justification $justification. Valid values are <:Real, :left, :center and :right."
    )
    return halign2num(halign)
end

function create_lineinfos(charinfos, word_wrap_width)
    last_line_start = 1
    ViewType = typeof(view(charinfos, 1:1))
    lineinfos = ViewType[]
    last_space_local_idx = 0
    last_space_global_idx = 0
    newline_offset = 0.0f0
    x = 0.0f0
    xs = [Float32[]]

    # If word_wrap_width > 0:
    # Whenever a space is hit, record its index in last_space_local_idx and
    # last_space_global_index. If there is already a space on record and the
    # current word overflows word_wrap_width, replace the last space with
    # a newline. newline character unset the last space index
    # word{space}word{space}word{space}
    #        ↑      ↑   ↑
    #        |     i-1  i
    # last_space_idx

    for (i, ci) in enumerate(charinfos)
        push!(xs[end], x)
        x += ci.extent.hadvance * first(ci.scale)
        if 0 < word_wrap_width < x && last_space_local_idx != 0 &&
                ((ci.char in (' ', '\n')) || i == length(charinfos))

            newline_offset = xs[end][last_space_local_idx + 1]
            push!(xs, xs[end][(last_space_local_idx + 1):end] .- newline_offset)
            xs[end - 1] = xs[end - 1][1:last_space_local_idx]
            push!(lineinfos, view(charinfos, last_line_start:last_space_global_idx))
            last_line_start = last_space_global_idx + 1
            x = xs[end][end] + ci.extent.hadvance * first(ci.scale)

            # TODO Do we need to redo the metrics for newlines?
            charinfos[last_space_global_idx] = let
                _, font, scale, lineheight, extent = charinfos[last_space_global_idx]
                (
                    char = '\n', font = font, scale = scale,
                    lineheight = lineheight, extent = extent,
                )
            end
        end

        if ci.char == '\n'
            push!(xs, Float32[])
            push!(lineinfos, view(charinfos, last_line_start:i))
            last_space_local_idx = 0
            last_line_start = i + 1
            x = 0.0f0
        elseif i == length(charinfos)
            push!(lineinfos, view(charinfos, last_line_start:i))
        end

        if 0 < word_wrap_width && ci.char == ' '
            last_space_local_idx = length(last(xs))
            last_space_global_idx = i
        end
    end

    # If the input ends with '\n' (or word-wrap newlines), the loop pushes a new
    # empty `Float32[]` to `xs` but never the matching empty view to `lineinfos`,
    # so a trailing newline contributes no vertical space. Append empty views so
    # lengths match — the trailing empty line then takes part in alignment and
    # bounding box computations.
    while length(lineinfos) < length(xs)
        n = length(charinfos)
        push!(lineinfos, view(charinfos, (n + 1):n))
    end

    return lineinfos, xs
end

"""
    layout_string(str::AbstractString, font_per_char, fontscale_px, lineheight_factor, justification, word_wrap_width)

Calculate the position of each glyph in a string given a certain font, font size,
line height etc. The origins are in the layout frame: the first line's baseline
sits at y = 0 and the left edge of the layout box at x = 0. `bbox` and `baseline`
describe that frame so alignment, rotation and offset can be applied afterwards.
"""
function layout_string(
        str::AbstractString, font_per_char, fontscale_px,
        lineheight_factor, justification::Real, word_wrap_width
    )
    isempty(str) && return (
        glyphindices = UInt64[],
        fonts = NativeFont[],
        origins = Point3f[],
        extents = GlyphExtent[],
        bbox = Rect2f(0, 0, 0, 0),
        baseline = 0.0f0,
    )
    # collect information about every character in the string
    # Ref: the font and the scale are one value for the whole string, and a `Vec2`
    # fontsize would otherwise broadcast as a two-element container
    charinfos = broadcast((c for c in str), Ref(font_per_char), Ref(fontscale_px)) do char, _font, scale
        font = find_font_for_char(char, _font)
        (
            char = char,
            font = font,
            scale = scale,
            lineheight = Float32(font.height / font.units_per_EM * lineheight_factor * last(scale)),
            extent = GlyphExtent(font, char),
        )
    end

    # split the character info vector into lines after every \n
    lineinfos, xs = create_lineinfos(charinfos, word_wrap_width)

    # For an empty trailing line (caused by a terminating '\n'), borrow metrics
    # from the '\n' that ended the previous line so it still occupies vertical
    # space and contributes to alignment / bounding boxes.
    metric_char(i) = isempty(lineinfos[i]) ? last(lineinfos[i - 1]) : last(lineinfos[i])

    # calculate linewidths as the last origin plus hadvance for each line
    linewidths = map(lineinfos, xs) do line, xx
        nchars = length(line)
        nchars == 0 && return 0.0f0  # empty trailing line (after a final '\n')
        # if the last and not the only character is \n, take the previous one
        # to compute the width
        i = (nchars > 1 && line[end].char == '\n') ? nchars - 1 : nchars
        xx[i] + line[i].extent.hadvance * first(line[i].scale)
    end

    # the maximum width is needed for justification
    maxwidth = maximum(linewidths)

    # how much each line differs from the maximum width for justification correction
    width_differences = maxwidth .- linewidths

    xs_justified = map(xs, width_differences) do xsgroup, wd
        xsgroup .+ wd * justification
    end

    # each character carries a "lineheight" metric given its font and scale and a lineheight scaling factor
    # make each line's height the maximum of these values in the line.
    lineheights = map(eachindex(lineinfos)) do i
        line = lineinfos[i]
        isempty(line) ? metric_char(i).lineheight : maximum(l -> l.lineheight, line)
    end

    # compute y values by adding up lineheights in negative y direction
    ys = cumsum([0.0; -lineheights[2:end]])

    # the layout box spans the largest ascender of the first line down to the
    # largest descender of the last line
    first_line_ascender = maximum(lineinfos[1]) do l
        last(l.scale) * l.extent.ascender
    end

    last_line_descender = if isempty(lineinfos[end])
        c = metric_char(length(lineinfos))
        last(c.scale) * c.extent.descender
    else
        minimum(lineinfos[end]) do l
            last(l.scale) * l.extent.descender
        end
    end

    bottom = ys[end] + last_line_descender

    # use 3D coordinates already because later they will be required in that format anyway
    charorigins = [Point3f.(xsgroup, y, 0) for (xsgroup, y) in zip(xs_justified, ys)]

    # each character's origin, height-insensitive boundingbox and horizontal
    # advance value should be enough to draw characters correctly, compute
    # boundingboxes without relayouting and maybe implement interactive features
    # that need to know where characters begin and end
    return (
        glyphindices = map(x -> glyph_index(x.font, x.char), charinfos),
        fonts = map(x -> x.font, charinfos),
        origins = reduce(vcat, charorigins),
        extents = map(x -> x.extent, charinfos),
        bbox = Rect2f(0, bottom, maxwidth, first_line_ascender - bottom),
        baseline = Float32(ys[end]),
    )
end

# function to concatenate vectors with a value between every pair
function padded_vcat(arrs::AbstractVector{T}, fillvalue) where {T <: AbstractVector{S}} where {S}
    n = sum(length.(arrs))
    arr = fill(convert(S, fillvalue), n + length(arrs) - 1)

    counter = 1
    @inbounds for a in arrs
        for v in a
            arr[counter] = v
            counter += 1
        end
        counter += 1
    end
    return arr
end

# Backend data

_offset_to_vec(o::VecTypes) = to_ndim(Vec3f, o, 0)
_offset_to_vec(o::Vector) = to_ndim.(Vec3f, o, 0)
