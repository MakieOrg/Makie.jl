struct MText{S,T}
    position::Observable{Point{S,T}}
    htext
end
function mtext!(ax, x, y; text, kwargs...)
    p = Observable(Point2f(x, y))
    return MText(p, text!(ax, p; text=text, kwargs...))
end
function mtext!(ax, x, y, z; text, kwargs...)
    p = Observable(Point3f(x, y, z))
    return MText(p, text!(ax, p; text=text, kwargs...))
end

function extents(mtexts)
    pdata = [mtext.position[] for mtext in mtexts]
    bbs = [rect2(boundingbox(mtext.htext)) for mtext in mtexts]
    ppixels = [bb.origin for bb in bbs]
    tform = AffineMap(ppixels => pdata)  # presumably this transformation can be computed from Makie's own internals?
    return bbs, tform
end

function reduce_overlap!(mtexts; itermax=100)
    rects, tform = extents(mtexts)
    rects = rect2.(rects)
    x = reduce(vcat, [r.origin for r in rects])
    x0 = copy(x)
    # The objective function we want to minimize: the sum of the overlap area across all pairs of labels,
    # plus a quadratic penalty on total displacement from the original positions.
    function overlapvol(x)
        xpos = [Vec{2}(x[i:i+1]...) for i in 1:2:length(x)]
        return overlapvolume([HyperRectangle(p, r.widths) for (p, r) in zip(xpos, rects)]) + sum(abs2, x - x0)
    end
    V = overlapvol(x)
    # Iterative gradient descent. We set the step length so that the maximum change of any label in any
    # cardinal direction is 1 pixel.
    iter = 0
    while iter < itermax
        g = ForwardDiff.gradient(overlapvol, x)  # TODO: manually compute the gradient so we don't depend on ForwardDiff
        all(iszero, g) && break
        dx = g / maximum(abs, g)   # move one pixel, max
        xnew = x - dx
        Vnew = overlapvol(xnew)
        Vnew > V && break
        V = Vnew
        x .= xnew
        iter += 1
    end
    # Set the new positions
    for (mtext, p) in zip(mtexts, [tform(Point2f(x[i:i+1]...)) for i in 1:2:length(x)])
        mtext.position[] = p
    end
    return mtexts
end


intervals(rect) = map(rect.origin, rect.widths) do o, w
    Interval(o, o + w)
end
overlapvolume(rect1::HyperRectangle, rect2::HyperRectangle) = prod(iv -> max(0, iv.right - iv.left), intersect.(intervals(rect1), intervals(rect2)))
function overlapvolume(rects::AbstractVector{HyperRectangle{N,T}}) where {N,T}
    V = zero(float(T))
    for i in eachindex(rects)
        for j in i+1:lastindex(rects)
            V += overlapvolume(rects[i], rects[j])
        end
    end
    return V
end

rect2(rect::HyperRectangle{2}) = rect
rect2(rect::HyperRectangle{3}) = HyperRectangle{2}(rect.origin[GeometryBasics.SOneTo(2)], rect.widths[GeometryBasics.SOneTo(2)])
