struct RichText
    type::Symbol
    children::Vector{Union{RichText,String}}
    attributes::Dict{Symbol, Any}
    function RichText(type::Symbol, children...; kwargs...)
        cs = Union{RichText,String}[children...]
        new(type, cs, Dict(kwargs))
    end
end

function check_textsize_deprecation(@nospecialize(dictlike))
    if haskey(dictlike, :textsize)
        throw(ArgumentError("`textsize` has been renamed to `fontsize` in Makie v0.19. Please change all occurrences of `textsize` to `fontsize` or revert back to an earlier version."))
    end
end

# We sort out position vs string(-like) vs mixed arguments before convert_arguments,
# so that we only get positions here
conversion_trait(::Type{<: Text}, args...) = PointBased()

convert_attribute(o, ::key"offset", ::key"text") = to_3d_offset(o) # same as marker_offset in scatter
convert_attribute(f, ::key"font", ::key"text") = f # later conversion with fonts

# Positions are always vectors so text should be too
convert_attribute(str::AbstractString, ::key"text", ::key"text") = [str]
convert_attribute(x::AbstractVector, ::key"text", ::key"text") = vec(x)


function register_arguments!(::Type{Text}, attr::ComputeGraph, user_kw, input_args)
    # Set up Inputs
    inputs = _register_input_arguments!(Text, attr, input_args)

    # User arguments can be PointBased(), String-like or mixed, with the
    # position and text attributes supplementing data not in arguments.
    # For conversion we want to move position data into the argument pipeline
    # and String-like data into attributes. Do this here:
    pushfirst!(inputs, :position, :text)
    register_computation!(attr, inputs, [:_positions, :input_text]) do inputs, changed, cached
        a_pos, a_text, args... = values(inputs)
        # Note: Could add RichText
        if args isa Tuple{<: AbstractString}
            # position data will always be wrapped in a Vector, so strings should too
            return ((a_pos,), [args[1]])
        elseif args isa Tuple{<: AbstractVector{<: AbstractString}}
            return ((a_pos,), args[1])
        elseif args isa Tuple{<: AbstractVector{<: Tuple{<: Any, <: VecTypes}}}
            # [(text, pos), ...] argument
            return ((last.(args[1]),), first.(args[1]))
        else # assume position data
            return (args, a_text)
        end
    end

    # Continue with _register_expand_arguments with adjusted input names
    _register_expand_arguments!(Text, attr, [:_positions], true)

    # And the rest of it
    _register_argument_conversions!(Text, attr, user_kw)

    return
end


function convert_text_arguments(text::AbstractString, fontsize, fonts, align, rotation, justification, lineheight, word_wrap_width, offset)
    nt = glyph_collection(
        text, fonts, fontsize, align...,
        lineheight, justification, word_wrap_width, rotation
    )
    return (nt.glyphindices, nt.font_per_char, nt.char_origins, nt.glyph_extents, [1:length(nt.glyphindices)])
end

function convert_text_arguments(text::AbstractVector, fontsize, fonts, align, rotation, justification, lineheight, word_wrap_width, offset)
    glyphindices = UInt64[]
    font_per_char = NativeFont[]
    char_origins = Point3f[]
    glyph_extents = GlyphExtent[]
    text_blocks = UnitRange{Int64}[]
    broadcast_foreach(text, fontsize, fonts, align, rotation, justification, lineheight, word_wrap_width) do text, fontsize, fonts, align, rotation, justification, lineheight, word_wrap_width
        nt = glyph_collection(text, fonts, fontsize, align..., lineheight, justification, word_wrap_width, rotation)
        curr = length(glyphindices)
        push!(text_blocks, (curr+1):(curr + length(nt.glyphindices)))
        append!(glyphindices, nt.glyphindices)
        append!(font_per_char, nt.font_per_char)
        append!(char_origins, nt.char_origins)
        append!(glyph_extents, nt.glyph_extents)
    end
    return (glyphindices, font_per_char, char_origins, glyph_extents, text_blocks)
end


function per_glyph_getindex(x, glyphs::Vector{UInt64}, text_blocks::Vector{UnitRange{Int}}, gi::Int, bi::Int)
    if isscalar(x)
        return x
    elseif isa(x, AbstractVector)
        if length(x) == length(glyphs)
            return x[gi] # use per glyph index
        elseif length(x) == length(text_blocks)
            return x[bi] # use per text block index
        else
            error("Invalid length of attribute $(typeof(x)). Length ($(length(x))) != $(length(glyphs)) or $(length(text_blocks))")
        end
    else
        return x
    end
