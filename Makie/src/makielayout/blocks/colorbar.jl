function colorbar_check(keys, kwargs_keys)
    for key in keys
        if key in kwargs_keys
            error("You should not pass the `$key` attribute to the colorbar when constructing it using an existing plot object. This attribute is copied from the plot object, and setting it from the colorbar will make the plot object and the colorbar go out of sync.")
        end
    end
    return
end

function extract_colorrange(@nospecialize(plot::AbstractPlot))::Vec2{Float64}
    if haskey(plot, :calculated_colors) && plot.calculated_colors[] isa Makie.ColorMapping
        return plot.calculated_colors[].colorrange[]
    elseif haskey(plot, :colorrange) && !(plot.colorrange[] isa Makie.Automatic)
        return plot.colorrange[]
    else
        error("colorrange not found and calculated_colors for the plot is missing or is not a proper color map. Heatmaps and images should always contain calculated_colors[].colorrange")
    end
end


function extract_colormap(plot::Arrows2D)
    return ColorMapping(
        plot.color[], plot.color, plot.colormap, plot.scaled_colorrange,
        get(plot, :colorscale, Observable(identity)),
        get(plot, :alpha, Observable(1.0)),
        get(plot, :highclip, Observable(automatic)),
        get(plot, :lowclip, Observable(automatic)),
        get(plot, :nan_color, Observable(RGBAf(0, 0, 0, 0))),
    )
end

function extract_colormap(plot::Union{Arrows3D, StreamPlot})
    return extract_colormap(plot.plots[1])
end

function extract_colormap(@nospecialize(plot::AbstractPlot))
    has_colorrange = haskey(plot, :colorrange) && !(plot.colorrange[] isa Makie.Automatic)
    if haskey(plot, :calculated_colors) && plot.calculated_colors[] isa Makie.ColorMapping
        return plot.calculated_colors[]
    elseif has_colorrange && all(x -> haskey(plot, x), [:colormap, :colorrange, :color]) && plot.color[] isa AbstractVector{<:Colorant}
        return ColorMapping(
            plot.color[], plot.color, plot.colormap, plot.colorrange,
            get(plot, :colorscale, Observable(identity)),
            get(plot, :alpha, Observable(1.0)),
            get(plot, :highclip, Observable(automatic)),
            get(plot, :lowclip, Observable(automatic)),
            get(plot, :nan_color, Observable(RGBAf(0, 0, 0, 0))),
        )
    else
        return nothing
    end
end
extract_colormap(@nospecialize(plot::ComputePlots)) = get_colormapping(plot)

function extract_colormap(plot::Plot{volumeslices})
    return extract_colormap(plot.plots[1])
end

function extract_colormap(plot::Union{Contourf, Tricontourf})
    levels = ComputePipeline.get_observable!(plot.computed_levels)
    limits = lift(l -> (l[1], l[end]), levels)
    function extend_color(color, computed)
        color === nothing && return automatic
        color == :auto || color == automatic && return computed
        return computed
    end
    elow = lift(extend_color, plot.extendlow, plot.computed_lowcolor)
    ehigh = lift(extend_color, plot.extendhigh, plot.computed_highcolor)
    return ColorMapping(
        levels[], levels, plot.computed_colormap, limits,
        plot.colorscale, Observable(1.0), elow, ehigh, plot.nan_color
    )
end

function extract_colormap(plot::Contour{<:Tuple{X, Y, Z, Vol}}) where {X, Y, Z, Vol}
    levels = ComputePipeline.get_observable!(plot.value_levels)
    # Users may use transparency to make layered isosurfaces visible. Because
    # 3D contours often accumulate the color of an isosurface over multiple
    # samples one typically needs very low alpha values for this, which would
    # make the colors in the colormap very faint. To keep the Colorbar useful,
    # we remove user alpha here. (The recipe also uses `alpha = 0` to remove
    # samples outside of isosurfaces. This is preserved here)
    colormap = map(cm -> RGBAf.(Colors.color.(cm), Colors.alpha.(cm) .> 0.0f0), plot.computed_colormap)
    return ColorMapping(
        levels[], levels, colormap, plot.padded_colorrange, plot.colorscale,
        Observable(1.0), Observable(automatic), Observable(automatic), plot.nan_color
    )
end

function extract_colormap(plot::Voxels)
    limits = plot.value_limits
    # TODO: does this need padding for lowclip and highclip?
    discretized_values = map(lims -> range(lims[1], lims[2], length = 253), plot, limits)

    return ColorMapping(
        discretized_values[], discretized_values, plot.colormap, limits, plot.colorscale,
        plot.alpha, plot.lowclip, plot.highclip, Observable(:transparent)
    )
end


