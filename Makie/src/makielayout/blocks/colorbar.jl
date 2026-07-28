function colorbar_check(keys, kwargs_keys)
    for key in keys
        if key in kwargs_keys
            error("You should not pass the `$key` attribute to the colorbar when constructing it using an existing plot object. This attribute is copied from the plot object, and setting it from the colorbar will make the plot object and the colorbar go out of sync.")
        end
    end
    return
end

"""
    extract_colormap(plot)

This function extracts plot attributes relevant for constructing a `Colorbar`.
It is meant to be extended for recipes with multiple child plots and when the
recipe handles colormapping by itself.

In the first case
`Makie.extract_colormap(plot::MyPlot) = Makie.extract_colormap(plot.plots[...])`
should simply select a child plot that contains the relevant colormapping
information.

For the second case a `Dict{Symbol, Any}` containing the relevant colormapping
attributes. These may include:
- `:colormap`: The colormap of the plot.
- `:color`: The color values that the colormap applies to.
- `:colorrange`: The colorrange of the plot, i.e. the extrema of `color`.
- `:colorscale`: The colorscale of plot.
- `:lowclip`: The lowclip of the plot.
- `:highclip`: The highclip of the plot.
- `:dim_convert_4`: The color dim convert of the plot.

If the returned dict is incomplete a parent plot may add missing attributes to
it. This may lead to Colorbar attributes not being synchronized with the
visuals of the plot, so a complete set of attributes is preferred. Note that
this is not relevant for `dim_convert_4` as it only appears when it is used.

To simplify this `Makie.add_default_colorbar_attributes!(dict, plot)` can be
used to fill out attributes that use the default names. (I.e. the names listed
as keys above.) Alternatively `Makie._extract_colormap(plot)` can be implemented
with an incomplete set of attributes instead of `extract_colormap()`. The default
`Makie.extract_colormap` method will then add the remaining defaults.

Note that attributes can also be set to constant values (as opposed to compute
nodes from `plot.attribute`). For example, adding `attr[:colorscale] = identity`
will prevent parent plot attributes getting connected. `Colorbar.colorscale`
will then be initialized with `identity` and remain as a changeable input.
"""
extract_colormap

# Example stairs:
# extract_colormap(plot)                     # 1. dispatch to _extract_colormap
#   _extract_colormap(plot)                  # 2. check and do step down to child plots
#       extract_colormap(plot.plots[1])      # 3. dispatch to _extract_colormap()
#           _extract_colormap(plot.plots[1]) # 4. add specialized inputs (none for lines)
#       extract_colormap(plot.plots[1])      # 5. Add missing default attributes (all)
# extract_colormap(plot)                     # 6. Add missing default attributes (none)
function extract_colormap(@nospecialize(plot::AbstractPlot))
    return add_default_colorbar_attributes(_extract_colormap(plot), plot)
end

function _extract_colormap(@nospecialize(plot::AbstractPlot))
    if isempty(plot.plots)
        error(
            "$plot seems to be a native plot (no children) but does not " *
                "implement an `extract_colormap` method."
        )
    elseif length(plot.plots) != 1
        error(
            "Plots with multiple child plots must implement a method " *
                "`extract_colormap(plot::$(plotsym(typeof(plot)))) = extract_colormap(plot.plots[...])`" *
                " to identify the sub plot from which colormap information should be extracted."
        )
    end
    return extract_colormap(only(plot.plots))
end

# Primitive Plots (recursion endpoints)
_extract_colormap(@nospecialize(::ComputePlots)) = Dict{Symbol, Any}()
_extract_colormap(@nospecialize(plot::Voxels)) = Dict{Symbol, Any}(:color => plot.chunk, :colorrange => plot.value_limits)
function _extract_colormap(@nospecialize(plot::Union{Surface, Heatmap, Image}))
    # args or recursive_convert
    pre_dc_args = plot.dim_converted.parent.inputs[1]
    map!(args -> args[end], plot, pre_dc_args, :pre_dc_color)
    return Dict{Symbol, Any}(:color => plot.pre_dc_color)
end

# Recipe Overwrites

# Use _extract_colormap to autocomplete attributes
function _extract_colormap(@nospecialize(plot::Arrows2D))
    map!(plot, [:tailcolor, :shaftcolor, :tipcolor, :color], :raw_merged_color) do a, b, c, d
        return [default_automatic(a, d); default_automatic(b, d); default_automatic(c, d)]
    end
    return Dict{Symbol, Any}(:color => plot.raw_merged_color)
end

# Step downs can be either method
function extract_colormap(@nospecialize(plot::VolumeSlices))
    attr = extract_colormap(plot.plots[1]) # complete set
    attr[:color] = plot[4] # replace view with full data
    return attr