end

function per_text_getindex(x, glyphs::Vector{UInt64}, text_blocks::Vector{UnitRange{Int}}, bi::Int)
    if isscalar(x)
        return x
    elseif isa(x, AbstractVector)
        # data is per glyph
        if length(x) == length(glyphs)
            return view(x, text_blocks[bi]) # use per glyph index
        elseif length(x) == length(text_blocks)
            return x[bi] # use per text block index
        else
            error("Invalid length of attribute $(typeof(x)). Length ($(length(x))) != $(length(glyphs)) or $(length(text_blocks))")
        end
    else
        return x
    end
end

function per_text_block(f, glyphs::Vector{UInt64}, text_blocks::Vector{UnitRange{Int}}, args::Tuple)
    _getindex(x, bi) = per_text_getindex(x, glyphs, text_blocks, bi)
    for block_idx in eachindex(text_blocks)
        block = text_blocks[block_idx]
        f(view(glyphs, block), _getindex.(args, block_idx)...)
    end
end

function per_glyph_attributes(f, glyphs::Vector{UInt64}, text_blocks::Vector{UnitRange{Int}}, args::Tuple)
    _getindex(x, gi, bi) = per_glyph_getindex(x, glyphs, text_blocks, gi, bi)
    glyph_idx = 1
    for block_idx in eachindex(text_blocks)
        for _ in text_blocks[block_idx]
            f(glyphs[glyph_idx], _getindex.(args, glyph_idx, block_idx)...)
            glyph_idx += 1
        end
    end
end

function map_per_glyph(glyphs::Vector{UInt64}, text_blocks::Vector{UnitRange{Int}}, Typ, arg)
    isscalar(arg) && return fill(arg, length(glyphs))
    result = Typ[]
    per_glyph_attributes(glyphs, text_blocks, (arg,)) do g, a
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

function convert_rich_text(input_text::AbstractVector{RichText}, fontsize, font, fonts, align, rotation, justification, lineheight, color)
    glyphindices = UInt64[]
    font_per_char = NativeFont[]
    char_origins = Point3f[]
    glyph_extents = GlyphExtent[]
    text_blocks = UnitRange{Int64}[]
    glyphcollections = GlyphCollection[]
    colors = RGBAf[]
    strokecolor = RGBAf[]
    strokewidth = Float32[]
    rotations = Quaternionf[]
    fontsizes = Vec2f[]
    broadcast_foreach(input_text, fontsize, font, fonts, align, rotation, justification, lineheight, color) do args...
        gc = layout_text(args...)
        push!(glyphcollections, gc)
        curr = length(glyphindices)
        n = length(gc.glyphs)
        push!(text_blocks, (curr+1):(curr + n))
        append!(glyphindices, gc.glyphs)
        append!(char_origins, gc.origins)
        append!(glyph_extents, gc.extents)
        append!(font_per_char, collect_vector(gc.fonts, n))
        append!(colors, collect_vector(gc.colors, n))
        append!(strokecolor, collect_vector(gc.strokecolors, n))
        append!(strokewidth, collect_vector(gc.strokewidths, n))
        append!(rotations, collect_vector(gc.rotations, n))
        append!(fontsizes, collect_vector(gc.scales, n))
    end
    # TODO, strokecolor per glyph?
    return (glyphcollections, glyphindices, font_per_char, char_origins, glyph_extents, text_blocks, colors, first(strokecolor), rotations, fontsizes)
end


