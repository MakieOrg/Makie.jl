function layoutable(::Type{<:Colorbar}, fig_or_scene, plot::AbstractPlot; kwargs...)

    layoutable(Colorbar, fig_or_scene;
        colormap = plot.colormap,
        limits = plot.colorrange,
        kwargs...
    )

end

function layoutable(::Type{<:Colorbar}, fig_or_scene, plot::AbstractPlotting.Contourf; kwargs...)

    steps = lift(plot._computed_levels) do lvls
        if lvls[1][2:end] != lvls[2][1:end-1]
            error("You can't make a colorbar for a contourf plot with non-adjacent levels")
        end
        push!(copy(lvls[1]), lvls[2][end])
    end

    limits = lift(steps) do steps
        steps[1], steps[end]
    end

    colormap = lift(steps, plot.colormap) do steps, colormap
        cgrad(colormap, (steps .- steps[1]) ./ (steps[end] - steps[1]), categorical = true)
    end

    layoutable(Colorbar, fig_or_scene;
        colormap = colormap,
        limits = limits,
        kwargs...
    )

end


function layoutable(::Type{<:Colorbar}, fig_or_scene; bbox = nothing, kwargs...)
    topscene = get_topscene(fig_or_scene)
    attrs = merge!(Attributes(kwargs), default_attributes(Colorbar, topscene).attributes)

    default_attrs = default_attributes(Colorbar, topscene).attributes
    theme_attrs = subtheme(topscene, :Colorbar)
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
    layoutobservables = LayoutObservables{Colorbar}(attrs.width, attrs.height, attrs.tellwidth, attrs.tellheight,
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


    cgradient = lift(colormap, typ = Any) do cmap
        if cmap isa Symbol
            cgrad(cmap)
        elseif cmap isa Tuple{Symbol, Number}
            cgrad(cmap[1], alpha = cmap[2])
        elseif cmap isa PlotUtils.ColorGradient
            cmap
        else
            error("Can't deal with colormap of type $(typeof(cmap))")
        end
    end

    steps = lift(cgradient, nsteps) do cgradient, n
        if cgradient isa PlotUtils.CategoricalColorGradient
            cgradient.values
        else
            collect(LinRange(0, 1, n))
        end::Vector{Float64}
    end

    rects_and_colors = lift(framebox, vertical, steps, cgradient) do fb, v, steps, gradient
        xmin, ymin = minimum(fb)
        xmax, ymax = maximum(fb)

        rects = if v
            yvals = steps .* (ymax - ymin) .+ ymin
            [BBox(xmin, xmax, b, t)
                for (b, t) in zip(yvals[1:end-1], yvals[2:end])]
        else
            xvals = steps .* (xmax - xmin) .+ xmin
            [BBox(l, r, ymin, ymax)
                for (l, r) in zip(xvals[1:end-1], xvals[2:end])]
        end

        colors = get.(Ref(gradient), (steps[1:end-1] .+ steps[2:end]) ./2)

        rects, colors
    end

    rects = poly!(topscene,
        lift(x -> getindex(x, 1), rects_and_colors),
        color = lift(x -> getindex(x, 2), rects_and_colors),
        show_axis = false)

    decorations[:colorrects] = rects

    # hm = heatmap!(topscene, xrange, yrange, colorcells, colormap = colormap, raw = true)
    # decorations[:heatmap] = hm

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
        labelcolor = labelcolor,
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

    Colorbar(fig_or_scene, layoutobservables, attrs, decorations)
end

function tight_ticklabel_spacing!(lc::Colorbar)
    tight_ticklabel_spacing!(lc.elements[:axis])
end
