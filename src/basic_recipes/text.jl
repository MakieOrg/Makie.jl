function check_textsize_deprecation(@nospecialize(dictlike))
    if haskey(dictlike, :textsize)
        throw(ArgumentError("`textsize` has been renamed to `fontsize` in Makie v0.19. Please change all occurrences of `textsize` to `fontsize` or revert back to an earlier version."))
    end
end

# conversion stopper for previous methods
convert_arguments(::Type{<:Text}, gcs::AbstractVector{<:GlyphCollection}) = (gcs,)
convert_arguments(::Type{<:Text}, gc::GlyphCollection) = (gc,)
convert_arguments(::Type{<:Text}, vec::AbstractVector{<:Tuple{<:Any,<:Point}}) = (vec,)
convert_arguments(::Type{<:Text}, strings::AbstractVector{<:AbstractString}) = (strings,)
convert_arguments(::Type{<:Text}, string::AbstractString) = (string,)
# Fallback to PointBased
convert_arguments(::Type{<:Text}, args...) = convert_arguments(PointBased(), args...)


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

    onany(plot, plot.text, plot.fontsize, plot.font, plot.fonts, plot.align,
            plot.rotation, plot.justification, plot.lineheight, plot.calculated_colors,
            plot.strokecolor, plot.strokewidth, plot.word_wrap_width, plot.offset) do str,
                ts, f, fs, al, rot, jus, lh, col, scol, swi, www, offs
        ts = to_fontsize(ts)
        f = to_font(fs, f)
        rot = to_rotation(rot)
        col = to_color(col)
        scol = to_color(scol)
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
            broadcast_foreach(push_args, str, 1:attr_broadcast_length(str), ts, f, fs, al, rot, jus, lh, col, scol, swi, www, offs
            )
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

to_offset(v::VecTypes) = Vec2f(v)
to_offset(v::AbstractVector) = map(to_offset, v)

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

    glyphcollections, linesegs, linewidths, linecolors, lineindices
end

function plot!(plot::Text{<:Tuple{<:AbstractString}})
    attrs = copy(plot.attributes)
    pop!(attrs, :calculated_colors)
    text!(plot, plot.position; attrs..., text = plot[1])
    plot
end



# TODO: is this necessary? there seems to be a recursive loop with the above
# function without these two interceptions, but I didn't need it before merging
# everything into the monorepo...
plot!(plot::Text{<:Tuple{<:GlyphCollection}}) = plot
plot!(plot::Text{<:Tuple{<:AbstractArray{<:GlyphCollection}}}) = plot

function plot!(plot::Text{<:Tuple{<:AbstractArray{<:AbstractString}}})
    attrs = copy(plot.attributes)
    pop!(attrs, :calculated_colors)
    text!(plot, plot.position; attrs..., text = plot[1])
    plot
end

# overload text plotting for a vector of tuples of a string and a point each
function plot!(plot::Text{<:Tuple{<:AbstractArray{<:Tuple{<:Any, <:Point}}}})
    strings_and_positions = plot[1]

    strings = Observable{Vector{Any}}(first.(strings_and_positions[]))

    positions = Observable(
        Point3d[to_ndim(Point3d, last(x), 0) for x in  strings_and_positions[]] # avoid Any for zero elements
    )

    attrs = plot.attributes
    pop!(attrs, :position)
    pop!(attrs, :calculated_colors)
    pop!(attrs, :text)

    text!(plot, positions; attrs..., text = strings)

    # update both text and positions together
    on(plot, strings_and_positions) do str_pos
        strs = first.(str_pos)
        poss = to_ndim.(Ref(Point3d), last.(str_pos), 0)

        strings_unequal = strings.val != strs
        pos_unequal = positions.val != poss
        strings_unequal && (strings.val = strs)
        pos_unequal && (positions.val = poss)
        # Check for equality very imortant, otherwise we get an infinite loop
        strings_unequal && notify(strings)
        pos_unequal && notify(positions)

        return
    end
    plot
end