end
extract_colormap(plot::StreamPlot) = extract_colormap(plot.plots[1])
extract_colormap(plot::Spy) = extract_colormap(plot.plots[1])
extract_colormap(plot::Dendrogram) = extract_colormap(plot.plots[1])
extract_colormap(plot::Density) = extract_colormap(plot.plots[1])
extract_colormap(plot::ScatterLines) = extract_colormap(plot.plots[1])
extract_colormap(plot::Band) = extract_colormap(plot.plots[1])
extract_colormap(plot::BarPlot) = extract_colormap(plot.plots[1])
extract_colormap(plot::Poly) = extract_colormap(plot.plots[1])
extract_colormap(plot::Errorbars) = extract_colormap(plot.plots[1])
extract_colormap(plot::Rangebars) = extract_colormap(plot.plots[1])
extract_colormap(plot::BoxPlot) = extract_colormap(plot.plots[3])
extract_colormap(plot::CrossBar) = extract_colormap(plot.plots[1])

# Autocomplete the result of this
function _extract_colormap(plot::Voronoiplot)
    if plot.plots[1] isa Voronoiplot
        return extract_colormap(plot.plots[1]) # child should be completed
    else
        return Dict{Symbol, Any}(:color => plot.color)
    end
end

_normalize_clipcolor(x) = x in (nothing, :auto, automatic) ? automatic : x
function _extract_colormap(plot::Union{Contourf, Tricontourf})
    map!(_normalize_clipcolor, plot, :extendlow, :cb_lowclip)
    map!(_normalize_clipcolor, plot, :extendhigh, :cb_highclip)
    return Dict{Symbol, Any}(
        :color => plot.computed_levels,
        :colormap => plot.computed_colormap,
        :colorrange => plot.computed_colorrange,
        :lowclip => plot.cb_lowclip,
        :highclip => plot.cb_highclip,
    )
end

function _extract_colormap(plot::Union{Contour, Contour3d})
    return Dict{Symbol, Any}(:color => plot.zlevels, :colorrange => plot.computed_colorrange)
end

function _extract_colormap(plot::Contour{<:Tuple{X, Y, Z, Vol}}) where {X, Y, Z, Vol}
    # Users may use transparency to make layered isosurfaces visible. Because
    # 3D contours often accumulate the color of an isosurface over multiple
    # samples one typically needs very low alpha values for this, which would
    # make the colors in the colormap very faint. To keep the Colorbar useful,
    # we remove user alpha here. (The recipe also uses `alpha = 0` to remove
    # samples outside of isosurfaces. This is preserved here)
    map!(cm -> RGBAf.(Colors.color.(cm), Colors.alpha.(cm) .> 0.0f0), plot, :computed_colormap, :opaque_colormap)
    return Dict{Symbol, Any}(
        :color => plot.value_levels,
        :colormap => plot.opaque_colormap,
        :colorrange => plot.padded_colorrange,
    )
end

function add_default_colorbar_attributes(attr::Dict{Symbol, Any}, @nospecialize(plot))
    return add_default_colorbar_attributes(attr, attr, plot)
end
function add_default_colorbar_attributes(attr, @nospecialize(plot))
    return add_default_colorbar_attributes(Dict{Symbol, Any}(), attr, plot)
end
function add_default_colorbar_attributes(output, overwrites, @nospecialize(plot))
    for name in [:color, :colormap, :colorrange, :colorscale, :lowclip, :highclip, :dim_convert_4]
        if haskey(overwrites, name)
            output[name] = overwrites[name]
        elseif haskey(plot, name)
            push!(output, name => plot[name])
        end
    end
    if !haskey(output, :color) && haskey(plot, :raw_color)
        output[:color] = plot.raw_color
    end
    return output
end

function add_default_colorbar_attributes(cm::ColorMapping, @nospecialize(plot))
    return handle_colormapping_deprecation(cm, plot)
end

handle_colormapping_deprecation(cm::Dict, @nospecialize(plot)) = cm
function handle_colormapping_deprecation(cm::ColorMapping, @nospecialize(plot))
    Base.depwarn(
        "`extract_colormap(plot::$(typeof(plot)))` should no longer return a `Makie.ColorMapping`." *
            "Instead it should return a `Dict{Symbol, Any}()` containing colormap related attributes. " *
            "See `?Makie.extract_colormap`", :extract_colormap
    )
    cmap = Dict{Symbol, Any}()
    cmap[:color] = cm.color
    cmap[:colormap] = cm.raw_colormap
    cmap[:colorrange] = cm.colorrange
    cmap[:colorscale] = cm.scale
    cmap[:lowclip] = cm.lowclip
    cmap[:highclip] = cm.highclip
    return cmap
end