function convert_latex(input_text::AbstractVector{LaTeXString}, fontsize, align, rotation, color, scolor, swidth, word_wrap_width)
    glyphindices = UInt64[]
    font_per_char = NativeFont[]
    char_origins = Point3f[]
    glyph_extents = GlyphExtent[]
    text_blocks = UnitRange{Int64}[]
    glyphcollections = GlyphCollection[]
    colors = RGBAf[]
    strokecolor = RGBAf[]
    strokewidth = Float32[]
    rotations = Quaternionf[]
    fontsizes = Vec2f[]
    broadcast_foreach(input_text, fontsize, align, rotation, color, scolor, swidth, word_wrap_width) do args...
        tex_elements, gc, offset = texelems_and_glyph_collection(args...)
        push!(glyphcollections, gc)
        curr = length(glyphindices)
        n = length(gc.glyphs)
        push!(text_blocks, (curr+1):(curr + n))
        append!(glyphindices, gc.glyphs)
        append!(char_origins, gc.origins)
        append!(glyph_extents, gc.extents)
        append!(font_per_char, collect_vector(gc.fonts, n))
        append!(colors, collect_vector(gc.colors, n))
        append!(strokecolor, collect_vector(gc.strokecolors, n))
        append!(strokewidth, collect_vector(gc.strokewidths, n))
        append!(rotations, collect_vector(gc.rotations, n))
        append!(fontsizes, collect_vector(gc.scales, n))
    end
    return (glyphcollections, glyphindices, font_per_char, char_origins, glyph_extents, text_blocks, colors, first(strokecolor), rotations, fontsizes)
end

function convert_text_inputs(
        input_text::AbstractVector{<:AbstractString},
        fontsize,
        selected_font,
        align,
        rotation,
        justification,
        lineheight,
        word_wrap_width,
        offset,
        fonts,
        color,
        strokecolor,
        strokewidth
    )
    glyphindices, font_per_char, glyph_origins, glyph_extents, text_blocks = convert_text_arguments(
        input_text, fontsize, selected_font,
        align, rotation, justification,
        lineheight, word_wrap_width, offset
    )
    text_color = map_per_glyph(glyphindices, text_blocks, RGBAf, color)
    text_rotation = map_per_glyph(glyphindices, text_blocks, Quaternionf, rotation)
    text_scales = map_per_glyph(glyphindices, text_blocks, Vec2f, to_2d_scale(fontsize))
    return (
        GlyphCollection[], glyphindices, font_per_char, glyph_origins, glyph_extents, text_blocks,
        text_color, strokecolor, text_rotation, text_scales
    )
end

function convert_text_inputs(
        input_text::AbstractVector{<:RichText},
        fontsize,
        selected_font,
        align,
        rotation,
        justification,
        lineheight,
        word_wrap_width,
        offset,
        fonts,
        color,
        strokecolor,
        strokewidth
    )
    return convert_rich_text(input_text, fontsize, selected_font, fonts, align, rotation, justification, lineheight, color)
end



function convert_text_inputs(
        input_text::AbstractVector{<:LaTeXString},
        fontsize,
        selected_font,
        align,
        rotation,
        justification,
        lineheight,
        word_wrap_width,
        offset,
        fonts,
        color,
        strokecolor,
        strokewidth
    )
    result = convert_latex(input_text, fontsize, align, rotation, color, strokecolor, strokewidth, word_wrap_width)
    return result
end

function convert_text_inputs(
        input_text::AbstractVector{Any}, args...)
    if isempty(input_text)
        return (GlyphCollection[], UInt64[], NativeFont[], Point3f[], GlyphExtent[], UnitRange{Int}[],
                RGBAf[], RGBAf(0,0,0,0), Quaternionf[], Vec2f[])
    end
    text = map(identity, input_text) # try to force an eltype
    eltype(text) == Any && error("Text input must be of type String, LaTeXString or RichText. Found: $(text)")
    return convert_text_inputs(text, args...)
end

function compute_glyph_collections!(attr::ComputeGraph)
    inputs = [
        :input_text,
        :fontsize,
        :selected_font,
        :align,
        :rotation,
        :justification,
        :lineheight,
        :word_wrap_width,
        :offset,
        :fonts,
        :color,
        :strokecolor,
        :strokewidth
    ]
    outputs = [
        :glyphcollections,
        :glyphindices,
        :font_per_char,
        :glyph_origins,
        :glyph_extents,
        :text_blocks,
        :text_color,
        :text_strokecolor,
        :text_rotation,
        :text_scales
    ]
    register_computation!(attr, inputs, outputs) do inputs, changed, cached
        return convert_text_inputs(inputs...)
    end
end

