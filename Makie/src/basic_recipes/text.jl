function check_textsize_deprecation(@nospecialize(dictlike))
    return if haskey(dictlike, :textsize)
        throw(ArgumentError("`textsize` has been renamed to `fontsize` in Makie v0.19. Please change all occurrences of `textsize` to `fontsize` or revert back to an earlier version."))
    end
end

# We sort out position vs string(-like) vs mixed arguments before convert_arguments,
# so that we only get positions here
conversion_trait(::Type{<:Text}, args...) = PointBased()

convert_attribute(o, ::key"offset", ::key"text") = to_3d_offset(o) # same as marker_offset in scatter
convert_attribute(f, ::key"font", ::key"text") = f # later conversion with fonts
# text also allows :baseline and resolves it later
function convert_attribute(align, ::key"align", ::key"text")
    validate_text_align(align)
    return Ref{Any}(align)
end

function validate_text_align(al::Union{Tuple, StaticVector})
    if length(al) != 2
        error("Text align must be a two-element tuple, got $(repr(al))")
    end
    if !(al[1] isa Real || al[1] in (:left, :right, :center))
        error("Horizontal text align must be a Real or :left, :right, :center. Got $(repr(al[1]))")
    end
    if !(al[2] isa Real || al[2] in (:top, :bottom, :center, :baseline))
        error("Vertical text align must be a Real or :top, :bottom, :center, :baseline. Got $(repr(al[2]))")
    end
    return
end

validate_text_align(als::AbstractVector) = foreach(validate_text_align, als)

validate_text_align(al) = error("Text align must be a two-element tuple, got $(repr(al))")

# Positions are always vectors so text should be too
convert_attribute(str::AbstractString, ::key"text", ::key"text") = Ref{Any}([str]) # don't fix string type
convert_attribute(rt::RichText, ::key"text", ::key"text") = Ref{Any}([rt])
convert_attribute(x::AbstractVector, ::key"text", ::key"text") = Ref{Any}(vec(x))

# `copy` so the producer emits a fresh `input_text` array each run. An aliased
# array makes `is_same` (which can't tell whether a shared array was mutated in
# place) report a change, re-running text layout on every position update while
# layout solves, which for image handlers (LaTeX) means recompiling every pass.
to_string_arr(text::AbstractVector) = copy(text)
to_string_arr(text) = [text]

function register_arguments!(::Type{Text}, attr::ComputeGraph, user_kw, input_args)
    # Set up Inputs
    inputs = _register_input_arguments!(attr, input_args)

    # User arguments can be PointBased(), String-like or mixed, with the
    # position and text attributes supplementing data not in arguments.
    # For conversion we want to move position data into the argument pipeline
    # and String-like data into attributes. Do this here:
    pushfirst!(inputs, :position, :text)
    if !haskey(attr, :text)
        add_input!(AttributeConvert(:text, :text), attr, :text, get(user_kw, :text, ""))
    end
    if !haskey(attr, :position)
        add_input!(AttributeConvert(:position, :text), attr, :position, get(user_kw, :position, (0.0, 0.0)))
    end
    register_computation!(attr, inputs, [:_positions, :input_text]) do inputs, changed, cached
        a_pos, a_text, args... = values(inputs)
        # Note: Could add RichText
        if args isa Tuple{<:AbstractString}
            # position data will always be wrapped in a Vector, so strings should too
            return ((a_pos,), Ref{Any}([args[1]]))
        elseif args isa Tuple{<:AbstractVector{<:AbstractString}}
            # copy: a fresh array lets `is_same` filter unchanged text (see `to_string_arr`)
            return ((a_pos,), Ref{Any}(copy(args[1])))
        elseif args isa Tuple{<:AbstractVector{<:Tuple{<:Any, <:VecTypes}}}
            # [(text, pos), ...] argument
            return ((last.(args[1]),), Ref{Any}(first.(args[1])))
        else # assume position data
            return (args, Ref{Any}(to_string_arr(a_text)))
        end
    end

    # Continue with _register_expand_arguments with adjusted input names
    expanded = _register_expand_arguments!(Text, attr, [:_positions], attr._positions[], true)

    # And the rest of it
    _register_argument_conversions!(Text, attr, user_kw, expanded)

    return
end

"""
    GlyphBuffer()

The arrays behind the outputs of the `Text` plot's glyph layout node, in output
order. The node reuses one buffer across evaluations (`empty!` + refill) so
re-layouting text does not allocate a fresh set of arrays every time.

Everything in here is in the layout frame: glyphs are shaped but not aligned,
rotated or offset. `block_bboxes` and `block_baselines` describe that frame per
text block, which is what the downstream placement node needs to apply `align`,
`rotation` and `offset` (see [`register_glyph_placement!`](@ref)).

Text is appended one block (one input string) at a time with
[`push_glyph_block!`](@ref) or [`push_empty_block!`](@ref), which keep
`text_blocks` consistent with the parallel per-glyph arrays. Non-glyph output
(LaTeX rules, handler images, ...) goes through [`push_text_spec!`](@ref).
"""
struct GlyphBuffer
    glyph_indices::Vector{UInt64}
    glyph_fonts::Vector{NativeFont}
    glyph_layout_origins::Vector{Point3f}
    glyph_extents::Vector{GlyphExtent}
    text_blocks::Vector{UnitRange{Int64}}
    glyph_colors::Vector{RGBAf}
    glyph_scales::Vector{Vec2f}
    glyph_strokewidths::Vector{Float32}
    glyph_strokecolors::Vector{RGBAf}
    block_bboxes::Vector{Rect2f}
    block_baselines::Vector{Float32}
    layout_specs::Vector{PlotSpec}
    layout_spec_bboxes::Vector{Rect3d}
    text_spec_block_indices::Vector{Int}
end

function GlyphBuffer()
    return GlyphBuffer(
        UInt64[], NativeFont[], Point3f[], GlyphExtent[], UnitRange{Int64}[],
        RGBAf[], Vec2f[], Float32[], RGBAf[],
        Rect2f[], Float32[], PlotSpec[], Rect3d[], Int[]
    )
end

# The node's outputs are named after the fields, so the cached outputs come back
# in field order and rewrapping them hands the same arrays back for reuse.
GlyphBuffer(cached::NamedTuple) = GlyphBuffer(values(cached)...)

