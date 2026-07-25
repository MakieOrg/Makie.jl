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
            return ((a_pos,), Ref{Any}(args[1]))
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

function per_glyph_getindex(x, text_blocks::Vector{UnitRange{Int}}, gi::Int, bi::Int)
    if isscalar(x)
        return x
    elseif isa(x, AbstractVector)
        N_strings = length(text_blocks)
        if (N_strings > 0) && (length(x) == last(last(text_blocks)))
            return x[gi] # use per glyph index
        elseif length(x) == N_strings
            return x[bi] # use per text block index
        else
            error("Invalid length of attribute $(typeof(x)). Length ($(length(x))) != $(length(glyphs)) or $(length(text_blocks))")
        end
    else
        return x
    end
end

function per_text_getindex(x, text_blocks::Vector{UnitRange{Int}}, bi::Int)
    if isscalar(x)
        return x
    elseif isa(x, AbstractVector)
        N_strings = length(text_blocks)
        if (N_strings > 0) && (length(x) == last(last(text_blocks))) # data is per glyph
            return view(x, text_blocks[bi]) # use per glyph index
        elseif length(x) == N_strings
            return x[bi] # use per text block index
        else
            error("Invalid length of attribute $(typeof(x)). Length ($(length(x))) != $(length(glyphs)) or $(length(text_blocks))")
        end
    else
        return x
    end
end

function per_text_block(f, text_blocks::Vector{UnitRange{Int}}, args::Tuple)
    _getindex(x, bi) = per_text_getindex(x, text_blocks, bi)
    for block_idx in eachindex(text_blocks)
        f(_getindex.(args, block_idx)...)
    end
    return
end

function per_glyph_attributes(f, text_blocks::Vector{UnitRange{Int}}, args::Tuple)
    _getindex(x, gi, bi) = per_glyph_getindex(x, text_blocks, gi, bi)
    glyph_idx = 1
    for block_idx in eachindex(text_blocks)
        for _ in text_blocks[block_idx]
            f(_getindex.(args, glyph_idx, block_idx)...)
            glyph_idx += 1
        end
    end
    return
end

function map_per_glyph(text_blocks::Vector{UnitRange{Int}}, Typ, arg)
    isscalar(arg) && return fill(arg, last(last(glyphs)))
    result = Typ[]
    per_glyph_attributes(text_blocks, (arg,)) do a
        push!(result, a)
    end
    return result
end


function get_from_collection(glyphcollection::AbstractArray, name::Symbol, Typ)
    result = Typ[]
    for g in glyphcollection
        arr = getfield(g, name)
        if arr isa Vector
            append!(result, arr)
        else
            _arr = arr.sv
            if _arr isa Vector
                append!(result, _arr)
            else
                append!(result, (_arr for i in 1:length(g.glyphs)))
            end
        end
    end
    return result
end

function get_text_blocks(gcs)
    text_blocks = UnitRange{Int}[]
    curr = 1
    for g in gcs
        push!(text_blocks, curr:(curr + length(g.glyphs)))
        curr += length(g.glyphs)
    end
    return text_blocks
end

#####################################
# New stuff

function per_glyph_block(data, block_idx, N_blocks, block::UnitRange)
    block_length = length(block)
    if isscalar(data)
        return fill(data, block_length)
    elseif length(data) == N_blocks
        return fill(data[block_idx], block_length)
    else
        return view(data, block)
    end
end