function register_text_computations!(attr::ComputeGraph) where T
    if !haskey(attr, :atlas)
        register_computation!(attr, Symbol[], [:atlas]) do _, changed, last
            (get_texture_atlas(),)
        end
    end

    register_computation!(attr, [:fonts, :font], [:selected_font]) do (fs, f), changed, cached
        return (to_font(fs, f),)
    end

    # This computes :glyphindices, :font_per_char, :glyph_origins, :glyph_extents, :text_blocks
    # And :glyphcollection if applicable
    compute_glyph_collections!(attr)

    register_computation!(attr, [:text_blocks, :positions], [:text_positions]) do (blocks, pos), changed, cached
        length(blocks) == length(pos) || error("Text blocks and positions have different lengths: $(length(blocks)) != $(length(pos))")
        return ([p for (b, p) in zip(blocks, pos) for i in b],)
    end

    register_computation!(attr, [:atlas, :glyphindices, :font_per_char], [:sdf_uv]) do (atlas, gi, fonts), changed, cached
        return (glyph_uv_width!.((atlas,), gi, fonts),)
    end

    register_computation!(attr, [:glyph_origins, :offset, :text_blocks], [:marker_offset]) do (origins, offset, blocks), changed, cached
        return (Point3f[origins[gi] + sv_getindex(offset, i) for (i, r) in enumerate(blocks) for gi in r], )
    end

    # glyph_boundingboxes are not tight to the character.
    # Vertically they fill the full space the character may occupy.
    # (I.e. a and g have the same y min and max)
    # Horizontally they fill the include the spacing between characters.
    # (I.e. boundingboxes of consecutive characters touch)
    register_computation!(attr, [:atlas, :glyphindices, :text_blocks, :font_per_char, :text_scales],
            [:glyph_boundingboxes, :quad_offset, :quad_scale]) do (atlas, gi, text_blocks, fonts, fontsize), changed, cached

        glyph_boundingboxes = Rect2d[]
        quad_offsets = Vec2f[]
        quad_scales = Vec2f[]
        pad = atlas.glyph_padding / atlas.pix_per_glyph
        per_glyph_attributes(gi, text_blocks, (fonts, fontsize)) do g, f, fs
            bb = FreeTypeAbstraction.metrics_bb(g, f, fs)[1]
            quad_offset = Vec2f(minimum(bb) .- fs .* pad)
            quad_scale = Vec2f(widths(bb) .+ fs * 2pad)
            push!(glyph_boundingboxes, bb)
            push!(quad_offsets, quad_offset)
            push!(quad_scales, quad_scale)
        end
        return (glyph_boundingboxes, quad_offsets, quad_scales)
    end
    # TODO: remapping positions to be per glyph first generates quite a few
    # redundant transform applications and projections in CairoMakie
    register_position_transforms!(attr, :text_positions)
    return
end


function get_text_type(x::AbstractVector{Any})
    isempty(x) && error("Cant determine text type from empty vector")
    return mapreduce(typeof, (a, b)-> a === b ? a : error("All text elements need same eltype. Found: $(a), $(b)"), x)
end

get_text_type(x::AbstractVector) = eltype(x)
get_text_type(::T) where T = T

function calculated_attributes!(::Type{Text}, plot::Plot)
    attr = plot.attributes

    register_computation!((args...) -> (Cint(DISTANCEFIELD), ), attr, Symbol[], [:sdf_marker_shape])

    register_colormapping!(attr)
    register_text_computations!(attr)

    # TODO: naming...?
    # markerspace bounding boxes of elements (i.e. each string passed to text)
    register_computation!(attr, [:glyphindices, :text_blocks, :glyph_origins, :text_scales, :glyph_extents, :rotation], [:per_string_bb]) do args, changed, last
        b_args = (args.glyph_origins, args.text_scales, args.glyph_extents, args.rotation)
        result = Rect3d[]
        per_text_block(args.glyphindices, args.text_blocks, b_args) do glyphs, origins, fontsizes, extents, rotation # per text
            push!(result, unchecked_boundingbox(glyphs, origins, fontsizes, extents, rotation))
        end
        return (result,)
    end

    # TODO: There is a :position attribute and a :positions Computed (after dim converts)
    #       This seems quite error prone...
    # data_limits()
    register_computation!(attr, [:per_string_bb, :positions, :space, :markerspace], [:data_limits]) do inputs, changed, last
        bbs, pos, space, markerspace = inputs
        # TODO: technically this should also verify transform_func === identity
        # TODO: technically this should consider scene space if space == :data
        if space === markerspace
            total_bb = Rect3d()
            for (bb, p) in zip(bbs, pos)
                total_bb = update_boundingbox(total_bb, bb + to_ndim(Point3d, p, 0))
            end
            return (total_bb,)
        elseif changed.positions
            return (Rect3d(pos),)
        else
            return nothing
        end
        return (Rect3d(inputs.positions),)
    end