node_outputs(buffer::GlyphBuffer) = map(name -> getfield(buffer, name), fieldnames(GlyphBuffer))

function Base.empty!(buffer::GlyphBuffer)
    foreach(empty!, node_outputs(buffer))
    return buffer
end

"""
    BlockAttribute(data, block_index, n_blocks)

Wraps a text attribute that still needs resolving for text block `block_index`.
`data` is either a scalar or one value per text block, and [`push_glyph_block!`](@ref)
resolves it while appending. Styling individual characters of a string this way is
not supported: a glyph is not a character (font shaping can merge several code
points into one), so per-character styling belongs in `rich` text.
"""
struct BlockAttribute{T}
    data::T
    block_index::Int
    n_blocks::Int
end

function append_per_glyph!(dest::Vector, attribute::BlockAttribute, n::Int)
    data = attribute.data
    isscalar(data) && return append_per_glyph!(dest, data, n)
    length(data) == attribute.n_blocks || error(
        "Expected a scalar or one value per string ($(attribute.n_blocks)), got $(length(data)). " *
            "To style parts of a string differently, use `rich` text."
    )
    return append_per_glyph!(dest, data[attribute.block_index], n)
end

function append_per_glyph!(dest::Vector, value, n::Int)
    if isscalar(value)
        append!(dest, Iterators.repeated(value, n))
    elseif length(value) == n
        append!(dest, value)
    else
        error("Expected a scalar or $n values per glyph, got $(length(value)).")
    end
    return
end

"""
    push_glyph_block!(buffer, glyphindices, fonts, origins, extents; bbox, baseline, scales, colors, strokecolors, strokewidths)

Appends the glyphs of one text block to `buffer` and records their index range in
`buffer.text_blocks`. `origins` are in the layout frame, described by `bbox` (the
box `align` positions) and `baseline` (the y that `valign = :baseline` puts on the
anchor). `glyphindices`, `origins` and `extents` are per glyph; the remaining
attributes may also be scalar or a [`BlockAttribute`](@ref).
"""
function push_glyph_block!(
        buffer::GlyphBuffer, glyphindices, fonts, origins, extents;
        bbox, baseline, scales, colors, strokecolors, strokewidths
    )

    n = length(glyphindices)
    offset = length(buffer.glyph_indices)
    push!(buffer.text_blocks, (offset + 1):(offset + n))
    push!(buffer.block_bboxes, bbox)
    push!(buffer.block_baselines, baseline)

    append!(buffer.glyph_indices, glyphindices)
    append!(buffer.glyph_layout_origins, origins)
    append!(buffer.glyph_extents, extents)

    append_per_glyph!(buffer.glyph_fonts, fonts, n)
    append_per_glyph!(buffer.glyph_scales, scales, n)
    append_per_glyph!(buffer.glyph_colors, colors, n)
    append_per_glyph!(buffer.glyph_strokecolors, strokecolors, n)
    append_per_glyph!(buffer.glyph_strokewidths, strokewidths, n)

    return
end

"""
    push_empty_block!(buffer; bbox, baseline)

Records a text block without glyphs (e.g. one a handler renders as an image), so
`buffer.text_blocks` keeps one entry per input string. `bbox` and `baseline` are
still needed: they are the layout frame the block's specs get placed in.
"""
function push_empty_block!(buffer::GlyphBuffer; bbox, baseline)
    n = length(buffer.glyph_indices)
    push!(buffer.text_blocks, (n + 1):n)
    push!(buffer.block_bboxes, bbox)
    push!(buffer.block_baselines, baseline)
    return
end

"""
    push_text_spec!(buffer, spec[, bbox])

Adds a non-glyph plot for the block currently being pushed, positioned in that
block's layout frame. `bbox` defaults to the bounding box of the spec's positions
and should be given when the visual extent differs from them (e.g. an image
marker). Placement transforms the positions and the bbox alike; a `rotation`
kwarg on the spec, if present, gets the block rotation composed into it, so an
oriented marker turns with the text.
"""
function push_text_spec!(buffer::GlyphBuffer, spec::PlotSpec, bbox::Rect3d = Rect3d(first(spec.args)))
    push!(buffer.layout_specs, spec)
    push!(buffer.text_spec_block_indices, length(buffer.text_blocks))
    push!(buffer.layout_spec_bboxes, bbox)
    return
end

function convert_text_string!(
        buffer::GlyphBuffer,
        input_text::AbstractString, i, N, fontsize, font, justification,
        lineheight, word_wrap_width, fonts, color, strokecolor, strokewidth
    )

    args = sv_getindex.((font, fontsize, lineheight, justification, word_wrap_width), i)
    layout = layout_string(input_text, args...)

    per_block(x) = BlockAttribute(x, i, N)
    push_glyph_block!(
        buffer, layout.glyphindices, layout.fonts, layout.origins, layout.extents;
        bbox = layout.bbox, baseline = layout.baseline,
        scales = per_block(to_2d_scale(fontsize)), # TODO: convert_attribute?
        colors = per_block(color),
        strokecolors = per_block(strokecolor),
        strokewidths = per_block(strokewidth),
    )

    return
end

function convert_text_string!(
        buffer::GlyphBuffer,
        input_text::RichText, i, N, fontsize, font, justification,
        lineheight, word_wrap_width, fonts, color, strokecolor, strokewidth
    )

    args = sv_getindex.((fontsize, font, fonts, justification, lineheight, color), i)
    layout = layout_text(input_text, args...)

    push_glyph_block!(
        buffer, layout.glyphindices, layout.fonts, layout.origins, layout.extents;
        bbox = layout.bbox, baseline = layout.baseline,
        scales = layout.scales, colors = layout.colors,
        strokecolors = layout.strokecolors, strokewidths = layout.strokewidths,
    )

    return
end

function convert_text_string!(
        buffer::GlyphBuffer,
        input_text::LaTeXString, i, N, fontsize, font, justification,
        lineheight, word_wrap_width, fonts, color, strokecolor, strokewidth
    )

    args = sv_getindex.((fontsize, color, strokecolor, strokewidth, word_wrap_width), i)
    tex_elements, layout = texelems_and_layout(input_text, args...)

    push_glyph_block!(
        buffer, layout.glyphindices, layout.fonts, layout.origins, layout.extents;
        bbox = layout.bbox, baseline = layout.baseline,
        scales = layout.scales, colors = layout.colors,
        strokecolors = layout.strokecolors, strokewidths = layout.strokewidths,
    )

    append_tex_linesegment_data!(buffer, tex_elements, args[1], args[2])

    return