function texelems_and_glyph_collection(str::LaTeXString, fontscale_px, halign, valign,
        rotation, color, strokecolor, strokewidth, word_wrap_width)

    rot = convert_attribute(rotation, key"rotation"())

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
    positions .= Ref(rot) .* positions

    pre_align_gl = GlyphCollection(
        glyphindices,
        fonts,
        Point3f.(positions),
        extents,
        scales_2d,
        rot,
        color,
        strokecolor,
        strokewidth
    )

    all_els, pre_align_gl, Point2f(xshift, yshift)
end

iswhitespace(l::LaTeXString) = iswhitespace(replace(l.s, '$' => ""))

struct RichText
    type::Symbol
    children::Vector{Union{RichText,String}}
    attributes::Dict{Symbol, Any}
    function RichText(type::Symbol, children...; kwargs...)
        cs = Union{RichText,String}[children...]
        typeof(cs)
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

rich(args...; kwargs...) = RichText(:span, args...; kwargs...)
subscript(args...; kwargs...) = RichText(:sub, args...; kwargs...)
superscript(args...; kwargs...) = RichText(:sup, args...; kwargs...)

export rich, subscript, superscript

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

    _f = to_font(fset, f)

    stack = [GlyphState(0, 0, Vec2f(ts), _f, to_color(col))]

    lines = [GlyphInfo[]]

    process_rt_node!(stack, lines, rt, fset)

    apply_lineheight!(lines, lh)
    apply_alignment_and_justification!(lines, jus, al)

    gc = GlyphCollection(reduce(vcat, lines))
    quat = to_rotation(rot)::Quaternionf
    gc.origins .= Ref(quat) .* gc.origins
    @assert gc.rotations.sv isa Vector # should always be a vector because that's how the glyphcollection is created
    gc.rotations.sv .= Ref(quat) .* gc.rotations.sv
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

function max_y_ascender(glyph_infos::Vector{GlyphInfo})::Float32
    return maximum(glyph_infos) do ginfo
        return ginfo.origin[2] + ginfo.extent.ascender * ginfo.size[2]
    end
end

function min_y_descender(glyph_infos::Vector{GlyphInfo})::Float32
    return minimum(glyph_infos) do ginfo
        return ginfo.origin[2] + ginfo.extent.descender * ginfo.size[2]
    end
end

function apply_alignment_and_justification!(lines, ju, al)

    max_xs = map(max_x_advance, lines)
    max_x = maximum(max_xs)

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

function process_rt_node!(stack, lines, rt::RichText, fonts)
    _type(x) = nothing
    _type(r::RichText) = r.type

    push!(stack, new_glyphstate(stack[end], rt, Val(rt.type), fonts))
    for (i, c) in enumerate(rt.children)
        process_rt_node!(stack, lines, c, fonts)
    end
    gs = pop!(stack)
    gs_top = stack[end]
    # x needs to continue even if going a level up
    stack[end] = GlyphState(gs.x, gs_top.baseline, gs_top.size, gs_top.font, gs_top.color)
    return
end

function process_rt_node!(stack, lines, s::String, _)
    gs = stack[end]
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
    stack[end] = GlyphState(x, y, gs.size, gs.font, gs.color)
    return
end

function new_glyphstate(gs::GlyphState, rt::RichText, val::Val, fonts)
    gs
end

_get_color(attributes, default)::RGBAf = haskey(attributes, :color) ? to_color(attributes[:color]) : default
_get_font(attributes, default::NativeFont, fonts)::NativeFont = haskey(attributes, :font) ? to_font(fonts, attributes[:font]) : default
_get_fontsize(attributes, default)::Vec2f = haskey(attributes, :fontsize) ? Vec2f(to_fontsize(attributes[:fontsize])) : default
_get_offset(attributes, default)::Vec2f = haskey(attributes, :offset) ? Vec2f(attributes[:offset]) : default

function new_glyphstate(gs::GlyphState, rt::RichText, val::Val{:sup}, fonts)
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

function new_glyphstate(gs::GlyphState, rt::RichText, val::Val{:span}, fonts)
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

function new_glyphstate(gs::GlyphState, rt::RichText, val::Val{:sub}, fonts)
    att = rt.attributes
    fontsize = _get_fontsize(att, gs.size * 0.66)
    offset = _get_offset(att, Vec2f(0)) .* fontsize
    GlyphState(
        gs.x + offset[1],
        gs.baseline - 0.15 * gs.size[2] + offset[2],
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
