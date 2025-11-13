struct RichText
    type::Symbol
    children::Vector{Union{RichText, String}}
    attributes::Dict{Symbol, Any}
    function RichText(type::Symbol, children...; kwargs...)
        cs = Union{RichText, String}[children...]
        return new(type, cs, Dict(kwargs))
    end
end

iswhitespace(r::RichText) = iswhitespace(String(r))

function Base.String(r::RichText)
    fn(io, x::RichText) = foreach(x -> fn(io, x), x.children)
    fn(io, s::String) = print(io, s)
    return sprint() do io
        fn(io, r)
    end
end

function Base.show(io::IO, ::MIME"text/plain", r::RichText)
    return print(io, "RichText: \"$(String(r))\"")
end

"""
    rich(args...; kwargs...)

Create a `RichText` object containing all elements in `args`.
"""
rich(args...; kwargs...) = RichText(:span, args...; kwargs...)
"""
    subscript(args...; kwargs...)

Create a `RichText` object representing a superscript containing all elements in `args`.
"""
subscript(args...; kwargs...) = RichText(:sub, args...; kwargs...)
"""
    superscript(args...; kwargs...)

Create a `RichText` object representing a superscript containing all elements in `args`.
"""
superscript(args...; kwargs...) = RichText(:sup, args...; kwargs...)
"""
    subsup(subscript, superscript; kwargs...)

Create a `RichText` object representing a right subscript/superscript combination,
where both scripts are left-aligned against the preceding text.
"""
subsup(args...; kwargs...) = RichText(:subsup, args...; kwargs...)
"""
    left_subsup(subscript, superscript; kwargs...)

Create a `RichText` object representing a left subscript/superscript combination,
where both scripts are right-aligned against the following text.
"""
left_subsup(args...; kwargs...) = RichText(:leftsubsup, args...; kwargs...)

export rich, subscript, superscript, subsup, left_subsup

# MARK: Layouting
is_layouter_compatible(::RichText, _) = false
is_layouter_compatible(::RichText, ::RichTextStringLayouter) = true

default_layouter(::RichText) = RichTextStringLayouter()

function layouted_string_plotspecs(inputs, ::RichTextStringLayouter, id)
    glyph_inputs = (;
        (
            i => sv_getindex(inputs[i], id) for i in [
                    :unwrapped_text,
                    :selected_font,
                    :fonts,
                    :fontsize,
                    :align,
                    :rotation,
                    :justification,
                    :lineheight,
                    :color,
                ]
        )...,
    )

    glyphinfos = layout_rich_text(glyph_inputs...)

    position = to_3d_offset(sv_getindex(inputs.positions, id))
    offset = sv_getindex(inputs.offset, id)

    return [PlotSpec(:Glyphs, glyphinfos; position = position, offset = offset, markerspace = inputs.markerspace)]
end

struct GlyphState
    x::Float32
    baseline::Float32
    size::Vec2f
    font::FreeTypeAbstraction.FTFont
    color::RGBAf
end

function layout_rich_text(rich_text, font, fonts, fontsize, align, rotation, justification, lineheight, color)
    lines = [GlyphInfo[]]

    glyph_state = GlyphState(0, 0, Vec2f(fontsize), font, color)

    process_rich_text_node!(lines, glyph_state, rich_text, fonts)

    apply_lineheight!(lines, lineheight)
    apply_alignment_and_justification!(lines, justification, align)

    return map(reduce(vcat, lines)) do glyphinfo
        GlyphInfo(glyphinfo; origin = rotation * glyphinfo.origin, rotation = rotation * glyphinfo.rotation)
    end
end

