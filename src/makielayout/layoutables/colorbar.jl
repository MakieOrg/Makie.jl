function layoutable(::Type{<:Colorbar}, fig_or_scene, plot::AbstractPlot; kwargs...)

    layoutable(Colorbar, fig_or_scene;
        colormap = plot.colormap,
        limits = plot.colorrange,
        kwargs...
    )

end

function layoutable(::Type{<:Colorbar}, fig_or_scene, heatmap::Union{Heatmap, Image}; kwargs...)

    layoutable(Colorbar, fig_or_scene;
        colormap = heatmap.colormap,
        limits = heatmap.colorrange,
        highclip = heatmap.highclip,
        lowclip = heatmap.lowclip,
        kwargs...
    )
end

function layoutable(::Type{<:Colorbar}, fig_or_scene, plot::AbstractPlotting.Contourf; kwargs...)

    steps = plot._computed_levels

    limits = lift(steps) do steps
        steps[1], steps[end]
    end

    layoutable(Colorbar, fig_or_scene;
        colormap = plot._computed_colormap,
        limits = limits,
        lowclip = plot._computed_extendlow,
        highclip = plot._computed_extendhigh,
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
        nsteps, highclip, lowclip)

    decorations = Dict{Symbol, Any}()

    protrusions = Node(GridLayoutBase.RectSides{Float32}(0, 0, 0, 0))
    layoutobservables = LayoutObservables{Colorbar}(attrs.width, attrs.height, attrs.tellwidth, attrs.tellheight,
        halign, valign, attrs.alignmode; suggestedbbox = bbox, protrusions = protrusions)

    framebox = @lift(round_to_IRect2D($(layoutobservables.computedbbox)))

    highclip_tri_visible = lift(x -> !(isnothing(x) || to_color(x) == to_color(:transparent)), highclip)
    lowclip_tri_visible = lift(x -> !(isnothing(x) || to_color(x) == to_color(:transparent)), lowclip)

    tri_heights = lift(highclip_tri_visible, lowclip_tri_visible, framebox) do hv, lv, box
        if vertical[]
            (lv * width(box), hv * width(box))
        else
            (lv * height(box), hv * height(box))
        end .* sin(pi/3)
    end

    barsize = lift(tri_heights) do heights
        if vertical[]
            max(1, height(framebox[]) - sum(heights))
        else
            max(1, width(framebox[]) - sum(heights))
        end
    end

    barbox = lift(barsize) do sz
        fbox = framebox[]
        if vertical[]
            BBox(left(fbox), right(fbox), bottom(fbox) + tri_heights[][1], top(fbox) - tri_heights[][2])
        else
            BBox(left(fbox) + tri_heights[][1], right(fbox) - tri_heights[][2], bottom(fbox), top(fbox))
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

    rects_and_colors = lift(barbox, vertical, steps, cgradient) do bbox, v, steps, gradient
        xmin, ymin = minimum(bbox)
        xmax, ymax = maximum(bbox)

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

    highclip_tri = lift(barbox, spinewidth) do box, spinewidth
        if vertical[]
            lb, rb = topline(box)
            l = lb
            r = rb
            t = ((l .+ r) ./ 2) .+ Point2f0(0, sqrt(sum((r .- l) .^ 2)) * sin(pi/3))
            [l, r, t]
        else
            b, t = rightline(box)
            r = ((b .+ t) ./ 2) .+ Point2f0(sqrt(sum((t .- b) .^ 2)) * sin(pi/3), 0)
            [t, b, r]
        end
    end

    highclip_tri_color = Observables.map(highclip) do hc
        to_color(isnothing(hc) ? :transparent : hc)
    end

    highclip_visible = lift(x -> !(isnothing(x) || to_color(x) == to_color(:transparent)), highclip)

    highclip_tri_poly = poly!(topscene, highclip_tri, color = highclip_tri_color,
        strokecolor = :transparent,
        visible = highclip_visible)

    decorations[:highclip] = highclip_tri_poly


    lowclip_tri = lift(barbox, spinewidth) do box, spinewidth
        if vertical[]
            lb, rb = bottomline(box)
            l = lb
            r = rb
            t = ((l .+ r) ./ 2) .- Point2f0(0, sqrt(sum((r .- l) .^ 2)) * sin(pi/3))
            [l, r, t]
        else
            b, t = leftline(box)
            l = ((b .+ t) ./ 2) .- Point2f0(sqrt(sum((t .- b) .^ 2)) * sin(pi/3), 0)
            [b, t, l]
        end
    end

    lowclip_tri_color = Observables.map(lowclip) do lc
        to_color(isnothing(lc) ? :transparent : lc)
    end

    lowclip_visible = lift(x -> !(isnothing(x) || to_color(x) == to_color(:transparent)), lowclip)

    lowclip_tri_poly = poly!(topscene, lowclip_tri, color = lowclip_tri_color,
        strokecolor = :transparent,
        visible = lowclip_visible)

    decorations[:lowclip] = lowclip_tri_poly


    borderpoints = lift(barbox, highclip_visible, lowclip_visible) do bb, hcv, lcv
        if vertical[]
            points = [bottomright(bb), topright(bb)]
            if hcv
                push!(points, highclip_tri[][3])
            end
            append!(points, [topleft(bb), bottomleft(bb)])
            if lcv
                push!(points, lowclip_tri[][3])
            end
            push!(points, bottomright(bb))
            points
        else
            points = [bottomleft(bb), bottomright(bb)]
            if hcv
                push!(points, highclip_tri[][3])
            end
            append!(points, [topright(bb), topleft(bb)])
            if lcv
                push!(points, lowclip_tri[][3])
            end
            push!(points, bottomleft(bb))
            points
        end
    end

    decorations[:spines] = lines!(topscene, borderpoints, linewidth = spinewidth, color = topspinecolor)

    axispoints = lift(barbox, vertical, flipaxisposition) do scenearea,
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
