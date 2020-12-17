function LColorbar(fig_or_scene, plot::AbstractPlot; kwargs...)

    LColorbar(fig_or_scene;
        colormap = plot.colormap,
        limits = plot.colorrange,
        kwargs...
    )

end

function LColorbar(fig_or_scene; bbox = nothing, kwargs...)
    topscene = get_topscene(fig_or_scene)
    attrs = merge!(Attributes(kwargs), default_attributes(LColorbar, topscene).attributes)

    default_attrs = default_attributes(LColorbar, topscene).attributes
    theme_attrs = subtheme(topscene, :LColorbar)
    attrs = merge!(merge!(Attributes(kwargs), theme_attrs), default_attrs)

    @extract attrs (
        label, labelcolor, labelsize, labelvisible, labelpadding, ticklabelsize,
        ticklabelspace, labelfont, ticklabelfont, ticklabelcolor,
        ticklabelsvisible, ticks, tickformat, ticksize, ticksvisible, ticklabelpad, tickalign,
        tickwidth, tickcolor, spinewidth, topspinevisible,
        rightspinevisible, leftspinevisible, bottomspinevisible, topspinecolor,
        leftspinecolor, rightspinecolor, bottomspinecolor, colormap, limits,
        halign, valign, vertical, flipaxisposition, ticklabelalign, flip_vertical_label,
        nsteps)

    decorations = Dict{Symbol, Any}()

    protrusions = Node(GridLayoutBase.RectSides{Float32}(0, 0, 0, 0))
    layoutobservables = LayoutObservables{LColorbar}(attrs.width, attrs.height, attrs.tellwidth, attrs.tellheight,
        halign, valign, attrs.alignmode; suggestedbbox = bbox, protrusions = protrusions)

    framebox = @lift(round_to_IRect2D($(layoutobservables.computedbbox)))

    colorlinepoints = lift(framebox, nsteps) do fb, nsteps
        fbw = fb.widths[1]
        fbh = fb.widths[2]

        if vertical[]
            [Point2f0(0.5f0 * fbw, y * fbh) for y in LinRange(0f0, 1f0, nsteps)]
        else
            [Point2f0(x * fbw, 0.5f0 * fbh) for x in LinRange(0f0, 1f0, nsteps)]
        end
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

    xrange = lift(framebox) do fb
        range(left(fb), right(fb), length = 2)
    end
    yrange = lift(framebox) do fb
        range(bottom(fb), top(fb), length = 2)
    end

    colorcells = lift(vertical, nsteps) do v, nsteps
        if v
            reshape(collect(1:nsteps), 1, :)
        else
            reshape(collect(1:nsteps), :, 1)
        end
    end

    hm = heatmap!(topscene, xrange, yrange, colorcells, colormap = colormap, raw = true)[end]
    decorations[:heatmap] = hm

    ab, al, ar, at = axislines!(
        topscene, framebox, spinewidth, topspinevisible, rightspinevisible,
        leftspinevisible, bottomspinevisible, topspinecolor, leftspinecolor,
        rightspinecolor, bottomspinecolor)
    decorations[:topspine] = at
    decorations[:leftspine] = al
    decorations[:rightspine] = ar
    decorations[:bottomspine] = ab

    axispoints = lift(framebox, vertical, flipaxisposition) do scenearea,
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

    axis = LineAxis(topscene, endpoints = axispoints, flipped = flipaxisposition,
        limits = limits, ticklabelalign = ticklabelalign, label = label,
        labelpadding = labelpadding, labelvisible = labelvisible, labelsize = labelsize,
        labelfont = labelfont, ticklabelfont = ticklabelfont, ticks = ticks, tickformat = tickformat,
        ticklabelsize = ticklabelsize, ticklabelsvisible = ticklabelsvisible, ticksize = ticksize,
        ticksvisible = ticksvisible, ticklabelpad = ticklabelpad, tickalign = tickalign,
        tickwidth = tickwidth, tickcolor = tickcolor, spinewidth = spinewidth,
        ticklabelspace = ticklabelspace, ticklabelcolor = ticklabelcolor,
        spinecolor = :transparent, spinevisible = :false, flip_vertical_label = flip_vertical_label)
    decorations[:axis] = axis

    onany(axis.protrusion, vertical, flipaxisposition) do axprotrusion,
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

        protrusions[] = GridLayoutBase.RectSides{Float32}(left, right, bottom, top)
    end

    # trigger protrusions with one of the attributes
    vertical[] = vertical[]

    # trigger bbox
    layoutobservables.suggestedbbox[] = layoutobservables.suggestedbbox[]

    LColorbar(fig_or_scene, layoutobservables, attrs, decorations)
end

function tight_ticklabel_spacing!(lc::LColorbar)
    tight_ticklabel_spacing!(lc.elements[:axis])
end
