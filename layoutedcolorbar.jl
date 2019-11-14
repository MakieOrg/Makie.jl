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

    bboxnode = Node(BBox(0, 100, 100, 0))

    scenearea = Node(IRect(0, 0, 100, 100))

    connect_scenearea_and_bbox!(scenearea, bboxnode, aspect, alignment, maxsize)

    limits = Node((0.0f0, 1.0f0))

    scene = Scene(parent, scenearea, raw = true)

    axislines!(
        parent, scene.px_area, spinewidth, topspinevisible, rightspinevisible,
        leftspinevisible, bottomspinevisible, topspinecolor, leftspinecolor,
        rightspinecolor, bottomspinecolor)

    campixel!(scene)

    protrusions = Node((0f0, 0f0, 0f0, 0f0))

    needs_update = Node(false)

    on(protrusions) do p
        needs_update[] = true
    end

    LayoutedColorbar(
        parent, scene, bboxnode, limits, protrusions,
        needs_update, attrs)
end