end

function append_tex_linesegment_data!(
        buffer::GlyphBuffer, tex_elements, fontsize, color::RGBAf
    )

    points = Point3f[]
    widths = Float32[]
    for (element, position, _) in tex_elements
        element isa MathTeXEngine.HLine || continue
        h = element
        x, y = position
        push!(
            points,
            to_ndim(Point3f, fontsize .* Point2f(x, y), 0),
            to_ndim(Point3f, fontsize .* Point2f(x + h.width, y), 0)
        )
        push!(widths, fontsize * h.thickness, fontsize * h.thickness)
    end
    isempty(points) && return
    push_text_spec!(buffer, PlotSpec(:LineSegments, points; linewidth = widths, color = color))
    return
end

"""
    display_independent_layout(text) -> Bool

Whether a text value's laid-out glyph geometry is independent of the display
attributes (color, strokecolor, strokewidth). Plain strings apply those per-glyph
*after* layout, so their geometry can be reused when only display attributes change.
`RichText` and `LaTeXString` bake color into their layout, so they return `false`
and recompute. Custom text types default to `false` (conservative).
"""
display_independent_layout(::AbstractString) = true
display_independent_layout(@nospecialize(x)) = false

# Keep the buffer's cached glyph geometry, refilling only the per-glyph display
# arrays. Valid only when no layout-affecting input changed and every block's text
# has `display_independent_layout == true` (checked by the caller).
function refill_display_attributes!(buffer::GlyphBuffer, color, strokecolor, strokewidth)
    empty!(buffer.glyph_colors)
    empty!(buffer.glyph_strokecolors)
    empty!(buffer.glyph_strokewidths)

    N = length(buffer.text_blocks)
    for (i, block) in enumerate(buffer.text_blocks)
        n = length(block)
        append_per_glyph!(buffer.glyph_colors, BlockAttribute(color, i, N), n)
        append_per_glyph!(buffer.glyph_strokecolors, BlockAttribute(strokecolor, i, N), n)
        append_per_glyph!(buffer.glyph_strokewidths, BlockAttribute(strokewidth, i, N), n)
    end
    return
end

################################################################################
### text_handler extension
################################################################################

"""
    emit_text!(buffer::GlyphBuffer, handler, src, font, fonts, fontsize, lineheight, justification, word_wrap_width, color, strokecolor, strokewidth) -> Bool

Lays out one text block with a `text_handler`. Define methods dispatching on the handler
and the input type it accepts (e.g. `LaTeXString`), append the result to `buffer`, and
return `true`. Return `false` without touching `buffer` to fall through to the built-in
path, which is how handled and unhandled strings mix in one plot.

Append with [`push_glyph_block!`](@ref) for glyphs, [`push_empty_block!`](@ref) for a block
that has none (an image, say), and [`push_text_spec!`](@ref) for non-glyph plots such as
rules. Exactly one block must be pushed per call.

Everything is in the block's layout frame: `align`, `rotation` and `offset` are applied
downstream, so a handler never sees them, and changing them re-runs placement rather than
the handler. `justification` arrives resolved to a fraction in 0..1 (`automatic` is already
folded in against `halign`). The appearance attributes are passed because a handler may
either bake them in (a rasterized image can't be recolored afterwards) or hand them to
`push_glyph_block!`.
"""
# Untyped so that a method typing just the handler and the input type is more
# specific than this one, rather than ambiguous with it.
function emit_text!(
        buffer, handler, src, font, fonts, fontsize, lineheight,
        justification, word_wrap_width, color, strokecolor, strokewidth
    )
    return false
end

# Route one text block through the handler, resolving the per-block attribute values.
function handle_text!(
        buffer::GlyphBuffer, handler, str, i, N, fontsize, font, justification,
        lineheight, word_wrap_width, fonts, color, strokecolor, strokewidth
    )
    return emit_text!(
        buffer, handler, str, sv_getindex(font, i), fonts, sv_getindex(fontsize, i),
        sv_getindex(lineheight, i), sv_getindex(justification, i), sv_getindex(word_wrap_width, i),
        sv_getindex(color, i), sv_getindex(strokecolor, i), sv_getindex(strokewidth, i)
    )::Bool
end

# Apply a per-point transform to a spec's positional data (its first positional arg).
function transform_text_spec(spec::PlotSpec, f)
    new_positions = Point3f[f(p) for p in first(spec.args)]
    new_args = copy(spec.args)
    new_args[1] = new_positions
    return PlotSpec(spec.type, new_args...; spec.kwargs...)
end

"""
    MathTeXHandler()

A `text_handler` that lays out `LaTeXString`s with MathTeXEngine.jl through the
generic [`emit_text!`](@ref) protocol. Setting `text_handler = MathTeXHandler()`
routes LaTeX math through the pluggable path; non-LaTeX inputs fall through.
"""
struct MathTeXHandler end

function emit_text!(
        buffer::GlyphBuffer, ::MathTeXHandler, str::LaTeXString, font, fonts, fontsize,
        lineheight, justification, word_wrap_width, color, strokecolor, strokewidth
    )

    fs = Vec2f(first(fontsize))
    all_els = generate_tex_elements(str)
    els = filter(x -> x[1] isa TeXChar, all_els)
    texchars = [x[1] for x in els]
    scales = Vec2f[Vec2f(x[3] * fs) for x in els]
    glyphindices = UInt64[FreeTypeAbstraction.glyph_index(tc) for tc in texchars]
    glyphfonts = NativeFont[tc.font for tc in texchars]
    extents = GlyphExtent.(texchars)
    origins = Point3f[to_ndim(Vec3f, fs, 0) .* to_ndim(Point3f, x[2], 0) for x in els]

    bboxes = map(extents, scales) do ext, scale
        unscaled = height_insensitive_boundingbox_with_advance(ext)
        return Rect2f(origin(unscaled) * scale, widths(unscaled) * scale)
    end
    bb = isempty(bboxes) ? Rect2f(0, 0, 0, 0) : mapreduce(union, zip(bboxes, origins)) do (b, pos)
            return Rect2f(Rect3f(b) + pos)
    end

    # MathTeXEngine's frame already has the baseline at y = 0
    push_glyph_block!(
        buffer, glyphindices, glyphfonts, origins, extents;
        bbox = bb, baseline = 0.0f0, scales = scales, colors = color,
        strokecolors = strokecolor, strokewidths = strokewidth,
    )

    rule_points = Point3f[]
    rule_widths = Float32[]
    for (element, position, _) in all_els
        element isa MathTeXEngine.HLine || continue
        x, y = position
        push!(rule_points, to_ndim(Point3f, fs .* Point2f(x, y), 0), to_ndim(Point3f, fs .* Point2f(x + element.width, y), 0))
        w = Float32(fs[1] * element.thickness)
        push!(rule_widths, w, w)
    end
    isempty(rule_points) || push_text_spec!(
        buffer, PlotSpec(:LineSegments, rule_points; linewidth = rule_widths, color = color)
    )

    return true