function extract_colormap_recursive(@nospecialize(plot::T)) where {T <: AbstractPlot}
    cmap = extract_colormap(plot)
    if !isnothing(cmap)
        return cmap
    else
        colormaps = [extract_colormap_recursive(child) for child in plot.plots]
        if length(colormaps) == 1
            return colormaps[1]
        elseif isempty(colormaps)
            return nothing
        else
            # Prefer ColorMapping if in doubt!
            cmaps = filter(x -> x isa ColorMapping, colormaps)
            length(cmaps) == 1 && return cmaps[1]
            error("Multiple colormaps found for plot $(plot), please specify which one to use manually. Please overload `Makie.extract_colormap(::$(T))` to allow for the automatic creation of a Colorbar.")
        end
    end
end

function Colorbar(fig_or_scene, plot::AbstractPlot; kwargs...)
    colorbar_check((:colormap, :limits, :highclip, :lowclip), keys(kwargs))
    cmap = extract_colormap_recursive(plot)
    func = plotfunc(plot)
    if isnothing(cmap)
        error("Neither $(func) nor any of its children use a colormap. Cannot create a Colorbar from this plot, please create it manually.
        If this is a recipe, one needs to overload `Makie.extract_colormap(::$(Plot{func}))` to allow for the automatic creation of a Colorbar.")
    end
    if !(cmap isa ColorMapping)
        error("extract_colormap(::$(Plot{func})) returned an invalid value: $cmap. Needs to return either a `Makie.ColorMapping`.")
    end

    if to_value(cmap.color) isa Union{AbstractVector{<:Colorant}, Colorant}
        error(
            """Plot $(func)'s color attribute uses colors directly, so it can't be used to create a Colorbar, since no numbers are mapped to a color via the colormap.
                 Please create the colorbar manually e.g. via `Colorbar(f[1, 2], colorrange=the_range, colormap=the_colormap)`..
            """
        )
    end

    return Colorbar(
        fig_or_scene;
        colormap = cmap,
        kwargs...
    )
end

function initialize_block!(cb::Colorbar)
    blockscene = cb.blockscene

    onany(blockscene, cb.size, cb.vertical) do sz, vertical
        if vertical
            cb.layoutobservables.autosize[] = (sz, nothing)
        else
            cb.layoutobservables.autosize[] = (nothing, sz)
        end
    end

    framebox = lift(round_to_IRect2D, blockscene, cb.layoutobservables.computedbbox)

    # TODO, always convert to ColorMapping!
    if cb.colormap[] isa ColorMapping
        cmap = cb.colormap[]
    else
        # Old way without Colormapping. We keep it, to be able to create a colormap directly
        limits = lift(blockscene, cb.limits, cb.colorrange) do limits, colorrange
            if all(!isnothing, (limits, colorrange))
                error("Both colorrange + limits are set, please only set one, they're aliases. colorrange: $(colorrange), limits: $(limits)")
            end
            return something(limits, colorrange, (0, 1))
        end
        alpha = Observable(1.0) # dont have these as fields in Colorbar
        nan_color = Observable(RGBAf(0, 0, 0, 0))
        cmap = ColorMapping(
            Float64[], Observable(Float64[]), cb.colormap, limits,
            cb.scale, alpha, cb.lowclip, cb.highclip, nan_color
        )
    end

    colormap = lift(cmap.raw_colormap, cmap.colormap, cmap.mapping) do rcm, cm, mapping
        if isnothing(mapping)
            return rcm
        else
            # if there is a mapping, we want to apply it to the colormap, which is already done for cmap.colormap (by calling to_colormap(cgrad(...)))
            # In the future, we may want to use cmap.mapping to do this ourselves
            return cm
        end
    end
    limits = cmap.colorrange
    colors = lift(
        blockscene, cmap.mapping, cmap.color_mapping_type, cmap.color, cb.nsteps, limits;
        ignore_equal_values = true
    ) do mapping, mapping_type, values, n, limits
        if mapping === nothing
            if mapping_type === Makie.banded
                error("Banded without a mapping is invalid. Please use colormap=cgrad(...; categorical=true)")
            elseif mapping_type === Makie.categorical
                # First we find all unique values,
                # then we throw out NaNs that are rendered independently anyway
                # then we clamp the remaining values to the limits,
                # remove remaining duplicates and sort
                vals = sort(unique(clamp.(filter(!isnan, unique(values)), limits...)))
                return convert(Vector{Float64}, vals)
            else
                return convert(Vector{Float64}, LinRange(limits..., n))
            end
        else
            if mapping_type === Makie.categorical
                # This is because cmap.mapping comes from cgrad.values, which doesn't encode categorical colormapping correctly
                error("Mapping should not be used for categorical colormaps")
            end
            if mapping_type === Makie.continuous
                # we need at least nsteps, to correctly sample from the colormap (which has the mapping applied already)
                return convert(Vector{Float64}, LinRange(limits..., n))
            else
                # Mapping is always 0..1, but color should be scaled
                return limits[1] .+ (mapping .* (limits[2] - limits[1]))
            end
            return
        end
    end

    lowclip_tri_visible = lift(x -> !(x isa Automatic), blockscene, cmap.lowclip; ignore_equal_values = true)
    highclip_tri_visible = lift(x -> !(x isa Automatic), blockscene, cmap.highclip; ignore_equal_values = true)
    tri_heights = lift(blockscene, highclip_tri_visible, lowclip_tri_visible, framebox; ignore_equal_values = true) do hv, lv, box
        if cb.vertical[]
            return (lv * width(box), hv * width(box))
        else
            return (lv * height(box), hv * height(box))
        end .* sin(pi / 3)
    end

    barbox = lift(blockscene, framebox; ignore_equal_values = true) do fbox
        if cb.vertical[]
            return BBox(left(fbox), right(fbox), bottom(fbox) + tri_heights[][1], top(fbox) - tri_heights[][2])
        else
            return BBox(left(fbox) + tri_heights[][1], right(fbox) - tri_heights[][2], bottom(fbox), top(fbox))
        end
    end

    xrange = Observable(Float32[]; ignore_equal_values = true)
    yrange = Observable(Float32[]; ignore_equal_values = true)

    function update_xyrange(bb, v, colors, scale, mapping_type)
        xmin, ymin = minimum(bb)
        xmax, ymax = maximum(bb)
        if mapping_type == Makie.categorical
            colors = edges(1:length(colors))
        end
        s_scaled = scale.(colors)
        mini, maxi = extrema(s_scaled)
        s_scaled = (s_scaled .- mini) ./ (maxi - mini)
        if v
            xrange[] = LinRange(xmin, xmax, 2)
            yrange[] = s_scaled .* (ymax - ymin) .+ ymin
        else
            xrange[] = s_scaled .* (xmax - xmin) .+ xmin
            yrange[] = LinRange(ymin, ymax, 2)
        end
        return
    end

    update_xyrange(barbox[], cb.vertical[], colors[], cmap.scale[], cmap.color_mapping_type[])
    onany(update_xyrange, blockscene, barbox, cb.vertical, colors, cmap.scale, cmap.color_mapping_type)

    # for continuous colormaps we sample a 1d image
    # to avoid white lines when rendering vector graphics
    continuous_pixels = lift(
        blockscene, cb.vertical, colors,
        cmap.color_mapping_type
    ) do v, colors, mapping_type
        if mapping_type !== Makie.categorical
            colors = (colors[1:(end - 1)] .+ colors[2:end]) ./ 2
        end
        n = length(colors)
        return v ? reshape((colors), 1, n) : reshape((colors), n, 1)
    end
    # TODO, implement interpolate = true for irregular grics in CairoMakie
    # Then, we can just use heatmap! and don't need the image plot!
    show_cats = Observable(false; ignore_equal_values = true)
    show_continuous = Observable(false; ignore_equal_values = true)
    on(blockscene, cmap.color_mapping_type; update = true) do type
        if type === continuous
            show_continuous[] = true
            show_cats[] = false
        else
            show_continuous[] = false
            show_cats[] = true
        end
    end
    heatmap!(
        blockscene,
        xrange, yrange, continuous_pixels;
        colormap = colormap,
        colorrange = limits,
        visible = show_cats,
        inspectable = false
    )
    image!(
        blockscene,
        lift(extrema, xrange), lift(extrema, yrange), continuous_pixels;
        colormap = colormap,
        colorrange = limits,
        visible = show_continuous,
        inspectable = false
    )

    highclip_tri = lift(blockscene, barbox, cb.spinewidth) do box, spinewidth
        if cb.vertical[]
            lb, rb = topline(box)
            l = lb
            r = rb
            t = ((l .+ r) ./ 2) .+ Point2f(0, sqrt(sum((r .- l) .^ 2)) * sin(pi / 3))
            [l, r, t]
        else
            b, t = rightline(box)
            r = ((b .+ t) ./ 2) .+ Point2f(sqrt(sum((t .- b) .^ 2)) * sin(pi / 3), 0)
            [t, b, r]
        end
    end

    highclip_tri_color = lift(blockscene, cmap.highclip) do hc
        to_color(hc isa Automatic || isnothing(hc) ? :transparent : hc)
    end

    poly!(
        blockscene, highclip_tri, color = highclip_tri_color,
        strokecolor = :transparent,
        visible = highclip_tri_visible, inspectable = false
    )

    lowclip_tri = lift(blockscene, barbox, cb.spinewidth) do box, spinewidth
        if cb.vertical[]
            lb, rb = bottomline(box)
            l = lb
            r = rb
            t = ((l .+ r) ./ 2) .- Point2f(0, sqrt(sum((r .- l) .^ 2)) * sin(pi / 3))
            [l, r, t]
        else
            b, t = leftline(box)
            l = ((b .+ t) ./ 2) .- Point2f(sqrt(sum((t .- b) .^ 2)) * sin(pi / 3), 0)
            [b, t, l]
        end
    end

    lowclip_tri_color = lift(blockscene, cmap.lowclip) do lc
        to_color(lc isa Automatic || isnothing(lc) ? :transparent : lc)
    end

    poly!(
        blockscene, lowclip_tri, color = lowclip_tri_color,
        strokecolor = :transparent,
        visible = lowclip_tri_visible, inspectable = false
    )

    borderpoints = lift(blockscene, barbox, highclip_tri_visible, lowclip_tri_visible) do bb, hcv, lcv
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

    axispoints = lift(blockscene, barbox, cb.vertical, cb.flipaxis) do scenearea,
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

    ticks = Observable{Any}()
    map!(ticks, colors, cmap.color_mapping_type, cb.ticks) do cs, type, ticks
        # For categorical we just enumerate
        type === Makie.categorical ? (1:length(cs), string.(cs)) : ticks
    end

    lims = lift(colors, cmap.color_mapping_type, limits) do cs, type, limits
        return type === Makie.categorical ? (0.5, length(cs) + 0.5) : limits
    end

    axis = LineAxis(
        blockscene, endpoints = axispoints, flipped = cb.flipaxis,
        limits = lims, ticklabelalign = cb.ticklabelalign, label = cb.label,
        labelpadding = cb.labelpadding, labelvisible = cb.labelvisible, labelsize = cb.labelsize,
        labelcolor = cb.labelcolor, labelrotation = cb.labelrotation,
        labelfont = cb.labelfont, ticklabelfont = cb.ticklabelfont,
        dim_convert = nothing, # TODO, we should also have a dim convert for Colorbar
        ticks = ticks, tickformat = cb.tickformat,
        ticklabelsize = cb.ticklabelsize, ticklabelsvisible = cb.ticklabelsvisible, ticksize = cb.ticksize,
        ticksvisible = cb.ticksvisible, ticklabelpad = cb.ticklabelpad, tickalign = cb.tickalign,
        ticklabelrotation = cb.ticklabelrotation,
        tickwidth = cb.tickwidth, tickcolor = cb.tickcolor, spinewidth = cb.spinewidth,
        ticklabelspace = cb.ticklabelspace, ticklabelcolor = cb.ticklabelcolor,
        spinecolor = :transparent, spinevisible = :false, flip_vertical_label = cb.flip_vertical_label,
        minorticksvisible = cb.minorticksvisible, minortickalign = cb.minortickalign,
        minorticksize = cb.minorticksize, minortickwidth = cb.minortickwidth,
        minortickcolor = cb.minortickcolor, minorticks = cb.minorticks, scale = cmap.scale
    )

    cb.axis = axis

    onany(blockscene, axis.protrusion, cb.vertical, cb.flipaxis) do axprotrusion,
            vertical, flipaxis

        left, right, top, bottom = 0.0f0, 0.0f0, 0.0f0, 0.0f0

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
    # We set everything via the ColorMapping now. To be backwards compatible, we always set those fields:
    if (cb.colormap[] isa ColorMapping)
        setfield!(cb, :limits, convert(Observable{Any}, limits))
        setfield!(cb, :colormap, convert(Observable{Any}, cmap.colormap))
        setfield!(cb, :highclip, convert(Observable{Any}, cmap.highclip))
        setfield!(cb, :lowclip, convert(Observable{Any}, cmap.lowclip))
        setfield!(cb, :scale, convert(Observable{Any}, cmap.scale))
    end
    # trigger bbox
    notify(cb.layoutobservables.suggestedbbox)
    notify(barbox)

    return
end

"""
    space = tight_ticklabel_spacing!(cb::Colorbar)

Sets the space allocated for the ticklabels of the `Colorbar` to the minimum that is needed and returns that value.
"""
tight_ticklabel_spacing!(cb::Colorbar) = tight_ticklabel_spacing!(cb.axis)

function scaled_steps(steps, scale, lims)
    # scale with scaling function
    steps_scaled = scale.(steps)
    # normalize to lims range
    steps_lim_scaled = @. steps_scaled * (scale(lims[2]) - scale(lims[1])) + scale(lims[1])
    # then rescale to 0 to 1
    return @. (steps_lim_scaled - steps_lim_scaled[begin]) / (steps_lim_scaled[end] - steps_lim_scaled[begin])
end