function convert_text_string!(
        outputs::NamedTuple,
        input_text::AbstractString, i, N, fontsize, font, align, rotation, justification,
        lineheight, word_wrap_width, offset, fonts, color, strokecolor, strokewidth
    )

    args = sv_getindex.((font, fontsize, align, lineheight, justification, word_wrap_width, rotation), i)
    nt = glyph_collection(input_text, args...)
    curr = length(outputs.glyphindices)
    block = (curr + 1):(curr + length(nt.glyphindices))

    push!(outputs.text_blocks, block)
    append!(outputs.glyphindices, nt.glyphindices)
    append!(outputs.font_per_char, nt.font_per_char)
    append!(outputs.glyph_origins, nt.char_origins)
    append!(outputs.glyph_extents, nt.glyph_extents)

    scales = per_glyph_block(to_2d_scale(fontsize), i, N, block) # TODO: convert_attribute?
    rotations = per_glyph_block(rotation, i, N, block)
    colors = per_glyph_block(color, i, N, block)

    # TODO: Should we get rid of this in general?
    gc = GlyphCollection(
        nt.glyphindices,
        nt.font_per_char,
        nt.char_origins,
        nt.glyph_extents,
        scales,
        rotations,
        colors,
        RGBAf[],
        Float32[]
    )

    push!(outputs.glyphcollections, gc)
    append!(outputs.text_color, colors)
    append!(outputs.text_rotation, rotations)
    append!(outputs.text_scales, scales)

    append!(outputs.text_strokecolor, per_glyph_block(strokecolor, i, N, block))
    append!(outputs.text_strokewidth, per_glyph_block(strokewidth, i, N, block))

    return
end

function convert_text_string!(
        outputs::NamedTuple,
        input_text::RichText, i, N, fontsize, font, align, rotation, justification,
        lineheight, word_wrap_width, offset, fonts, color, strokecolor, strokewidth
    )

    args = sv_getindex.((fontsize, font, fonts, align, rotation, justification, lineheight, color), i)
    gc = layout_text(input_text, args...)
    curr = length(outputs.glyphindices)
    n = length(gc.glyphs)

    push!(outputs.glyphcollections, gc)
    push!(outputs.text_blocks, (curr + 1):(curr + n))
    append!(outputs.glyphindices, gc.glyphs)
    append!(outputs.glyph_origins, gc.origins)
    append!(outputs.glyph_extents, gc.extents)

    append!(outputs.font_per_char, collect_vector(gc.fonts, n))
    append!(outputs.text_color, collect_vector(gc.colors, n))
    append!(outputs.text_strokecolor, collect_vector(gc.strokecolors, n))
    append!(outputs.text_strokewidth, collect_vector(gc.strokewidths, n))
    append!(outputs.text_rotation, collect_vector(gc.rotations, n))
    append!(outputs.text_scales, collect_vector(gc.scales, n))

    return
end

function convert_text_string!(
        outputs::NamedTuple,
        input_text::LaTeXString, i, N, fontsize, font, align, rotation, justification,
        lineheight, word_wrap_width, offset, fonts, color, strokecolor, strokewidth
    )

    args = sv_getindex.((fontsize, align, rotation, color, strokecolor, strokewidth, word_wrap_width), i)
    tex_elements, gc, tex_offsets = texelems_and_glyph_collection(input_text, args...)
    curr = length(outputs.glyphindices)
    n = length(gc.glyphs)

    push!(outputs.glyphcollections, gc)
    push!(outputs.text_blocks, (curr + 1):(curr + n))
    append!(outputs.glyphindices, gc.glyphs)
    append!(outputs.glyph_origins, gc.origins)
    append!(outputs.glyph_extents, gc.extents)
    append!(outputs.font_per_char, collect_vector(gc.fonts, n))
    append!(outputs.text_color, collect_vector(gc.colors, n))
    append!(outputs.text_strokecolor, collect_vector(gc.strokecolors, n))
    append!(outputs.text_strokewidth, collect_vector(gc.strokewidths, n))
    append!(outputs.text_rotation, collect_vector(gc.rotations, n))
    append!(outputs.text_scales, collect_vector(gc.scales, n))

    append_tex_linesegment_data!(
        outputs, tex_offsets, tex_elements,
        args[1], args[3], args[4], sv_getindex(offset, i)
    )
    # args = fontsize, rotation, color

    return
end

function append_tex_linesegment_data!(
        outputs::NamedTuple,
        tex_offset, tex_elements, fontsize, rotation::Quaternion, color::RGBAf, offset::VecTypes{3}
    )

    points = Point3f[]
    widths = Float32[]
    for (element, position, _) in tex_elements
        element isa MathTeXEngine.HLine || continue
        h = element
        x, y = position
        p0 = rotation * to_ndim(Point3f, fontsize .* Point2f(x, y) .- tex_offset, 0) .+ offset
        p1 = rotation * to_ndim(Point3f, fontsize .* Point2f(x + h.width, y) .- tex_offset, 0) .+ offset
        push!(points, p0, p1)
        push!(widths, fontsize * h.thickness, fontsize * h.thickness)
    end
    isempty(points) && return
    push_text_spec!(outputs, PlotSpec(:LineSegments, points; linewidth = widths, color = color))
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

