"""
Shorthand for `isnothing(optional) ? fallback : optional`
"""
@inline ifnothing(optional, fallback) = isnothing(optional) ? fallback : optional

function alignedbboxnode!(
    suggestedbbox::Node{BBox},
    computedsize::Node{NTuple{2, Optional{Float32}}},
    alignment::Node,
    sizeattrs::Node,
    autosizenode::Node{NTuple{2, Optional{Float32}}})

    finalbbox = Node(BBox(0, 100, 0, 100))

    onany(suggestedbbox, alignment, computedsize) do sbbox, al, csize

        bw = width(sbbox)
        bh = height(sbbox)

        # we only passively retrieve sizeattrs here because if they change
        # they also trigger computedsize, which triggers this node, too
        # we only need to know here if there are relative sizes given, because
        # those can only be computed knowing the suggestedbbox
        widthattr, heightattr = sizeattrs[]

        cwidth, cheight = csize

        w = if isnothing(cwidth)
            @match widthattr begin
                wa::Relative => wa.x * bw
                wa::Nothing => bw
                wa::Auto => if isnothing(autosizenode[][1])
                        # we have no autowidth available anyway
                        # take suggested width
                        bw
                    else
                        # use the width that was auto-computed
                        autosizenode[][1]
                    end
                wa => error("At this point, if computed width is not known,
                widthattr should be a Relative or Nothing, not $wa.")
            end
        else
            cwidth
        end

        h = if isnothing(cheight)
            @match heightattr begin
                ha::Relative => ha.x * bh
                ha::Nothing => bh
                ha::Auto => if isnothing(autosizenode[][2])
                        # we have no autoheight available anyway
                        # take suggested height
                        bh
                    else
                        # use the height that was auto-computed
                        autosizenode[][2]
                    end
                ha => error("At this point, if computed height is not known,
                heightattr should be a Relative or Nothing, not $ha.")
            end
        else
            cheight
        end

        # how much space is left in the bounding box
        rw = bw - w
        rh = bh - h

        xshift = @match al[1] begin
            :left => 0.0f0
            :center => 0.5f0 * rw
            :right => rw
            x::Real => x * rw
            x => error("Invalid horizontal alignment $x (only Real or :left, :center, or :right allowed).")
        end

        yshift = @match al[2] begin
            :bottom => 0.0f0
            :center => 0.5f0 * rh
            :top => rh
            x::Real => x * rh
            x => error("Invalid vertical alignment $x (only Real or :bottom, :center, or :top allowed).")
        end

        # align the final bounding box in the layout bounding box
        l = left(sbbox) + xshift
        b = bottom(sbbox) + yshift
        r = l + w
        t = b + h

        newbbox = BBox(l, r, b, t)
        # if finalbbox[] != newbbox
        #     finalbbox[] = newbbox
        # end
        finalbbox[] = newbbox
    end

    finalbbox
end

function computedsizenode!(sizeattrs, autosizenode::Node{NTuple{2, Optional{Float32}}})

    # set up csizenode with correct type manually
    csizenode = Node{NTuple{2, Optional{Float32}}}((nothing, nothing))

    onany(sizeattrs, autosizenode) do sizeattrs, autosize

        wattr, hattr = sizeattrs
        wauto, hauto = autosize

        wsize = computed_size(wattr, wauto)
        hsize = computed_size(hattr, hauto)

        csizenode[] = (wsize, hsize)
    end

    # trigger first value
    sizeattrs[] = sizeattrs[]

    csizenode
end

# function computedsizenode!(sizeattrs)
#
#     # set up csizenode with correct type manually
#     csizenode = Node{NTuple{2, Optional{Float32}}}((nothing, nothing))
#
#     onany(sizeattrs) do sizeattrs
#
#         wattr, hattr = sizeattrs
#
#         wsize = computed_size(wattr)
#         hsize = computed_size(hattr)
#
#         csizenode[] = (wsize, hsize)
#     end
#
#     # trigger first value
#     sizeattrs[] = sizeattrs[]
#
#     csizenode
# end

function computed_size(sizeattr, autosize)
    ms = @match sizeattr begin
        sa::Nothing => nothing
        sa::Real => sa
        sa::Fixed => sa.x
        sa::Relative => nothing
        sa::Auto => if sa.trydetermine
                # if trydetermine we report the autosize to the layout
                autosize
            else
                # but not if it's false, this allows for single span content
                # not to shrink its column or row, like a small legend next to an
                # axis or a super title over a single axis
                nothing
            end
        sa => error("""
            Invalid size attribute $sizeattr.
            Can only be Nothing, Fixed, Relative, Auto or Real""")
    end
end

# function computed_size(sizeattr)
#     ms = @match sizeattr begin
#         sa::Nothing => nothing
#         sa::Real => sa
#         sa::Fixed => sa.x
#         sa::Relative => nothing
#         sa => error("""
#             Invalid size attribute $sizeattr.
#             Can only be Nothing, Fixed, Relative or Real""")
#     end
# end

function sizenode!(widthattr::Node, heightattr::Node)
    sizeattrs = Node{Tuple{Any, Any}}((widthattr[], heightattr[]))
    onany(widthattr, heightattr) do w, h
        sizeattrs[] = (w, h)
    end
    sizeattrs
end

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
        new_scenearea = IRect2D(newbbox)
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
    Node(BBox(bbox))
end

function create_suggested_bboxnode(node::Node{BBox})
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


function enlarge(bbox::BBox, l, r, b, t)
    BBox(left(bbox) - l, right(bbox) + r, bottom(bbox) - b, top(bbox) + t)
end

function center(bbox::BBox)
    Point2f0((right(bbox) + left(bbox)) / 2, (top(bbox) + bottom(bbox)) / 2)
end

"""
Converts a point in fractions of rect dimensions into real coordinates.
"""
function fractionpoint(bbox::BBox, point::T) where T <: Point2
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

function Base.foreach(f::Function, contenttype::Type, layout::GridLayout; recursive = true)
    for c in layout.content
        if recursive && c.al isa GridLayout
            foreach(f, contenttype, c.al)
        elseif c.al isa contenttype
            f(c.al)
        end
    end
end
