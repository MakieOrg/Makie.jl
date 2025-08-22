const histogram_plot_types = (BarPlot, Heatmap, Volume)

function convert_arguments(P::Type{<:AbstractPlot}, h::StatsBase.Histogram{<:Any, N}) where {N}
    ptype = plottype(P, histogram_plot_types[N])
    f(edges) = edges[1:(end - 1)] .+ diff(edges) ./ 2
    kwargs = N == 1 ? (; width = step(h.edges[1]), gap = 0, dodge_gap = 0) : NamedTuple()
    return to_plotspec(ptype, convert_arguments(ptype, map(f, h.edges)..., Float64.(h.weights)); kwargs...)
end

function _hist_center_weights(values, edges, normalization, scale_to, wgts)
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
    "Can be an `Int` to create that number of equal-width bins over the range of `values`. Alternatively, it can be a sorted iterable of bin edges."
    bins = 15 # Int or iterable of edges
    """Allows to apply a normalization to the histogram.
    Possible values are:

    * `:pdf`: Normalize by sum of weights and bin sizes. Resulting histogram
      has norm 1 and represents a PDF.
    * `:density`: Normalize by bin sizes only. Resulting histogram represents
      count density of input and does not have norm 1. Will not modify the
      histogram if it already represents a density (`h.isdensity == 1`).
    * `:probability`: Normalize by sum of weights only. Resulting histogram
      represents the fraction of probability mass for each bin and does not have
      norm 1.
    * `:none`: Do not normalize.
    """
    normalization = :none
    "Allows to provide statistical weights."
    weights = automatic
    cycle = [:color => :patchcolor]
    color = @inherit patchcolor
    linewidth = @inherit linewidth
    linestyle = :solid
    "Allows to scale all values to a certain height."
    scale_to = nothing
end

function Makie.plot!(plot::StepHist)

    map!(pick_hist_edges, plot, [:values, :bins], :edges)

    map!(plot, [:values, :edges, :normalization, :scale_to, :weights], :points) do values, edges, normalization, scale_to, wgts
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
    Can be an `Int` to create that number of equal-width bins over the range of `values`. Alternatively, it can be a sorted iterable of bin edges.
    """
    bins = 15
    """
    Allows to normalize the histogram. Possible values are:

    *  `:pdf`: Normalize by sum of weights and bin sizes. Resulting histogram
       has norm 1 and represents a PDF.
    * `:density`: Normalize by bin sizes only. Resulting histogram represents
       count density of input and does not have norm 1. Will not modify the
       histogram if it already represents a density (`h.isdensity == 1`).
    * `:probability`: Normalize by sum of weights only. Resulting histogram
       represents the fraction of probability mass for each bin and does not have
       norm 1.
    *  `:none`: Do not normalize.
    """
    normalization = :none
    "Allows to statistically weight the observations."
    weights = automatic
    cycle = [:color => :patchcolor]
    """
    Color can either be:
    * a vector of `bins` colors
    * a single color
    * `:values`, to color the bars with the values from the histogram
    """
    color = @inherit patchcolor
    strokewidth = @inherit patchstrokewidth
    strokecolor = @inherit patchstrokecolor
    "Adds an offset to every value."
    offset = 0.0
    "Defines where the bars start."
    fillto = automatic
    """
    Allows to scale all values to a certain height. This can also be set to
    `:flip` to flip the direction of histogram bars without scaling them to a
    common height.
    """
    scale_to = nothing
    bar_labels = nothing
    flip_labels_at = Inf
    label_color = @inherit textcolor
    over_background_color = automatic
    over_bar_color = automatic
    label_offset = 5
    label_font = @inherit font
    label_size = 20
    label_formatter = bar_label_formatter
    "Set the direction of the bars."
    direction = :y
    "Gap between the bars (see barplot)."
    gap = 0
end

function pick_hist_edges(vals, bins)
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

function Makie.plot!(plot::Hist)

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
        plot, Attributes(plot), plot.points; width = plot.widths, fillto = plot.fillto,
        offset = plot.offset, bar_labels = plot.computed_bar_labels, color = plot.computed_colors
    )

    return plot
end
