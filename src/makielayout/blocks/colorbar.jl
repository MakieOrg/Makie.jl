function block_docs(::Type{Colorbar})
    """
    Create a colorbar that shows a continuous or categorical colormap with ticks
    chosen according to the colorrange.

    You can set colorrange and colormap manually, or pass a plot object as the second argument
    to copy its respective attributes.

    ## Constructors

    ```julia
    Colorbar(fig_or_scene; kwargs...)
    Colorbar(fig_or_scene, plot::AbstractPlot; kwargs...)
    Colorbar(fig_or_scene, heatmap::Union{Heatmap, Image}; kwargs...)
    Colorbar(fig_or_scene, contourf::Makie.Contourf; kwargs...)
    ```
    """
end


function Colorbar(fig_or_scene, plot::AbstractPlot; kwargs...)

    for key in (:colormap, :limits)
        if key in keys(kwargs)
            error("You should not pass the `$key` attribute to the colorbar when constructing it using an existing plot object. This attribute is copied from the plot object, and setting it from the colorbar will make the plot object and the colorbar go out of sync.")
        end
    end

    Colorbar(
        fig_or_scene;
        colormap = plot.colormap,
        limits = plot.colorrange,
        kwargs...
    )
end

function Colorbar(fig_or_scene, heatmap::Union{Heatmap, Image}; kwargs...)

    for key in (:colormap, :limits, :highclip, :lowclip)
        if key in keys(kwargs)
            error("You should not pass the `$key` attribute to the colorbar when constructing it using an existing plot object. This attribute is copied from the plot object, and setting it from the colorbar will make the plot object and the colorbar go out of sync.")
        end
    end

    Colorbar(
        fig_or_scene;
        colormap = heatmap.colormap,
        limits = heatmap.colorrange,
        highclip = heatmap.highclip,
        lowclip = heatmap.lowclip,
        kwargs...
    )
end

function Colorbar(fig_or_scene, contourf::Makie.Contourf; kwargs...)

    for key in (:colormap, :limits, :highclip, :lowclip)
        if key in keys(kwargs)
            error("You should not pass the `$key` attribute to the colorbar when constructing it using an existing plot object. This attribute is copied from the plot object, and setting it from the colorbar will make the plot object and the colorbar go out of sync.")
        end
    end

    steps = contourf._computed_levels

    limits = lift(steps) do steps
        steps[1], steps[end]
    end

    Colorbar(
        fig_or_scene;
        colormap = contourf._computed_colormap,
        limits = limits,
        lowclip = contourf._computed_extendlow,
        highclip = contourf._computed_extendhigh,
        kwargs...
    )

end


