using FreeTypeAbstraction: hadvance, leftinkbound, inkwidth, get_extent, ascender, descender

one_attribute_per_char(attribute, string) = (attribute for char in string)

function one_attribute_per_char(font::NativeFont, string)
    return (find_font_for_char(char, font) for char in string)
end

function attribute_per_char(string, attribute)
    n_words = 0
    if attribute isa AbstractVector
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
    Glyphlayout

Stores information about the glyphs in a string that had a layout calculated for them.
`origins` are the character origins relative to the layout's [0,0] point (the alignment)
and rotation anchor). `bboxes` are the glyph bounding boxes relative to the glyphs' own
origins. `hadvances` are the horizontal advance values, those are mostly needed for interactive
purposes, for example to display a cursor at the right offset from a space character.
"""
struct Glyphlayout
    origins::Vector{Point3f0}
    bboxes::Vector{FRect2D}
    hadvances::Vector{Float32}
end

"""
    layout_text(
        string::AbstractString, textsize::Union{AbstractVector, Number},
        font, align, rotation, model, justification, lineheight
    )

Compute a Glyphlayout for a `string` given textsize, font, align, rotation, model, justification, and lineheight.
"""
function layout_text(
        string::AbstractString, textsize::Union{AbstractVector, Number},
        font, align, rotation, model, justification, lineheight
    )

    ft_font = to_font(font)
    rscale = to_textsize(textsize)
    rot = to_rotation(rotation)

    # atlas = get_texture_atlas()
    # mpos = model * Vec4f0(to_ndim(Vec3f0, startpos, 0f0)..., 1f0)
    # pos = to_ndim(Point3f0, mpos, 0)

    fontperchar = attribute_per_char(string, ft_font)
    textsizeperchar = attribute_per_char(string, rscale)

    glyphlayout = glyph_positions(string, fontperchar, textsizeperchar, align[1],
        align[2], lineheight, justification, rot)

    return glyphlayout
end

"""
    glyph_positions(str::AbstractString, font_per_char, fontscale_px, halign, valign, lineheight_factor, justification, rotation)