# Reuse cached glyph geometry, recomputing only the per-glyph display arrays.
# Valid only when no layout-affecting input changed and every block's text has
# `display_independent_layout == true` (checked by the caller).
function reuse_glyph_layout(cached, color, strokecolor, strokewidth)
    (gcs, gi, fpc, go, ge, tb, _, trot, tscale, _, _, ts, tsbi, tsbb) = cached
    N = length(tb)
    text_color = RGBAf[]
    text_strokecolor = RGBAf[]
    text_strokewidth = Float32[]
    for (i, block) in enumerate(tb)
        append!(text_color, per_glyph_block(color, i, N, block))
        append!(text_strokecolor, per_glyph_block(strokecolor, i, N, block))
        append!(text_strokewidth, per_glyph_block(strokewidth, i, N, block))
    end
    return (gcs, gi, fpc, go, ge, tb, text_color, trot, tscale, text_strokewidth, text_strokecolor, ts, tsbi, tsbb)
end

################################################################################
### text_handler extension
################################################################################

"""
    compile_text(handler, src, font, fonts, fontsize, lineheight, justification, word_wrap_width, color, strokecolor, strokewidth)

Engine step of a `text_handler`. Define methods dispatching on the input type the handler
accepts (e.g. `LaTeXString`). Return a `CompiledText`, or a custom payload with a matching
`place_text!` method (e.g. a rasterized image marker), or `nothing` to fall through to the
built-in path.

The appearance attributes (`color`, `strokecolor`, `strokewidth`) are passed because some
handlers bake them into their output (a rasterized LaTeX image can't be recolored
afterwards). Glyph-based handlers can ignore them and let `place_text!` apply them to the
glyph batch instead. `place_text!` receives the same appearance attributes plus the
placement ones (align, rotation, offset), which are never baked.
"""
compile_text(handler, src, font, fonts, fontsize, lineheight, justification, word_wrap_width, color, strokecolor, strokewidth) = nothing

"""
    CompiledGlyphs

Backend-neutral, unaligned glyph layout (fontsize baked in, glyphs only), carried by
`CompiledText`. The Makie-provided `place_text!` computes the alignment shift from `bbox`
and `baseline`, applies rotation and offset and the block color, and merges the glyphs
into the shared `Glyphs` batch. Non-glyph output (rules, images, ...) travels alongside
as `CompiledText.specs`, not in here.
"""
struct CompiledGlyphs
    glyphindices::Vector{UInt64}
    fonts::Vector{NativeFont}
    origins::Vector{Point3f}       # unaligned layout origins
    extents::Vector{GlyphExtent}
    scales::Vector{Vec2f}
    bbox::Rect2f                   # alignment box for :top/:bottom/:center/fractions
    baseline::Float32              # baseline y in the layout frame, for valign = :baseline
end

"""
    CompiledText(glyphs::CompiledGlyphs)
    CompiledText(specs::Vector{PlotSpec})
    CompiledText(glyphs::CompiledGlyphs, specs::Vector{PlotSpec})

Return value of `compile_text`: an optional glyph layout plus optional non-glyph plots
(rules, images, ...) for one text block. A handler constructs it from whichever parts it
produces.
"""
struct CompiledText
    glyphs::Union{Nothing, CompiledGlyphs}
    specs::Union{Nothing, Vector{PlotSpec}}
end
CompiledText(glyphs::CompiledGlyphs) = CompiledText(glyphs, nothing)
CompiledText(specs::Vector{PlotSpec}) = CompiledText(nothing, specs)

