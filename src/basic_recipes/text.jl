function plot!(plot::Text)
    # attach a function to any text that calculates the glyph layout and stores it
    glyphcollection = lift(plot[1], plot.textsize, plot.font, plot.align,
            plot.rotation, plot.model, plot.justification, plot.lineheight,
            plot.color, plot.strokecolor, plot.strokewidth) do str,
                ts, f, al, rot, mo, jus, lh, col, scol, swi
        ts = to_textsize(ts)
        f = to_font(f)
        rot = to_rotation(rot)
        col = to_color(col)
        scol = to_color(scol)
        return layout_text(str, ts, f, al, rot, mo, jus, lh, col, scol, swi)
    end
    text!(plot, glyphcollection; plot.attributes...)
    plot
end

# TODO: is this necessary? there seems to be a recursive loop with the above
# function without these two interceptions, but I didn't need it before merging
# everything into the monorepo...
plot!(plot::Text{<:Tuple{<:GlyphCollection}}) = plot
plot!(plot::Text{<:Tuple{<:AbstractArray{<:GlyphCollection}}}) = plot

to_point3_vec(vec::Vector{Point3f0}) = vec
to_point3_vec(vec) = to_ndim.(Point3f0, vec, 0)

function plot!(plot::Text{<:Tuple{<:AbstractArray{<:AbstractString}}})

    rotation = Node{Any}(nothing)
    positions = Node{Vector{Point3f0}}(Point3f0[])

    glyphcollections = lift(plot[1], plot.textsize,
            plot.font, plot.align, plot.rotation, plot.model, plot.justification,
            plot.lineheight, plot.color, plot.strokecolor, plot.strokewidth) do str,
                    ts, f, al, rot, mo, jus, lh, col, scol, swi
        ts = to_textsize(ts)
        f = to_font(f)
        rot = to_rotation(rot)
        col = to_color(col)
        scol = to_color(scol)

        gcs = GlyphCollection[]
        broadcast_foreach(str, ts, f, al, rot, Ref(mo), jus, lh, col, scol, swi) do str,
                ts, f, al, rot, mo, jus, lh, col, scol, swi
            subgl = layout_text(str, ts, f, al, rot, mo, jus, lh, col, scol, swi)
            push!(gcs, subgl)
        end
        positions.val = to_point3_vec(plot.position[])
        rotation.val = rot
        gcs
    end

    text!(plot, glyphcollections; position = positions, rotation = rotation,
        model = plot.model, offset = plot.offset, space = plot.space, visible=plot.visible)

    plot
end

# overload text plotting for a vector of tuples of a string and a point each
function plot!(plot::Text{<:Tuple{<:AbstractArray{<:Tuple{<:AbstractString, <:Point}}}})
    strings_and_positions = plot[1]

    strings = Node(first.(strings_and_positions[]))
    positions = Node(to_ndim.(Ref(Point3f0), last.(strings_and_positions[]), 0))

    attrs = plot.attributes
    pop!(attrs, :position)

    t = text!(plot, strings; position = positions, attrs...)

    # update both text and positions together
    on(strings_and_positions) do str_pos
        strs = first.(str_pos)
        poss = to_ndim.(Ref(Point3f0), last.(str_pos), 0)
        # first mutate strings without triggering redraw
        empty!(positions.val)
        append!(positions.val, poss)
        # then update positions with trigger
        t[1] = strs
    end
    plot
end


