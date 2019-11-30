function LayoutedColorbar(parent::Scene; kwargs...)
    attrs = merge!(Attributes(kwargs), default_attributes(LayoutedColorbar))

    @extract attrs (
        label, title, titlefont, titlesize, titlegap, titlevisible, titlealign,
        labelcolor, labelsize, labelvisible, labelpadding, ticklabelsize,
        ticklabelsvisible, ticksize, ticksvisible, ticklabelpad, tickalign,
        tickwidth, tickcolor, spinewidth, idealtickdistance, topspinevisible,
        rightspinevisible, leftspinevisible, bottomspinevisible, topspinecolor,
        leftspinecolor, rightspinecolor, bottomspinecolor,
        aspect, alignment, maxsize, vertical, flipaxisposition, ticklabelalign)

    decorations = Dict{Symbol, Any}()

    bboxnode = Node(BBox(0, 100, 0, 100))

    scenearea = Node(IRect(0, 0, 100, 100))

    limits = Node((0.0f0, 1.0f0))

    # here limits isn't really useful, maybe split up the functions for colorbar and axis
    connect_scenearea_and_bbox!(scenearea, bboxnode, limits, aspect, alignment, maxsize)


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

function align_to_bbox!(lc::LayoutedColorbar, bbox)
    lc.bboxnode[] = bbox
end