# Route one text block through the handler. Returns true if the handler produced
# output, false to fall through to the built-in `convert_text_string!` path.
function handle_text!(
        outputs, handler, str, i, N, fontsize, font, align, rotation, justification,
        lineheight, word_wrap_width, offset, fonts, color, strokecolor, strokewidth
    )
    compiled = compile_text(
        handler, str, sv_getindex(font, i), fonts, sv_getindex(fontsize, i),
        sv_getindex(lineheight, i), sv_getindex(justification, i), sv_getindex(word_wrap_width, i),
        sv_getindex(color, i), sv_getindex(strokecolor, i), sv_getindex(strokewidth, i)
    )
    compiled === nothing && return false
    place_text!(
        outputs, compiled, sv_getindex(align, i), sv_getindex(rotation, i),
        sv_getindex(offset, i), sv_getindex(color, i), sv_getindex(strokecolor, i),
        sv_getindex(strokewidth, i)
    )
    return true
end

# Makie-provided placement for the neutral CompiledText payload: compute the
# alignment shift, merge the glyphs into the shared batch, and emit any non-glyph
# specs (rules, images, ...) into the text_specs plotlist channel.
function place_text!(outputs, c::CompiledText, align, rotation, offset, color, strokecolor, strokewidth)
    glyphs = c.glyphs
    shift = if glyphs === nothing
        Vec3f(0)
    else
        halign, valign = align
        bb = glyphs.bbox
        xshift = get_xshift(minimum(bb)[1], maximum(bb)[1], halign)
        yshift = get_yshift(minimum(bb)[2], maximum(bb)[2], valign; default = glyphs.baseline)
        Vec3f(xshift, yshift, 0)
    end

    if glyphs === nothing
        curr = length(outputs.glyphindices)
        push!(outputs.text_blocks, (curr + 1):curr) # empty block keeps per-string indices aligned
    else
        place_glyphs!(outputs, glyphs, shift, rotation, color, strokecolor, strokewidth)
    end

    if c.specs !== nothing
        for spec in c.specs
            placed = transform_text_spec(spec, p -> rotation * (to_ndim(Point3f, p, 0) - shift) + offset)
            # specs that don't set their own color follow the text color (e.g. rules)
            haskey(placed.kwargs, :color) || (placed.kwargs[:color] = color)
            push_text_spec!(outputs, placed)
        end
    end
    return
end

function place_glyphs!(outputs, c::CompiledGlyphs, shift, rotation, color, strokecolor, strokewidth)
    n = length(c.glyphindices)
    curr = length(outputs.glyphindices)
    push!(outputs.text_blocks, (curr + 1):(curr + n))
    origins = Point3f[rotation * (o - shift) for o in c.origins]
    append!(outputs.glyphindices, c.glyphindices)
    append!(outputs.font_per_char, c.fonts)
    append!(outputs.glyph_origins, origins)
    append!(outputs.glyph_extents, c.extents)
    append!(outputs.text_scales, c.scales)
    append!(outputs.text_color, fill(color, n))
    append!(outputs.text_rotation, fill(rotation, n))
    append!(outputs.text_strokecolor, fill(strokecolor, n))
    append!(outputs.text_strokewidth, fill(strokewidth, n))
    push!(outputs.glyphcollections, GlyphCollection(c.glyphindices, c.fonts, origins, c.extents, c.scales, rotation, color, strokecolor, strokewidth))
    return
end

# Apply a per-point transform to a spec's positional data (its first positional arg).
function transform_text_spec(spec::PlotSpec, f)
    new_positions = Point3f[f(p) for p in first(spec.args)]
    new_args = copy(spec.args)
    new_args[1] = new_positions
    return PlotSpec(spec.type, new_args...; spec.kwargs...)
end

# Push a placed (markerspace, block-relative) spec into the text_specs plotlist
# channel, tagged with the current block index and its bounding box.
function push_text_spec!(outputs, spec::PlotSpec)
    push!(outputs.text_specs, spec)
    push!(outputs.text_spec_block_indices, length(outputs.text_blocks))
    push!(outputs.text_spec_bboxes, Rect3d(first(spec.args)))
    return
end

"""
    MathTeXHandler()

A `text_handler` that lays out `LaTeXString`s with MathTeXEngine.jl through the
generic `compile_text`/`place_text!` protocol. Setting `text_handler = MathTeXHandler()`
routes LaTeX math through the pluggable path; non-LaTeX inputs fall through.
"""
struct MathTeXHandler end

