function LayoutedColorbar(parent::Scene; kwargs...)
    attrs = merge!(default_attributes(LayoutedColorbar), Attributes(kwargs))

    @extract attrs (
        label, title, titlefont, titlesize, titlegap, titlevisible, titlealign,
        labelcolor, labelsize, labelvisible, labelpadding, ticklabelsize,
        ticklabelsvisible, ticksize, ticksvisible, ticklabelpad, tickalign,
        tickwidth, tickcolor, spinewidth, idealtickdistance, topspinevisible,
        rightspinevisible, leftspinevisible, bottomspinevisible, topspinecolor,
        leftspinecolor, rightspinecolor, bottomspinecolor,
        aspect, alignment, maxsize)

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

    LayoutedColorbar(
        parent, scene, bboxnode, limits, protrusions,
        needs_update, attrs)
end

defaultlayout(lc::LayoutedColorbar) = ProtrusionLayout(lc)

function align_to_bbox!(lc::LayoutedColorbar, bbox)
    lc.bboxnode[] = bbox
end