# MARK: process node
function process_rich_text_node!(lines, glyph_state::GlyphState, rich_text::RichText, fonts)
    T = Val(rich_text.type)

    if T === Val(:subsup) || T === Val(:leftsubsup)
        if length(rich_text.children) != 2
            throw(
                ArgumentError(
                    "Found subsup rich text with $(length(rich_text.children)) which has to have exactly 2 children instead. The children were: $(rt.children)",
                ),
            )
        end
        sub, sup = rich_text.children
        sub_lines = Vector{GlyphInfo}[[]]
        new_glyph_state_sub = new_glyphstate(glyph_state, rich_text, Val(:subsup_sub), fonts)
        new_glyph_state_sub_post = process_rich_text_node!(sub_lines, new_glyph_state_sub, sub, fonts)
        sup_lines = Vector{GlyphInfo}[[]]
        new_glyph_state_sup = new_glyphstate(glyph_state, rich_text, Val(:subsup_sup), fonts)
        new_glyph_state_sup_post = process_rich_text_node!(sup_lines, new_glyph_state_sup, sup, fonts)
        if length(sub_lines) != 1
            error(
                "It is not allowed to include linebreaks in a subsup rich text element, the invalid element was: $(repr(sub))",
            )
        end
        if length(sup_lines) != 1
            error(
                "It is not allowed to include linebreaks in a subsup rich text element, the invalid element was: $(repr(sup))",
            )
        end
        sub_line = only(sub_lines)
        sup_line = only(sup_lines)
        if T === Val(:leftsubsup)
            right_align!(sub_line, sup_line)
        end
        append!(lines[end], sub_line)
        append!(lines[end], sup_line)
        x = max(new_glyph_state_sub_post.x, new_glyph_state_sup_post.x)
    else
        new_glyph_state = new_glyphstate(glyph_state, rich_text, T, fonts)
        for (i, c) in enumerate(rich_text.children)
            new_glyph_state = process_rich_text_node!(lines, new_glyph_state, c, fonts)
        end
        x = new_glyph_state.x
    end

    return GlyphState(x, glyph_state.baseline, glyph_state.size, glyph_state.font, glyph_state.color)
end

function process_rich_text_node!(lines, glyph_state::GlyphState, text::String, _)
    y = glyph_state.baseline
    x = glyph_state.x
    for char in text
        if char === '\n'
            x = 0
            push!(lines, GlyphInfo[])
        else
            bestfont = find_font_for_char(char, glyph_state.font)
            glyph_index = FreeTypeAbstraction.glyph_index(bestfont, char)
            glyph_extent = GlyphExtent(bestfont, char)
            origin = Point3f(x, y, 0)
            push!(
                lines[end],
                GlyphInfo(
                    glyph_index,
                    bestfont,
                    origin,
                    glyph_extent,
                    glyph_state.size,
                    to_rotation(0),
                    glyph_state.color,
                    RGBAf(0, 0, 0, 0),
                    0.0f0,
                ),
            )
            x = x + glyph_extent.hadvance * glyph_state.size[1]
        end
    end
    return GlyphState(x, y, glyph_state.size, glyph_state.font, glyph_state.color)
end

function new_glyphstate(gs::GlyphState, rt::RichText, ::Val{:sup}, fonts)
    att = rt.attributes
    fontsize = _get_fontsize(att, gs.size * 0.66)
    offset = _get_offset(att, Vec2f(0)) .* fontsize
    return GlyphState(
        gs.x + offset[1],
        gs.baseline + 0.4 * gs.size[2] + offset[2],
        fontsize,
        _get_font(att, gs.font, fonts),
        _get_color(att, gs.color),
    )
end

function new_glyphstate(gs::GlyphState, rt::RichText, ::Val{:span}, fonts)
    att = rt.attributes
    fontsize = _get_fontsize(att, gs.size)
    offset = _get_offset(att, Vec2f(0)) .* fontsize
    return GlyphState(
        gs.x + offset[1],
        gs.baseline + offset[2],
        fontsize,
        _get_font(att, gs.font, fonts),
        _get_color(att, gs.color),
    )
end

function new_glyphstate(gs::GlyphState, rt::RichText, ::Val{:sub}, fonts)
    att = rt.attributes
    fontsize = _get_fontsize(att, gs.size * 0.66)
    offset = _get_offset(att, Vec2f(0)) .* fontsize
    return GlyphState(
        gs.x + offset[1],
        gs.baseline - 0.25 * gs.size[2] + offset[2],
        fontsize,
        _get_font(att, gs.font, fonts),
        _get_color(att, gs.color),
    )
end

function new_glyphstate(gs::GlyphState, rt::RichText, ::Val{:subsup_sub}, fonts)
    att = rt.attributes
    fontsize = _get_fontsize(att, gs.size * 0.66)
    return GlyphState(
        gs.x,
        gs.baseline - 0.25 * gs.size[2],
        fontsize,
        _get_font(att, gs.font, fonts),
        _get_color(att, gs.color),
    )
