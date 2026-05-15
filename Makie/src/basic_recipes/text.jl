function check_textsize_deprecation(@nospecialize(dictlike))
    return if haskey(dictlike, :textsize)
        throw(ArgumentError("`textsize` has been renamed to `fontsize` in Makie v0.19. Please change all occurrences of `textsize` to `fontsize` or revert back to an earlier version."))
    end
end

# Text primitives: pluggable graphical elements that a string layout can emit
# alongside (or instead of) glyphs. Built-in: glyphs and MathTeX line segments
# have dedicated channels for performance; arbitrary primitives go through
# the `text_primitives` channel below and are dispatched to child plots via
# `register_text_primitive_plot!`.

"""
    AbstractTextPrimitive

Supertype for graphical elements that a `text` plot can render at the
markerspace position of a text block. Built-in subtypes include
[`ImageTextPrimitive`](@ref); downstream packages (e.g. MakieTeX) define
their own to plug arbitrary content into `text`.

A subtype `P` must implement:

* `text_primitive_bbox(p::P)::Rect3d` — markerspace bounding box relative to
  the text block origin (used by the text plot's bounding-box pipeline).
* `register_text_primitive_plot!(plot::Plot, ::Type{P}, items::Vector{P}, block_indices::Vector{Int})`
  — register a child plot that renders `items`, observing the text plot's
  current markerspace block positions.

Items are pushed by `convert_text_string!` overloads (one per input text type)
into the `outputs.text_primitives` channel.
"""
abstract type AbstractTextPrimitive end

function text_primitive_bbox end
function register_text_primitive_plot! end

"""
    is_text_input(::Type) -> Bool

Trait that tells the `text` recipe "this type is one of my single-element
inputs, route it into the string dispatch path rather than treating it as
position data." Default `false`; built-in `true` for `AbstractString` and
`RichText`. Downstream packages opt their types in with one method:

    Makie.is_text_input(::Type{TeXString}) = true

No subtyping required — the package's `convert_text_string!` method on the
concrete type still does the work; this trait just gets the value to it.
"""
is_text_input(::Type) = false
is_text_input(::Type{<:AbstractString}) = true
is_text_input(::Type{<:RichText}) = true
is_text_input(x) = is_text_input(typeof(x))

"""
    ImageTextPrimitive(image, marker_offset::Vec3f, size::Vec2f, rotation::Quaternionf)

A text primitive that renders `image` as a single scatter marker at the
text block's position. Used by e.g. MakieTeX to embed pre-rendered LaTeX
into a Makie `text` plot.

* `image`     — any marker accepted by `scatter` (typically a `Matrix{<:Colorant}`)
* `marker_offset` — markerspace offset from the block origin to the marker's
                    center (this matches `scatter`'s `marker_offset` semantics)
* `size`      — markerspace marker size
* `rotation`  — applied to the marker by scatter
"""
struct ImageTextPrimitive{I} <: AbstractTextPrimitive
    image::I
    marker_offset::Vec3f
    size::Vec2f
    rotation::Quaternionf
end

function text_primitive_bbox(p::ImageTextPrimitive)
    half = 0.5 .* Vec3d(p.size..., 0)
    bb = Rect3d(to_ndim(Point3d, p.marker_offset, 0) .- half, Vec3d(p.size..., 0))
    return rotate_bbox(bb, p.rotation)
end

# We sort out position vs string(-like) vs mixed arguments before convert_arguments,
# so that we only get positions here
conversion_trait(::Type{<:Text}, args...) = PointBased()

convert_attribute(o, ::key"offset", ::key"text") = to_3d_offset(o) # same as marker_offset in scatter
convert_attribute(f, ::key"font", ::key"text") = f # later conversion with fonts

# Positions are always vectors so text should be too. Anything not already
# a vector is wrapped in one — that includes built-in string types and any
# downstream payload that opted in via `is_text_input`.
convert_attribute(x::AbstractVector, ::key"text", ::key"text") = Ref{Any}(vec(x))
convert_attribute(x, ::key"text", ::key"text") = Ref{Any}([x])

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
        # A single arg that opts in to `is_text_input` (built-in for
        # AbstractString/RichText) is the text; the position comes from the
        # attr. A vector whose element type opts in is a vector of texts.
        if length(args) == 1 && is_text_input(typeof(args[1]))
            # position data will always be wrapped in a Vector, so strings should too
            return ((a_pos,), Ref{Any}([args[1]]))
        elseif length(args) == 1 && args[1] isa AbstractVector && is_text_input(eltype(args[1]))
            return ((a_pos,), Ref{Any}(args[1]))
        elseif args isa Tuple{<:AbstractVector{<:Tuple{<:Any, <:VecTypes}}}
            # [(text, pos), ...] argument
            return ((last.(args[1]),), Ref{Any}(first.(args[1])))
        else # assume position data
            return (args, Ref{Any}(to_string_arr(a_text)))
        end
    end

    # Continue with _register_expand_arguments with adjusted input names
    _register_expand_arguments!(Text, attr, [:_positions], true)

    # And the rest of it
    _register_argument_conversions!(Text, attr, user_kw)

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

    block_idx = length(outputs.text_blocks)
    pos_idx = first(last(outputs.text_blocks))

    for (element, position, _) in tex_elements
        if element isa MathTeXEngine.HLine
            h = element
            x, y = position
            p0 = rotation * to_ndim(Point3f, fontsize .* Point2f(x, y) .- tex_offset, 0) .+ offset
            p1 = rotation * to_ndim(Point3f, fontsize .* Point2f(x + h.width, y) .- tex_offset, 0) .+ offset
            push!(outputs.linesegments, p0, p1)
            push!(outputs.linewidths, fontsize * h.thickness, fontsize * h.thickness)
            push!(outputs.linecolors, color, color)
            push!(outputs.lineindices, block_idx => pos_idx, block_idx => pos_idx)
        end
    end
    return nothing
