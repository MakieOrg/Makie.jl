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
        if str isa Vector
            # If we have a Vector of strings, Vector arguments are interpreted 
            # as per string.
            broadcast_foreach(
                func, 
                str, 1:attr_broadcast_length(str), ts, f, al, rot, jus, lh, col, scol, swi, www
            )
        else
            # Otherwise Vector arguments are interpreted by layout_text/
            # glyph_collection as per character.
            func(str, 1, ts, f, al, rot, jus, lh, col, scol, swi, www)
        end
        glyphcollections[] = gcs
        linewidths[] = lwidths
        linecolors[] = lcolors
        lineindices[] = lindices
        linesegs[] = lsegs
    end

    linesegs_shifted = Observable(Point2f[])

    sc = parent_scene(plot)

    onany(linesegs, positions, sc.camera.projectionview, sc.px_area, 
            transform_func_obs(sc), get(plot, :space, :data)) do segs, pos, _, _, transf, space
        pos_transf = scene_to_screen(apply_transform(transf, pos, space), sc)
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

function _get_glyphcollection_and_linesegments(str::AbstractString, index, ts, f, al, rot, jus, lh, col, scol, swi, www)
    gc = layout_text(string(str), ts, f, al, rot, jus, lh, col, scol, swi, www)
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
