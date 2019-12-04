"""
Shorthand for `isnothing(optional) ? fallback : optional`
"""
@inline ifnothing(optional, fallback) = isnothing(optional) ? fallback : optional

function alignedbboxnode!(
    suggestedbbox::Node{BBox},
    computedsize::Node{NTuple{2, Optional{Float32}}},
    alignment::Node,
    sizeattrs::Node)

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
            x => error("Invalid horizontal alignment $x (only :left, :center, or :right allowed).")
        end

        yshift = @match al[2] begin
            :bottom => 0.0f0
            :center => 0.5f0 * rh
            :top => rh
            x => error("Invalid vertical alignment $x (only :bottom, :center, or :top allowed).")
        end

        # align the final bounding box in the layout bounding box
        l = left(sbbox) + xshift
        b = bottom(sbbox) + yshift
        r = l + w
        t = b + h

        newbbox = BBox(l, r, b, t)
        if finalbbox[] != newbbox
            finalbbox[] = newbbox
        end
    end

    finalbbox
end

function computedsizenode!(sizeattrs, autosizenode::Node{NTuple{2, Float32}})

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

function computedsizenode!(sizeattrs)

    # set up csizenode with correct type manually
    csizenode = Node{NTuple{2, Optional{Float32}}}((nothing, nothing))

    onany(sizeattrs) do sizeattrs

        wattr, hattr = sizeattrs

        wsize = computed_size(wattr)
        hsize = computed_size(hattr)

        csizenode[] = (wsize, hsize)
    end

    # trigger first value
    sizeattrs[] = sizeattrs[]

    csizenode
end

function computed_size(sizeattr, autosize)
    ms = @match sizeattr begin
        sa::Nothing => nothing
        sa::Real => sa
        sa::Fixed => sa.x
        sa::Relative => nothing
        sa::Auto => autosize
        sa => error("""
            Invalid size attribute $sizeattr.
            Can only be Nothing, Fixed, Relative, Auto or Real""")
    end
end

function computed_size(sizeattr)
    ms = @match sizeattr begin
        sa::Nothing => nothing
        sa::Real => sa
        sa::Fixed => sa.x
        sa::Relative => nothing
        sa => error("""
            Invalid size attribute $sizeattr.
            Can only be Nothing, Fixed, Relative or Real""")
    end
end

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
