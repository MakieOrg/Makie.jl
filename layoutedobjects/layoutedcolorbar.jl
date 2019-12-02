function LayoutedColorbar(parent::Scene, plot::AbstractPlot; kwargs...)

    LayoutedColorbar(parent;
        colormap = plot.colormap,
        limits = plot.colorrange,
        kwargs...
    )

end

function LayoutedColorbar(parent::Scene; kwargs...)
    attrs = merge!(Attributes(kwargs), default_attributes(LayoutedColorbar))

    @extract attrs (
        label, labelcolor, labelsize, labelvisible, labelpadding, ticklabelsize,
        ticklabelspace,
        ticklabelsvisible, ticksize, ticksvisible, ticklabelpad, tickalign,
        tickwidth, tickcolor, spinewidth, idealtickdistance, topspinevisible,
        rightspinevisible, leftspinevisible, bottomspinevisible, topspinecolor,
        leftspinecolor, rightspinecolor, bottomspinecolor, colormap, limits,
        alignment, vertical, flipaxisposition, ticklabelalign, width, height)

    decorations = Dict{Symbol, Any}()

    bboxnode = Node(BBox(0, 100, 0, 100))

    scenearea = Node(IRect(0, 0, 100, 100))

    # here limits isn't really useful, maybe split up the functions for colorbar and axis
    connect_scenearea_and_bbox_colorbar!(scenearea, bboxnode, width, height, alignment)

    scene = Scene(parent, scenearea, camera = campixel!, raw = true)

    # # have one standard projection that always fits the mesh
    # on(scene.px_area) do pxarea
    #     pxarea = BBox(pxarea)
    #     projection = AbstractPlotting.orthographicprojection(
    #         0f0, pxarea.widths[1], 0f0, pxarea.widths[2], -10000f0, 10000f0)
    #     camera(scene).projection[] = projection
    #     camera(scene).projectionview[] = projection
    # end

    framebox = lift(scene.px_area) do pxa
        BBox(0, pxa.widths[1], 0, pxa.widths[2])
    end

    vertices = Point3f0[(0, 0, 0), (0, 1, 0), (1, 1, 0), (1, 0, 0)]
    mesh = AbstractPlotting.GLNormalUVMesh(
        vertices = copy(vertices),
        faces = AbstractPlotting.GLTriangle[(1, 2, 3), (3, 4, 1)],
        texturecoordinates = AbstractPlotting.UV{Float32}[(0, 1), (0, 0), (0, 0), (0, 1)]
    )

    nsteps = 100

    colorlinepoints = lift(framebox) do fb
        fbw = fb.widths[1]
        fbh = fb.widths[2]

        if vertical[]
            [Point2f0(0.5f0 * fbw, y * fbh) for y in LinRange(0f0, 1f0, nsteps)]
        else
            [Point2f0(x * fbw, 0.5f0 * fbh) for x in LinRange(0f0, 1f0, nsteps)]
        end
    end

    cmap_node = lift(colormap) do cmap
        c = AbstractPlotting.to_colormap(cmap, nsteps)
    end

    linewidth = lift(framebox) do fb
        fbw = fb.widths[1]
        fbh = fb.widths[2]

        if vertical[]
            fbw
        else
            fbh
        end
    end

    lines!(scene, colorlinepoints, linewidth = linewidth, color = cmap_node, raw = true)

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
        limits = limits, ticklabelalign = ticklabelalign, label = label,
        labelpadding = labelpadding, labelvisible = labelvisible,
        ticklabelsize = ticklabelsize, ticklabelsvisible = ticklabelsvisible, ticksize = ticksize,
        ticksvisible = ticksvisible, ticklabelpad = ticklabelpad, tickalign = tickalign,
        tickwidth = tickwidth, tickcolor = tickcolor, spinewidth = spinewidth,
        idealtickdistance = idealtickdistance, ticklabelspace = ticklabelspace)
    decorations[:axis] = axis

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
        parent, scene, bboxnode, protrusions,
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


function connect_scenearea_and_bbox_colorbar!(scenearea, bboxnode, widthnode, heightnode, alignment)
    onany(bboxnode, widthnode, heightnode, alignment) do bbox, widthnode, heightnode, alignment

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


function tight_ticklabel_spacing!(lc::LayoutedColorbar)
    tight_ticklabel_spacing!(lc.decorations[:axis])
end