end

# `align` only reaches text layout through this: automatic justification follows
# halign, everything else about alignment is applied after layout. Resolving it to
# a number here means an align change that leaves justification alone (a different
# valign, or halign on left-justified text) is filtered by `is_same` and never
# triggers a relayout.
function register_resolved_justification!(attr::ComputeGraph)
    return map!(attr, [:input_text, :justification, :align], :resolved_justification) do input_text, justification, align
        isscalar(justification) && isscalar(align) && return justification2float(justification, align[1])
        # per-block values, so `input_text` sets the count rather than either input
        return Float32[
            justification2float(sv_getindex(justification, i), sv_getindex(align, i)[1])
                for i in eachindex(input_text)
        ]
    end
end

function register_glyph_layout!(attr::ComputeGraph)
    inputs = [
        :input_text,
        :text_handler,
        :fontsize,
        :selected_font,
        :resolved_justification,
        :lineheight,
        :word_wrap_width,
        :fonts,
        :computed_color,
        :strokecolor,
        :strokewidth,
    ]
    outputs = collect(fieldnames(GlyphBuffer))
    return register_computation!(attr, inputs, outputs) do inputs, changed, cached
        (; input_text, text_handler, fontsize, selected_font, resolved_justification) = inputs
        (; lineheight, word_wrap_width, fonts, computed_color, strokecolor, strokewidth) = inputs

        buffer = cached === nothing ? GlyphBuffer() : GlyphBuffer(cached)

        if cached !== nothing && text_handler === nothing && all(display_independent_layout, input_text) &&
                !changed.input_text && !changed.fontsize && !changed.selected_font &&
                !changed.resolved_justification && !changed.lineheight &&
                !changed.word_wrap_width && !changed.fonts
            refill_display_attributes!(buffer, computed_color, strokecolor, strokewidth)
            return node_outputs(buffer)
        end

        empty!(buffer)
        args = (
            fontsize, selected_font, resolved_justification, lineheight, word_wrap_width,
            fonts, computed_color, strokecolor, strokewidth,
        )
        N = length(input_text)
        for (block_index, str) in enumerate(input_text)
            if text_handler === nothing || !handle_text!(buffer, text_handler, str, block_index, N, args...)
                convert_text_string!(buffer, str, block_index, N, args...)
            end
        end

        return node_outputs(buffer)
    end

end

"""
    block_alignment_shift(bbox, baseline, align)

The point of a text block's layout frame that `align` puts on its anchor position,
so subtracting it from a layout position aligns that position.
"""
function block_alignment_shift(bbox::Rect2f, baseline::Real, align)
    halign, valign = align
    xshift = interpolate_align(minimum(bbox)[1], maximum(bbox)[1], halign2num(halign))
    yshift = valign === :baseline ? Float32(baseline) :
        interpolate_align(minimum(bbox)[2], maximum(bbox)[2], valign2num(valign))
    return Vec3f(xshift, yshift, 0)
end

compose_spec_rotation(rotation, r::AbstractVector) = Quaternionf[rotation * to_rotation(x) for x in r]
compose_spec_rotation(rotation, r) = rotation * to_rotation(r)

function place_spec(spec::PlotSpec, rotation, shift, offset)
    placed = transform_text_spec(spec, p -> rotation * (to_ndim(Point3f, p, 0) - shift) + offset)
    if haskey(placed.kwargs, :rotation)
        placed.kwargs[:rotation] = compose_spec_rotation(rotation, placed.kwargs[:rotation])
    end
    return placed
end

"""
    register_glyph_placement!(attr::ComputeGraph)

Turns the layout frame that text layout produced into placed markerspace data by
applying `align`, `rotation` and `offset` per text block. Keeping this separate
means those three attributes never re-run layout, which for an expensive
`text_handler` (a LaTeX engine, say) is the difference between recompiling a label
and moving it.
"""
function register_glyph_placement!(attr::ComputeGraph)
    inputs = [
        :glyph_layout_origins, :text_blocks, :block_bboxes, :block_baselines,
        :align, :rotation, :offset,
        :layout_specs, :layout_spec_bboxes, :text_spec_block_indices,
    ]
    outputs = [:glyph_origins, :glyph_rotations, :text_specs, :text_spec_bboxes]
    return register_computation!(attr, inputs, outputs) do inputs, changed, cached
        (; glyph_layout_origins, text_blocks, block_bboxes, block_baselines) = inputs
        (; align, rotation, offset, layout_specs, layout_spec_bboxes, text_spec_block_indices) = inputs

        origins, rotations, specs, spec_bboxes = if cached === nothing
            (Point3f[], Quaternionf[], PlotSpec[], Rect3d[])
        else
            empty!.(values(cached))
        end

        shifts = map(eachindex(text_blocks)) do i
            return block_alignment_shift(block_bboxes[i], block_baselines[i], sv_getindex(align, i))
        end

        for (i, block) in enumerate(text_blocks)
            rot = to_rotation(sv_getindex(rotation, i))
            for gi in block
                push!(origins, rot * (glyph_layout_origins[gi] - shifts[i]))
                push!(rotations, rot)
            end
        end

        for (spec, bbox, i) in zip(layout_specs, layout_spec_bboxes, text_spec_block_indices)
            rot = to_rotation(sv_getindex(rotation, i))
            off = to_ndim(Vec3f, sv_getindex(offset, i), 0)
            push!(specs, place_spec(spec, rot, shifts[i], off))
            push!(spec_bboxes, rotate_bbox(bbox - to_ndim(Vec3d, shifts[i], 0), rot) + off)
        end

        return (origins, rotations, specs, spec_bboxes)
    end