Calculate the positions for each glyph in a string given a certain font, font size, alignment, etc.
This layout in text coordinates, relative to the anchor point [0,0] can then be translated and
rotated to wherever it is needed in the plot.
"""
function glyph_positions(str::AbstractString, font_per_char, fontscale_px, halign, valign, lineheight_factor, justification, rotation)

    isempty(str) && return Glyphlayout([], [], [])

    # collect information about every character in the string
    charinfos = broadcast([c for c in str], font_per_char, fontscale_px) do char, font, scale
        # TODO: scale as SVector not Number
        unscaled_extent = get_extent(font, char)
        lineheight = Float32(font.height / font.units_per_EM * lineheight_factor * scale)
        unscaled_hi_bb = height_insensitive_boundingbox(unscaled_extent, font)
        hi_bb = FRect2D(
            AbstractPlotting.origin(unscaled_hi_bb) * scale,
            widths(unscaled_hi_bb) * scale)
        (char = char, font = font, scale = scale, hadvance = hadvance(unscaled_extent) * scale,
            hi_bb = hi_bb, lineheight = lineheight)
    end

    # split the character info vector into lines after every \n
    lineinfos = let
        last_line_start = 1
        lineinfos = typeof(view(charinfos, last_line_start:last_line_start))[]
        for (i, ci) in enumerate(charinfos)
            if ci.char == '\n' || i == length(charinfos)
                push!(lineinfos, view(charinfos, last_line_start:i))
                last_line_start = i+1
            end
        end
        lineinfos
    end

    # calculate the x positions of each character in each line
    xs = map(lineinfos) do line
        cumsum([
            isempty(line) ? 0.0 : -(line[1].hi_bb.origin[1]);
            [l.hadvance for l in line[1:end-1]]
        ])
    end

    # calculate linewidths as the last origin plus inkwidth for each line
    linewidths = map(lineinfos, xs) do line, xx
        nchars = length(line)
        # if the last and not the only character is \n, take the previous one
        # to compute the width
        i = (nchars > 1 && line[end].char == '\n') ? nchars - 1 : nchars
        xx[i] + widths(line[i].hi_bb)[1]
    end

    # the maximum width is needed for justification
    maxwidth = maximum(linewidths)

    # how much each line differs from the maximum width for justification correction
    width_differences = maxwidth .- linewidths

    # shift all x values by the justification amount needed for each line
    # if justification is automatic it depends on alignment
    float_justification = if justification === automatic
        if halign == :left || halign == 0
            0.0f0
        elseif halign == :right || halign == 1
            1.0f0
        elseif halign == :center || halign == 0.5
            0.5f0
        else
            0.5f0
        end
    elseif justification == :left
        0.0f0
    elseif justification == :right
        1.0f0
    elseif justification == :center
        0.5f0
    else
        Float32(justification)
    end

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
    halign = if halign isa Number
        Float32(halign)
    elseif halign == :left
        0.0f0
    elseif halign == :center
        0.5f0
    elseif halign == :right
        1.0f0
    else
        error("Invalid halign $halign. Valid values are <:Number, :left, :center and :right.")
    end

    xs_aligned = [xsgroup .- halign * maxwidth for xsgroup in xs_justified]

    # for y alignment, we need the largest ascender of the first line
    # and the largest descender of the last line
    first_line_ascender = maximum(lineinfos[1]) do l
        ascender(l.font) * l.scale
    end

    last_line_descender = minimum(lineinfos[end]) do l
        descender(l.font) * l.scale
    end

    # compute the height of all lines together
    overall_height = first_line_ascender - ys[end] - last_line_descender

    # compute y values after top/center/bottom/baseline alignment
    ys_aligned = if valign == :baseline
        ys .- first_line_ascender .+ overall_height .+ last_line_descender
    else
        va = if valign isa Number
            Float32(valign)
        elseif valign == :top
            1f0
        elseif valign == :bottom
            0f0
        elseif valign == :center
            0.5f0
        else
            error("Invalid valign $valign. Valid values are <:Number, :bottom, :baseline, :top, and :center.")
        end

        ys .- first_line_ascender .+ (1 - va) .* overall_height
    end

    # compute the origins for each character by rotating each character around the common origin
    # which is the alignment anchor and now [0, 0]
    # use 3D coordinates already because later they will be required in that format anyway
    charorigins = [Ref(rotation) .* Point3f0.(xsgroup, y, 0) for (xsgroup, y) in zip(xs_aligned, ys_aligned)]

    # return a GlyphLayout, which contains each character's origin, height-insensitive
    # boundingbox and horizontal advance value
    # these values should be enough to draw characters correctly,
    # compute boundingboxes without relayouting and maybe implement
    # interactive features that need to know where characters begin and end
    return Glyphlayout(
        reduce(vcat, charorigins),
        reduce(vcat, map(line -> [l.hi_bb for l in line], lineinfos)),
        reduce(vcat, map(line -> [l.hadvance for l in line], lineinfos)))
end

function preprojected_glyph_arrays(string::String, position::VecTypes, glyphlayout::AbstractPlotting.Glyphlayout, font, textsize, space::Symbol, projview, resolution, offset::VecTypes, transfunc)

    offset = to_ndim(Point3f0, offset, 0)
    pos3f0 = to_ndim(Point3f0, position, 0)

    atlas = get_texture_atlas()
    if space == :data
        positions = apply_transform(transfunc, [pos3f0 + offset + o for o in glyphlayout.origins])
    elseif space == :screen
        projected = AbstractPlotting.project(projview, resolution, apply_transform(transfunc, pos3f0))
        positions = [to_ndim(Point3f0, projected, 0) + offset + o for o in glyphlayout.origins]
    else
        error("Unknown space $space, only :data or :screen allowed")
    end

    uv = Vec4f0[]
    scales = Vec2f0[]
    offsets = Vec2f0[]
    for (c, font, pixelsize) in zip(string, attribute_per_char(string, font), attribute_per_char(string, textsize))
        push!(uv, glyph_uv_width!(atlas, c, font))
        glyph_bb, extent = FreeTypeAbstraction.metrics_bb(c, font, pixelsize)
        push!(scales, widths(glyph_bb))
        push!(offsets, minimum(glyph_bb))
    end
    return positions, offsets, uv, scales
end


function preprojected_glyph_arrays(strings::AbstractVector{<:String}, positions::AbstractVector, glyphlayouts::Vector, font, textsize, space::Symbol, projview, resolution, offset, transfunc)

    if offset isa VecTypes
        offset = [to_ndim(Point3f0, offset, 0)]
    end

    megastring = join(strings, "")

    if space == :data
        allpos = broadcast(positions, glyphlayouts, offset) do pos, glyphlayout::AbstractPlotting.Glyphlayout, offs
            p = to_ndim(Point3f0, pos, 0)
            apply_transform(
                transfunc,
                [p .+ to_ndim(Point3f0, offs, 0) .+ o for o in glyphlayout.origins]
            )
        end
    elseif space == :screen
        allpos = broadcast(positions, glyphlayouts, offset) do pos, glyphlayout::AbstractPlotting.Glyphlayout, offs
            projected = to_ndim(
                Point3f0,
                AbstractPlotting.project(
                    projview,
                    resolution,
                    apply_transform(transfunc, to_ndim(Point3f0, pos, 0))
                ),
                0)

            return [projected .+ to_ndim(Point3f0, offs, 0) + o
                        for o in glyphlayout.origins]
        end
    else
        error("Unknown space $space, only :data or :screen allowed")
    end

    megapos::Vector{Point3f0} = if isempty(allpos)
        Point3f0[]
    else
        reduce(vcat, allpos)
    end

    atlas = get_texture_atlas()
    uv = Vec4f0[]
    scales = Vec2f0[]
    offsets = Vec2f0[]

    broadcast_foreach(strings, font, textsize) do str, fo, ts
        for (c, f, pixelsize) in zip(str, attribute_per_char(str, fo), attribute_per_char(str, ts))
            push!(uv, glyph_uv_width!(atlas, c, f))
            glyph_bb, extent = FreeTypeAbstraction.metrics_bb(c, f, pixelsize)
            push!(scales, widths(glyph_bb))
            push!(offsets, minimum(glyph_bb))
        end
    end
    return megapos, offsets, uv, scales
end


# function to concatenate vectors with a value between every pair
function padded_vcat(arrs::AbstractVector{T}, fillvalue) where T <: AbstractVector{S} where S
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
    arr
end

function alignment2num(x::Symbol)
    (x == :center) && return 0.5f0
    (x in (:left, :bottom)) && return 0.0f0
    (x in (:right, :top)) && return 1.0f0
    return 0.0f0 # 0 default, or better to error?
end
