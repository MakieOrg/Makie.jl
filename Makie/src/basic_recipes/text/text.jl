function plot!(text::Text)
    # text.attributes now contains the attributes from the recipe, including generic and colormap
    # as well as arg1,arg2... and position, which is a legacy attribute that we should probably get rid of
    # :converted contains the converted args normalised to the points, as specified in the recipe

    attr = text.attributes

    # TODO: figure out per character colormapping when there are multiple strings?
    register_colormapping!(attr)

    # TODO: again, what happens with per char stuff?
    # Resolve colormapping to colors early. This allows rich text which returns
    # its own colors to be mixed with other text types which dont.
    add_computation!(attr, Val(:computed_color))

    @assert length(attr.converted[][1]) == length(attr.input_text[]) "there should be given as many positions as texts."

    # unwrap text and resolve layouters
    map!(attr, [:input_text, :string_layouter], [:unwrapped_text, :resolved_layouters]) do strings, layouters
        unwrapped_strings = unwrap_string.(strings)
        resolved_layouters = map(enumerate(strings)) do (i, s)
            given_layouter = sv_getindex(layouters, i)
            resolve_string_layouter(s, given_layouter)
        end
        # type inference can lead to this being Vector{String} or similar. Changing string type will then break.
        (Ref{Any}(unwrapped_strings), Ref{Any}(resolved_layouters))
    end

    # TODO: figure out per character font when there are multiple strings?
    map!(attr, [:unwrapped_text, :fonts, :font], :selected_font) do strings, fonts, font
        Ref{Any}(
            map(enumerate(strings)) do (i, string)
                scalar_font = sv_getindex(font, i)
                to_font(string, fonts, scalar_font)
            end
        )
    end

    # need to have transformed positions for every plot that does not do this by itself?
    register_position_transforms!(attr; input_name = :positions, transformed_name = :positions_transformed)
    register_model_clip_planes!(attr)
    register_markerspace_positions!(text)

    # TODO: this is probably massively inefficient...
    register_computation!(attr, collect(keys(attr.outputs)), [:plotspecs, :blocks]) do inputs, changed, cached
        specs = PlotSpec[]
        blocks = UnitRange{Int}[]
        for (i, layouter) in enumerate(inputs.resolved_layouters)
            layouted_specs = layouted_string_plotspecs(inputs, layouter, i)
            push!(blocks, eachindex(layouted_specs) .+ length(specs))
            append!(specs, layouted_specs)
        end
        return (specs, blocks)
    end

    # TODO: somehow, markerspace is not inherited here?
    # TODO: the main attrs that are inherited seem to overwrite all the attrs that the subspecs have...
    # plotlist!(text, attr, attr.plotspecs; markerspace=attr.markerspace)
    plotlist!(text, attr, attr.plotspecs)

    # TODO: register some bounding box shenanigans that labels and stuff care about?
    return text
end

to_font(_, fonts, font) = to_font(fonts, font)

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
convert_attribute(align, ::key"align", ::key"text") = Ref{Any}(align)

# Positions are always vectors so text should be too
convert_attribute(str::AbstractString, ::key"text", ::key"text") = Ref{Any}([str]) # don't fix string type
convert_attribute(rt::RichText, ::key"text", ::key"text") = Ref{Any}([rt])
convert_attribute(x::AbstractVector, ::key"text", ::key"text") = Ref{Any}(vec(x))

to_string_arr(text::AbstractVector) = text
to_string_arr(text) = [text]

function register_arguments!(::Type{Text}, attr::ComputeGraph, user_kw, input_args)
    # Set up Inputs
    inputs = _register_input_arguments!(Text, attr, input_args)


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
    _register_expand_arguments!(Text, attr, [:_positions], true)

    # And the rest of it
    _register_argument_conversions!(Text, attr, user_kw)

    return
end

function register_text_boundingboxes!(plot, space = :pixel)
    if !haskey(plot.attributes, :text_boundingboxes)
        map!(plot.attributes, [:plotspecs, :blocks], :text_boundingboxes) do specs, blocks
            map(blocks) do block
                mapreduce(p -> boundingbox(p, space), update_boundingbox, plot.plots[1].plots[block], init = Rect3d())
            end
        end
    end
    return plot.attributes.text_boundingboxes
