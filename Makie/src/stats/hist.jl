const histogram_plot_types = (BarPlot, Heatmap, Volume)

function convert_arguments(P::Type{<:AbstractPlot}, h::StatsBase.Histogram{<:Any, N}) where {N}
    ptype = plottype(P, histogram_plot_types[N])
    f(edges) = edges[1:(end - 1)] .+ diff(edges) ./ 2
    kwargs = N == 1 ? (; width = step(h.edges[1]), gap = 0, dodge_gap = 0) : NamedTuple()
    return to_plotspec(ptype, convert_arguments(ptype, map(f, h.edges)..., Float64.(h.weights)); kwargs...)
end

function _hist_center_weights(values, edges, normalization, scale_to, wgts)
    isempty(edges) && return Float64[], Float64[]
    w = wgts === automatic ? () : (StatsBase.weights(wgts),)
    h = StatsBase.fit(StatsBase.Histogram, values, w..., edges)
    h_norm = StatsBase.normalize(h; mode = normalization)
    weights = h_norm.weights
    centers = edges[1:(end - 1)] .+ (diff(edges) ./ 2)
    if scale_to === :flip
        weights .= -weights
    elseif !isnothing(scale_to)
        max = maximum(weights)
        weights .= weights ./ max .* scale_to
    end
    return centers, weights
end

"""
    stephist(values)

Plot a step histogram of `values`.
"""
@recipe StepHist (values,) begin
    documented_attributes(Stairs)...

    """
    Sets the number of bins if set to an integer or the edges of bins if set to
    an sorted collection of real numbers.
    """
    bins = 15 # Int or iterable of edges
    """
    Sets the normalization applied to the histogram. Possible values are:

    * `:pdf`: Normalize by sum of weights and bin sizes. Resulting histogram
      has norm 1 and represents a probability density function.
    * `:density`: Normalize by bin sizes only. Resulting histogram represents
      count density of input and does not have norm 1. Will not modify the
      histogram if it already represents a density (`h.isdensity == 1`).
    * `:probability`: Normalize by sum of weights only. Resulting histogram
      represents the fraction of probability mass for each bin and does not have
      norm 1.
    * `:none`: Do not normalize.
    """
    normalization = :none
    "Sets optional statistical weights."
    weights = automatic
    "Scales the histogram by a common factor such that the largest bin reaches the given value."
    scale_to = nothing
end

function plot!(plot::StepHist)

    map!(pick_hist_edges, plot, [:values, :bins], :edges)

    map!(plot, [:values, :edges, :normalization, :scale_to, :weights], :points) do values, edges, normalization, scale_to, wgts
        isempty(edges) && return Point2d[]
        _, weights = _hist_center_weights(values, edges, normalization, scale_to, wgts)
        phantomedge = edges[end] # to bring step back to baseline
        edges = vcat(edges, phantomedge)
        z = zero(eltype(weights))
        heights = vcat(z, weights, z)
        return Point2.(edges, heights)
    end

    map!(plot, [:points, :color], :computed_colors) do points, color
        return color === :values ? last.(points) : color
    end

    stairs!(plot, Attributes(plot), plot.points; color = plot.computed_colors)
    return plot
end

"""
    hist(values)

Plot a histogram of `values`.
"""
@recipe Hist (values,) begin
    """
    Sets the number of bins if set to an integer or the edges of bins if set to
    an sorted collection of real numbers.
    """
    bins = 15
    """
    Sets the normalization applied to the histogram. Possible values are:

    *  `:pdf`: Normalize by sum of weights and bin sizes. Resulting histogram
       has norm 1 and represents a probability density function.
    * `:density`: Normalize by bin sizes only. Resulting histogram represents
       count density of input and does not have norm 1. Will not modify the
       histogram if it already represents a density (`h.isdensity == 1`).
    * `:probability`: Normalize by sum of weights only. Resulting histogram
       represents the fraction of probability mass for each bin and does not have
       norm 1.
    *  `:none`: Do not normalize.
    """
    normalization = :none
    "Sets optional statistical weights."
    weights = automatic
    """
    Scales the histogram by a common factor such that the largest bin reaches the
    given value. This can also be set to `:flip` to flip the direction of histogram
    bars without scaling them.
    """
    scale_to = nothing

    filtered_attributes(
        BarPlot, exclude = (
            :dodge, :n_dodge, :dodge_gap, :stack, :width,
            :color_over_background, :color_over_bar, # renamed here :(
        )
    )...
    "Sets the gap between bars relative to their width. The new width is `w * (1 - gap)`."
    gap = 0
    "Sets the color of labels that are drawn outside of bars. Defaults to `label_color`"
    over_background_color = automatic
    "Sets the color of labels that are drawn inside of/over bars. Defaults to `label_color`"
    over_bar_color = automatic
end

function pick_hist_edges(vals, bins)
    isempty(vals) && return 1.0:0.0
    if bins isa Int
        mi, ma = float.(extrema(vals))
        if mi == ma
            return (mi - 0.5):(ma + 0.5)
        end
        # hist is right-open, so to include the upper data point, make the last bin a tiny bit bigger
        ma = nextfloat(ma)
        return range(mi, ma, length = bins + 1)
    else
        if !issorted(bins)
            error("Histogram bins are not sorted: $bins")
        end
        return bins
    end
end

function plot!(plot::Hist)

    map!(pick_hist_edges, plot, [:values, :bins], :edges)

    map!(plot, [:values, :edges, :normalization, :scale_to, :weights], :points) do values, edges, normalization, scale_to, wgts
        centers, weights = _hist_center_weights(values, edges, normalization, scale_to, wgts)
        return Point2.(centers, weights)
    end

    map!(diff, plot, :edges, :widths)
    map!(plot, [:points, :color], :computed_colors) do points, color
        return color === :values ? last.(points) : color
    end

    map!(plot, :bar_labels, :computed_bar_labels) do x
        return x === :values ? :y : x
    end

    # plot the values, not the observables, to be in control of updating
    barplot!(
        plot, Attributes(plot), plot.points;
        bar_labels = plot.computed_bar_labels, color = plot.computed_colors
    )

    return plot
end