function colorbar_attributes_complete(dictlike)
    # TODO: Should this be less strict?
    # Technically colorrange can be derived from colors, and colors are
    # unnecessary with colorrange unless the colormap is categorical.
    # lowclip, highclip and colorscale are generally more niche
    full = (:colormap, :color, :colorrange, :colorscale, :lowclip, :highclip)
    return issubset(full, keys(dictlike))
end

function Colorbar(fig_or_scene, plot::AbstractPlot; kwargs...)
    cmap = try
        temp = extract_colormap(plot)
        # Autocomplete + ColorMapping deprecation
        add_default_colorbar_attributes(temp, plot)
    catch e
        @error("Failed to extract colormap from $(plotsym(typeof(plot))):")
        rethrow(e)
    end

    func = plotfunc(plot)
    if !colorbar_attributes_complete(cmap)
        error(
            "Could not extract a complete set of colormapping attributes from $func. \
            `extract_colormap(plot)` should produce: \n   \
            (:color, :colormap, :colorrange, :colorscale, :lowclip, :highclip). \n\
            Produced = $(keys(cmap))"
        )
    end

    haskey(cmap, :colorscale) && (cmap[:scale] = pop!(cmap, :colorscale))
    haskey(cmap, :color) && (cmap[:values] = pop!(cmap, :color))
    haskey(cmap, :dim_convert_4) && (cmap[:dim_conversion] = pop!(cmap, :dim_convert_4))

    cmap_keys = collect(keys(cmap))
    haskey(cmap, :colorrange) && push!(cmap_keys, :limits)
    colorbar_check(cmap_keys, keys(kwargs))

    if haskey(cmap, :values) && to_value(cmap[:values]) isa Union{AbstractArray{<:Colorant}, Colorant, ShaderAbstractions.Sampler, AbstractPattern}
        error(
            """Plot $(func)'s color attribute uses colors directly, so it can't be used to create a Colorbar, since no numbers are mapped to a color via the colormap.
                 Please create the colorbar manually e.g. via `Colorbar(f[1, 2], colorrange=the_range, colormap=the_colormap)`..
            """
        )
    end

    return Colorbar(fig_or_scene; cmap..., kwargs...)
end