end

# TODO: Naming?
"""
    string_widths(plot::Text)

Returns the markerspace size for each text element drawn by the given text plot.
This is the width and height of the bounding box each individual glyph collection,
in markerspace.
"""
string_widths(plot) = widths.(plot.per_string_bb[]) # These do not include positions

"""
    maximum_string_widths(plot::Text)

Returns the maximum width, height and depth of each text element drawn by the
given text plot.
"""
maximum_string_widths(plot) = reduce((a,b) -> max.(a, b), string_widths(plot), init = Vec3d(0))

function string_boundingbox(plot::Text)
    # TODO: technically this should consider scene space if space == :data
    if plot.space[] == plot.markerspace[]
        # TODO: Should probably be positions_transformed_f32c since those are the
        #       positions that mix with marker/text metrics
        pos = to_ndim.(Point3d, plot.positions[], 0)
    else
        cam = (parent_scene(plot).camera,)
        transformed = plot.positions_transformed_f32c[]
        pos = Makie.project.(cam, plot.space[], plot.markerspace[], transformed) # TODO: vectorized project
    end

    total_bb = Rect3d()
    for (bb, p) in zip(plot.per_string_bb[], pos)
        total_bb = update_boundingbox(total_bb, bb + to_ndim(Point3d, p, 0))
    end
    return (total_bb,)
end

# replacement for charbbs()
# TODO: Maybe generalize this? I.e. for multiple text blocks, markerpace != space, transformations, etc
function _tight_character_boundingboxes(plot::Text)
    register_computation!(plot.attributes,
            [:text_positions, :glyph_extents, :text_scales, :glyph_origins],
            [:tight_character_boundingboxes]
        ) do inputs, changed, cached

        positions, extents, scales, origins = inputs
        if all(x -> length(x) == length(positions) || length(x) == 1, inputs)
            bbs = Rect2f[]
            broadcast_foreach(positions, extents, scales, origins) do pos, ext, sc, ori
                bb = Makie.height_insensitive_boundingbox_with_advance(ext)
                bb2 = Rect2f(bb * sc) + Point2f(ori) + Point2f(pos)
                push!(bbs, bb2)
            end
            return (bbs, )
        elseif isnothing(cached)
            return (Rect2f[],)
        else
            return nothing
        end
    end

    return plot.tight_character_boundingboxes[]
end


function _get_glyphcollection_and_linesegments(latexstring::LaTeXString, index, ts, f, fs, al, rot, jus, lh, col, scol, swi, www, offs)
    tex_elements, glyphcollections, offset = texelems_and_glyph_collection(latexstring, ts,
                al[1], al[2], rot, col, scol, swi, www)

    linesegs = Point2f[]
    linewidths = Float32[]
    linecolors = RGBAf[]
    lineindices = Int[]

    rotate_2d(quat, point2) = Point2f(quat * to_ndim(Point3f, point2, 0))

    for (element, position, _) in tex_elements
        if element isa MathTeXEngine.HLine
            h = element
            x, y = position
            push!(linesegs, rotate_2d(rot, ts * Point2f(x, y) - offset) + offs)
            push!(linesegs, rotate_2d(rot, ts * Point2f(x + h.width, y) - offset) + offs)
            push!(linewidths, ts * h.thickness)
            push!(linewidths, ts * h.thickness)
            push!(linecolors, col) # TODO how to specify color better?
            push!(linecolors, col)
            push!(lineindices, index)
            push!(lineindices, index)
        end
    end

    return glyphcollections, linesegs, linewidths, linecolors, lineindices
end

function texelems_and_glyph_collection(str::LaTeXString, fontscale_px, align,
        rotation, color, strokecolor, strokewidth, word_wrap_width)
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
        newline_offset = Point3f(basepositions[1][1], 0f0, 0)

        for i in eachindex(texchars)
            basepositions[i] -= newline_offset
            if texchars[i].represented_char == ' ' || i == length(texchars)
                right_pos = basepositions[i][1] + width(bboxes[i])
                if last_space_idx != 0 && right_pos > word_wrap_width
                    section_offset = basepositions[last_space_idx + 1][1]
                    lineheight = maximum((height(bb) for bb in bboxes[last_newline_idx:last_space_idx]))
                    last_newline_idx = last_space_idx+1
                    newline_offset += Point3f(section_offset, lineheight, 0)

                    # TODO: newlines don't really need to represented at all?
                    # chars[last_space_idx] = '\n'
                    for j in last_space_idx+1:i
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
    yshift = get_yshift(minimum(bb)[2], maximum(bb)[2], valign, default=0f0)

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



