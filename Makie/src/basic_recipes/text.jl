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

to_string_arr(text::AbstractVector) = text
to_string_arr(text) = [text]

# The producer hands back the same array when the text is untouched, and `is_same`
# reads an aliased array as changed because it cannot tell one from a mutated one.
# Saying whether the text changed rather than leaving it to be guessed keeps a
# position update from re-running layout, which for an image handler (LaTeX) is the
# difference between moving a label and recompiling it.
text_update(value, changed::Bool) = ExplicitUpdate(Ref{Any}(value), changed ? :force : :deny)

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
    register_computation!(attr, inputs, [:_positions, :_text_update]) do inputs, changed, cached
        a_pos, a_text, args... = values(inputs)
        _, text_changed, args_changed... = values(changed)
        # Note: Could add RichText
        if args isa Tuple{<:Union{AbstractString, RichText}}
            # position data will always be wrapped in a Vector, so strings should too
            return ((a_pos,), text_update([args[1]], args_changed[1]))
        elseif args isa Tuple{<:AbstractVector{<:Union{AbstractString, RichText}}}
            return ((a_pos,), text_update(args[1], args_changed[1]))
        elseif args isa Tuple{<:AbstractVector{<:Tuple{<:Any, <:VecTypes}}}
            # [(text, pos), ...] argument
            return ((last.(args[1]),), text_update(first.(args[1]), args_changed[1]))
        else # assume position data
            return (args, text_update(to_string_arr(a_text), text_changed))
        end
    end

    map!(unwrap_explicit_update, attr, :_text_update, :input_text)

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

One [`TextLayout`](@ref) is appended per input string, keeping `text_blocks`
consistent with the parallel per-glyph and per-spec arrays.
"""
struct GlyphBuffer
    glyph_indices::Vector{UInt64}
    glyph_fonts::Vector{NativeFont}
    glyph_layout_origins::Vector{Point3f}
    glyph_extents::Vector{GlyphExtent}
    text_blocks::Vector{UnitRange{Int64}}
    layout_colors::Vector{RGBAf}
    glyph_scales::Vector{Vec2f}
    layout_strokewidths::Vector{Float32}
    layout_strokecolors::Vector{RGBAf}
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

function append_per_glyph!(dest::Vector, value, n::Int)
    isscalar(value) ? append!(dest, Iterators.repeated(value, n)) : append!(dest, value)
    return
end

"""
    TextLayout(glyphindices, fonts, origins, extents; bbox, baseline, scales,
        colors, strokecolors, strokewidths, specs = PlotSpec[],
        spec_bboxes = Rect3d[])

The layout result for one scalar text value. `origins` are in the layout frame,
described by `bbox` (the box `align` positions) and `baseline` (the y that
`valign = :baseline` puts on the anchor). `glyphindices`, `origins` and `extents`
are per glyph; the remaining glyph attributes are either per glyph or one value
for the whole block.