function initialize_block!(cb::Colorbar)
    blockscene = cb.blockscene

    map!(cb, [:size, :vertical], :autosize) do sz, vertical
        return vertical ? (sz, nothing) : (nothing, sz)
    end
    ComputePipeline.set_type!(cb.autosize, Any)
    map!(identity, blockscene, cb.layoutobservables.autosize, cb.autosize)

    add_input!(cb, :computedbbox, cb.layoutobservables.computedbbox)
    map!(round_to_IRect2D, cb, :computedbbox, :framebox)

    # Run the normal color(map) processing. This either uses the inputs given
    # to `Colorbar()` explicitly, or the inputs extracted from a plot.
    register_colormapping_without_color!(cb.attributes)

    # Auto dim conversion
    if hasinput(cb.attributes, :dim_conversion) # not managed externally
        init = dim_conversion_from_args(color)
        cb.dim_conversion = init
    end

    if !isa(cb.dim_conversion[], Union{Nothing, NoDimConversion})
        map!(cb, [:dim_conversion, :values], :dc_values) do dc, color
            converted = convert_dim_value(dc, cb.attributes, color, nothing)
            return to_color(converted)
        end
    else
        ComputePipeline.map!(to_color, cb, :values, :dc_values)
    end

    map!(cb, :dc_values, :_derived_colorrange) do values
        return Vec2d(distinct_extrema_nan(values)...)
    end

    register_computation!(
        cb.attributes,
        [:dim_conversion, :colorrange, :limits, :_derived_colorrange],
        [:resolved_colorrange]
    ) do (dc, _colorrange, limits, autorange), changed, @nospecialize(cached)
        colorrange = if changed.limits && (limits !== automatic)
            @warn("Colorbar :limits has been deprecated in favor of :colorrange.")
            limits
        else
            _colorrange
        end

        if colorrange === automatic || colorrange === nothing
            return (autorange,)
        else
            # colorscale is processed later
            low = process_color_value(dc, identity, first(colorrange), first(autorange))
            high = process_color_value(dc, identity, last(colorrange), last(autorange))
            return (Vec2d(low, high),)
        end
    end

    map!(
        cb,
        [:color_mapping, :color_mapping_type, :values, :nsteps, :resolved_colorrange],
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

    map!(x -> x !== automatic, cb, :lowclip, :lowclip_tri_visible)
    map!(x -> x !== automatic, cb, :highclip, :highclip_tri_visible)

    map!(
        cb, [:highclip_tri_visible, :lowclip_tri_visible, :framebox, :vertical], :tri_heights
    ) do hv, lv, box, vertical
        return (lv, hv) .* ifelse(vertical, width(box), height(box)) .* sin(pi / 3)
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
        [:barbox, :vertical, :cb_colors, :scale, :color_mapping_type],
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
            xrange = collect(LinRange(xmin, xmax, 2))
            yrange = s_scaled .* (ymax - ymin) .+ ymin
        else
            xrange = s_scaled .* (xmax - xmin) .+ xmin
            yrange = collect(LinRange(ymin, ymax, 2))
        end
        return xrange, yrange
    end

    # for continuous colormaps we sample a 1d image
    # to avoid white lines when rendering vector graphics
    map!(
        cb, [:vertical, :cb_colors, :color_mapping_type], :continuous_pixels
    ) do vertical, colors, mapping_type
        if mapping_type !== Makie.categorical
            colors = (colors[1:(end - 1)] .+ colors[2:end]) ./ 2
        end
        n = length(colors)
        return vertical ? reshape((colors), 1, n) : reshape((colors), n, 1)
    end

    # TODO, implement interpolate = true for irregular grids in CairoMakie
    # Then, we can just use heatmap! and don't need the image plot!
    map!(cb, :color_mapping_type, [:show_catigorical, :show_continuous]) do type
        return (type !== continuous, type === continuous)
    end

    heatmap!(
        blockscene,
        cb.xrange, cb.yrange, cb.continuous_pixels;
        colormap = cb.alpha_colormap,
        colorrange = cb.resolved_colorrange,
        visible = cb.show_catigorical,
        inspectable = false
    )

    map!(extrema, cb, :xrange, :xlims)
    map!(extrema, cb, :yrange, :ylims)

    image!(
        blockscene,
        cb.xlims, cb.ylims, cb.continuous_pixels;
        colormap = cb.alpha_colormap,
        colorrange = cb.resolved_colorrange,
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
            er = ((br .+ tr) ./ 2) .+ Point2f(sqrt(sum((tr .- br) .^ 2)) * sin(pi / 3), 0)
            bl, tl = leftline(box)
            el = ((bl .+ tl) ./ 2) .- Point2f(sqrt(sum((tl .- bl) .^ 2)) * sin(pi / 3), 0)
            return [Polygon([br, tr, er]), Polygon([bl, tl, el])]
        end
    end

    map!(cb, [:highclip, :lowclip], :clip_tri_colors) do hc, lc
        return [
            to_color(hc isa Automatic || isnothing(hc) ? :transparent : hc),
            to_color(lc isa Automatic || isnothing(lc) ? :transparent : lc),
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

    map!(cb, [:cb_colors, :color_mapping_type, :ticks], :finalticks) do cs, type, ticks
        # For categorical we just enumerate
        return type === Makie.categorical ? (1:length(cs), string.(cs)) : ticks
    end
    ComputePipeline.set_type!(cb.finalticks, Any)

    map!(cb, [:cb_colors, :color_mapping_type, :resolved_colorrange], :ticklimits) do cs, type, limits
        return type === Makie.categorical ? (0.5, length(cs) + 0.5) : limits
    end

    axis = LineAxis(
        blockscene, ComputePipeline.ComputeGraphView(cb.attributes, :axis),
        endpoints = cb.axispoints, flipped = cb.flipaxis,
        limits = cb.ticklimits, ticklabelalign = cb.ticklabelalign, label = cb.label,
        labelpadding = cb.labelpadding, labelvisible = cb.labelvisible, labelsize = cb.labelsize,
        labelcolor = cb.labelcolor, labelrotation = cb.labelrotation,
        labelfont = cb.labelfont, ticklabelfont = cb.ticklabelfont,
        dim_convert = cb.dim_conversion,
        ticks = cb.finalticks, tickformat = cb.tickformat,
        ticklabelsize = cb.ticklabelsize, ticklabelsvisible = cb.ticklabelsvisible, ticksize = cb.ticksize,
        ticksvisible = cb.ticksvisible, ticklabelpad = cb.ticklabelpad, tickalign = cb.tickalign,
        ticklabelrotation = cb.ticklabelrotation,
        tickwidth = cb.tickwidth, tickcolor = cb.tickcolor, spinewidth = cb.spinewidth,
        ticklabelspace = cb.ticklabelspace, ticklabelcolor = cb.ticklabelcolor,
        spinecolor = :transparent, spinevisible = false, flip_vertical_label = cb.flip_vertical_label,
        minorticksvisible = cb.minorticksvisible, minortickalign = cb.minortickalign,
        minorticksize = cb.minorticksize, minortickwidth = cb.minortickwidth,
        minortickcolor = cb.minortickcolor, minorticks = cb.minorticks, scale = cb.scale,
        unit_in_ticklabel = cb.unit_in_ticklabel, unit_in_label = cb.unit_in_label,
        suffix_formatter = cb.label_suffix
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