end

function register_text_computations!(attr::ComputeGraph)
    map!(to_font, attr, [:fonts, :font], :selected_font)

    # Resolve colormapping to colors early. This allows rich text which returns
    # its own colors to be mixed with other text types which dont.
    add_computation!(attr, Val(:computed_color))

    register_resolved_justification!(attr)

    # one output per `GlyphBuffer` field
    register_glyph_layout!(attr)

    register_glyph_placement!(attr)

    map!(attr, [:glyph_origins, :offset, :text_blocks], :marker_offset) do origins, offset, blocks
        return Point3f[origins[gi] + sv_getindex(offset, i) for (i, r) in enumerate(blocks) for gi in r]
    end

    register_position_transforms!(attr, input_name = :positions, transformed_name = :positions_transformed)

    # One data-space anchor position per glyph (repeated within a string). The
    # Glyphs child transforms these; per-string transform reuse is task #8.
    map!(attr, [:positions, :text_blocks], :per_glyph_positions) do positions, blocks
        return Point3f[to_ndim(Point3f, sv_getindex(positions, i), 0) for (i, r) in enumerate(blocks) for _ in r]
    end

    return
end


function get_text_type(x::AbstractVector{Any})
    isempty(x) && error("Cannot determine text type from empty vector")
    return mapreduce(typeof, (a, b) -> a === b ? a : error("All text elements need same eltype. Found: $(a), $(b)"), x)
end

get_text_type(x::AbstractVector) = eltype(x)
get_text_type(::T) where {T} = T

function calculated_attributes!(::Type{Text}, plot::Plot)
    attr = plot.attributes

    register_colormapping!(attr)
    register_text_computations!(attr)
    register_glyphs!(plot)
    return register_text_plotlist!(plot)
end

# Materialize the non-glyph text specs (LaTeX rules, handler images, ...) as a plotlist
# child. Each spec is in its block's markerspace frame; here we add the block's projected
# position (per camera) and render in markerspace. Empty for plain text, so the plotlist
# has no children and no render objects.
function register_text_plotlist!(plot)
    register_model_clip_planes!(plot.attributes)
    map!(
        plot.attributes,
        [
            :text_specs, :text_spec_block_indices, :preprojection, :model_f32c,
            :positions_transformed_f32c, :model_clip_planes, :space, :markerspace,
        ],
        :_shifted_text_specs,
    ) do specs, block_indices, preprojection, model_f32c, positions, clip_planes, space, markerspace
        isempty(specs) && return PlotSpec[]
        ms_positions = _project(preprojection * model_f32c, positions, clip_planes, space)
        return map(specs, block_indices) do spec, bidx
            shifted = transform_text_spec(spec, p -> p + ms_positions[bidx])
            kw = copy(shifted.kwargs)
            kw[:space] = markerspace
            return PlotSpec(shifted.type, shifted.args...; kw...)
        end
    end
    return plotlist!(plot, plot._shifted_text_specs)
end

function register_glyphs!(plot)
    return glyphs!(
        plot, plot.per_glyph_positions;
        glyphindices = plot.glyph_indices,
        font_per_char = plot.glyph_fonts,
        marker_offset = plot.marker_offset,
        scale = plot.glyph_scales,
        color = plot.glyph_colors,
        rotation = plot.glyph_rotations,
        strokecolor = plot.glyph_strokecolors,
        strokewidth = plot.strokewidth, # scalar uniform; GL/WGL can't do per-glyph stroke width
        glowcolor = plot.glowcolor,
        glowwidth = plot.glowwidth,
        markerspace = plot.markerspace,
        transform_marker = plot.transform_marker,
        space = plot.space,
    )
end

################################################################################
### Bounding Boxes
################################################################################

# Notes:
# - metrics_bb(): bounding box tightly around glyphs, not used outside of gl backends
# - height_insensitive_boundingbox_with_advance(): bounding box of glyphs as part
#   of a string layout at unit scale
# - rotation is already applied to glyph_origins, so applying origins without
#   rotation doesn't make sense / is wrong
# - offset always applies in markerspace w/o rotation. Excluding it when positions
#   are included makes little sense

function register_markerspace_positions!(plot::Text, ::Type{OT} = Point3f; kwargs...) where {OT}
    # Careful, text uses :text_positions as the input to the transformation pipeline
    # We can also skip that part:
    return register_positions_projected!(
        plot, OT; kwargs...,
        input_name = :positions_transformed_f32c, output_name = :markerspace_positions,
        input_space = :space, output_space = :markerspace,
        apply_model = true, apply_clip_planes = true
    )
end

struct PerCharIterator{T}
    blocks::Vector{UnitRange{Int64}}
    data::Vector{T}
    is_per_block::Bool
end
function PerCharIterator(blocks, data)
    return PerCharIterator(blocks, data, length(blocks) == length(data))
end

function Base.iterate(iter::PerCharIterator, state = (1, 1))
    char_idx, block_idx = state
    if block_idx > length(iter.blocks) || char_idx > last(last(iter.blocks))
        return nothing
    end

    if iter.is_per_block

        if char_idx in iter.blocks[block_idx]
            return iter.data[block_idx], (char_idx + 1, block_idx)
        else
            return iterate(iter, (char_idx, block_idx + 1))
        end
    else
        return iter.data[char_idx], (char_idx + 1, 0)
    end
end

Base.length(iter::PerCharIterator) = last(last(iter.blocks))


# TODO: anything per-string should include lines?

function register_raw_glyph_boundingboxes!(plot)
    if !haskey(plot.attributes, :raw_glyph_boundingboxes)
        map!(gl_bboxes, plot.attributes, [:glyph_indices, :glyph_scales, :glyph_extents], :raw_glyph_boundingboxes)
    end
    return plot.raw_glyph_boundingboxes
end

"""
    raw_glyph_boundingboxes(plot::Text)

Returns the raw glyph bounding boxes of the text plot. These only include scaling
from fontsize. String layouting and application of rotation, offset and position
attributes is not included. Lines from LaTeXStrings are not included.
"""
raw_glyph_boundingboxes(plot) = register_raw_glyph_boundingboxes!(plot)[]::Vector{Rect2d}
raw_glyph_boundingboxes_obs(plot) = ComputePipeline.get_observable!(register_raw_glyph_boundingboxes!(plot))

