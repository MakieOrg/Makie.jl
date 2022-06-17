function plot!(plot::Text)
    positions = plot[1]
    # attach a function to any text that calculates the glyph layout and stores it
    glyphcollections = Observable(GlyphCollection[])
    
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
        func = (gc -> push!(gcs, gc)) ∘ _get_glyphcollection
        broadcast_foreach(func, str, ts, f, al, rot, jus, lh, col, scol, swi, www)
        glyphcollections[] = gcs
    end

    notify(plot.text)

    attrs = copy(plot.attributes)
    pop!(attrs, :position)
    pop!(attrs, :text)

    text!(plot, glyphcollections; attrs..., position = positions)

    plot
end

_get_glyphcollection(string::String, ts, f, al, rot, jus, lh, col, scol, swi, www) = layout_text(string, ts, f, al, rot, jus, lh, col, scol, swi, www)
function _get_glyphcollection(latexstring::LaTeXString, ts, f, al, rot, jus, lh, col, scol, swi, www)
    tex_elements, glyphcollections, offsets = texelems_and_glyph_collection(latexstring, ts,
                al[1], al[2], rot, col, scol, swi, www)

    glyphcollections
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


# function plot!(plot::Text{<:Tuple{<:Union{LaTeXString, AbstractVector{<:LaTeXString}}}})
    
#     # attach a function to any text that calculates the glyph layout and stores it
#     lineels_glyphcollection_offset = lift(plot[1], plot.textsize, plot.align, plot.rotation,
#             plot.model, plot.color, plot.strokecolor, plot.strokewidth, 
#             plot.word_wrap_width) do latexstring, ts, al, rot, mo, color, scolor, swidth, www

#         ts = to_textsize(ts)
#         rot = to_rotation(rot)

#         if latexstring isa AbstractVector
#             tex_elements = []
#             glyphcollections = GlyphCollection[]
#             offsets = Point2f[]
#             broadcast_foreach(latexstring, ts, al, rot, color, scolor, swidth, www) do latexstring,
#                 ts, al, rot, color, scolor, swidth, _www

#                 te, gc, offs = texelems_and_glyph_collection(latexstring, ts,
#                     al[1], al[2], rot, color, scolor, swidth, www)
#                 push!(tex_elements, te)
#                 push!(glyphcollections, gc)
#                 push!(offsets, offs)
#             end
#             return tex_elements, glyphcollections, offsets
#         else
#             tex_elements, glyphcollections, offsets = texelems_and_glyph_collection(latexstring, ts,
#                 al[1], al[2], rot, color, scolor, swidth, www)
#             return tex_elements, glyphcollections, offsets
#         end
#     end

#     glyphcollection = @lift($lineels_glyphcollection_offset[2])


#     linepairs = Observable(Tuple{Point2f, Point2f}[])
#     linewidths = Observable(Float32[])

#     scene = Makie.parent_scene(plot)

#     onany(lineels_glyphcollection_offset, plot.position, scene.camera.projectionview
#             ) do (allels, gcs, offs), pos, _

#         if pos isa Vector && (length(pos) != length(allels))
#             return
#         end
#         # inv_projview = inv(projview)
#         ts = plot.textsize[]
#         rot = plot.rotation[]

#         ts = to_textsize(ts)
#         rot = convert_attribute(rot, key"rotation"())

#         empty!(linepairs.val)
#         empty!(linewidths.val)

#         # for the vector case, allels is a vector of vectors
#         # so for broadcasting the single vector needs to be wrapped in Ref
#         if gcs isa GlyphCollection
#             allels = [allels]
#         end
#         broadcast_foreach(allels, offs, pos, ts, rot) do allels, offs, pos, ts, rot
#             offset = project(scene.camera, :data, :pixel, Point2f(pos))[Vec(1, 2)]

#             els = map(allels) do el
#                 el[1] isa VLine || el[1] isa HLine || return nothing

#                 t = el[1].thickness * ts
#                 p = el[2]

#                 ps = if el[1] isa VLine
#                     h = el[1].height
#                     (Point2f(p[1], p[2]) .* ts, Point2f(p[1], p[2] + h) .* ts) .- Ref(offs)
#                 else
#                     w = el[1].width
#                     (Point2f(p[1], p[2]) .* ts, Point2f(p[1] + w, p[2]) .* ts) .- Ref(offs)
#                 end
#                 ps = Ref(rot) .* to_ndim.(Point3f, ps, 0)
#                 # TODO the points need to be projected to work inside Axis
#                 # ps = project ps with projview somehow

#                 ps = Point2f.(ps) .+ Ref(offset)
#                 ps, t
#             end
#             pairs = filter(!isnothing, els)
#             append!(linewidths.val, repeat(last.(pairs), inner = 2))
#             append!(linepairs.val, first.(pairs))
#         end
#         notify(linepairs)
#         return
#     end

#     notify(plot.position)

#     text!(plot, glyphcollection; plot.attributes...)
#     linesegments!(
#         plot, linepairs, linewidth = linewidths, color = plot.color,
#         visible = plot.visible, inspectable = plot.inspectable, 
#         transparent = plot.transparency, space = :pixel
#     )

#     plot
# end

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

    positions = basepositions .- Ref(Vec3f(xshift, yshift, 0))
    positions .= Ref(rot) .* positions

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