function initialize_block!(cb::Colorbar)
    blockscene = cb.blockscene
    limits = lift(cb.limits, cb.colorrange) do limits, colorrange
        if all(!isnothing, (limits, colorrange))
            error("Both colorrange + limits are set, please only set one, they're aliases. colorrange: $(colorrange), limits: $(limits)")
        end
        return something(limits, colorrange, (0, 1))
    end

    onany(cb.size, cb.vertical) do sz, vertical
        if vertical
            cb.layoutobservables.autosize[] = (sz, nothing)
        else
            cb.layoutobservables.autosize[] = (nothing, sz)
        end
    end

    framebox = @lift(round_to_IRect2D($(cb.layoutobservables.computedbbox)))

    highclip_tri_visible = lift(x -> !(x isa Automatic || to_color(x) == to_color(:transparent)), cb.highclip)
    lowclip_tri_visible = lift(x -> !(x isa Automatic || to_color(x) == to_color(:transparent)), cb.lowclip)

    tri_heights = lift(highclip_tri_visible, lowclip_tri_visible, framebox) do hv, lv, box
        if cb.vertical[]
            (lv * width(box), hv * width(box))
        else
            (lv * height(box), hv * height(box))
        end .* sin(pi/3)
    end

    barsize = lift(tri_heights) do heights
        if cb.vertical[]
            max(1, height(framebox[]) - sum(heights))
        else
            max(1, width(framebox[]) - sum(heights))
        end
    end

    barbox = lift(barsize) do sz
        fbox = framebox[]
        if cb.vertical[]
            BBox(left(fbox), right(fbox), bottom(fbox) + tri_heights[][1], top(fbox) - tri_heights[][2])
        else
            BBox(left(fbox) + tri_heights[][1], right(fbox) - tri_heights[][2], bottom(fbox), top(fbox))
        end
    end

    cgradient = Observable{PlotUtils.ColorGradient}()
    map!(cgradient, cb.colormap) do cmap
        if cmap isa PlotUtils.ColorGradient
            # if we have a colorgradient directly, we want to keep it intact
            # to enable correct categorical colormap behavior etc
            return cmap
        else
            # this is a bit weird, first convert to a vector of colors,
            # then use cgrad, but at least I can use `get` on that later
            converted = Makie.to_colormap(cmap)
            return cgrad(converted)
        end
    end

    map_is_categorical = lift(x -> x isa PlotUtils.CategoricalColorGradient, cgradient)

    steps = lift(cgradient, cb.nsteps) do cgradient, n
        s = if cgradient isa PlotUtils.CategoricalColorGradient
            cgradient.values
        else
            collect(LinRange(0, 1, n))
        end::Vector{Float64}
    end

    # it's hard to draw categorical and continous colormaps well
    # with the same primitives

    # therefore we make one interpolated image for continous
    # colormaps and number of polys for categorical colormaps
    # at the same time, then we just set one of them invisible
    # depending on the type of colormap
    # this should solve most white-line issues

    # for categorical colormaps we make a number of rectangle polys

    rects_and_colors = lift(barbox, cb.vertical, steps, cgradient, cb.scale, limits) do bbox, v, steps, gradient, scale, lims

        # we need to convert the 0 to 1 steps into rescaled 0 to 1 steps given the
        # colormap's `scale` attribute

        s_scaled = scaled_steps(steps, scale, lims)

        xmin, ymin = minimum(bbox)
        xmax, ymax = maximum(bbox)

        rects = if v
            yvals = s_scaled .* (ymax - ymin) .+ ymin
            [BBox(xmin, xmax, b, t)
                for (b, t) in zip(yvals[1:end-1], yvals[2:end])]
        else
            xvals = s_scaled .* (xmax - xmin) .+ xmin
            [BBox(l, r, ymin, ymax)
                for (l, r) in zip(xvals[1:end-1], xvals[2:end])]
        end

        colors = get.(Ref(gradient), (steps[1:end-1] .+ steps[2:end]) ./2)
        rects, colors
    end

    colors = lift(x -> getindex(x, 2), rects_and_colors)
    rects = poly!(blockscene,
        lift(x -> getindex(x, 1), rects_and_colors),
        color = colors,
        visible = map_is_categorical,
        inspectable = false
    )

    # for continous colormaps we sample a 1d image
    # to avoid white lines when rendering vector graphics

    continous_pixels = lift(cb.vertical, cb.nsteps, cgradient, limits, cb.scale) do v, n, grad, lims, scale

        s_steps = scaled_steps(LinRange(0, 1, n), scale, lims)
        px = get.(Ref(grad), s_steps)
        v ? reshape(px, 1, n) : reshape(px, n, 1)
    end

    cont_image = image!(blockscene,
        @lift(range(left($barbox), right($barbox), length = 2)),
        @lift(range(bottom($barbox), top($barbox), length = 2)),
        continous_pixels,
        visible = @lift(!$map_is_categorical),
        interpolate = true,
        inspectable = false
    )


    highclip_tri = lift(barbox, cb.spinewidth) do box, spinewidth
        if cb.vertical[]
            lb, rb = topline(box)
            l = lb
            r = rb
            t = ((l .+ r) ./ 2) .+ Point2f(0, sqrt(sum((r .- l) .^ 2)) * sin(pi/3))
            [l, r, t]
        else
            b, t = rightline(box)
            r = ((b .+ t) ./ 2) .+ Point2f(sqrt(sum((t .- b) .^ 2)) * sin(pi/3), 0)
            [t, b, r]
        end
    end

    highclip_tri_color = Observables.map(cb.highclip) do hc
        to_color(isnothing(hc) ? :transparent : hc)
    end

    highclip_visible = lift((x, cm) -> to_color(x) != cm[end], cb.highclip, cgradient)

    highclip_tri_poly = poly!(blockscene, highclip_tri, color = highclip_tri_color,
        strokecolor = :transparent,
        visible = highclip_visible, inspectable = false)



    lowclip_tri = lift(barbox, cb.spinewidth) do box, spinewidth
        if cb.vertical[]
            lb, rb = bottomline(box)
            l = lb
            r = rb
            t = ((l .+ r) ./ 2) .- Point2f(0, sqrt(sum((r .- l) .^ 2)) * sin(pi/3))
            [l, r, t]
        else
            b, t = leftline(box)
            l = ((b .+ t) ./ 2) .- Point2f(sqrt(sum((t .- b) .^ 2)) * sin(pi/3), 0)
            [b, t, l]
        end
    end

    lowclip_tri_color = Observables.map(cb.lowclip) do lc
        to_color(isnothing(lc) ? :transparent : lc)
    end

    lowclip_visible = lift((x, cm) -> to_color(x) != cm[1], cb.lowclip, cgradient)

    lowclip_tri_poly = poly!(blockscene, lowclip_tri, color = lowclip_tri_color,
        strokecolor = :transparent,
        visible = lowclip_visible, inspectable = false)



    borderpoints = lift(barbox, highclip_visible, lowclip_visible) do bb, hcv, lcv
        if cb.vertical[]
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

    lines!(blockscene, borderpoints, linewidth = cb.spinewidth, color = cb.topspinecolor, inspectable = false)

    axispoints = lift(barbox, cb.vertical, cb.flipaxis) do scenearea,
            vertical, flipaxis

        if vertical
            if flipaxis
                (bottomright(scenearea), topright(scenearea))
            else
                (bottomleft(scenearea), topleft(scenearea))
            end
        else
            if flipaxis
                (topleft(scenearea), topright(scenearea))
            else
                (bottomleft(scenearea), bottomright(scenearea))
            end
        end

    end

    axis = LineAxis(blockscene, endpoints = axispoints, flipped = cb.flipaxis,
        limits = limits, ticklabelalign = cb.ticklabelalign, label = cb.label,
        labelpadding = cb.labelpadding, labelvisible = cb.labelvisible, labelsize = cb.labelsize,
        labelcolor = cb.labelcolor,
        labelfont = cb.labelfont, ticklabelfont = cb.ticklabelfont, ticks = cb.ticks, tickformat = cb.tickformat,
        ticklabelsize = cb.ticklabelsize, ticklabelsvisible = cb.ticklabelsvisible, ticksize = cb.ticksize,
        ticksvisible = cb.ticksvisible, ticklabelpad = cb.ticklabelpad, tickalign = cb.tickalign,
        ticklabelrotation = cb.ticklabelrotation,
        tickwidth = cb.tickwidth, tickcolor = cb.tickcolor, spinewidth = cb.spinewidth,
        ticklabelspace = cb.ticklabelspace, ticklabelcolor = cb.ticklabelcolor,
        spinecolor = :transparent, spinevisible = :false, flip_vertical_label = cb.flip_vertical_label,
        minorticksvisible = cb.minorticksvisible, minortickalign = cb.minortickalign,
        minorticksize = cb.minorticksize, minortickwidth = cb.minortickwidth,
        minortickcolor = cb.minortickcolor, minorticks = cb.minorticks, scale = cb.scale)

    cb.axis = axis


    onany(axis.protrusion, cb.vertical, cb.flipaxis) do axprotrusion,
            vertical, flipaxis


        left, right, top, bottom = 0f0, 0f0, 0f0, 0f0

        if vertical
            if flipaxis
                right += axprotrusion
            else
                left += axprotrusion
            end
        else
            if flipaxis
                top += axprotrusion
            else
                bottom += axprotrusion
            end
        end

        cb.layoutobservables.protrusions[] = GridLayoutBase.RectSides{Float32}(left, right, bottom, top)
    end

    # trigger protrusions with one of the attributes
    notify(cb.vertical)

    # trigger bbox
    notify(cb.layoutobservables.suggestedbbox)

    return
end

"""
    space = tight_ticklabel_spacing!(cb::Colorbar)

Sets the space allocated for the ticklabels of the `Colorbar` to the minimum that is needed and returns that value.
"""
function tight_ticklabel_spacing!(cb::Colorbar)
    space = tight_ticklabel_spacing!(cb.axis)
    return space
end

function scaled_steps(steps, scale, lims)
    # first scale to limits so we can actually apply the scale to the values
    # (log(0) doesn't work etc.)
    s_limits = steps .* (lims[2] - lims[1]) .+ lims[1]
    # scale with scaling function
    s_limits_scaled = scale.(s_limits)
    # then rescale to 0 to 1
    s_scaled = (s_limits_scaled .- s_limits_scaled[1]) ./ (s_limits_scaled[end] - s_limits_scaled[1])
end
