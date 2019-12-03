@inline ifnothing(optional, fallback) = isnothing(optional) ? fallback : optional

function alignedbboxnode!(
    suggestedbbox,
    widthattr,
    heightattr,
    align)

    finalbbox = Node(BBox(0, 100, 0, 100))

    onany(suggestedbbox, widthattr, heightattr, align) do sbbox, wattr, hattr, al

        bw = width(sbbox)
        bh = height(sbbox)

        w = @match wattr begin
            wa::Nothing => bw
            wa::Real => wa
            wa::Fixed => wa.x
            wa::Relative => bw * wa.x
            wa => error("""
                Invalid width attribute $wattr.
                Can only be Nothing, Fixed, Relative or Real""")
        end
        h = @match hattr begin
            ha::Nothing => bh
            ha::Real => ha
            ha::Fixed => ha.x
            ha::Relative => bh * ha.x
            ha => error("""
                Invalid height attribute $hattr.
                Can only be Nothing, Fixed, Relative or Real""")
        end

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