# target: rotation aware layouting, e.g. Axis ticks, Menu, ...
function register_fast_glyph_boundingboxes!(plot)
    if !haskey(plot.attributes, :fast_glyph_boundingboxes)
        register_raw_glyph_boundingboxes!(plot)
        # To consider newlines (and word_wrap_width) we need to include origins.
        # To not include rotation we need to strip it from origins
        map!(
            plot.attributes, [:raw_glyph_boundingboxes, :marker_offset, :glyph_rotations],
            :fast_glyph_boundingboxes
        ) do bbs, origins, rotations

            return map(bbs, origins, rotations) do bb, o, rot
                glyphbb3 = Rect3d(to_ndim(Point3d, origin(bb), 0), to_ndim(Point3d, widths(bb), 0))
                return rotate_bbox(glyphbb3, rot) + o
            end
        end
    end
    return plot.fast_glyph_boundingboxes
end

"""
    fast_glyph_boundingboxes(plot::Text)

Returns the markerspace glyph boundingboxes without including `positions`.
Rotation and offset are included. Lines from LaTeXStrings are not included.
"""
fast_glyph_boundingboxes(plot) = register_fast_glyph_boundingboxes!(plot)[]::Vector{Rect3d}
fast_glyph_boundingboxes_obs(plot) = ComputePipeline.get_observable!(register_fast_glyph_boundingboxes!(plot))


# target: Menu? charbbs() replacement with more safety
function register_glyph_boundingboxes!(plot)
    if !haskey(plot.attributes, :glyph_boundingboxes)
        register_raw_glyph_boundingboxes!(plot)
        register_markerspace_positions!(plot)
        map!(
            plot.attributes,
            [:raw_glyph_boundingboxes, :marker_offset, :glyph_rotations, :text_blocks, :markerspace_positions],
            :glyph_boundingboxes
        ) do bbs, origins, rotations, blocks, positions

            return map(bbs, origins, rotations, PerCharIterator(blocks, positions)) do bb, o, rotation, position
                glyphbb3 = Rect3d(to_ndim(Point3d, origin(bb), 0), to_ndim(Point3d, widths(bb), 0))
                return rotate_bbox(glyphbb3, rotation) + o + position
            end
        end
    end
    return plot.glyph_boundingboxes
end

"""
    glyph_boundingboxes(plot)

Returns the final markerspace boundingbox of each glyph in the plot. This includes
all relevant attributes (glyphs, fontsize, string layouting, rotation, offset and
position). Lines from LaTeXStrings are not included.

Note that this bounding box is is reliant on the camera due to including positions
which need to be transformed to `markerspace`.
"""
glyph_boundingboxes(plot) = register_glyph_boundingboxes!(plot)[]::Vector{Rect3d}
glyph_boundingboxes_obs(plot) = ComputePipeline.get_observable!(register_glyph_boundingboxes!(plot))

# target: rotation aware layouting, e.g. Axis ticks, Menu, ...
function register_raw_string_boundingboxes!(plot)
    if !haskey(plot.attributes, :raw_string_boundingboxes)
        register_raw_glyph_boundingboxes!(plot)
        # To consider newlines (and word_wrap_width) we need to include origins.
        # To not include rotation we need to strip it from origins
        map!(
            plot.attributes, [:text_blocks, :raw_glyph_boundingboxes, :glyph_origins, :glyph_rotations, :text_spec_bboxes, :text_spec_block_indices],
            :raw_string_boundingboxes
        ) do blocks, bbs, origins, rotation, spec_bboxes, spec_block_indices

            text_bbs = map(blocks) do idxs
                output = Rect3d()
                for i in idxs
                    glyphbb = bbs[i]
                    glyphbb3 = Rect3d(to_ndim(Point3d, origin(glyphbb), 0), to_ndim(Point3d, widths(glyphbb), 0))
                    ms_bb = rotate_bbox(glyphbb3, rotation[i]) + origins[i]
                    output = update_boundingbox(output, ms_bb)
                end
                return output
            end

            for (block_idx, bb) in zip(spec_block_indices, spec_bboxes)
                text_bbs[block_idx] = update_boundingbox(text_bbs[block_idx], bb)
            end

            return text_bbs
        end
    end
    return plot.raw_string_boundingboxes
end

"""
    raw_string_boundingboxes(plot::Text)

Returns the markerspace string boundingboxes without including `positions` and `offset`.
Rotation is included. Lines from LaTeXStrings are included.
"""
raw_string_boundingboxes(plot) = register_raw_string_boundingboxes!(plot)[]::Vector{Rect3d}
raw_string_boundingboxes_obs(plot) = ComputePipeline.get_observable!(register_raw_string_boundingboxes!(plot))

# target: rotation aware layouting, e.g. Axis ticks, Menu, ...
function register_fast_string_boundingboxes!(plot)
    if !haskey(plot.attributes, :fast_string_boundingboxes)
        register_raw_glyph_boundingboxes!(plot)
        # To consider newlines (and word_wrap_width) we need to include origins.
        # To not include rotation we need to strip it from origins
        map!(
            plot.attributes, [:text_blocks, :raw_glyph_boundingboxes, :marker_offset, :glyph_rotations, :text_spec_bboxes, :text_spec_block_indices],
            :fast_string_boundingboxes
        ) do blocks, bbs, origins, rotation, spec_bboxes, spec_block_indices

            text_bbs = map(blocks) do idxs
                output = Rect3d(Point3d(NaN), Vec3d(0))
                for i in idxs
                    glyphbb = bbs[i]
                    glyphbb3 = Rect3d(to_ndim(Point3d, origin(glyphbb), 0), to_ndim(Point3d, widths(glyphbb), 0))
                    ms_bb = rotate_bbox(glyphbb3, rotation[i]) + origins[i]
                    output = update_boundingbox(output, ms_bb)
                end
                return output
            end

            for (block_idx, bb) in zip(spec_block_indices, spec_bboxes)
                text_bbs[block_idx] = update_boundingbox(text_bbs[block_idx], bb)
            end

            return text_bbs
        end
    end
    return plot.fast_string_boundingboxes
end