`specs` contains non-glyph plots such as LaTeX rules or a handler-rendered image.
Each one needs its visual bounding box in `spec_bboxes`, which only the handler
knows: a spec's positions don't imply its extent (a scatter marker covers far more
than the point it sits on).
"""
struct TextLayout{I, F, O, E, S, C, SC, SW}
    glyphindices::I
    fonts::F
    origins::O
    extents::E
    scales::S
    colors::C
    strokecolors::SC
    strokewidths::SW
    bbox::Rect2f
    baseline::Float32
    specs::Vector{PlotSpec}
    spec_bboxes::Vector{Rect3d}
end

function TextLayout(
        glyphindices, fonts, origins, extents;
        bbox, baseline, scales, colors, strokecolors, strokewidths,
        specs = PlotSpec[], spec_bboxes = Rect3d[]
    )
    return TextLayout(
        glyphindices, fonts, origins, extents, scales, colors, strokecolors,
        strokewidths, bbox, baseline, specs, spec_bboxes
    )
end

function TextLayout(; bbox, baseline, specs = PlotSpec[], spec_bboxes = Rect3d[])
    return TextLayout(
        UInt64[], NativeFont[], Point3f[], GlyphExtent[];
        bbox, baseline, scales = Vec2f[], colors = RGBAf[],
        strokecolors = RGBAf[], strokewidths = Float32[], specs, spec_bboxes
    )
end

function validate_glyph_value(name, value, n)
    (isscalar(value) || length(value) == n) && return
    error("Expected a scalar or $n values per glyph for $name, got $(length(value)).")
end

function append_text_layout!(buffer::GlyphBuffer, layout::TextLayout)
    n = length(layout.glyphindices)
    length(layout.origins) == n ||
        error("Expected $n glyph origins, got $(length(layout.origins)).")
    length(layout.extents) == n ||
        error("Expected $n glyph extents, got $(length(layout.extents)).")
    for name in (:fonts, :scales, :colors, :strokecolors, :strokewidths)
        validate_glyph_value(name, getfield(layout, name), n)
    end
    length(layout.specs) == length(layout.spec_bboxes) ||
        error("Expected one bounding box per text spec.")

    offset = length(buffer.glyph_indices)
    push!(buffer.text_blocks, (offset + 1):(offset + n))
    push!(buffer.block_bboxes, layout.bbox)
    push!(buffer.block_baselines, layout.baseline)

    append!(buffer.glyph_indices, layout.glyphindices)
    append!(buffer.glyph_layout_origins, layout.origins)
    append!(buffer.glyph_extents, layout.extents)
    append_per_glyph!(buffer.glyph_fonts, layout.fonts, n)
    append_per_glyph!(buffer.glyph_scales, layout.scales, n)
    append_per_glyph!(buffer.layout_colors, layout.colors, n)
    append_per_glyph!(buffer.layout_strokecolors, layout.strokecolors, n)
    append_per_glyph!(buffer.layout_strokewidths, layout.strokewidths, n)

    append!(buffer.layout_specs, layout.specs)
    append!(buffer.layout_spec_bboxes, layout.spec_bboxes)
    append!(
        buffer.text_spec_block_indices,
        Iterators.repeated(length(buffer.text_blocks), length(layout.specs))
    )
    return
end

"""
    TextAttributes

Everything about one text block except the string itself, as handed to
[`layout_text`](@ref). The values are already resolved for that block: an attribute given
per string is indexed, `fontsize` is a `Vec2f`, and `justification` is a fraction in 0..1
(`automatic` folded in against `halign`).

`align`, `rotation` and `offset` are deliberately absent. They are applied by a downstream
placement node, so a handler works in the block's own layout frame and changing them
re-runs placement rather than the handler.

This is a struct rather than a long argument list so that a new attribute can be added
without breaking existing handlers. Destructure the ones you need:

```julia
function Makie.layout_text(::MyHandler, str::AbstractString, attributes)
    (; fontsize, color) = attributes
    # ...
end
```
"""
struct TextAttributes
    font::NativeFont
    fonts::Any
    fontsize::Vec2f
    lineheight::Float32
    justification::Float32
    word_wrap_width::Float32
    color::RGBAf
    strokecolor::RGBAf
    strokewidth::Float32
end

# Makie's own text layout is just the `handler === nothing` implementation of
# `layout_text`, so the built-in path and a `text_handler` go through one protocol.

function layout_text(::Nothing, src, attributes::TextAttributes)
    return error(
        "`text` cannot lay out $(typeof(src)). Pass a `text_handler` with a " *
            "`layout_text` method for it, or convert it to a String, `rich` text or a LaTeXString."
    )
end

function layout_text(::Nothing, src::AbstractString, attributes::TextAttributes)
    (; font, fontsize, lineheight, justification, word_wrap_width) = attributes
    layout = layout_string(src, font, fontsize, lineheight, justification, word_wrap_width)

    return TextLayout(
        layout.glyphindices, layout.fonts, layout.origins, layout.extents;
        bbox = layout.bbox, baseline = layout.baseline,
        scales = fontsize, colors = attributes.color,
        strokecolors = attributes.strokecolor, strokewidths = attributes.strokewidth,
    )
end

function layout_text(::Nothing, src::RichText, attributes::TextAttributes)
    (; fontsize, font, fonts, justification, lineheight, color) = attributes
    layout = layout_richtext(src, fontsize, font, fonts, justification, lineheight, color)

    return TextLayout(
        layout.glyphindices, layout.fonts, layout.origins, layout.extents;
        bbox = layout.bbox, baseline = layout.baseline,
        scales = layout.scales, colors = layout.colors,
        strokecolors = layout.strokecolors, strokewidths = layout.strokewidths,
    )
end

function layout_text(::Nothing, src::LaTeXString, attributes::TextAttributes)
    (; fontsize, color, strokecolor, strokewidth, word_wrap_width) = attributes
    tex_elements, layout = texelems_and_layout(src, fontsize, color, strokecolor, strokewidth, word_wrap_width)
    # the rules share the glyphs' uniform size (`texelems_and_layout` takes the
    # first component too)
    spec = tex_linesegment_spec(tex_elements, fontsize[1], color)
    # a rule's extent is its two end points, give or take its thickness
    specs = spec === nothing ? PlotSpec[] : PlotSpec[spec]
    spec_bboxes = Rect3d[Rect3d(first(s.args)) for s in specs]

    return TextLayout(
        layout.glyphindices, layout.fonts, layout.origins, layout.extents;
        bbox = layout.bbox, baseline = layout.baseline,
        scales = layout.scales, colors = layout.colors,
        strokecolors = layout.strokecolors, strokewidths = layout.strokewidths,
        specs, spec_bboxes,
    )
end

function tex_linesegment_spec(tex_elements, fontsize, color::RGBAf)
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
    isempty(points) && return nothing
    return PlotSpec(:LineSegments, points; linewidth = widths, color = color)
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

"""
    bakes_display_attributes(handler, text) -> Bool

Whether laying `text` out resolves the display attributes, so that changing one has to
lay it out again. A handler is assumed to bake, since it may rasterize.
"""
bakes_display_attributes(handler, text) = handler !== nothing || !display_independent_layout(text)

################################################################################
### text_handler extension
################################################################################


"""
    layout_text(handler, src, attributes::TextAttributes) -> TextLayout

Lays out one text block with a `text_handler`. A handler claims an input type by having a
method for it and returns one [`TextLayout`](@ref) per call:

```julia
struct MyHandler end

function Makie.layout_text(::MyHandler, src::LaTeXString, attributes::Makie.TextAttributes)
    (; fontsize, color) = attributes
    # ...
    return Makie.TextLayout(glyphindices, fonts, origins, extents; bbox, baseline, ...)
end
```

Makie's own layout is the `handler === nothing` implementation of this same function, which
is what `text_handler = nothing` means and where input types a handler has no method for
end up, so handled and unhandled strings mix in one plot without the handler doing
anything. A handler that only decides once it sees the content hands the block back with
`layout_text(nothing, src, attributes)`.

Note that `LaTeXString <: AbstractString`, so a method taking `AbstractString` claims LaTeX
input as well and would lay out its raw source. Dispatch on `String` to leave it to Makie.