end

function compute_glyph_collections!(attr::ComputeGraph)
    inputs = [
        :input_text,
        :latex_handler,
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
        :linesegments, :linewidths, :linecolors, :lineindices,
        :text_primitives, :text_primitive_block_indices,
    ]
    return register_computation!(attr, inputs, outputs) do (input_texts, latex_handler, _inputs...), changed, cached
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
            linesegments = Point3f[],
            linewidths = Float32[],
            linecolors = RGBAf[],
            lineindices = Pair{Int, Int}[],
            text_primitives = AbstractTextPrimitive[],
            text_primitive_block_indices = Int[],
        )
        # strokewidth = Float32[] # TODO: Skipped?

        N = length(input_texts)
        for (block_index, str) in enumerate(input_texts)
            # `LaTeXString` is themable: if `latex_handler` is set, route the
            # block through it instead of the built-in MathTeXEngine path.
            if str isa LaTeXString && latex_handler !== nothing
                latex_handler(_outputs, str, block_index, N, _inputs...)
            else
                convert_text_string!(_outputs, str, block_index, N, _inputs...)
            end
        end

        return values(_outputs)
    end

end

function register_text_computations!(attr::ComputeGraph)
    add_constant!(attr, :atlas, get_texture_atlas())

    map!(to_font, attr, [:fonts, :font], :selected_font)

    # Resolve colormapping to colors early. This allows rich text which returns
    # its own colors to be mixed with other text types which dont.
    add_computation!(attr, Val(:computed_color))

    # This computes :glyphindices, :font_per_char, :glyph_origins, :glyph_extents, :text_blocks
    # And :glyphcollection if applicable
    compute_glyph_collections!(attr)

    map!(attr, [:atlas, :glyphindices, :font_per_char], :sdf_uv) do atlas, gi, fonts
        return glyph_uv_width!.((atlas,), gi, fonts)
    end

    map!(attr, [:glyph_origins, :offset, :text_blocks], :marker_offset) do origins, offset, blocks
        return Point3f[origins[gi] + sv_getindex(offset, i) for (i, r) in enumerate(blocks) for gi in r]
    end

    map!(
        attr, [:atlas, :glyphindices, :text_blocks, :font_per_char, :text_scales],
        [:quad_offset, :quad_scale]
    ) do atlas, gi, text_blocks, fonts, fontsize

        quad_offsets = Vec2f[]
        quad_scales = Vec2f[]
        pad = atlas.glyph_padding / atlas.pix_per_glyph
        per_glyph_attributes(text_blocks, (gi, fonts, fontsize)) do g, f, fs
            # These are tight to the glyph. They do not fill the full space
            # a glyph takes within a string/layout.
            bb = FreeTypeAbstraction.metrics_bb(g, f, fs)[1]
            quad_offset = Vec2f(minimum(bb) .- fs .* pad)
            quad_scale = Vec2f(widths(bb) .+ fs * 2pad)
            push!(quad_offsets, quad_offset)
            push!(quad_scales, quad_scale)
        end
        return (quad_offsets, quad_scales)
    end
    # TODO: remapping positions to be per glyph first generates quite a few
    # redundant transform applications and projections in CairoMakie
    register_position_transforms!(attr, input_name = :positions, transformed_name = :positions_transformed)

    map!(attr, [:text_blocks, :positions_transformed_f32c], :per_char_positions_transformed_f32c) do blocks, pos
        if length(blocks) != length(pos)
            error("Text blocks and positions have different lengths: $(length(blocks)) != $(length(pos)). Please use `update!(plot_object; arg1/arg2/text/position/color/etc...) to update multiple attributes together.")
        end
        return [p for (b, p) in zip(blocks, pos) for i in b]
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

    add_constant!(attr, :sdf_marker_shape, Cint(DISTANCEFIELD))

    register_colormapping!(attr)
    register_text_computations!(attr)
    tex_linesegments!(plot)
    return register_text_primitive_plot!(plot, ImageTextPrimitive)
end