"""
    fast_string_boundingboxes(plot::Text)

Returns the markerspace string boundingboxes without including `positions`.
Rotation and offset are included. Lines from LaTeXStrings are included.
"""
fast_string_boundingboxes(plot) = register_fast_string_boundingboxes!(plot)[]::Vector{Rect3d}
fast_string_boundingboxes_obs(plot) = ComputePipeline.get_observable!(register_fast_string_boundingboxes!(plot))


# target: contour, textlabel
function register_string_boundingboxes!(plot)
    if !haskey(plot.attributes, :string_boundingboxes)
        register_fast_string_boundingboxes!(plot)
        register_markerspace_positions!(plot)
        # project positions to markerspace, add them
        map!(
            plot.attributes,
            [:fast_string_boundingboxes, :markerspace_positions],
            :string_boundingboxes
        ) do bbs, positions

            return map(bbs, positions) do bb, pos
                mini = minimum(bb)
                if isfinite(mini)
                    return bb + pos
                else # empty bboxes end up as Rect3d(Point3d(Inf), Vec3d(-Inf))
                    return Rect3d(pos, Vec3d(0))
                end
            end
        end
    end
    return plot.string_boundingboxes
end

"""
    string_boundingboxes(plot)

Returns the final markerspace boundingbox of each string in the plot. This includes
all relevant attributes (glyphs, fontsize, string layouting, rotation, offset and
position). Lines from LaTeXStrings are included.

Note that this bounding box is is reliant on the camera due to including positions
which need to be transformed to `markerspace`.
"""
string_boundingboxes(plot) = register_string_boundingboxes!(plot)[]::Vector{Rect3d}
string_boundingboxes_obs(plot) = ComputePipeline.get_observable!(register_string_boundingboxes!(plot))

# This can not be used as `boundingbox()` for Axis/camera limits due to it
# changing with camera updates
function register_full_boundingbox!(plot, target_space::Symbol)
    bbox_name = Symbol(target_space, :_boundingbox)
    if !haskey(plot.attributes, bbox_name)
        register_string_boundingboxes!(plot)
        scene_graph = parent_scene(plot).compute
        map!(plot.attributes, [:markerspace, :string_boundingboxes], bbox_name) do markerspace, bbs
            if markerspace === target_space
                return reduce(update_boundingbox, bbs, init = Rect3d())
            else
                proj = get_space_to_space_matrix(scene_graph, markerspace, target_space)
                bb = mapreduce(update_boundingbox, bbs, init = Rect3d()) do bb
                    return Rect3d(_project(proj, coordinates(bb)))
                end
                return bb
            end
        end
    end
    return getproperty(plot, bbox_name)
end

"""
    full_boundingbox(plot, target_space = plot.space[])

Returns the boundingbox of the full plot including all relevant text attributes
transformed to `target_space`. This include fontsize, string layouting, rotation,
offsets and positions. Lines from LaTeXStrings are included.

Note that this bounding box is is reliant on the camera due to including positions
which need to be transformed to `markerspace`.
"""
function full_boundingbox(plot::Text, target_space::Symbol = plot.space[])
    return register_full_boundingbox!(plot, target_space)[]::Rect3d
end
function full_boundingbox_obs(plot::Text, target_space::Symbol = plot.space[])
    return ComputePipeline.get_observable!(register_full_boundingbox!(plot, target_space))
end

# target: data_limits()
function register_data_limits!(plot)
    if !haskey(plot.attributes, :data_limits)
        register_string_boundingboxes!(plot)
        map!(
            plot.attributes,
            [:markerspace, :space, :string_boundingboxes, :positions],
            :data_limits
        ) do markerspace, space, bbs, positions

            if markerspace === space
                return reduce(update_boundingbox, bbs, init = Rect3d())
            else
                return Rect3d(positions)
            end
        end
    end
    return plot.data_limits
end

data_limits(plot::Text) = register_data_limits!(plot)[]::Rect3d
data_limits_obs(plot::Text) = ComputePipeline.get_observable!(register_data_limits!(plot))

######################


function texelems_and_layout(
        str::LaTeXString, fontscale_px,
        color, strokecolor, strokewidth, word_wrap_width
    )
    all_els = generate_tex_elements(str)
    els = filter(x -> x[1] isa TeXChar, all_els)

    # hacky, but attr per char needs to be fixed
    fs = Vec2f(first(fontscale_px))

    scales_2d = [Vec2f(x[3] * Vec2f(fs)) for x in els]

    texchars = [x[1] for x in els]
    glyphindices = [FreeTypeAbstraction.glyph_index(texchar) for texchar in texchars]
    fonts = [texchar.font for texchar in texchars]
    extents = GlyphExtent.(texchars)

    bboxes = map(extents, scales_2d) do ext, scale
        unscaled_hi_bb = height_insensitive_boundingbox_with_advance(ext)
        return Rect2f(
            origin(unscaled_hi_bb) * scale,
            widths(unscaled_hi_bb) * scale
        )
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

    n = length(glyphindices)
    layout = (
        glyphindices = UInt64.(glyphindices),
        fonts = fonts,
        origins = Point3f.(basepositions),
        extents = extents,
        scales = scales_2d,
        colors = fill(to_color(color), n),
        strokecolors = fill(to_color(strokecolor), n),
        strokewidths = fill(Float32(strokewidth), n),
        bbox = bb,
        baseline = 0.0f0,
    )

    return all_els, layout
end

iswhitespace(l::LaTeXString) = iswhitespace(replace(l.s, '$' => ""))


struct GlyphState
    x::Float32
    baseline::Float32
    size::Vec2f
    font::FreeTypeAbstraction.FTFont
    color::RGBAf
end

struct GlyphInfo
    glyph::Int
    font::FreeTypeAbstraction.FTFont
    origin::Point2f
    extent::GlyphExtent
    size::Vec2f
    color::RGBAf
    strokecolor::RGBAf
    strokewidth::Float32
end

# Copy constructor, to overwrite a field
function GlyphInfo(
        gi::GlyphInfo;
        glyph = gi.glyph,
        font = gi.font,
        origin = gi.origin,
        extent = gi.extent,
        size = gi.size,
        color = gi.color,
        strokecolor = gi.strokecolor,
        strokewidth = gi.strokewidth
    )

    return GlyphInfo(
        glyph,
        font,
        origin,
        extent,
        size,
        color,
        strokecolor,
        strokewidth
    )
end


