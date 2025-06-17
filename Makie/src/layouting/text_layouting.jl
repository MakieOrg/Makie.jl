using FreeTypeAbstraction: hadvance, leftinkbound, inkwidth, get_extent, ascender, descender

one_attribute_per_char(attribute, string) = [attribute for char in string]

function one_attribute_per_char(font::NativeFont, string)
    return [find_font_for_char(char, font) for char in string]
end

function attribute_per_char(string, attribute)
    n_words = 0
    if attribute isa GeometryBasics.StaticVector
        return one_attribute_per_char(attribute, string)
    elseif attribute isa AbstractVector
        if length(attribute) == length(string)
            return attribute
        else
            n_words = length(split(string, r"\s+"))
            if length(attribute) == n_words
                i = 1
                return map(collect(string)) do char
                    f = attribute[i]
                    char == "\n" && (i += 1)
                    return f
                end
            end
        end
    else
        return one_attribute_per_char(attribute, string)
    end
    error("A vector of attributes with $(length(attribute)) elements was given but this fits neither the length of '$string' ($(length(string))) nor the number of words ($(n_words))")
end


"""
    layout_text(
        string::AbstractString, fontsize::Union{AbstractVector, Number},
        font, align, rotation, justification, lineheight, word_wrap_width
    )

Compute a GlyphCollection for a `string` given fontsize, font, align, rotation, model, justification, and lineheight.
"""
function layout_text(
        string::AbstractString, fontsize::Union{AbstractVector, Number}, fonts, align, justification, lineheightword_wrap_width
    )
    # TODO, somehow some unicode symbols don't get rendered if we dont have one font per char
    # Which is really odd
    return glyph_collection(
        string, fontperchar, fontsize, align[1], align[2],
        lineheight, justification, word_wrap_width
    )
end


function justification2float(justification, halign)
    if justification === automatic
        if halign === :left || halign == 0
            return 0.0f0
        elseif halign === :right || halign == 1
            return 1.0f0
        elseif halign === :center || halign == 0.5
            return 0.5f0
        else
            return 0.5f0
        end
    else
        msg = "Invalid justification $justification. Valid values are <:Real, :left, :center and :right."
        return halign2num(justification, msg)
    end
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

    return lineinfos, xs
end

"""
    glyph_collection(str::AbstractString, font_per_char, fontscale_px, halign, valign, lineheight_factor, justification, rotation, color, word_wrap_width)

Calculate the positions for each glyph in a string given a certain font, font size, alignment, etc.
This layout in text coordinates, relative to the anchor point [0,0] can then be translated and
rotated to wherever it is needed in the plot.
"""
function glyph_collection(
        str::AbstractString, font_per_char, fontscale_px, (halign, valign),
        lineheight_factor, justification, word_wrap_width, rotation
    )
    return glyph_collection(
        str, font_per_char, fontscale_px, halign, valign,
        lineheight_factor, justification, word_wrap_width, rotation
    )
end

function glyph_collection(
        str::AbstractString, font_per_char, fontscale_px, halign, valign,
        lineheight_factor, justification, word_wrap_width, rotation
    )
    isempty(str) && return (
        glyphindices = UInt64[],
        font_per_char = NativeFont[],
        char_origins = Point3f[],
        glyph_extents = FreeTypeAbstraction.FontExtent{Float32}[],
    )
    # collect information about every character in the string
    charinfos = broadcast((c for c in str), font_per_char, fontscale_px) do char, _font, scale
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
        va = valign2num(valign, "Invalid valign $valign. Valid values are <:Number, :bottom, :baseline, :top, and :center.")
        ys .- first_line_ascender .+ (1 - va) .* overall_height
    end

    # compute the origins for each character by rotating each character around the common origin
    # which is the alignment anchor and now [0, 0]
    # use 3D coordinates already because later they will be required in that format anyway
    charorigins = [Ref(rotation) .* Point3f.(xsgroup, y, 0) for (xsgroup, y) in zip(xs_aligned, ys_aligned)]

    # return a GlyphCollection, which contains each character's origin, height-insensitive
    # boundingbox and horizontal advance value
    # these values should be enough to draw characters correctly,
    # compute boundingboxes without relayouting and maybe implement
    # interactive features that need to know where characters begin and end
    return (
        glyphindices = map(x -> glyph_index(x.font, x.char), charinfos),
        font_per_char = map(x -> x.font, charinfos),
        char_origins = reduce(vcat, charorigins),
        glyph_extents = map(x -> x.extent, charinfos),
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
Base.getindex(x::ScalarOrVector, i) = x.sv isa Vector ? x.sv[i] : x.sv
Base.lastindex(x::ScalarOrVector) = x.sv isa Vector ? length(x.sv) : 1
