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
In the last case, the distribution type is fitted to the data `y`.

The attribute `qqline` (defaults to `:robust`) determines how to compute a fit line for the Q-Q plot.
Possible values are the following.
- `:identity` draws the identity line.
- `:fit` computes a least squares line fit of the quantile pairs.
- `:robust` computes the line that passes through the first and third quartiles of the distributions.
- `:none` (or any other value) omits drawing the line.
Broadly speaking, `qqline = :identity` is useful to see if `x` and `y` follow the same distribution,
whereas `qqline = :fit` and `qqline = :robust` are useful to see if the distribution of `y` can be
obtained from the distribution of `x` via an affine transformation.

Graphical attributes are
- `color` to control color of both line and markers (if `markercolor` is not specified)
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

Shorthand for `qqplot(Normal(0,1), y)`, i.e., draw a Q-Q plot of `y` against the
standard normal distribution. See `qqplot` for more details.
"""
@recipe(QQNorm) do scene
    default_theme(scene, QQPlot)
end

# Compute points and line for the qqplot
function fit_qqplot(x, y; qqline = :robust)
    h = qqbuild(x, y)
    points = Point2f.(h.qx, h.qy)
    qqline in (:identity, :fit, :robust) || return points, Point2f[]
    xs = collect(extrema(h.qx))
    if qqline == :identity
        ys = xs
    elseif qqline == :fit
        itc, slp = hcat(fill!(similar(h.qx), 1), h.qx) \ h.qy
        ys = @. slp * xs + itc
    else # if qqline == :robust
        quantx, quanty = quantile(x, [0.25, 0.75]), quantile(y, [0.25, 0.75])
        slp = (quanty[2] - quanty[1]) / (quantx[2] - quantx[1])
        ys = @. quanty + slp * (xs - quantx)
    end
    return points, Point2f.(xs, ys)
end

# Fit distribution type, otherwise leave first argument unchanged
maybefit(D::Type{<:Distribution}, y) = Distributions.fit(D, y)
maybefit(x, _) = x

function convert_arguments(::Type{<:QQPlot}, x′, y; qqline = :robust)
    x = maybefit(x′, y)
    points, line = fit_qqplot(x, y; qqline = qqline)
    return PlotSpec{QQPlot}(points, line)
end

convert_arguments(::Type{<:QQNorm}, y; qqline = :robust) =
    convert_arguments(QQPlot, Distributions.Normal(0, 1), y; qqline = qqline)

used_attributes(::Type{<:QQNorm}, y) = (:qqline,)
used_attributes(::Type{<:QQPlot}, x, y) = (:qqline,)

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