function compile_text(::MathTeXHandler, str::LaTeXString, font, fonts, fontsize, lineheight, justification, word_wrap_width, color, strokecolor, strokewidth)
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

    rule_points = Point3f[]
    rule_widths = Float32[]
    for (element, position, _) in all_els
        element isa MathTeXEngine.HLine || continue
        x, y = position
        push!(rule_points, to_ndim(Point3f, fs .* Point2f(x, y), 0), to_ndim(Point3f, fs .* Point2f(x + element.width, y), 0))
        w = Float32(fs[1] * element.thickness)
        push!(rule_widths, w, w)
    end
    specs = PlotSpec[]
    isempty(rule_points) || push!(specs, PlotSpec(:LineSegments, rule_points; linewidth = rule_widths))

    return CompiledText(CompiledGlyphs(glyphindices, glyphfonts, origins, extents, scales, bb, 0.0f0), specs)
end

function compute_glyph_collections!(attr::ComputeGraph)
    inputs = [
        :input_text,
        :text_handler,
        :fontsize,
        :selected_font,
        :align,
        :rotation,
        :justification,
        :lineheight,
        :word_wrap_width,
        :offset,
        :fonts,
        :computed_color,
        :strokecolor,
        :strokewidth,
    ]
    outputs = [
        :glyphcollections, :glyphindices,
        :font_per_char,
        :glyph_origins, :glyph_extents,
        :text_blocks,
        :text_color, :text_rotation, :text_scales,
        :text_strokewidth, :text_strokecolor,
        :text_specs, :text_spec_block_indices, :text_spec_bboxes,
    ]
    return register_computation!(attr, inputs, outputs) do (input_texts, text_handler, _inputs...), changed, cached
        if cached !== nothing && text_handler === nothing && all(display_independent_layout, input_texts) &&
                !changed.input_text && !changed.fontsize && !changed.selected_font &&
                !changed.align && !changed.rotation && !changed.justification &&
                !changed.lineheight && !changed.word_wrap_width && !changed.offset && !changed.fonts
            return reuse_glyph_layout(cached, _inputs[10], _inputs[11], _inputs[12])
        end

        _outputs = (
            glyphcollections = GlyphCollection[],
            glyphindices = UInt64[],
            font_per_char = NativeFont[],
            glyph_origins = Point3f[],
            glyph_extents = GlyphExtent[],
            text_blocks = UnitRange{Int64}[],
            text_color = RGBAf[],
            text_rotation = Quaternionf[],
            text_scales = Vec2f[],
            text_strokewidth = Float32[],
            text_strokecolor = RGBAf[],
            text_specs = PlotSpec[],
            text_spec_block_indices = Int[],
            text_spec_bboxes = Rect3d[],
        )
        # strokewidth = Float32[] # TODO: Skipped?

        N = length(input_texts)
        for (block_index, str) in enumerate(input_texts)
            if text_handler === nothing || !handle_text!(_outputs, text_handler, str, block_index, N, _inputs...)
                convert_text_string!(_outputs, str, block_index, N, _inputs...)
            end
        end

        return values(_outputs)
    end

end

function register_text_computations!(attr::ComputeGraph)
    map!(to_font, attr, [:fonts, :font], :selected_font)

    # Resolve colormapping to colors early. This allows rich text which returns
    # its own colors to be mixed with other text types which dont.
    add_computation!(attr, Val(:computed_color))

    # This computes :glyphindices, :font_per_char, :glyph_origins, :glyph_extents, :text_blocks
    # And :glyphcollection if applicable
    compute_glyph_collections!(attr)

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
        glyphindices = plot.glyphindices,
        font_per_char = plot.font_per_char,
        marker_offset = plot.marker_offset,
        scale = plot.text_scales,
        color = plot.text_color,
        rotation = plot.text_rotation,
        strokecolor = plot.text_strokecolor,
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
        map!(gl_bboxes, plot.attributes, [:glyphindices, :text_scales, :glyph_extents], :raw_glyph_boundingboxes)
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
            plot.attributes, [:raw_glyph_boundingboxes, :marker_offset, :text_rotation],
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
            [:raw_glyph_boundingboxes, :marker_offset, :text_rotation, :text_blocks, :markerspace_positions],
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
            plot.attributes, [:text_blocks, :raw_glyph_boundingboxes, :glyph_origins, :text_rotation, :text_spec_bboxes, :text_spec_block_indices],
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
            plot.attributes, [:text_blocks, :raw_glyph_boundingboxes, :marker_offset, :text_rotation, :text_spec_bboxes, :text_spec_block_indices],
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


