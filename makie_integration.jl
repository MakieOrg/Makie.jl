function axislines!(scene, rect, spinewidth, topspinevisible, rightspinevisible,
    leftspinevisible, bottomspinevisible, topspinecolor, leftspinecolor,
    rightspinecolor, bottomspinecolor)

    bottomline = lift(rect, spinewidth) do r, sw
        y = r.origin[2] - 0.5f0 * sw
        p1 = Point2(r.origin[1] - sw, y)
        p2 = Point2(r.origin[1] + r.widths[1] + sw, y)
        [p1, p2]
    end

    leftline = lift(rect, spinewidth) do r, sw
        x = r.origin[1] - 0.5f0 * sw
        p1 = Point2(x, r.origin[2] - sw)
        p2 = Point2(x, r.origin[2] + r.widths[2] + sw)
        [p1, p2]
    end

    topline = lift(rect, spinewidth) do r, sw
        y = r.origin[2] + r.widths[2] + 0.5f0 * sw
        p1 = Point2(r.origin[1] - sw, y)
        p2 = Point2(r.origin[1] + r.widths[1] + sw, y)
        [p1, p2]
    end

    rightline = lift(rect, spinewidth) do r, sw
        x = r.origin[1] + r.widths[1] + 0.5f0 * sw
        p1 = Point2(x, r.origin[2] - sw)
        p2 = Point2(x, r.origin[2] + r.widths[2] + sw)
        [p1, p2]
    end

    lines!(scene, bottomline, linewidth = spinewidth, show_axis = false,
        visible = bottomspinevisible, color = bottomspinecolor)
    lines!(scene, leftline, linewidth = spinewidth, show_axis = false,
        visible = leftspinevisible, color = leftspinecolor)
    lines!(scene, rightline, linewidth = spinewidth, show_axis = false,
        visible = rightspinevisible, color = rightspinecolor)
    lines!(scene, topline, linewidth = spinewidth, show_axis = false,
        visible = topspinevisible, color = topspinecolor)
end


function interleave_vectors(vec1::Vector{T}, vec2::Vector{T}) where T
    n = length(vec1)
    @assert n == length(vec2)

    vec = Vector{T}(undef, 2 * n)
    for i in 1:n
        k = 2(i - 1)
        vec[k + 1] = vec1[i]
        vec[k + 2] = vec2[i]
    end
    vec
end

function connect_scenearea_and_bbox!(scenearea, bboxnode, aspect, alignment, maxsize)
    onany(bboxnode, aspect, alignment, maxsize) do bbox, aspect, alignment, maxsize

        w = width(bbox)
        h = height(bbox)
        mw = min(w, maxsize[1])
        mh = min(h, maxsize[2])
        as = mw / mh

        aspect = aspect.aspect
        if !isnothing(aspect)

            if as >= aspect
                # too wide
                mw *= aspect / as
            else
                # too high
                mh *= as / aspect
            end
        end

        restw = w - mw
        resth = h - mh

        l = left(bbox) + alignment[1] * restw
        b = bottom(bbox) + alignment[2] * resth

        newbbox = BBox(l, l + mw, b + mh, b)

        # only update scene if pixel positions change
        new_scenearea = IRect2D(newbbox)
        if new_scenearea != scenearea[]
            scenearea[] = new_scenearea
        end
    end
end


function applylayout(sg::SolvedGridLayout)
    for c in sg.content
        applylayout(c.al)
    end
end

function applylayout(sa::SolvedAxisLayout)
    # sa.axis.scene.px_area[] = IRect2D(sa.inner)
    sa.bboxnode[] = sa.bbox
end

function applylayout(sb::SolvedBoxLayout)
    sb.bboxnode[] = sb.bbox
end

function shrinkbymargin(rect, margin)
    IRect((rect.origin .+ margin), (rect.widths .- 2 .* margin))
end
