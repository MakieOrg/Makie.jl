function plot!(plot::Text)
    positions = plot[1]
    # attach a function to any text that calculates the glyph layout and stores it
    glyphcollections = Observable(GlyphCollection[])
    linesegs = Observable(Point2f[])
    linewidths = Observable(Float32[])
    linecolors = Observable(RGBAf[])
    lineindices = Ref(Int[])
    
    onany(plot.text, plot.textsize, plot.font, plot.fonts, plot.align,
            plot.rotation, plot.justification, plot.lineheight, plot.color, 
            plot.strokecolor, plot.strokewidth, plot.word_wrap_width) do str,
                ts, f, fs, al, rot, jus, lh, col, scol, swi, www
        ts = to_textsize(ts)
        f = to_font(fs, f)
        rot = to_rotation(rot)
        col = to_color(col)
        scol = to_color(scol)

        gcs = GlyphCollection[]
        lsegs = Point2f[]
        lwidths = Float32[]
        lcolors = RGBAf[]
        lindices = Int[]
        function push_args((gc, ls, lw, lc, lindex))
            push!(gcs, gc)
            append!(lsegs, ls)
            append!(lwidths, lw)
            append!(lcolors, lc)
            append!(lindices, lindex)
            return
        end
        func = push_args ∘ _get_glyphcollection_and_linesegments
        if str isa Vector
            # If we have a Vector of strings, Vector arguments are interpreted 
            # as per string.
            broadcast_foreach(
                func, 
                str, 1:attr_broadcast_length(str), ts, f, fs, al, rot, jus, lh, col, scol, swi, www
            )
        else
            # Otherwise Vector arguments are interpreted by layout_text/
            # glyph_collection as per character.
            func(str, 1, ts, f, fs, al, rot, jus, lh, col, scol, swi, www)
        end
        glyphcollections[] = gcs
        linewidths[] = lwidths
        linecolors[] = lcolors
        lineindices[] = lindices
        linesegs[] = lsegs
    end

    linesegs_shifted = Observable(Point2f[])

    sc = parent_scene(plot)

    onany(linesegs, positions, sc.camera.projectionview, sc.px_area, transform_func_obs(sc)) do segs, pos, _, _, transf
        pos_transf = scene_to_screen(apply_transform(transf, pos), sc)
        linesegs_shifted[] = map(segs, lineindices[]) do seg, index
            seg + attr_broadcast_getindex(pos_transf, index)
        end
    end

    notify(plot.text)

    attrs = copy(plot.attributes)
    # remove attributes that are already in the glyphcollection
    pop!(attrs, :position)
    pop!(attrs, :text)
    pop!(attrs, :align)
    pop!(attrs, :color)

    t = text!(plot, glyphcollections; attrs..., position = positions)
    # remove attributes that the backends will choke on
    pop!(t.attributes, :font)
    pop!(t.attributes, :fonts)
    linesegments!(plot, linesegs_shifted; linewidth = linewidths, color = linecolors, space = :pixel)

    plot
end

function _get_glyphcollection_and_linesegments(str::AbstractString, index, ts, f, fs, al, rot, jus, lh, col, scol, swi, www)
    gc = layout_text(string(str), ts, f, fs, al, rot, jus, lh, col, scol, swi, www)
    gc, Point2f[], Float32[], RGBAf[], Int[]
end
function _get_glyphcollection_and_linesegments(latexstring::LaTeXString, index, ts, f, fs, al, rot, jus, lh, col, scol, swi, www)
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
            push!(linesegs, rotate_2d(rot, ts * Point2f(x, y) - offset))
            push!(linesegs, rotate_2d(rot, ts * Point2f(x + h.width, y) - offset))
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
    text!(plot, plot.position; text = plot[1], plot.attributes...)
    plot
end

# conversion stopper for previous methods
convert_arguments(::Type{<: Text}, gcs::AbstractVector{<:GlyphCollection}) = (gcs,)
convert_arguments(::Type{<: Text}, gc::GlyphCollection) = (gc,)
convert_arguments(::Type{<: Text}, vec::AbstractVector{<:Tuple{<:AbstractString, <:Point}}) = (vec,)
convert_arguments(::Type{<: Text}, strings::AbstractVector{<:AbstractString}) = (strings,)
convert_arguments(::Type{<: Text}, string::AbstractString) = (string,)

# TODO: is this necessary? there seems to be a recursive loop with the above
# function without these two interceptions, but I didn't need it before merging
# everything into the monorepo...
plot!(plot::Text{<:Tuple{<:GlyphCollection}}) = plot
plot!(plot::Text{<:Tuple{<:AbstractArray{<:GlyphCollection}}}) = plot