function texelems_and_glyph_collection(
        str::LaTeXString, fontscale_px, align,
        rotation, color, strokecolor, strokewidth, word_wrap_width
    )
    halign, valign = align
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

    xshift = get_xshift(minimum(bb)[1], maximum(bb)[1], halign)
    yshift = get_yshift(minimum(bb)[2], maximum(bb)[2], valign, default = 0.0f0)

    shift = Vec3f(xshift, yshift, 0)
    positions = basepositions .- Ref(shift)
    positions .= Ref(rotation) .* positions

    pre_align_gl = GlyphCollection(
        glyphindices,
        fonts,
        Point3f.(positions),
        extents,
        scales_2d,
        rotation,
        color,
        strokecolor,
        strokewidth
    )

    return all_els, pre_align_gl, Point2f(xshift, yshift)
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
    rotation::Quaternionf
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
        rotation = gi.rotation,
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
        rotation,
        color,
        strokecolor,
        strokewidth
    )
end


function GlyphCollection(v::Vector{GlyphInfo})
    return GlyphCollection(
        [i.glyph for i in v],
        [i.font for i in v],
        [Point3f(i.origin..., 0) for i in v],
        [i.extent for i in v],
        [i.size for i in v],
        [i.rotation for i in v],
        [i.color for i in v],
        [i.strokecolor for i in v],
        [i.strokewidth for i in v],
    )
end


function layout_text(rt::RichText, ts, f, fset, al, rot, jus, lh, col)
    lines = [GlyphInfo[]]

    gs = GlyphState(0, 0, Vec2f(ts), f, col)

    process_rt_node!(lines, gs, rt, fset)

    apply_lineheight!(lines, lh)
    apply_alignment_and_justification!(lines, jus, al)

    gc = GlyphCollection(reduce(vcat, lines))
    gc.origins .= Ref(rot) .* gc.origins
    @assert gc.rotations.sv isa Vector # should always be a vector because that's how the glyphcollection is created
    gc.rotations.sv .= Ref(rot) .* gc.rotations.sv
    return gc
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

function apply_alignment_and_justification!(lines, ju, al)

    max_xs = map(max_x_advance, lines)
    max_x = maximum(max_xs)

    # TODO: Should we check the next line if the first/last is empty?
    top_y = max_y_ascender(lines[1])
    bottom_y = min_y_descender(lines[end])

    al_offset_x = get_xshift(0.0f0, max_x, al[1]; default = 0.0f0)
    al_offset_y = get_yshift(bottom_y, top_y, al[2]; default = 0.0f0)

    fju = float_justification(ju, al)

    for (i, line) in enumerate(lines)
        ju_offset = fju * (max_x - max_xs[i])
        for j in eachindex(line)
            l = line[j]
            o = l.origin
            l = GlyphInfo(l; origin = o .- Point2f(al_offset_x - ju_offset, al_offset_y))
            line[j] = l
        end
    end
    return
end

function float_justification(ju, al)::Float32
    halign = al[1]
    return float_justification = if ju === automatic
        get_xshift(0.0f0, 1.0f0, halign)
    else
        get_xshift(0.0f0, 1.0f0, ju; default = ju) # errors if wrong symbol is used
    end
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
                    to_rotation(0),
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

function get_xshift(lb, ub, align; default = 0.5f0)
    if align isa Symbol
        align = align === :left ? 0.0f0 :
            align === :center ? 0.5f0 :
            align === :right ? 1.0f0 : default
    end
    return lb * (1 - align) + ub * align |> Float32
end

function get_yshift(lb, ub, align; default = 0.5f0)
    if align isa Symbol
        align = align === :bottom ? 0.0f0 :
            align === :center ? 0.5f0 :
            align === :top ? 1.0f0 : default
    end
    return lb * (1 - align) + ub * align |> Float32
end
