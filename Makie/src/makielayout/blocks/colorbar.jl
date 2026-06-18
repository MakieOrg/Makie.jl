function colorbar_check(keys, kwargs_keys)
    for key in keys
        if key in kwargs_keys
            error("You should not pass the `$key` attribute to the colorbar when constructing it using an existing plot object. This attribute is copied from the plot object, and setting it from the colorbar will make the plot object and the colorbar go out of sync.")
        end
    end
    return
end

function extract_colormap(@nospecialize(plot::AbstractPlot))
    minimal_keys = (:color, :colormap, :colorrange)

    if all(key -> haskey(plot, key), minimal_keys)
        # TODO: maybe we should check that all or none of the outputs of
        # register_colormapping!() are available?

        if plot.color[] isa Union{AbstractArray{<:Colorant}, ShaderAbstractions.Sampler, AbstractPattern, Colorant}
            return nothing
        end

        haskey(plot, :alpha) || add_constant!(plot, :alpha, 1.0)
        haskey(plot, :lowclip) || add_constant!(plot, :lowclip, automatic)
        haskey(plot, :highclip) || add_constant!(plot, :highclip, automatic)
        haskey(plot, :nan_color) || add_constant!(plot, :nan_color, RGBAf(0, 0, 0, 0))
        haskey(plot, :colorscale) || add_constant!(plot, :colorscale, identity)

        if !haskey(plot, :scaled_colorrange)
            register_colormapping!(plot.attributes)
        end

        isnothing(plot.scaled_colorrange[]) && return nothing

        return (
            color = plot.color,
            colormap = plot.alpha_colormap,
            colorscale = plot.colorscale,
            mapping = plot.color_mapping,
            colorrange = plot.scaled_colorrange,
            lowclip = plot.lowclip,
            highclip = plot.highclip,
            color_mapping_type = plot.color_mapping_type
        )
    end
end

function extract_colormap(plot::ComputePlots)
    return (
        color = plot.scaled_color,
        colormap = plot.alpha_colormap,
        colorscale = plot.colorscale,
        mapping = plot.color_mapping,
        colorrange = plot.scaled_colorrange,
        lowclip = plot.lowclip,
        highclip = plot.highclip,
        color_mapping_type = plot.color_mapping_type
    )
end

function extract_colormap(plot::Arrows2D)
    map!(plot, [:scaled_tailcolor, :scaled_shaftcolor, :scaled_tipcolor], :scaled_merged_color) do a, b, c
        return [a; b; c]
    end
    return (
        color = plot.scaled_merged_color,
        colormap = plot.alpha_colormap,
        colorscale = plot.colorscale,
        mapping = plot.color_mapping,
        colorrange = plot.scaled_colorrange,
        lowclip = plot.lowclip,
        highclip = plot.highclip,
        color_mapping_type = plot.color_mapping_type
    )
end

function extract_colormap(plot::Voxels)
    return (
        color = plot.chunk,
        colormap = plot.alpha_colormap,
        colorscale = plot.colorscale,
        mapping = nothing, # not supported
        colorrange = plot.value_limits,
        lowclip = plot.lowclip,
        highclip = plot.highclip,
        color_mapping_type = plot.color_mapping_type
    )
end

extract_colormap(plot::StreamPlot) = extract_colormap(plot.plots[1])
extract_colormap(plot::VolumeSlices) = extract_colormap(plot.plots[1])

_normalize_clipcolor(x) = x in (nothing, :auto, automatic) ? automatic : x
function extract_colormap(plot::Union{Contourf, Tricontourf})
    map!(plot, :computed_colormap, [:alpha_colormap, :color_mapping]) do cm
        return to_colormap(cm), cm.values
    end
    map!(_normalize_clipcolor, plot, :extendlow, :cb_lowclip)
    map!(_normalize_clipcolor, plot, :extendhigh, :cb_highclip)
    return (
        color = plot.computed_levels,
        colormap = plot.alpha_colormap,
        colorscale = plot.colorscale,
        mapping = plot.color_mapping,
        colorrange = plot.computed_colorrange, # missing colorscale?
        lowclip = plot.cb_lowclip,
        highclip = plot.cb_highclip,
        color_mapping_type = banded
    )
end