function plot!(plot::Text{<:Tuple{<:AbstractArray{<:AbstractString}}})
    text!(plot, plot.position; text = plot[1], plot.attributes...)
    plot
end

# overload text plotting for a vector of tuples of a string and a point each
function plot!(plot::Text{<:Tuple{<:AbstractArray{<:Tuple{<:AbstractString, <:Point}}}})    
    strings_and_positions = plot[1]

    strings = Observable{Vector{AbstractString}}(first.(strings_and_positions[]))

    positions = Observable(
        Point3f[to_ndim(Point3f, last(x), 0) for x in  strings_and_positions[]] # avoid Any for zero elements
    )

    attrs = plot.attributes
    pop!(attrs, :position)

    text!(plot, positions; text = strings, attrs...)

    # update both text and positions together
    on(strings_and_positions) do str_pos
        strs = first.(str_pos)
        poss = to_ndim.(Ref(Point3f), last.(str_pos), 0)

        strings.val != strs && (strings[] = strs)
        positions.val != poss && (positions[] = poss)

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

    xshift = if halign == :center
        width(bb) ./ 2
    elseif halign == :left
        minimum(bb)[1]
    elseif halign == :right
        maximum(bb)[1]
    end

    yshift = if valign == :center
        maximum(bb)[2] - (height(bb) / 2)
    elseif valign == :top
        maximum(bb)[2]
    else
        minimum(bb)[2]
    end

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

struct RichText <: AbstractString
    type::Symbol
    children::Vector{Union{RichText,String}}
    attributes::Dict{Symbol, Any}
    function RichText(type::Symbol, children...; kwargs...)
        cs = Union{RichText,String}[children...]
        typeof(cs)
        new(type, cs, Dict(kwargs))
    end
end

function Base.:(==)(r1::RichText, r2::RichText)
    r1.type == r2.type && r1.children == r2.children && r1.attributes == r2.attributes
end

rich(args...; kwargs...) = RichText(:span, args...; kwargs...)
subscript(args...; kwargs...) = RichText(:sub, args...; kwargs...)
superscript(args...; kwargs...) = RichText(:sup, args...; kwargs...)

export rich, subscript, superscript

##
function Makie._get_glyphcollection_and_linesegments(rt::RichText, index, ts, f, fset, al, rot, jus, lh, col, scol, swi, www)
    gc = Makie.layout_text(rt, ts, f, fset, al, rot, jus, lh, col)
    gc, Point2f[], Float32[], Makie.RGBAf[], Int[]
end

struct GlyphState2
    x::Float32
    baseline::Float32
    size::Vec2f
    font::Makie.FreeTypeAbstraction.FTFont
    color::RGBAf
end

struct GlyphInfo2
    glyph::Int
    font::Makie.FreeTypeAbstraction.FTFont
    origin::Point2f
    extent::Makie.GlyphExtent
    size::Vec2f
    rotation::Makie.Quaternion
    color::RGBAf
    strokecolor::RGBAf
    strokewidth::Float32
end

