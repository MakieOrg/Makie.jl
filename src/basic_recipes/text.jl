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
convert_attribute(rt::RichText, ::key"text", ::key"text") = [rt]
convert_attribute(str::AbstractString, ::key"text", ::key"text") = [str]
convert_attribute(x::AbstractVector, ::key"text", ::key"text") = vec(x)


function register_text_arguments!(attr::ComputeGraph, user_kw, input_args...)
    # Set up Inputs
    inputs = _register_input_arguments!(Text, attr, input_args)

    # User arguments can be PointBased(), String-like or mixed, with the
    # position and text attributes supplementing data not in arguments.
    # For conversion we want to move position data into the argument pipeline
    # and String-like data into attributes. Do this here:
    pushfirst!(inputs, :position, :text)
    register_computation!(attr, inputs, [:input_positions, :input_text]) do inputs, changed, cached
        a_pos, a_text, args... = values(inputs)

        # Note: Could add RichText
        if args isa Tuple{<: AbstractString}
            # position data will allways be wrapped in a Vector, so strings should too
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
    _register_expand_arguments!(Text, attr, [:input_positions], true)

    # And the rest of it
    _register_argument_conversions!(Text, attr, user_kw)

    return
end

function register_text_computations!(attr::ComputeGraph)
    register_computation!(attr, [:fonts, :font], [:selected_font]) do (fs, f), changed, cached
        return (to_font(fs, f),)
    end

    # TODO: maybe split this up
    # Generate glyphcollections and whatnot
    inputs = [
        :input_text, :fontsize,
        :selected_font, # TODO: include to_font here
        :fonts, # TODO: remove this
        :align, :rotation, :justification,
        :lineheight,
        :scaled_color, :strokecolor, :strokewidth, # TODO: can we remove these?
        :word_wrap_width, :offset
    ]

    register_computation!(attr, inputs,
            [:glyph_collections, :linepoints, :linewidths, :linecolors, :lineindices]
        ) do inputs, changed, cached

        str, ts, f, fs, al, rot, jus, lh, col, scol, swi, www, offs = inputs

        if isnothing(cached)
            gcs = GlyphCollection[]
            lsegs = Point2f[]
            lwidths = Float32[]
            lcolors = RGBAf[]
            lindices = Int[]
        else
            gcs = empty!(cached[1])
            lsegs = empty!(cached[2])
            lwidths = empty!(cached[3])
            lcolors = empty!(cached[4])
            lindices = empty!(cached[5])
        end

        broadcast_foreach(str, 1:attr_broadcast_length(str), ts, f, fs, al, rot, jus, lh, col, scol, swi, www, offs) do args...
            gc, ls, lw, lc, lindex = _get_glyphcollection_and_linesegments(args...)
            push!(gcs, gc)
            append!(lsegs, ls)
            append!(lwidths, lw)
            append!(lcolors, lc)
            append!(lindices, lindex)
        end

        return (gcs, lsegs, lwidths, lcolors, lindices)
    end

    return
end

# TODO: is this needed in CairoMakie?
#       Do it earlier then
function per_glyph_data((gcs, ), changed, cached)
    color       = reduce(vcat, (Makie.collect_vector(g.colors, length(g.glyphs)) for g in gcs), init = RGBAf[])
    strokecolor = reduce(vcat, (Makie.collect_vector(g.strokecolors, length(g.glyphs)) for g in gcs), init = RGBAf[])
    rotation    = reduce(vcat, (Makie.collect_vector(g.rotations, length(g.glyphs)) for g in gcs), init = Quaternionf[])
    return (color, strokecolor, rotation)
end

function compute_text_attributes((atlas, positions, glyph_collections, offsets), changed, cached)
    return text_quads(atlas, positions, glyph_collections, offsets)
end

function register_quad_computations!(attr, atlas_res=1024, atlas_ppg=32)
    if haskey(attr, :atlas)
        @error("Overwriting the texture atlas probably doesn't work")
    else
        register_computation!(attr, Symbol[], [:atlas]) do _, changed, last
            (get_texture_atlas(atlas_res, atlas_ppg),)
        end
    end
    inputs = [:atlas, :positions_transformed_f32c, :glyph_collections, :offset]
    outputs = [:gl_position, :gl_marker_offset, :gl_quad_offset, :gl_uv_offset_width, :gl_scale]
    register_computation!(compute_text_attributes, attr, inputs, outputs)

    register_computation!(per_glyph_data, attr, [:glyph_collections], [:gl_color, :gl_stroke_color, :gl_rotation])

    # TODO:
    # This is the bulk of draw_atomic
    # just need to sort out the naming and deal with preprojection
    # and add_f32c_scale I guess

    return
end

function compute_plot(::Type{Text}, args::Tuple, user_kw::Dict{Symbol,Any})
    attr = ComputeGraph()
    add_attributes!(Text, attr, user_kw)
    register_colormapping!(attr)
    register_text_arguments!(attr, user_kw, args...)
    register_text_computations!(attr)

    # TODO: naming...?
    # markerspace bounding boxes of elements (i.e. each string passed to text)
    register_computation!(attr, [:glyph_collections, :rotation], [:element_bbs]) do (gcs, rot), changed, last
        N = length(gcs)
        @assert attr_broadcast_length(rot) in (1, N) ":rotation must be either scalar or have the same length as :text"

        bbs = [unchecked_boundingbox(gcs[i], attr_broadcast_getindex(rot, i)) for i in 1:N]
        return (bbs,)
    end

    # TODO: There is a :position attribute and a :positions Computed (after dim converts)
    #       This seems quite error prone...

    # data_limits()
    register_computation!(attr, [:element_bbs, :positions, :space, :markerspace], [:data_limits]) do inputs, changed, last
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

        return (Rect3d(positions),)
    end

    T = typeof(attr[:positions][])
    p = Plot{text, Tuple{T}}(user_kw, Observable(Pair{Symbol,Any}[]), Any[attr], Observable[])
    p.transformation = Transformation()
    return p