end


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

function boundingbox(plot::Text, target_space::Symbol)
    # TODO: figure out a native way to get text boundingboxes
    # This is temporary prep work for the future. We should actually consider
    # plot.space, markerspace, textsize, etc when computing the boundingbox in
    # the target_space given to the function.
    # We may also want a cheap version that only considers forward
    # transformations (i.e. drops textsize etc when markerspace is not part of
    # the plot.space -> target_space conversion chain)
    if target_space == plot.markerspace[]
        # text only contains a plotlist
        return boundingbox(plot.plots[1], target_space)
        # return full_boundingbox(plot, target_space)
    elseif Makie.is_data_space(target_space)
        return _project(plot.model[]::Mat4d, Rect3d(plot.positions_transformed[])::Rect3d)
    else
        error("`target_space = :$target_space` must be either :data or markerspace = :$(plot.markerspace[])")
    end
end

################################################################################
### MARK: Old Bounding Boxes
################################################################################

# Notes:
# - metrics_bb(): bounding box tightly around glyphs, not used outside of gl backends
# - height_insensitive_boundingbox_with_advance(): bounding box of glyphs as part
#   of a string layout at unit scale
# - rotation is already applied to glyph_origins, so applying origins without
#   rotation doesn't make sense / is wrong
# - offset always applies in markerspace w/o rotation. Excluding it when positions
#   are included makes little sense

function register_raw_glyph_boundingboxes_old!(plot)
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
raw_glyph_boundingboxes(plot) = register_raw_glyph_boundingboxes_old!(plot)[]::Vector{Rect2d}
raw_glyph_boundingboxes_obs(plot) = ComputePipeline.get_observable!(register_raw_glyph_boundingboxes_old!(plot))

# target: rotation aware layouting, e.g. Axis ticks, Menu, ...
function register_fast_glyph_boundingboxes!(plot)
    if !haskey(plot.attributes, :fast_glyph_boundingboxes)
        register_raw_glyph_boundingboxes_old!(plot)
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
        register_raw_glyph_boundingboxes_old!(plot)
        register_markerspace_positions!(plot)
        map!(
            plot.attributes,
            [:raw_glyph_boundingboxes, :marker_offset, :text_rotation, :markerspace_positions],
            :glyph_boundingboxes
        ) do bbs, origins, rotations, positions

            return map(bbs, origins, rotations, positions) do bb, o, rotation, position
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
function register_fast_string_boundingboxes!(plot)
    if !haskey(plot.attributes, :fast_string_boundingboxes)
        register_raw_glyph_boundingboxes_old!(plot)
        # To consider newlines (and word_wrap_width) we need to include origins.
        # To not include rotation we need to strip it from origins
        map!(
            plot.attributes, [:text_blocks, :raw_glyph_boundingboxes, :marker_offset, :text_rotation, :linesegments, :linewidths, :lineindices],
            :fast_string_boundingboxes
        ) do blocks, bbs, origins, rotation, segments, linewidths, lineindices

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
            [:text_blocks, :fast_string_boundingboxes, :markerspace_positions],
            :string_boundingboxes
        ) do text_blocks, bbs, positions

            return map(enumerate(text_blocks)) do (i, idxs)
                if isempty(idxs)
                    return Rect3d(Point3d(NaN), Vec3d(0))
                else
                    return bbs[i] + positions[first(idxs)]
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

# target: data_limits()
function register_data_limits!(plot)
    b
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

# TODO: is this ever called?
data_limits(plot::Text) = register_data_limits!(plot)[]::Rect3d
data_limits_obs(plot::Text) = ComputePipeline.get_observable!(register_data_limits!(plot))


# MARK: Small helpers
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

# MARK: WGL Makie dependencies?
# TODO: this can probably be removed once WGL Makie has been looked at
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

# TODO: this can probably be removed once WGL Makie has been looked at
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

# TODO: this can probably be removed once WGL Makie has been looked at
function map_per_glyph(text_blocks::Vector{UnitRange{Int}}, Typ, arg)
    isscalar(arg) && return fill(arg, last(last(glyphs)))
    result = Typ[]
    per_glyph_attributes(text_blocks, (arg,)) do a
        push!(result, a)
    end
    return result
end
