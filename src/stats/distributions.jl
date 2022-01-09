#=
Taken from https://github.com/JuliaPlots/StatsMakie.jl/blob/master/src/typerecipes/distribution.jl
The StatMakie.jl package is licensed under the MIT "Expat" License:
    Copyright (c) 2018: Pietro Vertechi. =#

# pick a nice default x range given a distribution
function default_range(dist::Distribution, alpha=0.0001)
    minval = isfinite(minimum(dist)) ? minimum(dist) : quantile(dist, alpha)
    maxval = isfinite(maximum(dist)) ? maximum(dist) : quantile(dist, 1 - alpha)
    minval..maxval
end

isdiscrete(::Distribution) = false
isdiscrete(::Distribution{<:VariateForm,<:Discrete}) = true

support(dist::Distribution) = default_range(dist)
support(dist::Distribution{<:VariateForm,<:Discrete}) = UnitRange(endpoints(default_range(dist))...)

convert_arguments(P::PlotFunc, dist::Distribution) = convert_arguments(P, support(dist), dist)

function convert_arguments(P::PlotFunc, x::Union{Interval,AbstractVector}, dist::Distribution)
    default_ptype = isdiscrete(dist) ? ScatterLines : Lines
    ptype = plottype(P, default_ptype)
    to_plotspec(ptype, convert_arguments(ptype, x, x -> pdf(dist, x)))
end
# -----------------------------------------------------------------------------
# qqplots (M. K. Borregaard implementation from StatPlots)

"""
    qqplot(x, y; kwargs...)
Draw a Q-Q plot, comparing quantiles of two distributions. `y` must be a list of
samples, i.e., `AbstractVector{<:Real}`, whereas `x` can be
- a list of samples,
- an abstract distribution, e.g. `Normal(0, 1)`,
- a distribution type, e.g. `Normal`.
In the last case, the Q-Q plot by fitting that distribution type to the data `y`.

The attribute `qqline` determines how to compute a fit line for the Q-Q plot.
Possible values are the following.
- `:identity` draws the identity line (useful to see if the two distributions are the same).
- `:fit` fits the line to the quantile pairs (useful to see if one distribution can be obtained for the other via an affine transformation).
- `:quantile` is analogous to `:fit` but uses a quantile-based fitting method.
- `:R` is an alias for `:quantile`, as that is the default behavior in `:R`.
- `:none` (or any other value) omits drawing the line.

Graphical attributes are
- `color` to control color of both line and markers
- `linestyle`
- `linewidth`
- `markercolor`
- `strokecolor`
- `strokewidth`
- `marker`
- `markersize`
"""
@recipe(QQPlot) do scene
    s_theme = default_theme(scene, Scatter)
    l_theme = default_theme(scene, Lines)
    Attributes(
        color = l_theme.color,
        linestyle = l_theme.linestyle,
        linewidth = l_theme.linewidth,
        markercolor = automatic,
        markersize = s_theme.markersize,
        strokecolor = s_theme.strokecolor,
        strokewidth = s_theme.strokewidth,
        marker = s_theme.marker,
        inspectable = theme(scene, :inspectable),
        cycle = [:color],
    )
end

"""
    qqnorm(y; kwargs...)

Shorthand for `qqplot(Normal, y)`. See [`qqplot`](@ref) for more details.
"""
@recipe(QQNorm) do scene
    default_theme(scene, QQPlot)
end

function fit_qqline(h::QQPair; qqline = :identity)
    if qqline in (:fit, :quantile, :identity, :R)
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
        return Point2f.(xs, ys)
    else
        return Point2f[]
    end
end

loc(D::Type{T}, x) where T <: Distribution = Distributions.fit(D, x), x
loc(D, x) = D, x

function convert_arguments(::Type{<:QQPlot}, x, y; qqline = :identity)
    h = qqbuild(loc(x, y)...)
    points = Point2f.(h.qx, h.qy)
    line = fit_qqline(h; qqline = qqline)
    return PlotSpec{QQPlot}(points, line)
end

convert_arguments(::Type{<:QQNorm}, y; qqline = :identity) =
    convert_arguments(QQPlot, Distributions.Normal(0, 1), y; qqline = qqline)

convert_arguments(::PlotFunc, h::QQPair; qqline = :identity) =
    convert_arguments(QQPlot, h.qx, h.qy; qqline = qqline)

used_attributes(::Type{<:QQNorm}, y) = (:qqline,)
used_attributes(::Type{<:QQPlot}, x, y) = (:qqline,)
used_attributes(::PlotFunc, ::QQPair) = (:qqline,)

function plot!(p::QQPlot)
    points, line = p[1], p[2]
    real_markercolor = lift(Any, p.color, p.markercolor) do color, markercolor
        markercolor === automatic ? color : markercolor
    end
    scatter!(p, points;
        color = real_markercolor,
        strokecolor = p.strokecolor,
        strokewidth = p.strokewidth,
        marker = p.marker,
        markersize = p.markersize,
        inspectable = p.inspectable
    )
    linesegments!(p, line;
        color = p.color,
        linestyle = p.linestyle,
        linewidth = p.linewidth,
        inspectable = p.inspectable
    )
end
