function ecdf_values(ecdf::StatsBase.ECDF, npoints)
    x = ecdf.sorted_values
    n = length(x)
    npoints ≥ n && return unique(x)
    return @inbounds range(x[1], x[n]; length=npoints)
end

function convert_arguments(P::PlotFunc, ecdf::StatsBase.ECDF)
    ptype = plottype(P, Stairs)
    x0 = ecdf_values(ecdf, Inf)
    if ptype <: Stairs
        kwargs = (; step=:post)
        x = [-Inf; x0]
    else
        kwargs = NamedTuple()
        x = x0
    end
    return to_plotspec(ptype, convert_arguments(ptype, x, ecdf); kwargs...)
end
function convert_arguments(P::PlotFunc, x::Union{AbstractVector,Interval}, ecdf::StatsBase.ECDF)
    ptype = plottype(P, Stairs)
    kwargs = ptype <: Stairs ? (; step=:post) : NamedTuple()
    y = x isa AbstractVector ? ecdf(x) : x -> ecdf(x)
    return to_plotspec(ptype, convert_arguments(ptype, x, y); kwargs...)
end

"""
    ecdfplot(values; npoints=10_000[, weights])

Plot the empirical cumulative distribution function (ECDF) of `values`.

`npoints` controls the resolution of the plot.
If `weights` for the values are provided, a weighted ECDF is plotted.

## Attributes
$(ATTRIBUTES)
"""
@recipe(ECDFPlot) do scene
    Theme(;
        default_theme(scene, Stairs)...,
        npoints=10_000,
        weights=StatsBase.Weights(Float64[]), # weights for weighted ECDFs
    )
end

function plot!(p::ECDFPlot{<:Tuple{<:AbstractVector}})
    points = lift(p[1], p.npoints, p.weights) do x, npoints, weights
        ecdf = StatsBase.ecdf(x; weights=weights)
        xnew = [-Inf; ecdf_values(ecdf, npoints)]
        ynew = ecdf(xnew)
        return Point2f0.(xnew, ynew)
    end

    attrs = filter(p -> first(p) ∉ (:npoints, :weights), p.attributes)
    stairs!(p, points; attrs..., step=:post)
    p
end