function Makie.GlyphCollection(v::Vector{GlyphInfo2})
    Makie.GlyphCollection(
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


function Makie.layout_text(rt::RichText, ts, f, fset, al, rot, jus, lh, col)

    _f = to_font(fset, f)

    stack = [GlyphState2(0, 0, Vec2f(ts), _f, Makie.to_color(col))]

    lines = [GlyphInfo2[]]
    
    process_rt_node!(stack, lines, rt, fset)

    apply_lineheight!(lines, lh)
    apply_alignment_and_justification!(lines, jus, al)

    Makie.GlyphCollection(reduce(vcat, lines))
end

function apply_lineheight!(lines, lh)
    for (i, line) in enumerate(lines)
        for j in eachindex(line)
            l = line[j]
            l = Setfield.@set l.origin[2] -= (i-1) * 20 # TODO: Lineheight
            line[j] = l
        end
    end
    return
end

function apply_alignment_and_justification!(lines, ju, al)
    max_xs = map(lines) do line
        maximum(line, init = 0f0) do ginfo
            ginfo.origin[1] + ginfo.extent.hadvance * ginfo.size[1]
        end
    end
    max_x = maximum(max_xs)

    top_y = maximum(lines[1]) do ginfo
        ginfo.origin[2] + ginfo.extent.ascender * ginfo.size[2]
    end
    bottom_y = minimum(lines[end]) do ginfo
        ginfo.origin[2] + ginfo.extent.descender * ginfo.size[2]
    end

    al_offset_x = if al[1] == :center
        max_x / 2
    elseif al[1] == :left
        0f0
    elseif al[1] == :right
        max_x
    else
        0f0
    end

    al_offset_y = if al[2] == :center
        0.5 * (top_y + bottom_y)
    elseif al[2] == :bottom
        bottom_y
    elseif al[2] == :top
        top_y
    else
        0f0
    end

    fju = float_justification(ju, al)
    
    for (i, line) in enumerate(lines)
        ju_offset = fju * (max_x - max_xs[i])
        for j in eachindex(line)
            l = line[j]
            l = Setfield.@set l.origin -= Point2f(al_offset_x - ju_offset, al_offset_y)
            line[j] = l
        end
    end
    return
end

function float_justification(ju, al)::Float32
    halign = al[1]
    float_justification = if ju === automatic
        if halign == :left || halign == 0
            0.0f0
        elseif halign == :right || halign == 1
            1.0f0
        elseif halign == :center || halign == 0.5
            0.5f0
        else
            0.5f0
        end
    elseif ju == :left
        0.0f0
    elseif ju == :right
        1.0f0
    elseif ju == :center
        0.5f0
    else
        Float32(ju)
    end
end

function process_rt_node!(stack, lines, rt::RichText, fonts)
    _type(x) = nothing
    _type(r::RichText) = r.type

    push!(stack, new_glyphstate(stack[end], rt, Val(rt.type), fonts))
    sup_x = 0f0
    for (i, c) in enumerate(rt.children)
        if _type(c) == :sup
            sup_x = stack[end].x
        end
        # This special implementation allows to stack super and subscripts.
        # In the naive implementation, x can only grow with each character,
        # however, to stack super and subscript, we need to track back to the
        # previous x value and afterwards continue with the maximum of super
        # and subscript.
        if i > 1 && _type(c) === :sub && _type(rt.children[i-1]) == :sup
            gs = stack[end]
            sup_x_end = gs.x
            gs_modified = Setfield.@set gs.x = sup_x
            stack[end] = gs_modified
            process_rt_node!(stack, lines, c, fonts)
            gs = stack[end]
            max_x = max(sup_x_end, gs.x)
            gs_max_x = Setfield.@set gs.x = max_x
            stack[end] = gs_max_x
        else
            process_rt_node!(stack, lines, c, fonts)
        end
    end
    gs = pop!(stack)
    gs_top = stack[end]
    # x needs to continue even if going a level up
    stack[end] = GlyphState2(gs.x, gs_top.baseline, gs_top.size, gs_top.font, gs_top.color)
    return
end

function process_rt_node!(stack, lines, s::String, _)
    gs = stack[end]
    y = gs.baseline
    x = gs.x
    for char in s
        if char === '\n'
            x = 0
            push!(lines, GlyphInfo2[])
        else
            gi = Makie.FreeTypeAbstraction.glyph_index(gs.font, char)
            gext = Makie.GlyphExtent(gs.font, char)
            ori = Point2f(x, y)
            push!(lines[end], GlyphInfo2(
                gi,
                gs.font,
                ori,
                gext,
                gs.size,
                Makie.to_rotation(0),
                gs.color,
                RGBAf(0, 0, 0, 0),
                0f0,
            ))
            x = x + gext.hadvance * gs.size[1]
        end
    end
    stack[end] = GlyphState2(x, y, gs.size, gs.font, gs.color)
    return
end

function new_glyphstate(gs::GlyphState2, rt::RichText, val::Val, fonts)
    gs
end

_get_color(attributes, default)::RGBAf = haskey(attributes, :color) ? Makie.to_color(attributes[:color]) : default
_get_font(attributes, default::NativeFont, fonts)::NativeFont = haskey(attributes, :font) ? Makie.to_font(fonts, attributes[:font]) : default

function new_glyphstate(gs::GlyphState2, rt::RichText, val::Val{:sup}, fonts)
    att = rt.attributes
    GlyphState2(
        gs.x,
        gs.baseline + 0.4 * gs.size[2],
        gs.size * 0.66,
        _get_font(att, gs.font, fonts),
        _get_color(att, gs.color),
    )
end

function new_glyphstate(gs::GlyphState2, rt::RichText, val::Val{:span}, fonts)
    att = rt.attributes
    GlyphState2(
        gs.x,
        gs.baseline,
        gs.size,
        _get_font(att, gs.font, fonts),
        _get_color(att, gs.color),
    )
end

function new_glyphstate(gs::GlyphState2, rt::RichText, val::Val{:sub}, fonts)
    att = rt.attributes
    GlyphState2(
        gs.x,
        gs.baseline - 0.15 * gs.size[2],
        gs.size * 0.66,
        _get_font(att, gs.font, fonts),
        _get_color(att, gs.color),
    )
end

Makie.iswhitespace(::RichText) = false
