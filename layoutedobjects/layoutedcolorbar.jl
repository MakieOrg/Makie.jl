function LayoutedColorbar(parent::Scene; kwargs...)
    attrs = merge!(Attributes(kwargs), default_attributes(LayoutedColorbar))

    @extract attrs (
        label, title, titlefont, titlesize, titlegap, titlevisible, titlealign,
        labelcolor, labelsize, labelvisible, labelpadding, ticklabelsize,
        ticklabelsvisible, ticksize, ticksvisible, ticklabelpad, tickalign,
        tickwidth, tickcolor, spinewidth, idealtickdistance, topspinevisible,
        rightspinevisible, leftspinevisible, bottomspinevisible, topspinecolor,
        leftspinecolor, rightspinecolor, bottomspinecolor,
        alignment, vertical, flipaxisposition, ticklabelalign, width, height)

    decorations = Dict{Symbol, Any}()

    bboxnode = Node(BBox(0, 100, 0, 100))

    scenearea = Node(IRect(0, 0, 100, 100))

    limits = Node((0.0f0, 1.0f0))

    # here limits isn't really useful, maybe split up the functions for colorbar and axis
    connect_scenearea_and_bbox_colorbar!(scenearea, bboxnode, limits, width, height, alignment)

    scene = Scene(parent, scenearea, raw = true)

    axislines!(
        parent, scene.px_area, spinewidth, topspinevisible, rightspinevisible,
        leftspinevisible, bottomspinevisible, topspinecolor, leftspinecolor,
        rightspinecolor, bottomspinecolor)

    campixel!(scene)

    protrusions = Node(RectSides{Float32}(0, 0, 0, 0))

    needs_update = Node(false)

    on(protrusions) do p
        needs_update[] = true
    end

    axispoints = lift(scenearea, vertical, flipaxisposition) do scenearea,
            vertical, flipaxisposition

        if vertical
            if flipaxisposition
                (bottomright(scenearea), topright(scenearea))
            else
                (bottomleft(scenearea), topleft(scenearea))
            end
        else
            if flipaxisposition
                (topleft(scenearea), topright(scenearea))
            else
                (bottomleft(scenearea), bottomright(scenearea))
            end
        end

    end

    axis = LineAxis(parent, endpoints = axispoints, flipped = flipaxisposition,
        ticklabelalign = ticklabelalign)

    protrusions = lift(axis.protrusion, vertical, flipaxisposition) do axprotrusion,
            vertical, flipaxisposition


        left, right, top, bottom = 0f0, 0f0, 0f0, 0f0

        if vertical
            if flipaxisposition
                right += axprotrusion
            else
                left += axprotrusion
            end
        else
            if flipaxisposition
                top += axprotrusion
            else
                bottom += axprotrusion
            end
        end

        RectSides{Float32}(left, right, bottom, top)
    end

    LayoutedColorbar(
        parent, scene, bboxnode, limits, protrusions,
        needs_update, attrs, decorations)
end

defaultlayout(lc::LayoutedColorbar) = ProtrusionLayout(lc)

function protrusionnode(lc::LayoutedColorbar)
    # work around the new optional protrusions
    node = Node{Union{Nothing, RectSides{Float32}}}(lc.protrusions[])
    on(lc.protrusions) do p
        node[] = p
    end
    node
end

function sizenodecontent(s)
    if s isa Union{Real, Fixed}
        s
    else
        nothing
    end
end

function widthnode(lc::LayoutedColorbar)
    node = Node{Union{Nothing, Float32}}(sizenodecontent(lc.attributes.width[]))
    on(lc.attributes.width) do w
        node[] = sizenodecontent(w)
    end
    node
end

function heightnode(lc::LayoutedColorbar)
    node = Node{Union{Nothing, Float32}}(sizenodecontent(lc.attributes.height[]))
    on(lc.attributes.height) do h
        node[] = sizenodecontent(h)
    end
    node
end

function align_to_bbox!(lc::LayoutedColorbar, bbox)
    lc.bboxnode[] = bbox
end


function connect_scenearea_and_bbox_colorbar!(scenearea, bboxnode, limits, widthnode, heightnode, alignment)
    onany(bboxnode, limits, widthnode, heightnode, alignment) do bbox, limits, widthnode, heightnode, alignment

        w = width(bbox)
        h = height(bbox)


        mw = if isnothing(widthnode)
            w
        elseif widthnode isa Real
            widthnode
        elseif widthnode isa Fixed
            widthnode.x
        elseif widthnode isa Relative
            widthnode.x * w
        else
            error("Invalid width $widthnode, can only be Fixed, Relative or Real")
        end

        mh = if isnothing(heightnode)
            h
        elseif heightnode isa Real
            heightnode
        elseif heightnode isa Fixed
            heightnode.x
        elseif heightnode isa Relative
            heightnode.x * h
        else
            error("Invalid height $heightnode, can only be Fixed, Relative or Real")
        end

        restw = w - mw
        resth = h - mh

        xalign = if alignment[1] == :left
            0
        elseif alignment[1] == :center
            0.5
        elseif alignment[1] == :right
            1
        else
            error("Invalid x alignment $(alignment[1])")
        end

        yalign = if alignment[2] == :bottom
            0
        elseif alignment[2] == :center
            0.5
        elseif alignment[2] == :top
            1
        else
            error("Invalid y alignment $(alignment[1])")
        end

        l = left(bbox) + xalign * restw
        b = bottom(bbox) + yalign * resth

        newbbox = BBox(l, l + mw, b, b + mh)

        # only update scene if pixel positions change
        new_scenearea = IRect2D(newbbox)
        if new_scenearea != scenearea[]
            scenearea[] = new_scenearea
        end
    end
end
