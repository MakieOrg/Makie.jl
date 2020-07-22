const histogram_plot_types = [BarPlot, Heatmap, Volume]

function convert_arguments(P::Type{<:AbstractPlot}, h::StatsBase.Histogram{<:Any, N}) where N
    ptype = plottype(P, histogram_plot_types[N])
    f(edges) = edges[1:end-1] .+ diff(edges)./2
    kwargs = N == 1 ? (; width = step(h.edges[1])) : NamedTuple()
    to_plotspec(ptype, convert_arguments(ptype, map(f, h.edges)..., Float64.(h.weights)); kwargs...)
end

"""
    histogram(values; bins = 15, normalization = :none)

Plot a histogram of `values`. `bins` can be an `Int` to create that
number of equal-width bins over the range of `values`.
Alternatively, it can be a sorted iterable of bin edges. The histogram
can be normalized by setting `normalization`. Possible values are:

*  `:pdf`: Normalize by sum of weights and bin sizes. Resulting histogram
   has norm 1 and represents a PDF.
* `:density`: Normalize by bin sizes only. Resulting histogram represents
   count density of input and does not have norm 1. Will not modify the
   histogram if it already represents a density (`h.isdensity == 1`).
* `:probability`: Normalize by sum of weights only. Resulting histogram
   represents the fraction of probability mass for each bin and does not have
   norm 1.
*  `:none`: Do not normalize.

## Attributes
$(ATTRIBUTES)
"""
@recipe(Histogram, values) do scene
    Attributes(
        bins = 15, # Int or iterable of edges
        normalization = :none
    )
end

function AbstractPlotting.plot!(plot::Histogram)

    values = plot[:values]

    edges = lift(values, plot.bins) do vals, bins
        if bins isa Int
            mi, ma = float.(extrema(vals))
            ma = nextfloat(ma) # hist is right-open, so to include the upper data point, make the last bin a tiny bit bigger
            return range(mi, ma, length = bins+1)
        else
            if !issorted(bins)
                error("Histogram bins are not sorted: $bins")
            end
            return bins
        end
    end

    points = lift(edges, plot.normalization) do edges, normalization
        h = StatsBase.fit(StatsBase.Histogram, values[], edges)
        h_norm = StatsBase.normalize(h, mode = normalization)
        centers = edges[1:end-1] .+ (diff(edges) ./ 2)
        weights = h_norm.weights
        return Point2f0.(centers, weights)
    end

    widths = lift(diff, edges)

    # plot the values, not the observables, to be in control of updating
    bp = barplot!(plot, points[]; width = widths[], plot.attributes...).plots[1]


    # update the barplot points without triggering, then trigger with `width`
    on(widths) do w
        bp[1].val = points[]
        bp.width = w
    end

    plot
end