end

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
    for (bb, p) in zip(plot.element_bbs[], pos)
        total_bb = update_boundingbox(total_bb, bb + to_ndim(Point3d, p, 0))
    end
    return (total_bb,)
end


# Old functions



function _get_glyphcollection_and_linesegments(str::AbstractString, index, ts, f, fs, al, rot, jus, lh, col, scol, swi, www, offs)
    gc = layout_text(string(str), ts, f, fs, al, rot, jus, lh, col, scol, swi, www)
    gc, Point2f[], Float32[], RGBAf[], Int[]
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

function texelems_and_glyph_collection(str::LaTeXString, fontscale_px, halign, valign,
        rotation, color, strokecolor, strokewidth, word_wrap_width)

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

struct RichText
    type::Symbol
    children::Vector{Union{RichText,String}}
    attributes::Dict{Symbol, Any}
    function RichText(type::Symbol, children...; kwargs...)
        cs = Union{RichText,String}[children...]
        new(type, cs, Dict(kwargs))
    end
end

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

#=

function plot!(plot::Text)
    positions = plot[1]
    # attach a function to any text that calculates the glyph layout and stores it
    glyphcollections = Observable(GlyphCollection[]; ignore_equal_values=true)
    linesegs = Observable(Point2f[]; ignore_equal_values=true)
    linewidths = Observable(Float32[]; ignore_equal_values=true)
    linecolors = Observable(RGBAf[]; ignore_equal_values=true)
    lineindices = Ref(Int[])
    if !haskey(plot, :text)
        attributes(plot)[:text] = plot[2]
    end
    calc_color = plot.calculated_colors[]

    color_scaled = calc_color isa ColorMapping ? calc_color.color_scaled : plot.color
    cmap = calc_color isa ColorMapping ? calc_color.colormap : plot.colormap

    onany(plot, plot.text, plot.fontsize, plot.font, plot.fonts, plot.align,
          plot.rotation, plot.justification, plot.lineheight, color_scaled, cmap,
            plot.strokecolor, plot.strokewidth, plot.word_wrap_width, plot.offset) do str,
                ts, f, fs, al, rot, jus, lh, cs, cmap, scol, swi, www, offs

        ts = to_fontsize(ts)                        # [convert_attribute] check
        f = to_font(fs, f)                          # [convert_attribute] -----
        rot = to_rotation(rot)                      # [convert_attribute] check
        col = to_color(plot.calculated_colors[])    # [convert_attribute] check
        scol = to_color(scol)                       # [convert_attribute] check
        offs = to_offset(offs)

        gcs = GlyphCollection[]
        lsegs = Point2f[]
        lwidths = Float32[]
        lcolors = RGBAf[]
        lindices = Int[]
        function push_args(args...)
            gc, ls, lw, lc, lindex = _get_glyphcollection_and_linesegments(args...)
            push!(gcs, gc)
            append!(lsegs, ls)
            append!(lwidths, lw)
            append!(lcolors, lc)
            append!(lindices, lindex)
            return
        end
        if str isa Vector
            # If we have a Vector of strings, Vector arguments are interpreted
            # as per string.
            broadcast_foreach(push_args, str, 1:attr_broadcast_length(str), ts, f, fs, al, rot, jus, lh, col, scol, swi, www, offs)
        else
            # Otherwise Vector arguments are interpreted by layout_text/
            # glyph_collection as per character.
            push_args(str, 1, ts, f, fs, al, rot, jus, lh, col, scol, swi, www, offs)
        end

        glyphcollections[] = gcs
        linewidths[] = lwidths
        linecolors[] = lcolors
        lineindices[] = lindices
        linesegs[] = lsegs
    end

    linesegs_shifted = Observable(Point2f[]; ignore_equal_values=true)

    sc = parent_scene(plot)

    onany(plot, linesegs, positions, sc.camera.projectionview, sc.viewport, f32_conversion_obs(sc),
            transform_func_obs(sc), get(plot, :space, :data)) do segs, pos, _, _, _, transf, space
        pos_transf = plot_to_screen(plot, pos)
        linesegs_shifted[] = map(segs, lineindices[]) do seg, index
            seg + attr_broadcast_getindex(pos_transf, index)
        end
    end

    notify(plot.text)

    attrs = copy(plot.attributes)
    # remove attributes that are already in the glyphcollection
    attributes(attrs)[:position] = positions
    pop!(attrs, :text)
    pop!(attrs, :align)
    pop!(attrs, :color)
    pop!(attrs, :calculated_colors)

    t = text!(plot, attrs, glyphcollections)
    # remove attributes that the backends will choke on
    pop!(t.attributes, :font)
    pop!(t.attributes, :fonts)
    pop!(t.attributes, :text)
    linesegments!(plot, linesegs_shifted; linewidth = linewidths, color = linecolors, space = :pixel)
    plot
end



=#