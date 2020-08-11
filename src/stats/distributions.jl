#=
Taken from https://github.com/JuliaPlots/StatsMakie.jl/blob/master/src/typerecipes/distribution.jl
The StatMakie.jl package is licensed under the MIT "Expat" License:
    Copyright (c) 2018: Pietro Vertechi.
=#

# pick a nice default x range given a distribution
function default_range(dist::Distribution, alpha = 0.0001)
    minval = isfinite(minimum(dist)) ? minimum(dist) : quantile(dist, alpha)
    maxval = isfinite(maximum(dist)) ? maximum(dist) : quantile(dist, 1-alpha)
    minval..maxval
end

isdiscrete(::Distribution) = false
isdiscrete(::Distribution{<:VariateForm, <:Discrete}) = true

support(dist::Distribution) = default_range(dist)
support(dist::Distribution{<:VariateForm, <:Discrete}) = UnitRange(endpoints(default_range(dist))...)

convert_arguments(P::PlotFunc, dist::Distribution) = convert_arguments(P, support(dist), dist)

function convert_arguments(P::PlotFunc, x::Union{Interval, AbstractVector}, dist::Distribution)
    default_ptype = isdiscrete(dist) ? ScatterLines : Lines
    ptype = plottype(P, default_ptype)
    to_plotspec(ptype, convert_arguments(ptype, x, x -> pdf(dist, x)))
end
#-----------------------------------------------------------------------------
# qqplots (M. K. Borregaard implementation from StatPlots)

@recipe(QQNorm) do scene
    default_theme(scene, Scatter)
end

@recipe(QQPlot) do scene
    default_theme(scene, Scatter)
end

convert_arguments(::Type{<:QQNorm}, args...; kwargs...) =
    convert_arguments(QQPlot, Distributions.Normal, args...; kwargs...)

convert_arguments(::Type{<:QQPlot}, args...; kwargs...) =
    convert_arguments(Scatter, qqbuild(loc(args...)...); kwargs...)

function convert_arguments(P::PlotFunc, h::QQPair; qqline = :identity)
    line = if qqline in (:fit, :quantile, :identity, :R)
        xs = [extrema(h.qx)...]
        if qqline == :identity
            ys = xs
        elseif qqline == :fit
            itc, slp = hcat(fill!(similar(h.qx), 1), h.qx) \ h.qy
            ys = slp .* xs .+ itc
        else # if qqline == :quantile || qqline == :R
            quantx, quanty = quantile(h.qx, [0.25, 0.75]), quantile(h.qy, [0.25, 0.75])
            slp = diff(quanty) ./ diff(quantx)
            ys = quanty .+ slp .* (xs .- quantx)
        end
        Point{2, Float32}.(xs, ys)
    else
        nothing
    end
    ptype = plottype(Scatter, P)
    PlotSpec{ptype}(h, line)
end

used_attributes(::Type{<:QQNorm}, args...) = (:qqline,)
used_attributes(::Type{<:QQPlot}, args...) = (:qqline,)
used_attributes(::PlotFunc, ::QQPair, args...) = (:qqline,)

function plot!(p::Combined{T, <:Tuple{QQPair, L}}) where {T, L}
    plot!(p, Scatter, Theme(p), lift(h -> Point{2, Float32}.(h.qx, h.qy), p[1]))
    L !== Nothing && plot!(p, LineSegments, Theme(p), p[2])
end

loc(D::Type{T}, x) where T<:Distribution = Distributions.fit(D, x), x
loc(D, x) = D, x