function extract_colormap(plot::Contour{<:Tuple{X, Y, Z, Vol}}) where {X, Y, Z, Vol}
    # Users may use transparency to make layered isosurfaces visible. Because
    # 3D contours often accumulate the color of an isosurface over multiple
    # samples one typically needs very low alpha values for this, which would
    # make the colors in the colormap very faint. To keep the Colorbar useful,
    # we remove user alpha here. (The recipe also uses `alpha = 0` to remove
    # samples outside of isosurfaces. This is preserved here)
    map!(cm -> RGBAf.(Colors.color.(cm), Colors.alpha.(cm) .> 0.0f0), plot, :computed_colormap, :opaque_colormap)
    return (
        color = plot.value_levels,
        colormap = plot.opaque_colormap,
        colorscale = plot.colorscale,
        mapping = nothing,
        colorrange = plot.padded_colorrange, # missing colorscale?
        lowclip = automatic,
        highclip = automatic,
        color_mapping_type = continuous
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

    if to_value(cmap.color) isa Union{AbstractVector{<:Colorant}, Colorant}
        error(
            """Plot $(func)'s color attribute uses colors directly, so it can't be used to create a Colorbar, since no numbers are mapped to a color via the colormap.
                 Please create the colorbar manually e.g. via `Colorbar(f[1, 2], colorrange=the_range, colormap=the_colormap)`..
            """
        )
    end

    return Colorbar(
        fig_or_scene;
        plot_data = cmap,
        kwargs...
    )
end

block_kwargs(::Type{Colorbar}) = Set([:plot_data])

function initialize_block!(cb::Colorbar; plot_data = nothing)
    blockscene = cb.blockscene

    map!(cb, [:size, :vertical], :autosize) do sz, vertical
        return vertical ? (sz, nothing) : (nothing, sz)
    end
    map!(identity, blockscene, cb.layoutobservables.autosize, cb.autosize)

    add_input!(cb, :computedbbox, cb.layoutobservables.computedbbox)
    map!(round_to_IRect2D, cb, :computedbbox, :framebox)

    cmap = ComputePipeline.ComputeGraphView(cb.attributes, :color_mapping)
    if plot_data isa NamedTuple
        add_input!(cmap, :color, plot_data.color)
        add_input!(cmap, :colormap, plot_data.colormap)
        add_input!(cmap, :scale, plot_data.colorscale)
        add_input!(cmap, :mapping, plot_data.mapping)
        add_input!(cmap, :colorrange, plot_data.colorrange)
        add_input!(cmap, :lowclip, plot_data.lowclip)
        add_input!(cmap, :highclip, plot_data.highclip)
        add_input!(cmap, :color_mapping_type, plot_data.color_mapping_type)
    else
        # Old way without Colormapping. We keep it, to be able to create a colormap directly
        map!(cmap, [cb.limits, cb.colorrange], :colorrange) do limits, colorrange
            if all(!isnothing, (limits, colorrange))
                error("Both colorrange + limits are set, please only set one, they're aliases. colorrange: $(colorrange), limits: $(limits)")
            end
            return something(limits, colorrange, (0.0, 1.0))
        end
        add_constant!(cmap, :color, Float64[])
        map!(c -> c isa Union{Nothing, Automatic} ? automatic : to_color(c), cmap, cb.lowclip, :lowclip)
        map!(c -> c isa Union{Nothing, Automatic} ? automatic : to_color(c), cmap, cb.highclip, :highclip)
        map!(to_colormap, cmap, cb.colormap, :colormap)
        map!(identity, cmap, cb.scale, :scale)
        map!(cm -> cm isa PlotUtils.ColorGradient ? cm.values : nothing, cmap, cb.colormap, :mapping)
        map!(colormapping_type, cmap, cb.colormap, :color_mapping_type)
    end

    map!(
        cb,
        [cmap.mapping, cmap.color_mapping_type, cmap.color, :nsteps, cmap.colorrange],
        :cb_colors
    ) do mapping, mapping_type, values, n, limits
        if mapping_type === Makie.continuous
            return convert(Vector{Float64}, LinRange(limits..., n))
        elseif mapping_type === Makie.banded
            if isnothing(mapping)
                error("Banded without a mapping is invalid. Please use colormap=cgrad(...; categorical=true)")
            else # PlotUtils.ColorGradient
                # Mapping is always 0..1, but color should be scaled
                return limits[1] .+ (mapping .* (limits[2] - limits[1]))
            end
        elseif mapping_type === Makie.categorical
            if isnothing(mapping)
                # First we find all unique values,
                # then we throw out NaNs that are rendered independently anyway
                # then we clamp the remaining values to the limits,
                # remove remaining duplicates and sort
                vals = sort(unique(clamp.(filter(!isnan, unique(values)), limits...)))
                return convert(Vector{Float64}, vals)
            else # PlotUtils.ColorGradient
                error("PlotUtils.ColorGradient should not be used for categorical colormaps")
            end
        else
            # unreachable
            error("Unknown mapping type $mapping_type")
        end
    end

    map!(x -> x !== automatic, cb, cmap.lowclip, :lowclip_tri_visible)
    map!(x -> x !== automatic, cb, cmap.highclip, :highclip_tri_visible)

    map!(
        cb, [:highclip_tri_visible, :lowclip_tri_visible, :framebox, :vertical], :tri_heights
    ) do hv, lv, box, vertical
        return (lv, hv) .* ifelse(vertical, width(box), height(box)) .* sin(pi/3)
    end

    map!(cb, [:framebox, :vertical, :tri_heights], :barbox) do fbox, vertical, tri_heights
        if vertical
            return BBox(left(fbox), right(fbox), bottom(fbox) + tri_heights[1], top(fbox) - tri_heights[2])
        else
            return BBox(left(fbox) + tri_heights[1], right(fbox) - tri_heights[2], bottom(fbox), top(fbox))
        end
    end

    map!(
        cb,
        [:barbox, :vertical, :cb_colors, cmap.scale, cmap.color_mapping_type],
        [:xrange, :yrange]
    ) do bb, vertical, colors, scale, mapping_type
        xmin, ymin = minimum(bb)
        xmax, ymax = maximum(bb)
        if mapping_type == Makie.categorical
            colors = edges(1:length(colors))
        end
        s_scaled = scale.(colors)
        mini, maxi = extrema(s_scaled)
        s_scaled = (s_scaled .- mini) ./ (maxi - mini)
        if vertical
            xrange = LinRange(xmin, xmax, 2)
            yrange = s_scaled .* (ymax - ymin) .+ ymin
        else
            xrange = s_scaled .* (xmax - xmin) .+ xmin
            yrange = LinRange(ymin, ymax, 2)
        end
        return xrange, yrange
    end


    # for continuous colormaps we sample a 1d image
    # to avoid white lines when rendering vector graphics
    map!(
        cb, [:vertical, :cb_colors, cmap.color_mapping_type], :continuous_pixels
    ) do vertical, colors, mapping_type
        if mapping_type !== Makie.categorical
            colors = (colors[1:(end - 1)] .+ colors[2:end]) ./ 2
        end
        n = length(colors)
        return vertical ? reshape((colors), 1, n) : reshape((colors), n, 1)
    end

    # TODO, implement interpolate = true for irregular grids in CairoMakie
    # Then, we can just use heatmap! and don't need the image plot!
    map!(cb, cmap.color_mapping_type, [:show_cats, :show_continuous]) do type
        return (type !== continuous, type === continuous)
    end

    heatmap!(
        blockscene,
        cb.xrange, cb.yrange, cb.continuous_pixels;
        colormap = cmap.colormap,
        colorrange = cmap.colorrange,
        visible = cb.show_cats,
        inspectable = false
    )

    map!(extrema, cb, :xrange, :xlims)
    map!(extrema, cb, :yrange, :ylims)

    image!(
        blockscene,
        cb.xlims, cb.ylims, cb.continuous_pixels;
        colormap = cmap.colormap,
        colorrange = cmap.colorrange,
        visible = cb.show_continuous,
        inspectable = false
    )

    map!(cb, [:barbox, :vertical], :clip_tris) do box, vertical
        if vertical
            lt, rt = topline(box)
            et = ((lt .+ rt) ./ 2) .+ Point2f(0, sqrt(sum((rt .- lt) .^ 2)) * sin(pi / 3))
            lb, rb = bottomline(box)
            eb = ((lb .+ rb) ./ 2) .- Point2f(0, sqrt(sum((rb .- lb) .^ 2)) * sin(pi / 3))
            return [Polygon([lt, rt, et]), Polygon([lb, rb, eb])]
        else
            br, tr = rightline(box)
            er = ((b .+ t) ./ 2) .+ Point2f(sqrt(sum((t .- b) .^ 2)) * sin(pi / 3), 0)
            bl, tl = leftline(box)
            el = ((b .+ t) ./ 2) .- Point2f(sqrt(sum((t .- b) .^ 2)) * sin(pi / 3), 0)
            return [Polygon([br, tr, er]), Polygon([bl, tl, el])]
        end
    end

    map!(cb, [cmap.highclip, cmap.lowclip], :clip_tri_colors) do hc, lc
        return [
            to_color(hc isa Automatic || isnothing(hc) ? :transparent : hc),
            to_color(lc isa Automatic || isnothing(lc) ? :transparent : lc)
        ]
    end

    poly!(
        blockscene, cb.clip_tris, color = cb.clip_tri_colors,
        strokecolor = :transparent, inspectable = false
    )

    map!(
        cb,
        [:barbox, :highclip_tri_visible, :lowclip_tri_visible, :vertical, :clip_tris],
        :borderpoints
    ) do bb, hcv, lcv, vertical, clip_tris
        if vertical
            points = [bottomright(bb), topright(bb)]
            if hcv
                push!(points, clip_tris[1].exterior[3])
            end
            append!(points, [topleft(bb), bottomleft(bb)])
            if lcv
                push!(points, clip_tris[2].exterior[3])
            end
            push!(points, bottomright(bb))
            return points
        else
            points = [bottomleft(bb), bottomright(bb)]
            if hcv
                push!(points, clip_tris[1].exterior[3])
            end
            append!(points, [topright(bb), topleft(bb)])
            if lcv
                push!(points, clip_tris[2].exterior[3])
            end
            push!(points, bottomleft(bb))
            return points
        end
    end

    lines!(blockscene, cb.borderpoints, linewidth = cb.spinewidth, color = cb.topspinecolor, inspectable = false)

    map!(cb, [:barbox, :vertical, :flipaxis], :axispoints) do scenearea, vertical, flipaxis
        if vertical
            if flipaxis
                return (bottomright(scenearea), topright(scenearea))
            else
                return (bottomleft(scenearea), topleft(scenearea))
            end
        else
            if flipaxis
                return (topleft(scenearea), topright(scenearea))
            else
                return (bottomleft(scenearea), bottomright(scenearea))
            end
        end
    end

    ticks = Observable{Any}()
    map!(cb, [:cb_colors, cmap.color_mapping_type, :ticks], :finalticks) do cs, type, ticks
        # For categorical we just enumerate
        return type === Makie.categorical ? (1:length(cs), string.(cs)) : ticks
    end

    map!(cb, [:cb_colors, cmap.color_mapping_type, cmap.colorrange], :ticklimits) do cs, type, limits
        return type === Makie.categorical ? (0.5, length(cs) + 0.5) : limits
    end

    axis = LineAxis(
        blockscene, ComputePipeline.ComputeGraphView(cb.attributes, :axis),
        endpoints = cb.axispoints, flipped = cb.flipaxis,
        limits = cb.ticklimits, ticklabelalign = cb.ticklabelalign, label = cb.label,
        labelpadding = cb.labelpadding, labelvisible = cb.labelvisible, labelsize = cb.labelsize,
        labelcolor = cb.labelcolor, labelrotation = cb.labelrotation,
        labelfont = cb.labelfont, ticklabelfont = cb.ticklabelfont,
        dim_convert = nothing, # TODO, we should also have a dim convert for Colorbar
        ticks = cb.finalticks, tickformat = cb.tickformat,
        ticklabelsize = cb.ticklabelsize, ticklabelsvisible = cb.ticklabelsvisible, ticksize = cb.ticksize,
        ticksvisible = cb.ticksvisible, ticklabelpad = cb.ticklabelpad, tickalign = cb.tickalign,
        ticklabelrotation = cb.ticklabelrotation,
        tickwidth = cb.tickwidth, tickcolor = cb.tickcolor, spinewidth = cb.spinewidth,
        ticklabelspace = cb.ticklabelspace, ticklabelcolor = cb.ticklabelcolor,
        spinecolor = :transparent, spinevisible = false, flip_vertical_label = cb.flip_vertical_label,
        minorticksvisible = cb.minorticksvisible, minortickalign = cb.minortickalign,
        minorticksize = cb.minorticksize, minortickwidth = cb.minortickwidth,
        minortickcolor = cb.minortickcolor, minorticks = cb.minorticks, scale = cmap.scale
    )

    cb.axis = axis

    map!(
        cb, [cb.attributes.axis.protrusion, :vertical, :flipaxis], :protrusions
    ) do axprotrusion, vertical, flipaxis
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

        return GridLayoutBase.RectSides{Float32}(left, right, bottom, top)
    end
    map!(identity, cb.layoutobservables.protrusions, cb.protrusions)

    # trigger bbox
    notify(cb.layoutobservables.suggestedbbox)

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