function Base.String(r::RichText)
    fn(io, x::RichText) = foreach(x -> fn(io, x), x.children)
    fn(io, s::String) = print(io, s)
    sprint() do io
        fn(io, r)
    end
end

function Base.show(io::IO, ::MIME"text/plain", r::RichText)
    print(io, "RichText: \"$(String(r))\"")
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

convert_attribute(rt::RichText, ::key"text", ::key"text") = [rt]

function _get_glyphcollection_and_linesegments(rt::RichText, index, ts, f, fset, al, rot, jus, lh, col, scol, swi, www, offs)
    gc = layout_text(rt, ts, f, fset, al, rot, jus, lh, col)
    gc, Point2f[], Float32[], RGBAf[], Int[]
end

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
    rotation::Quaternion
    color::RGBAf
    strokecolor::RGBAf
    strokewidth::Float32
end

# Copy constructor, to overwrite a field
function GlyphInfo(gi::GlyphInfo;
        glyph=gi.glyph,
        font=gi.font,
        origin=gi.origin,
        extent=gi.extent,
        size=gi.size,
        rotation=gi.rotation,
        color=gi.color,
        strokecolor=gi.strokecolor,
        strokewidth=gi.strokewidth)

    return GlyphInfo(glyph,
                     font,
                     origin,
                     extent,
                     size,
                     rotation,
                     color,
                     strokecolor,
                     strokewidth)
end


function GlyphCollection(v::Vector{GlyphInfo})
    GlyphCollection(
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
            l = GlyphInfo(l; origin=Point2f(ox, oy - (i - 1) * 20))
            line[j] = l
        end
    end
    return
end

function max_x_advance(glyph_infos::Vector{GlyphInfo})::Float32
    return maximum(glyph_infos; init=0.0f0) do ginfo
        ginfo.origin[1] + ginfo.extent.hadvance * ginfo.size[1]
    end
end


# Characters can be completely above or below the baseline, so minimum/maximum
# should not initialize with 0. It should also not be ±Inf or ±floatmax() as that
# results in incorrect limits
function max_y_ascender(glyph_infos::Vector{GlyphInfo})::Float32
    if isempty(glyph_infos)
        return 0f0
    else
        return maximum(glyph_infos) do ginfo
            return ginfo.origin[2] + ginfo.extent.ascender * ginfo.size[2]
        end
    end
end

function min_y_descender(glyph_infos::Vector{GlyphInfo})::Float32
    if isempty(glyph_infos)
        return 0f0
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

    al_offset_x = get_xshift(0f0,      max_x, al[1]; default=0f0)
    al_offset_y = get_yshift(bottom_y, top_y, al[2]; default=0f0)

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
    float_justification = if ju === automatic
        get_xshift(0f0, 1f0, halign)
    else
        get_xshift(0f0, 1f0, ju; default=ju) # errors if wrong symbol is used
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
        maximum(line; init = 0f0) do ginfo
            GlyphInfo
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
            push!(lines[end], GlyphInfo(
                gi,
                bestfont,
                ori,
                gext,
                gs.size,
                to_rotation(0),
                gs.color,
                RGBAf(0, 0, 0, 0),
                0f0,
            ))
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
    GlyphState(
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
    GlyphState(
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
    GlyphState(
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
    GlyphState(
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
    GlyphState(
        gs.x,
        gs.baseline + 0.4 * gs.size[2],
        fontsize,
        _get_font(att, gs.font, fonts),
        _get_color(att, gs.color),
    )
end

iswhitespace(r::RichText) = iswhitespace(String(r))

function get_xshift(lb, ub, align; default=0.5f0)
    if align isa Symbol
        align = align === :left   ? 0.0f0 :
                align === :center ? 0.5f0 :
                align === :right  ? 1.0f0 : default
    end
    lb * (1-align) + ub * align |> Float32
end

function get_yshift(lb, ub, align; default=0.5f0)
    if align isa Symbol
        align = align === :bottom ? 0.0f0 :
                align === :center ? 0.5f0 :
                align === :top    ? 1.0f0 : default
    end
    lb * (1-align) + ub * align |> Float32
end
