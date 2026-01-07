function convert_arguments(P::Type{<:AbstractPlot}, d::KernelDensity.UnivariateKDE)
    ptype = plottype(P, Lines) # choose the more concrete one
    return to_plotspec(ptype, convert_arguments(ptype, d.x, d.density))
end

function convert_arguments(::Type{<:Poly}, d::KernelDensity.UnivariateKDE)
    points = Vector{Point2f}(undef, length(d.x) + 2)
    points[1] = Point2f(d.x[1], 0)
    points[2:(end - 1)] .= Point2f.(d.x, d.density)
    points[end] = Point2f(d.x[end], 0)
    return (points,)
end

function convert_arguments(P::Type{<:AbstractPlot}, d::KernelDensity.BivariateKDE)
    ptype = plottype(P, Heatmap)
    return to_plotspec(ptype, convert_arguments(ptype, d.x, d.y, d.density))
end

"""
    density(values)

Plot a kernel density estimate of `values`.
"""
@recipe Density begin
    mixin_colormap_attributes()...
    mixin_generic_plot_attributes()...
    """
    Sets the color of the density plot. This is usually a single color, but can
    also be `:x` or `:y` to color with a gradient.
    """
    color = @inherit patchcolor

    "Sets the color of the density outline. This requires `strokewidth > 0`."
    strokecolor = @inherit patchstrokecolor
    "Sets the linewidth of the density outline."
    strokewidth = @inherit patchstrokewidth
    "Sets the line pattern of the density outline."
    linestyle = nothing
    "Controls whether the outline only draws around the complete density (true) or just the maximum values (false)."
    strokearound = false

    "The resolution of the estimated curve along the dimension set in `direction`."
    npoints = 200
    "Shift the density baseline, for layering multiple densities on top of each other."
    offset = 0.0
    "The dimension along which the `values` are distributed. Can be `:x` or `:y`."
    direction = :x
    "Boundary of the density estimation, determined automatically if `automatic`."
    boundary = automatic
    "Kernel density bandwidth, determined automatically if `automatic`."
    bandwidth = automatic
    "Assign a vector of statistical weights to `values`."
    weights = automatic
    """
    Sets which attributes to cycle when creating multiple plots. The values to
    cycle through are defined by the parent Theme. Multiple cycled attributes can
    be set by passing a vector. Elements can
    - directly refer to a cycled attribute, e.g. `:color`
    - map a cycled attribute to a palette attribute, e.g. `:linecolor => :color`
    - map multiple cycled attributes to a palette attribute, e.g. `[:linecolor, :markercolor] => :color`
    """
    cycle = [:color => :patchcolor]
end

function plot!(plot::Density{<:Tuple{<:AbstractVector}})
    map!(
        plot, [:converted_1, :direction, :boundary, :offset, :npoints, :bandwidth, :weights],
        [:lower, :upper]
    ) do x, dir, bound, offs, n, bw, weights

        k = KernelDensity.kde(
            x;
            npoints = n,
            (bound === automatic ? NamedTuple() : (boundary = bound,))...,
            (bw === automatic ? NamedTuple() : (bandwidth = bw,))...,
            (weights === automatic ? NamedTuple() : (weights = StatsBase.weights(weights),))...
        )

        if dir === :x
            lowerv = Point2f.(k.x, offs)
            upperv = Point2f.(k.x, offs .+ k.density)
        elseif dir === :y
            lowerv = Point2f.(offs, k.x)
            upperv = Point2f.(offs .+ k.density, k.x)
        else
            error("Invalid direction $dir, only :x or :y allowed")
        end
        return lowerv, upperv
    end

    map!(plot, [:lower, :upper, :strokearound], :linepoints) do lower, upper, strokearound
        if strokearound
            ps = copy(upper)
            push!(ps, lower[end])
            push!(ps, lower[1])
            push!(ps, lower[2])
            return ps
        else
            return upper
        end
    end

    map!(
        plot,
        [:color, :lower, :upper, :direction, :offset],
        :computed_color
    ) do color, lower, upper, dir, o
        if (dir === :x && color === :x) || (dir === :y && color === :y)
            dim = dir === :x ? 1 : 2
            return getindex.(lower, dim)
        elseif (dir === :y && color === :x) || (dir === :x && color === :y)
            dim = dir === :x ? 2 : 1
            return vcat(getindex.(lower, dim), getindex.(upper, dim)) .- o
        else
            return color
        end
    end

    band!(
        plot, plot.lower, plot.upper, color = plot.computed_color, colormap = plot.colormap, colorscale = plot.colorscale,
        colorrange = plot.colorrange, inspectable = plot.inspectable, alpha = plot.alpha, visible = plot.visible
    )
    l = lines!(
        plot, plot.linepoints, color = plot.strokecolor,
        linestyle = plot.linestyle, linewidth = plot.strokewidth,
        inspectable = plot.inspectable, alpha = plot.alpha, visible = plot.visible
    )
    return plot
end
