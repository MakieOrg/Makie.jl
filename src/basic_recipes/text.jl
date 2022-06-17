function plot!(plot::Text)
    positions = plot[1]
    # attach a function to any text that calculates the glyph layout and stores it
    glyphcollections = Observable(GlyphCollection[])
    linesegs = Observable(Point2f[])
    linewidths = Observable(Float32[])
    linecolors = Observable(RGBAf[])
    lineindices = Ref(Int[])
    
    onany(plot.text, plot.textsize, plot.font, plot.align,
            plot.rotation, plot.justification, plot.lineheight, plot.color, 
            plot.strokecolor, plot.strokewidth, plot.word_wrap_width) do str,
                ts, f, al, rot, jus, lh, col, scol, swi, www
        ts = to_textsize(ts)
        f = to_font(f)
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
        broadcast_foreach(func, str, 1:attr_broadcast_length(str), ts, f, al, rot, jus, lh, col, scol, swi, www)
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

    text!(plot, glyphcollections; attrs..., position = positions)
    linesegments!(plot, linesegs_shifted; linewidth = linewidths, color = linecolors, space = :pixel)

    plot
end

function _get_glyphcollection_and_linesegments(string::AbstractString, index, ts, f, al, rot, jus, lh, col, scol, swi, www)
    gc = layout_text(string, ts, f, al, rot, jus, lh, col, scol, swi, www)
    gc, Point2f[], Float32[], RGBAf[], Int[]
end
function _get_glyphcollection_and_linesegments(latexstring::LaTeXString, index, ts, f, al, rot, jus, lh, col, scol, swi, www)
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

    strings = Observable(first.(strings_and_positions[]))
    positions = Observable(to_ndim.(Ref(Point3f), last.(strings_and_positions[]), 0))

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
    chars = [texchar.char for texchar in texchars]
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

        for i in eachindex(chars)
            basepositions[i] -= newline_offset
            if chars[i] == ' ' || i == length(chars)
                right_pos = basepositions[i][1] + width(bboxes[i])
                if last_space_idx != 0 && right_pos > word_wrap_width
                    section_offset = basepositions[last_space_idx + 1][1]
                    lineheight = maximum((height(bb) for bb in bboxes[last_newline_idx:last_space_idx]))
                    last_newline_idx = last_space_idx+1
                    newline_offset += Point3f(section_offset, lineheight, 0)

                    chars[last_space_idx] = '\n'
                    for j in last_space_idx+1:i
                        basepositions[j] -= Point3f(section_offset, lineheight, 0)
                    end
                end
                last_space_idx = i
            elseif chars[i] == '\n'
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

    # # we replace VLine and HLine with characters that are specifically scaled and positioned
    # # such that they match line length and thickness
    # for (el, position, _) in all_els
    #     el isa MathTeXEngine.VLine || el isa MathTeXEngine.HLine || continue
    #     if el isa MathTeXEngine.HLine
    #         w, h = el.width, el.thickness
    #     else
    #         w, h = el.thickness, el.height
    #     end
    #     font = to_font("TeX Gyre Heros Makie")
    #     c = el isa MathTeXEngine.HLine ? '_' : '|'
    #     fext = get_extent(font, c)
    #     inkbb = FreeTypeAbstraction.inkboundingbox(fext)
    #     w_ink = width(inkbb)
    #     h_ink = height(inkbb)
    #     ori = inkbb.origin
        
    #     char_scale = Vec2f(w / w_ink, h / h_ink) * fs

    #     pos_scaled = fs * Vec2f(position)
    #     pos_inkshifted = pos_scaled - char_scale * ori - Vec2f(0, h_ink / 2) # TODO fix for VLine
    #     pos_final = rot * Vec3f((pos_inkshifted - Vec2f(shift[Vec(1, 2)]))..., 0)

    #     push!(positions, pos_final)
    #     push!(chars, c)
    #     push!(fonts, font)
    #     push!(extents, GlyphExtent(font, c))
    #     push!(scales_2d, char_scale)
    # end

    pre_align_gl = GlyphCollection(
        chars,
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
