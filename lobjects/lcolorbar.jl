function LColorbar(parent::Scene, plot::AbstractPlot; kwargs...)

    LColorbar(parent;
        colormap = plot.colormap,
        limits = plot.colorrange,
        kwargs...
    )

end

function LColorbar(parent::Scene; bbox = nothing, kwargs...)
    attrs = merge!(Attributes(kwargs), default_attributes(LColorbar, parent))

    @extract attrs (
        label, labelcolor, labelsize, labelvisible, labelpadding, ticklabelsize,
        ticklabelspace, labelfont, ticklabelfont,
        ticklabelsvisible, ticks, ticksize, ticksvisible, ticklabelpad, tickalign,
        tickwidth, tickcolor, spinewidth, topspinevisible,
        rightspinevisible, leftspinevisible, bottomspinevisible, topspinecolor,
        leftspinecolor, rightspinecolor, bottomspinecolor, colormap, limits,
        halign, valign, vertical, flipaxisposition, ticklabelalign, flip_vertical_label,
        nsteps)

    decorations = Dict{Symbol, Any}()

    layoutobservables = LayoutObservables(LColorbar, attrs.width, attrs.height,
        halign, valign; suggestedbbox = bbox)

    framebox = layoutobservables.computedbbox

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

    heatmap!(parent, xrange, yrange, colorcells, colormap = colormap, raw = true)

    axislines!(
        parent, framebox, spinewidth, topspinevisible, rightspinevisible,
        leftspinevisible, bottomspinevisible, topspinecolor, leftspinecolor,
        rightspinecolor, bottomspinecolor)

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

    axis = LineAxis(parent, endpoints = axispoints, flipped = flipaxisposition,
        limits = limits, ticklabelalign = ticklabelalign, label = label,
        labelpadding = labelpadding, labelvisible = labelvisible, labelsize = labelsize,
        labelfont = labelfont, ticklabelfont = ticklabelfont, ticks = ticks,
        ticklabelsize = ticklabelsize, ticklabelsvisible = ticklabelsvisible, ticksize = ticksize,
        ticksvisible = ticksvisible, ticklabelpad = ticklabelpad, tickalign = tickalign,
        tickwidth = tickwidth, tickcolor = tickcolor, spinewidth = spinewidth,
        ticklabelspace = ticklabelspace,
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

        layoutobservables.protrusions[] = GridLayoutBase.RectSides{Float32}(left, right, bottom, top)
    end

    # trigger protrusions with one of the attributes
    vertical[] = vertical[]

    # trigger bbox
    layoutobservables.suggestedbbox[] = layoutobservables.suggestedbbox[]

    LColorbar(parent, Scene(), layoutobservables, attrs, decorations)
end

function tight_ticklabel_spacing!(lc::LColorbar)
    tight_ticklabel_spacing!(lc.decorations[:axis])
end
