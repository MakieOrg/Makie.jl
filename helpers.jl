@inline ifnothing(optional, fallback) = isnothing(optional) ? fallback : optional

function alignedbboxnode!(
    layoutbbox,
    computedwidthnode::Node{Optional{Float32}},
    computedheightnode::Node{Optional{Float32}},
    align)

    finalbbox = Node(BBox(0, 100, 0, 100))

    onany(layoutbbox, computedwidthnode, computedheightnode, align) do lbbox, cwn, chn, al

        bw = width(lbbox)
        bh = height(lbbox)

        # the final width / height is either what the element computed itself or,
        # if these values are nothing, what the layout provided
        w = ifnothing(cwn, bw)
        h = ifnothing(chn, bh)

        # how much space is left in the bounding box
        rw = bw - w
        rh = bh - h

        xshift = @match al[1] begin
            :left => 0.0f0
            :center => 0.5f0 * rw
            :right => rw
            x => error("Invalid halign $x (only :left, :center, or :right allowed).")
        end

        yshift = @match al[2] begin
            :bottom => 0.0f0
            :center => 0.5f0 * rh
            :top => rh
            x => error("Invalid valign $x (only :bottom, :center, or :top allowed).")
        end

        # align the final bounding box in the layout bounding box
        l = left(lbbox) + xshift
        b = bottom(lbbox) + yshift
        r = l + w
        t = b + h

        newbbox = BBox(l, r, b, t)
        if finalbbox[] != newbbox
            finalbbox[] = newbbox
        end
    end

    finalbbox
end


function computedsizenode!(dim::Int, sizeattr)

    if dim < 1 || dim > 2
        error("Invalid dimension $dim, only 1 or 2 allowed.")
    end

    node = Node{Optional{Float32}}(nothing)

    on(sizeattr) do sizeattr
        ms = @match sizeattr begin
            sa::Nothing => nothing
            sa::Real => sa
            sa::Fixed => sa.x
            # sa::Relative => sa.x * bsize
            sa::Relative => nothing
            sa => error("""
                Invalid $(dim == 1 ? "width" : "height") attribute $sizeattr.
                Can only be Nothing, Fixed, Relative or Real""")
        end

        node[] = ms
    end

    # trigger first value
    sizeattr[] = sizeattr[]

    node
end
