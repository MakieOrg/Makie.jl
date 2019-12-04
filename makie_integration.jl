function axislines!(scene, rect, spinewidth, topspinevisible, rightspinevisible,
    leftspinevisible, bottomspinevisible, topspinecolor, leftspinecolor,
    rightspinecolor, bottomspinecolor)

    bottomline = lift(rect, spinewidth) do r, sw
        y = bottom(r) - 0.5f0 * sw
        p1 = Point2(left(r) - sw, y)
        p2 = Point2(right(r) + sw, y)
        [p1, p2]
    end

    leftline = lift(rect, spinewidth) do r, sw
        x = left(r) - 0.5f0 * sw
        p1 = Point2(x, bottom(r) - sw)
        p2 = Point2(x, top(r) + sw)
        [p1, p2]
    end

    topline = lift(rect, spinewidth) do r, sw
        y = top(r) + 0.5f0 * sw
        p1 = Point2(left(r) - sw, y)
        p2 = Point2(right(r) + sw, y)
        [p1, p2]
    end

    rightline = lift(rect, spinewidth) do r, sw
        x = right(r) + 0.5f0 * sw
        p1 = Point2(x, bottom(r) - sw)
        p2 = Point2(x, top(r) + sw)
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
    @inbounds for i in 1:n
        k = 2(i - 1)
        vec[k + 1] = vec1[i]
        vec[k + 2] = vec2[i]
    end
    vec
end


function applylayout(sg::SolvedGridLayout)
    for c in sg.content
        applylayout(c.al)
    end
end

function applylayout(sa::SolvedProtrusionLayout)
    align_to_bbox!(sa.content, sa.bbox)
end

function applylayout(spcl::SolvedProtrusionContentLayout)
    align_to_bbox!(spcl.content, spcl.bbox)
end

function shrinkbymargin(rect, margin)
    IRect((rect.origin .+ margin), (rect.widths .- 2 .* margin))
end

function limits(r::Rect{N, T}) where {N, T}
    ows = r.origin .+ r.widths
    ntuple(i -> (r.origin[i], ows[i]), N)
    # tuple(zip(r.origin, ows)...)
end

function limits(r::Rect{N, T}, dim::Int) where {N, T}
    o = r.origin[dim]
    w = r.widths[dim]
    (o, o + w)
end

xlimits(r::Rect{2}) = limits(r, 1)
ylimits(r::Rect{2}) = limits(r, 2)