The layout is in the block's own frame: `align`, `rotation` and `offset` are applied
downstream, so changing them re-runs placement rather than the handler. The appearance
attributes in [`TextAttributes`](@ref) are there because a handler may either bake them in
(a rasterized image can't be recolored afterwards) or include them in the returned glyph
arrays.
"""
layout_text(handler, src, attributes) = layout_text(nothing, src, attributes)

# Pick out block `i`'s value from each attribute.
function block_attributes(
        i, fontsize, font, justification, lineheight, word_wrap_width,
        fonts, color, strokecolor, strokewidth
    )
    return TextAttributes(
        sv_getindex(font, i), fonts, to_2d_scale(sv_getindex(fontsize, i)),
        sv_getindex(lineheight, i), sv_getindex(justification, i), sv_getindex(word_wrap_width, i),
        sv_getindex(color, i), sv_getindex(strokecolor, i), sv_getindex(strokewidth, i)
    )
end

# An attribute is either one value for all strings or one per string. Indexing per
# glyph is not supported: shaping can merge code points into a single glyph, so
# `rich` text is how parts of a string get styled differently.
function validate_per_string(
        name::Symbol, value, n_strings::Int,
        hint = "To style parts of a string differently, use `rich` text."
    )
    (isscalar(value) || length(value) == n_strings) && return
    return error("Expected a scalar $name or one value per string ($n_strings), got $(length(value)). $hint")
end

# Apply a per-point transform to a spec's positional data (its first positional arg).
function transform_text_spec(spec::PlotSpec, f)
    new_positions = Point3f[f(p) for p in first(spec.args)]
    new_args = copy(spec.args)
    new_args[1] = new_positions
    return PlotSpec(spec.type, new_args...; spec.kwargs...)
end

# `align` only reaches text layout through this: automatic justification follows
# halign, everything else about alignment is applied after layout. Resolving it to
# a number here means an align change that leaves justification alone (a different
# valign, or halign on left-justified text) is filtered by `is_same` and never
# triggers a relayout.
function register_resolved_justification!(attr::ComputeGraph)
    return map!(attr, [:input_text, :justification, :validated_align], :resolved_justification) do input_text, justification, align
        isscalar(justification) && isscalar(align) && return justification2float(justification, align[1])
        # per-block values, so `input_text` sets the count rather than either input
        return Float32[
            justification2float(sv_getindex(justification, i), sv_getindex(align, i)[1])
                for i in eachindex(input_text)
        ]
    end
end

# The display attributes only reach layout when some text bakes them in; otherwise this
# stays `nothing` from one evaluation to the next, so recoloring never marks layout dirty.
function register_baked_display_attributes!(attr::ComputeGraph)
    inputs = [:input_text, :text_handler, :computed_color, :converted_strokecolor, :strokewidth]
    map!(attr, inputs, :baked_display_attributes) do text, handler, color, strokecolor, strokewidth
        # here rather than downstream so a bad length is reported when the plot is
        # created, not when its colors are first pulled
        for (name, value) in [(:color, color), (:strokecolor, strokecolor), (:strokewidth, strokewidth)]
            validate_per_string(name, value, length(text))
        end
        any(str -> bakes_display_attributes(handler, str), text) || return nothing
        return (color, strokecolor, strokewidth)
    end
    # the value alternates between `nothing` and a tuple as the text type changes
    ComputePipeline.set_type!(attr.baked_display_attributes, Any)
    return
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
        :baked_display_attributes,
    ]
    outputs = collect(fieldnames(GlyphBuffer))
    return register_computation!(attr, inputs, outputs) do inputs, changed, cached
        (; input_text, text_handler, fontsize, selected_font, resolved_justification) = inputs
        (; lineheight, word_wrap_width, fonts, baked_display_attributes) = inputs

        # Placeholders when nothing bakes: what a layouter puts in its glyph arrays for
        # those blocks is replaced by `register_glyph_display!` anyway.
        color, strokecolor, strokewidth = something(
            baked_display_attributes, (RGBAf(0, 0, 0, 1), RGBAf(0, 0, 0, 0), 0.0f0)
        )

        buffer = cached === nothing ? GlyphBuffer() : GlyphBuffer(cached)
        empty!(buffer)
        N = length(input_text)
        for (name, value) in [
                (:fontsize, fontsize), (:font, selected_font), (:lineheight, lineheight),
                (:word_wrap_width, word_wrap_width),
            ]
            validate_per_string(name, value, N)
        end

        for (i, str) in enumerate(input_text)
            attributes = block_attributes(
                i, fontsize, selected_font, resolved_justification, lineheight,
                word_wrap_width, fonts, color, strokecolor, strokewidth
            )
            append_text_layout!(buffer, layout_text(text_handler, str, attributes))
        end

        return node_outputs(buffer)
    end

end

"""
    register_glyph_display!(attr::ComputeGraph)

Expands `color`, `strokecolor` and `strokewidth` to one value per glyph. Text that bakes
them keeps what its layouter resolved; everything else takes the plot's value for its
string, which is why recoloring plain text costs an expansion rather than a layout.
"""
function register_glyph_display!(attr::ComputeGraph)
    inputs = [
        :input_text, :text_handler, :text_blocks,
        :layout_colors, :layout_strokecolors, :layout_strokewidths,
        :computed_color, :converted_strokecolor, :strokewidth,
    ]
    outputs = [:glyph_colors, :glyph_strokecolors, :glyph_strokewidths]
    return register_computation!(attr, inputs, outputs) do inputs, changed, cached
        (; input_text, text_handler, text_blocks) = inputs
        (; layout_colors, layout_strokecolors, layout_strokewidths) = inputs
        (; computed_color, converted_strokecolor, strokewidth) = inputs

        colors, strokecolors, strokewidths = cached === nothing ?
            (RGBAf[], RGBAf[], Float32[]) : empty!.(values(cached))

        for (i, block) in enumerate(text_blocks)
            if bakes_display_attributes(text_handler, input_text[i])
                append!(colors, view(layout_colors, block))
                append!(strokecolors, view(layout_strokecolors, block))
                append!(strokewidths, view(layout_strokewidths, block))
            else
                n = length(block)
                append_per_glyph!(colors, sv_getindex(computed_color, i), n)
                append_per_glyph!(strokecolors, sv_getindex(converted_strokecolor, i), n)
                append_per_glyph!(strokewidths, sv_getindex(strokewidth, i), n)
            end
        end

        return (colors, strokecolors, strokewidths)
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
        :validated_align, :rotation, :converted_offset,
        :layout_specs, :layout_spec_bboxes, :text_spec_block_indices,
    ]
    outputs = [:glyph_origins, :glyph_rotations, :text_specs, :text_spec_bboxes]
    return register_computation!(attr, inputs, outputs) do inputs, changed, cached
        (; glyph_layout_origins, text_blocks, block_bboxes, block_baselines) = inputs
        (; rotation, layout_specs, layout_spec_bboxes, text_spec_block_indices) = inputs
        (; validated_align, converted_offset) = inputs

        validate_per_string(
            :rotation, rotation, length(text_blocks),
            "Glyphs within a string share one rotation."
        )

        origins, rotations, specs, spec_bboxes = if cached === nothing
            (Point3f[], Quaternionf[], PlotSpec[], Rect3d[])
        else
            empty!.(values(cached))
        end

        shifts = map(eachindex(text_blocks)) do i
            return block_alignment_shift(block_bboxes[i], block_baselines[i], sv_getindex(validated_align, i))
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
            off = to_ndim(Vec3f, sv_getindex(converted_offset, i), 0)
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
    add_computation!(attr, Val(:computed_color); nan_color = :converted_nan_color)

    register_resolved_justification!(attr)

    # one output per `GlyphBuffer` field
    register_baked_display_attributes!(attr)
    register_glyph_layout!(attr)
    register_glyph_display!(attr)

    register_glyph_placement!(attr)

    map!(attr, [:glyph_origins, :converted_offset, :text_blocks], :marker_offset) do origins, offset, blocks
        return Point3f[origins[gi] + sv_getindex(offset, i) for (i, r) in enumerate(blocks) for gi in r]
    end

    register_position_transforms!(attr, input_name = :positions, transformed_name = :positions_transformed)

    # One anchor position per glyph, repeated within a string. `transform_func` is
    # applied before the repeat, so it runs once per string rather than once per glyph;
    # the `Glyphs` child inherits only the model and does not transform again. The float
    # type is kept so Float64 positions survive until the child's float32 rescaling.
    map!(attr, [:positions_transformed, :text_blocks], :per_glyph_positions) do positions, blocks
        PT = Point3{eltype(eltype(positions))}
        return PT[to_ndim(PT, sv_getindex(positions, i), 0) for (i, r) in enumerate(blocks) for _ in r]
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

    # `Text` is a recipe, so its attributes arrive unconverted. Layout bakes colors into
    # the glyph arrays and placement needs a 3d offset, so it converts what it consumes;
    # what it forwards to the `Glyphs` child is converted there.
    map!(to_color, attr, :color, :converted_color)
    map!(to_color, attr, :nan_color, :converted_nan_color)
    map!(to_color, attr, :strokecolor, :converted_strokecolor)
    map!(to_3d_offset, attr, :offset, :converted_offset)
    map!(attr, :align, :validated_align) do align
        validate_text_align(align)
        return align
    end
    register_colormapping!(attr, :converted_color)
    register_text_computations!(attr)
    return
end

function plot!(plot::Text)
    # `add_text_specs!` projects each block's anchor position, which needs the camera.
    # Primitives get this from `connect_plot!`; a recipe asks for it.
    register_camera!(parent_scene(plot), plot)
    add_glyphs!(plot)
    add_text_specs!(plot)
    return plot
end

# Materialize the non-glyph text specs (LaTeX rules, handler images, ...) as a plotlist
# child. Each spec is in its block's markerspace frame; here we add the block's projected
# position (per camera) and render in markerspace. Empty for plain text, so the plotlist
# has no children and no render objects.
function add_text_specs!(plot)
    register_model_clip_planes!(plot.attributes)
    map!(
        plot.attributes,
        [
            :text_specs, :text_spec_block_indices, :preprojection, :model_f32c,
            :positions_transformed_f32c, :model_clip_planes, :space, :markerspace, :visible,
        ],
        :_shifted_text_specs,
    ) do specs, block_indices, preprojection, model_f32c, positions, clip_planes, space, markerspace, visible
        isempty(specs) && return PlotSpec[]
        ms_positions = _project(preprojection * model_f32c, positions, clip_planes, space)
        return map(specs, block_indices) do spec, bidx
            shifted = transform_text_spec(spec, p -> p + ms_positions[bidx])
            kw = copy(shifted.kwargs)
            kw[:space] = markerspace
            kw[:visible] = visible
            return PlotSpec(shifted.type, shifted.args...; kw...)
        end
    end
    return plotlist!(plot, plot._shifted_text_specs)
end

function add_glyphs!(plot)
    return glyphs!(
        plot,
        # everything not resolved per glyph below travels as is, so `visible`,
        # `depth_shift`, `fxaa` and friends reach what actually draws. `alpha` is
        # excluded because it is already folded into the glyph colors.
        shared_attributes(
            plot, Glyphs;
            drop = [:color, :alpha, :strokecolor, :strokewidth, :rotation, :marker_offset]
        ),
        plot.per_glyph_positions;
        glyphindices = plot.glyph_indices,
        font_per_char = plot.glyph_fonts,
        marker_offset = plot.marker_offset,
        scale = plot.glyph_scales,
        color = plot.glyph_colors,
        rotation = plot.glyph_rotations,
        strokecolor = plot.glyph_strokecolors,
        strokewidth = plot.glyph_strokewidths,
        transformation = :inherit_model,
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


function layout_richtext(rt::RichText, ts, f, fset, jus, lh, col)
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
