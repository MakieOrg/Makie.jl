function ecdf_xvalues(ecdf::StatsBase.ECDF, npoints)
    x = ecdf.sorted_values
    n = length(x)
    npoints ≥ n && return float(unique(x))
    return @inbounds range(x[1], x[n]; length = npoints)
end

used_attributes(::Type{<:Plot}, ::StatsBase.ECDF) = (:npoints,)
function convert_arguments(P::Type{<:Plot}, ecdf::StatsBase.ECDF; npoints = 10_000)
    ptype = plottype(P, Stairs)
    x0 = ecdf_xvalues(ecdf, npoints)
    if ptype <: Stairs
        kwargs = (; step = :post)
        x1 = x0[1]
        x = [x1 - eps(x1); x0]
    else
        kwargs = NamedTuple()
        x = x0
    end
    return to_plotspec(ptype, convert_arguments(ptype, x, ecdf(x)); kwargs...)
end

function convert_arguments(P::Type{<:Plot}, x::AbstractVector, ecdf::StatsBase.ECDF)
    ptype = plottype(P, Stairs)
    kwargs = ptype <: Stairs ? (; step = :post) : NamedTuple()
    return to_plotspec(ptype, convert_arguments(ptype, x, ecdf(x)); kwargs...)
end

function convert_arguments(P::Type{<:Plot}, x0::AbstractInterval, ecdf::StatsBase.ECDF)
    xmin, xmax = extrema(x0)
    z = ecdf_xvalues(ecdf, Inf)
    n = length(z)
    imin, imax = findfirst(>(xmin), z), findlast(<(xmax), z)
    idx_min = imin === nothing ? n + 1 : imin
    idx_max = imax === nothing ? -1 : imax
    x = [xmin - eps(oftype(z[1], xmin)); xmin; view(z, idx_min:idx_max); xmax]
    return convert_arguments(P, x, ecdf)
end

"""
    ecdfplot(values; npoints=10_000[, weights])

Plot the empirical cumulative distribution function (ECDF) of `values`.

`npoints` controls the resolution of the plot.
If `weights` for the values are provided, a weighted ECDF is plotted.
"""
@recipe ECDFPlot begin
    documented_attributes(Stairs)...
end

used_attributes(::Type{<:ECDFPlot}, ::AbstractVector) = (:npoints, :weights)

function Makie.convert_arguments(
        ::Type{<:ECDFPlot},
        x::AbstractVector;
        npoints = 10_000,
        weights = StatsBase.Weights(Float64[]),
    )
    ecdf = StatsBase.ecdf(x; weights = weights)
    return convert_arguments(Stairs, ecdf; npoints = npoints)
end
