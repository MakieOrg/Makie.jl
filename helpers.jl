"""
Shorthand for `isnothing(optional) ? fallback : optional`
"""
@inline ifnothing(optional, fallback) = isnothing(optional) ? fallback : optional

IRect2D_rounded(r::Rect{2}) = Rect{2, Int}(round.(Int, r.origin), round.(Int, r.widths))

function sceneareanode!(finalbbox, limits, aspect)

    scenearea = Node(IRect(0, 0, 100, 100))

    onany(finalbbox, limits, aspect) do bbox, limits, aspect

        w = width(bbox)
        h = height(bbox)
        # mw = min(w, maxsize[1])
        # mh = min(h, maxsize[2])
        # as = mw / mh
        as = w / h
        mw, mh = w, h


        if aspect isa AxisAspect
            aspect = aspect.aspect
        elseif aspect isa DataAspect
            aspect = limits.widths[1] / limits.widths[2]
        end

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

        # l = left(bbox) + alignment[1] * restw
        # b = bottom(bbox) + alignment[2] * resth
        l = left(bbox) + 0.5f0 * restw
        b = bottom(bbox) + 0.5f0 * resth

        newbbox = BBox(l, l + mw, b, b + mh)

        # only update scene if pixel positions change
        new_scenearea = IRect2D_rounded(newbbox)
        if new_scenearea != scenearea[]
            scenearea[] = new_scenearea
        end
    end

    scenearea
end


function create_suggested_bboxnode(n::Nothing)
    Node(BBox(0, 100, 0, 100))
end

function create_suggested_bboxnode(tup::Tuple)
    Node(BBox(tup...))
end

function create_suggested_bboxnode(bbox::AbstractPlotting.Rect2D)
    Node(FRect2D(bbox))
end

function create_suggested_bboxnode(node::Node{FRect2D})
    node
end


function roundedrectvertices(rect, cornerradius, cornersegments)
    cr = cornerradius
    csegs = cornersegments

    cr = min(width(rect) / 2, height(rect) / 2, cr)

    # inner corners
    ictl = topleft(rect) .+ Point2(cr, -cr)
    ictr = topright(rect) .+ Point2(-cr, -cr)
    icbl = bottomleft(rect) .+ Point2(cr, cr)
    icbr = bottomright(rect) .+ Point2(-cr, cr)

    # check if corners touch so we can remove one vertex that is doubled
    wtouching = width(rect) / 2 == cr
    htouching = height(rect) / 2 == cr

    cstr = if wtouching
        anglepoint.(Ref(ictr), LinRange(0, pi/2, csegs), cr)
    else
        anglepoint.(Ref(ictr), LinRange(0, pi/2, csegs)[1:end-1], cr)
    end
    cstl = if htouching
        anglepoint.(Ref(ictl), LinRange(pi/2, pi, csegs), cr)
    else
        anglepoint.(Ref(ictl), LinRange(pi/2, pi, csegs)[1:end-1], cr)
    end
    csbl = if wtouching
        anglepoint.(Ref(icbl), LinRange(pi, 3pi/2, csegs), cr)
    else
        anglepoint.(Ref(icbl), LinRange(pi, 3pi/2, csegs)[1:end-1], cr)
    end
    csbr = if htouching
        anglepoint.(Ref(icbr), LinRange(3pi/2, 2pi, csegs), cr)
    else
        anglepoint.(Ref(icbr), LinRange(3pi/2, 2pi, csegs)[1:end-1], cr)
    end
    arr = [cstr; cstl; csbl; csbr]
end

function anglepoint(center::Point2, angle::Real, radius::Real)
    Ref(center) .+ Ref(Point2(cos(angle), sin(angle))) .* radius
end


function enlarge(bbox::FRect2D, l, r, b, t)
    BBox(left(bbox) - l, right(bbox) + r, bottom(bbox) - b, top(bbox) + t)
end

function center(bbox::FRect2D)
    Point2f0((right(bbox) + left(bbox)) / 2, (top(bbox) + bottom(bbox)) / 2)
end

"""
Converts a point in fractions of rect dimensions into real coordinates.
"""
function fractionpoint(bbox::FRect2D, point::T) where T <: Point2
    T(left(bbox) + point[1] * width(bbox), bottom(bbox) + point[2] * height(bbox))
end


function tightlimits!(la::LAxis)
    la.xautolimitmargin = (0, 0)
    la.yautolimitmargin = (0, 0)
    autolimits!(la)
end

function tightlimits!(la::LAxis, sides::Union{Left, Right, Bottom, Top}...)
    for s in sides
        tightlimits!(la, s)
    end
end

function tightlimits!(la::LAxis, ::Left)
    la.xautolimitmargin = Base.setindex(la.xautolimitmargin[], 0.0, 1)
    autolimits!(la)
end

function tightlimits!(la::LAxis, ::Right)
    la.xautolimitmargin = Base.setindex(la.xautolimitmargin[], 0.0, 2)
    autolimits!(la)
end

function tightlimits!(la::LAxis, ::Bottom)
    la.yautolimitmargin = Base.setindex(la.yautolimitmargin[], 0.0, 1)
    autolimits!(la)
end

function tightlimits!(la::LAxis, ::Top)
    la.yautolimitmargin = Base.setindex(la.yautolimitmargin[], 0.0, 2)
    autolimits!(la)
end


"""
    layoutscene(padding = 30; kwargs...)

Create a `Scene` in `campixel!` mode and a `GridLayout` aligned to the scene's pixel area with `alignmode = Outside(padding)`.
"""
function layoutscene(padding = 30; kwargs...)
    scene = Scene(; camera = campixel!, kwargs...)
    gl = GridLayout(scene, alignmode = Outside(padding))
    scene, gl
end

"""
    layoutscene(nrows::Int, ncols::Int, padding = 30; kwargs...)

Create a `Scene` in `campixel!` mode and a `GridLayout` aligned to the scene's pixel area with size `nrows` x `ncols` and `alignmode = Outside(padding)`.
"""
function layoutscene(nrows::Int, ncols::Int, padding = 30; kwargs...)
    scene = Scene(; camera = campixel!, kwargs...)
    gl = GridLayout(scene, nrows, ncols, alignmode = Outside(padding))
    scene, gl
end


GridLayoutBase.GridLayout(scene::Scene, args...; kwargs...) = GridLayout(args...; bbox = lift(x -> FRect2D(x), pixelarea(scene)), kwargs...)


bottomleft(bbox::Rect2D{T}) where T = Point2{T}(left(bbox), bottom(bbox))
topleft(bbox::Rect2D{T}) where T = Point2{T}(left(bbox), top(bbox))
bottomright(bbox::Rect2D{T}) where T = Point2{T}(right(bbox), bottom(bbox))
topright(bbox::Rect2D{T}) where T = Point2{T}(right(bbox), top(bbox))

topline(bbox::FRect2D) = (topleft(bbox), topright(bbox))
bottomline(bbox::FRect2D) = (bottomleft(bbox), bottomright(bbox))
leftline(bbox::FRect2D) = (bottomleft(bbox), topleft(bbox))
rightline(bbox::FRect2D) = (bottomright(bbox), topright(bbox))



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