function layout_text(rt::RichText, ts, f, fset, jus, lh, col)
    lines = [GlyphInfo[]]

    gs = GlyphState(0, 0, Vec2f(ts), f, col)

    process_rt_node!(lines, gs, rt, fset)

    apply_lineheight!(lines, lh)
    bbox = apply_justification!(lines, jus)

    return glyph_arrays(reduce(vcat, lines), bbox, 0.0f0)
end

# Flatten laid-out glyphs into the parallel arrays a glyph block is pushed from.
function glyph_arrays(infos::Vector{GlyphInfo}, bbox::Rect2f, baseline::Real)
    return (
        glyphindices = UInt64[i.glyph for i in infos],
        fonts = NativeFont[i.font for i in infos],
        origins = Point3f[to_ndim(Point3f, i.origin, 0) for i in infos],
        extents = GlyphExtent[i.extent for i in infos],
        scales = Vec2f[i.size for i in infos],
        colors = RGBAf[i.color for i in infos],
        strokecolors = RGBAf[i.strokecolor for i in infos],
        strokewidths = Float32[i.strokewidth for i in infos],
        bbox = bbox,
        baseline = Float32(baseline),
    )
end

function apply_lineheight!(lines, lh)
    for (i, line) in enumerate(lines)
        for j in eachindex(line)
            l = line[j]
            ox, oy = l.origin
            # TODO: Lineheight
            l = GlyphInfo(l; origin = Point2f(ox, oy - (i - 1) * 20))
            line[j] = l
        end
    end
    return
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

# Shifts each line by its share of the unused width and returns the layout box the
# lines occupy. Alignment happens downstream, against that box.
function apply_justification!(lines, justification::Real)

    max_xs = map(max_x_advance, lines)
    max_x = maximum(max_xs)

    # TODO: Should we check the next line if the first/last is empty?
    top_y = max_y_ascender(lines[1])
    bottom_y = min_y_descender(lines[end])

    for (i, line) in enumerate(lines)
        ju_offset = justification * (max_x - max_xs[i])
        for j in eachindex(line)
            l = line[j]
            line[j] = GlyphInfo(l; origin = l.origin .+ Point2f(ju_offset, 0))
        end
    end
    return Rect2f(0, bottom_y, max_x, top_y - bottom_y)
end

function process_rt_node!(lines, gs::GlyphState, rt::RichText, fonts)
    T = Val(rt.type)

    if T === Val(:subsup) || T === Val(:leftsubsup)
        if length(rt.children) != 2
            throw(ArgumentError("Found subsup rich text with $(length(rt.children)) which has to have exactly 2 children instead. The children were: $(rt.children)"))
        end
        sub, sup = rt.children
        sub_lines = Vector{GlyphInfo}[[]]
        new_gs_sub = new_glyphstate(gs, rt, Val(:subsup_sub), fonts)
        new_gs_sub_post = process_rt_node!(sub_lines, new_gs_sub, sub, fonts)
        sup_lines = Vector{GlyphInfo}[[]]
        new_gs_sup = new_glyphstate(gs, rt, Val(:subsup_sup), fonts)
        new_gs_sup_post = process_rt_node!(sup_lines, new_gs_sup, sup, fonts)
        if length(sub_lines) != 1
            error("It is not allowed to include linebreaks in a subsup rich text element, the invalid element was: $(repr(sub))")
        end
        if length(sup_lines) != 1
            error("It is not allowed to include linebreaks in a subsup rich text element, the invalid element was: $(repr(sup))")
        end
        sub_line = only(sub_lines)
        sup_line = only(sup_lines)
        if T === Val(:leftsubsup)
            right_align!(sub_line, sup_line)
        end
        append!(lines[end], sub_line)
        append!(lines[end], sup_line)
        x = max(new_gs_sub_post.x, new_gs_sup_post.x)
    else
        new_gs = new_glyphstate(gs, rt, T, fonts)
        for (i, c) in enumerate(rt.children)
            new_gs = process_rt_node!(lines, new_gs, c, fonts)
        end
        x = new_gs.x
    end

    return GlyphState(x, gs.baseline, gs.size, gs.font, gs.color)
end

function right_align!(line1::Vector{GlyphInfo}, line2::Vector{GlyphInfo})
    isempty(line1) || isempty(line2) && return
    xmax1, xmax2 = map((line1, line2)) do line
        maximum(line; init = 0.0f0) do ginfo
            ginfo.origin[1] + ginfo.size[1] * (ginfo.extent.ink_bounding_box.origin[1] + ginfo.extent.ink_bounding_box.widths[1])
        end
    end
    line_to_shift = xmax1 > xmax2 ? line2 : line1
    for j in eachindex(line_to_shift)
        l = line_to_shift[j]
        o = l.origin
        l = GlyphInfo(l; origin = o .+ Point2f(abs(xmax2 - xmax1), 0))
        line_to_shift[j] = l
    end
    return
end

function process_rt_node!(lines, gs::GlyphState, s::String, _)
    y = gs.baseline
    x = gs.x
    for char in s
        if char === '\n'
            x = 0
            push!(lines, GlyphInfo[])
        else
            bestfont = find_font_for_char(char, gs.font)
            gi = FreeTypeAbstraction.glyph_index(bestfont, char)
            gext = GlyphExtent(bestfont, char)
            ori = Point2f(x, y)
            push!(
                lines[end], GlyphInfo(
                    gi,
                    bestfont,
                    ori,
                    gext,
                    gs.size,
                    gs.color,
                    RGBAf(0, 0, 0, 0),
                    0.0f0,
                )
            )
            x = x + gext.hadvance * gs.size[1]
        end
    end
    return GlyphState(x, y, gs.size, gs.font, gs.color)
end

_get_color(attributes, default)::RGBAf = haskey(attributes, :color) ? to_color(attributes[:color]) : default
_get_font(attributes, default::NativeFont, fonts)::NativeFont = haskey(attributes, :font) ? to_font(fonts, attributes[:font]) : default
_get_fontsize(attributes, default)::Vec2f = haskey(attributes, :fontsize) ? Vec2f(to_fontsize(attributes[:fontsize])) : default
_get_offset(attributes, default)::Vec2f = haskey(attributes, :offset) ? Vec2f(attributes[:offset]) : default

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

iswhitespace(r::RichText) = iswhitespace(String(r))

interpolate_align(lb, ub, fraction) = Float32(lb * (1 - fraction) + ub * fraction)