function plot!(plot::Text{<:Tuple{<:Union{LaTeXString, AbstractVector{<:LaTeXString}}}})

    # attach a function to any text that calculates the glyph layout and stores it
    lineels_glyphcollection_offset = lift(plot[1], plot.textsize, plot.align, plot.rotation,
            plot.model, plot.color, plot.strokecolor, plot.strokewidth, plot.position) do latexstring,
                ts, al, rot, mo, color, scolor, swidth, _

        ts = to_textsize(ts)
        rot = to_rotation(rot)

        if latexstring isa AbstractVector
            tex_elements = []
            glyphcollections = GlyphCollection[]
            offsets = Point2f0[]
            broadcast_foreach(latexstring, ts, al, rot, color, scolor, swidth) do latexstring,
                ts, al, rot, color, scolor, swidth

                te, gc, offs = texelems_and_glyph_collection(latexstring, ts,
                    al[1], al[2], rot, color, scolor, swidth)
                push!(tex_elements, te)
                push!(glyphcollections, gc)
                push!(offsets, offs)
            end
            tex_elements, glyphcollections, offsets
        else
            tex_elements, glyphcollection, offset = texelems_and_glyph_collection(latexstring, ts,
                al[1], al[2], rot, color, scolor, swidth)
        end
    end

    glyphcollection = @lift($lineels_glyphcollection_offset[2])


    linepairs = Node(Tuple{Point2f0, Point2f0}[])
    linewidths = Node(Float32[])

    scene = Makie.parent_scene(plot)

    onany(lineels_glyphcollection_offset, scene.camera.projectionview) do (allels, gcs, offs), projview

        inv_projview = inv(projview)
        pos = plot.position[]
        ts = plot.textsize[]
        rot = plot.rotation[]

        ts = to_textsize(ts)
        rot = convert_attribute(rot, key"rotation"())

        empty!(linepairs.val)
        empty!(linewidths.val)

        # for the vector case, allels is a vector of vectors
        # so for broadcasting the single vector needs to be wrapped in Ref
        if gcs isa GlyphCollection
            allels = [allels]
        end
        broadcast_foreach(allels, offs, pos, ts, rot) do allels, offs, pos, ts, rot
            offset = Point2f0(pos)

            els = map(allels) do el
                el[1] isa VLine || el[1] isa HLine || return nothing

                t = el[1].thickness * ts
                p = el[2]

                ps = if el[1] isa VLine
                    h = el[1].height
                    (Point2f0(p[1], p[2]) .* ts, Point2f0(p[1], p[2] + h) .* ts) .- Ref(offs)
                else
                    w = el[1].width
                    (Point2f0(p[1], p[2]) .* ts, Point2f0(p[1] + w, p[2]) .* ts) .- Ref(offs)
                end
                ps = Ref(rot) .* to_ndim.(Point3f0, ps, 0)
                # TODO the points need to be projected to work inside Axis
                # ps = project ps with projview somehow

                ps = Point2f0.(ps) .+ Ref(offset)
                ps, t
            end
            pairs = filter(!isnothing, els)
            append!(linewidths.val, repeat(last.(pairs), inner = 2))
            append!(linepairs.val, first.(pairs))
        end
        notify(linepairs)
    end

    notify(plot.position)

    text!(plot, glyphcollection; plot.attributes...)
    linesegments!(plot, linepairs, linewidth = linewidths, color = plot.color)

    plot
end

function texelems_and_glyph_collection(str::LaTeXString, fontscale_px, halign, valign,
        rotation, color, strokecolor, strokewidth)

    rot = convert_attribute(rotation, key"rotation"())

    all_els = generate_tex_elements(str.s[2:end-1])
    els = filter(x -> x[1] isa TeXChar, all_els)

    # hacky, but attr per char needs to be fixed
    fs = Vec2f0(first(fontscale_px))

    scales_2d = [Vec2f0(x[3] * Vec2f0(fs)) for x in els]

    chars = [x[1].char for x in els]
    fonts = [x[1].font for x in els]

    extents = [FreeTypeAbstraction.get_extent(f, c) for (f, c) in zip(fonts, chars)]

    bboxes = map(extents, fonts, scales_2d) do ext, font, scale
        unscaled_hi_bb = FreeTypeAbstraction.height_insensitive_boundingbox(ext, font)
        return FRect2D(
            origin(unscaled_hi_bb) * scale,
            widths(unscaled_hi_bb) * scale
        )
    end

    basepositions = [to_ndim(Vec3f0, fs, 0) .* to_ndim(Point3f0, x[2], 0)
        for x in els]

    bb = isempty(bboxes) ? BBox(0, 0, 0, 0) : begin
        mapreduce(union, zip(bboxes, basepositions)) do (b, pos)
            FRect2D(FRect3D(b) + pos)
        end
    end

    xshift = if halign == :center
        width(bb) / 2
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

    positions = basepositions .- Ref(Point3f0(xshift, yshift, 0))
    positions .= Ref(rot) .* positions

    pre_align_gl = GlyphCollection(
        chars,
        fonts,
        Point3f0.(positions),
        extents,
        scales_2d,
        rot,
        color,
        strokecolor,
        strokewidth,
    )

    all_els, pre_align_gl, Point2f0(xshift, yshift)
end

MakieLayout.iswhitespace(l::LaTeXString) = MakieLayout.iswhitespace(l.s[2:end-1])
