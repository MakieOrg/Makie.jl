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
        alignment, vertical, flipaxisposition, ticklabelalign)

    widthattr = attrs.width
    heightattr = attrs.height

    decorations = Dict{Symbol, Any}()

    suggestedbbox = Node(BBox(0, 100, 0, 100))

    computedwidth = computedsizenode!(1, widthattr)
    computedheight = computedsizenode!(2, heightattr)

    finalbbox = alignedbboxnode!(suggestedbbox, widthattr, heightattr, alignment)

    scenearea = lift(IRect2D, finalbbox)

    scene = Scene(parent, scenearea, camera = campixel!, raw = true)

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

    layoutnodes = LayoutNodes(suggestedbbox, protrusions, computedwidth, computedheight, finalbbox)

    LayoutedColorbar(parent, scene, layoutnodes, attrs, decorations)
end

defaultlayout(lc::LayoutedColorbar) = ProtrusionLayout(lc)

protrusionnode(lc::LayoutedColorbar) = lc.layoutnodes.protrusions
widthnode(lc::LayoutedColorbar) = lc.layoutnodes.computedwidth
heightnode(lc::LayoutedColorbar) = lc.layoutnodes.computedheight

function align_to_bbox!(lc::LayoutedColorbar, bbox)
    lc.layoutnodes.suggestedbbox[] = bbox
end

function tight_ticklabel_spacing!(lc::LayoutedColorbar)
    tight_ticklabel_spacing!(lc.decorations[:axis])
end