end
function new_glyphstate(gs::GlyphState, rt::RichText, ::Val{:subsup_sup}, fonts)
    att = rt.attributes
    fontsize = _get_fontsize(att, gs.size * 0.66)
    return GlyphState(
        gs.x,
        gs.baseline + 0.4 * gs.size[2],
        fontsize,
        _get_font(att, gs.font, fonts),
        _get_color(att, gs.color),
    )
end

function right_align!(line1::Vector{GlyphInfo}, line2::Vector{GlyphInfo})
    isempty(line1) || isempty(line2) && return nothing
    xmax1, xmax2 = map((line1, line2)) do line
        maximum(line; init = 0.0f0) do ginfo
            # TODO: typo?
            GlyphInfo
            ginfo.origin[1] +
                ginfo.size[1] *
                (ginfo.extent.ink_bounding_box.origin[1] + ginfo.extent.ink_bounding_box.widths[1])
        end
    end
    line_to_shift = xmax1 > xmax2 ? line2 : line1
    for j in eachindex(line_to_shift)
        l = line_to_shift[j]
        o = l.origin
        l = GlyphInfo(l; origin = o .+ Point3f(abs(xmax2 - xmax1), 0, 0))
        line_to_shift[j] = l
    end
    return nothing
end

_get_color(attributes, default)::RGBAf = haskey(attributes, :color) ? to_color(attributes[:color]) : default
_get_font(attributes, default::NativeFont, fonts)::NativeFont =
    haskey(attributes, :font) ? to_font(fonts, attributes[:font]) : default
_get_fontsize(attributes, default)::Vec2f =
    haskey(attributes, :fontsize) ? Vec2f(to_fontsize(attributes[:fontsize])) : default
_get_offset(attributes, default)::Vec2f = haskey(attributes, :offset) ? Vec2f(attributes[:offset]) : default

# MARK: apply lineheight
function apply_lineheight!(lines, lineheight)
    for (i, line) in enumerate(lines)
        for j in eachindex(line)
            glyph = line[j]
            ox, oy, oz = glyph.origin
            # TODO: use lineheight value
            glyph = GlyphInfo(glyph; origin = Point3f(ox, oy - (i - 1) * 20, oz))
            line[j] = glyph
        end
    end
    return nothing
end

# MARK: align and justify
function apply_alignment_and_justification!(lines, justification, align)
    max_xs = map(max_x_advance, lines)
    max_x = maximum(max_xs)

    # TODO: Should we check the next line if the first/last is empty?
    top_y = max_y_ascender(lines[1])
    bottom_y = min_y_descender(lines[end])

    align_offset_x = get_xshift(0.0f0, max_x, align[1]; default = 0.0f0)
    align_offset_y = get_yshift(bottom_y, top_y, align[2]; default = 0.0f0)

    float_justification = to_float_justification(justification, align)

    for (i, line) in enumerate(lines)
        justification_offset = float_justification * (max_x - max_xs[i])
        for j in eachindex(line)
            glyph = line[j]
            o = glyph.origin
            glyph = GlyphInfo(
                glyph; origin = o .- Point3f(align_offset_x - justification_offset, align_offset_y, 0.0)
            )
            line[j] = glyph
        end
    end
    return nothing
end

function max_x_advance(glyph_infos::Vector{GlyphInfo})::Float32
    return maximum(glyph_infos; init = 0.0f0) do ginfo
        ginfo.origin[1] + ginfo.extent.hadvance * ginfo.size[1]
    end
end

# Characters can be completely above or below the baseline, so minimum/maximum
# should not initialize with 0. It should also not be ±Inf or ±floatmax() as that
# results in incorrect limits
function max_y_ascender(glyph_infos::Vector{GlyphInfo})::Float32
    if isempty(glyph_infos)
        return 0.0f0
    else
        return maximum(glyph_infos) do ginfo
            return ginfo.origin[2] + ginfo.extent.ascender * ginfo.size[2]
        end
    end
end

function min_y_descender(glyph_infos::Vector{GlyphInfo})::Float32
    if isempty(glyph_infos)
        return 0.0f0
    else
        return minimum(glyph_infos) do ginfo
            return ginfo.origin[2] + ginfo.extent.descender * ginfo.size[2]
        end
    end
end

function to_float_justification(ju, al)::Float32
    halign = al[1]
    return if ju === automatic
        get_xshift(0.0f0, 1.0f0, halign)
    else
        get_xshift(0.0f0, 1.0f0, ju; default = ju) # errors if wrong symbol is used
    end
end