"""
    register_text_primitive_plot!(plot::Plot{text}, ::Type{P})

Default-dispatch hook for plugging an `AbstractTextPrimitive` subtype into the
`text` recipe. Called once per primitive type from `calculated_attributes!`.
Built-in implementation handles [`ImageTextPrimitive`](@ref) by registering a
child `scatter!` plot. Downstream packages can register their own primitive
types by extending this method (and `text_primitive_bbox`).
"""
register_text_primitive_plot!(plot, ::Type{<:AbstractTextPrimitive}) = nothing

# Filter the heterogeneous text_primitives channel for entries of a specific
# concrete primitive type. Returns aligned vectors of items, block indices,
# offsets, sizes, and rotations suitable for a child scatter plot.
function _filter_text_primitives(primitives::Vector{AbstractTextPrimitive}, block_indices::Vector{Int}, ::Type{T}) where {T <: AbstractTextPrimitive}
    items = T[]
    idxs = Int[]
    for (b, p) in zip(block_indices, primitives)
        p isa T || continue
        push!(items, p)
        push!(idxs, b)
    end
    return items, idxs
end

function register_text_primitive_plot!(plot, ::Type{<:ImageTextPrimitive})
    register_model_clip_planes!(plot.attributes)

    map!(
        plot.attributes,
        [
            :text_primitives, :text_primitive_block_indices,
            :preprojection, :model_f32c, :positions_transformed_f32c,
            :model_clip_planes, :space,
        ],
        [
            :_image_primitive_positions, :_image_primitive_markers,
            :_image_primitive_sizes, :_image_primitive_offsets,
            :_image_primitive_rotations,
        ]
    ) do prims, indices, preprojection, model_f32c, positions, clip_planes, space
        items, idxs = _filter_text_primitives(prims, indices, ImageTextPrimitive)
        if isempty(items)
            return (Point3f[], Any[], Vec2f[], Vec3f[], Quaternionf[])
        end
        markerspace_positions = _project(preprojection * model_f32c, positions, clip_planes, space)
        out_pos = [markerspace_positions[idxs[i]] for i in eachindex(items)]
        out_marker = Any[p.image for p in items]
        out_size = [p.size for p in items]
        out_offset = [p.marker_offset for p in items]
        out_rot = [p.rotation for p in items]
        return (out_pos, out_marker, out_size, out_offset, out_rot)
    end

    return scatter!(
        plot, plot._image_primitive_positions;
        marker = plot._image_primitive_markers,
        markersize = plot._image_primitive_sizes,
        marker_offset = plot._image_primitive_offsets,
        rotation = plot._image_primitive_rotations,
        space = plot.markerspace,
        markerspace = plot.markerspace,
    )
end

function tex_linesegments!(plot)
    register_model_clip_planes!(plot.attributes)

    # Don't user register_markerspace_positions() here so we skip calculating them
    # if no linesegments are needed
    map!(
        plot.attributes,
        [:linesegments, :lineindices, :preprojection, :model_f32c, :positions_transformed_f32c, :model_clip_planes, :space],
        :linesgments_shifted
    ) do linesegments, indices, preprojection, model_f32c, positions, clip_planes, space
        isempty(linesegments) && return Point3f[]
        markerspace_positions = _project(preprojection * model_f32c, positions, clip_planes, space)
        return map(linesegments, indices) do seg, (block_idx, glyph_idx)
            return seg + markerspace_positions[block_idx]
        end
    end

    return linesegments!(
        plot, plot.linesgments_shifted; linewidth = plot.linewidths,
        color = plot.linecolors, space = plot.markerspace
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
            plot.attributes, [:text_blocks, :raw_glyph_boundingboxes, :glyph_origins, :text_rotation, :linesegments, :linewidths, :lineindices, :text_primitives, :text_primitive_block_indices],
            :raw_string_boundingboxes
        ) do blocks, bbs, origins, rotation, segments, linewidths, lineindices, primitives, primitive_block_indices

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

            for (pos, lw, (block_idx, glyph_idx)) in zip(segments, linewidths, lineindices)
                bb = Rect3d(to_ndim(Point3d, pos, 0) .- 0.5lw, Vec3d(lw))
                text_bbs[block_idx] = update_boundingbox(text_bbs[block_idx], bb)
            end

            for (block_idx, prim) in zip(primitive_block_indices, primitives)
                text_bbs[block_idx] = update_boundingbox(text_bbs[block_idx], text_primitive_bbox(prim))
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
            plot.attributes, [:text_blocks, :raw_glyph_boundingboxes, :marker_offset, :text_rotation, :linesegments, :linewidths, :lineindices, :text_primitives, :text_primitive_block_indices],
            :fast_string_boundingboxes
        ) do blocks, bbs, origins, rotation, segments, linewidths, lineindices, primitives, primitive_block_indices

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

            for (pos, lw, (block_idx, glyph_idx)) in zip(segments, linewidths, lineindices)
                bb = Rect3d(to_ndim(Point3d, pos, 0) .- 0.5lw, Vec3d(lw))
                text_bbs[block_idx] = update_boundingbox(text_bbs[block_idx], bb)
            end

            for (block_idx, prim) in zip(primitive_block_indices, primitives)
                text_bbs[block_idx] = update_boundingbox(text_bbs[block_idx], text_primitive_bbox(prim))
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
