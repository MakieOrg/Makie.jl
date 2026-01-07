#=
Taken from https://github.com/MakieOrg/StatsMakie.jl/blob/master/src/typerecipes/distribution.jl
The StatMakie.jl package is licensed under the MIT "Expat" License:
    Copyright (c) 2018: Pietro Vertechi. =#

# pick a nice default x range given a distribution
function default_range(dist::Distribution, alpha = 0.0001)
    minval = isfinite(minimum(dist)) ? minimum(dist) : quantile(dist, alpha)
    maxval = isfinite(maximum(dist)) ? maximum(dist) : quantile(dist, 1 - alpha)
    return minval .. maxval
end

isdiscrete(::Distribution) = false
isdiscrete(::Distribution{<:VariateForm, <:Discrete}) = true

support(dist::Distribution) = default_range(dist)
support(dist::Distribution{<:VariateForm, <:Discrete}) = UnitRange(endpoints(default_range(dist))...)

convert_arguments(P::Type{<:AbstractPlot}, dist::Distribution) = convert_arguments(P, support(dist), dist)

function convert_arguments(P::Type{<:AbstractPlot}, x::Union{Interval, AbstractVector}, dist::Distribution)
    default_ptype = isdiscrete(dist) ? ScatterLines : Lines
    ptype = plottype(P, default_ptype)
    return to_plotspec(ptype, convert_arguments(ptype, x, x -> pdf(dist, x)))
end
# -----------------------------------------------------------------------------
# qqplots (M. K. Borregaard implementation from StatPlots)

"""
    qqplot(x, y; kwargs...)
    qqplot(y; distribution, kwargs...)

Draw a Q-Q plot, comparing quantiles of two distributions. `y` must be a list of
samples, i.e., `AbstractVector{<:Real}`, whereas `x` can be
- a list of samples,
- an abstract distribution, e.g. `Normal(0, 1)`,
- a distribution type, e.g. `Normal`.
In the last case, the distribution type is fitted to the data `y`.

If only one positional argument is given, this must be a vector `y` and the distribution
to use or distribution type to fit must be given as the keyword argument `distribution`.

The attribute `qqline` (defaults to `:none`) determines how to compute a fit line for the Q-Q plot.
Possible values are the following.
- `:identity` draws the identity line.
- `:fit` computes a least squares line fit of the quantile pairs.
- `:fitrobust` computes the line that passes through the first and third quartiles of the distributions.
- `:none` omits drawing the line.
Broadly speaking, `qqline = :identity` is useful to see if `x` and `y` follow the same distribution,
whereas `qqline = :fit` and `qqline = :fitrobust` are useful to see if the distribution of `y` can be
obtained from the distribution of `x` via an affine transformation.
"""
@recipe QQPlot begin
    filtered_attributes(ScatterLines, exclude = (:joinstyle, :miter_limit))...
end

"""
    qqnorm(y; kwargs...)

Shorthand for `qqplot(Normal(0,1), y)`, i.e., draw a Q-Q plot of `y` against the
standard normal distribution. See `qqplot` for more details.
"""
@recipe QQNorm begin
    documented_attributes(QQPlot)...
end

# Compute points and line for the qqplot
function fit_qqplot(x, y; qqline = :none)
    if !(qqline in (:identity, :fit, :fitrobust, :none))
        msg = "valid values for qqline are :identity, :fit, :fitrobust or :none, " *
            "encountered " * repr(qqline)
        throw(ArgumentError(msg))
    end
    h = qqbuild(x, y)
    points = Point2f.(h.qx, h.qy)
    qqline === :none && return points, Point2f[]
    xs = collect(extrema(h.qx))
    if qqline === :identity
        ys = xs
    elseif qqline === :fit
        itc, slp = hcat(fill!(similar(h.qx), 1), h.qx) \ h.qy
        ys = @. slp * xs + itc
    else # if qqline === :fitrobust
        quantx, quanty = quantile.(Ref(x), [0.25, 0.75]), quantile.(Ref(y), [0.25, 0.75])
        slp = (quanty[2] - quanty[1]) / (quantx[2] - quantx[1])
        ys = @. quanty + slp * (xs - quantx)
    end
    return points, Point2f.(xs, ys)
end

# Fit distribution type, otherwise leave first argument unchanged
maybefit(D::Type{<:Distribution}, y) = Distributions.fit(D, y)
maybefit(x, _) = x

function convert_arguments(
        ::Type{<:QQPlot}, points::AbstractVector{<:Point2},
        lines::AbstractVector{<:Point2}; qqline = :none
    )
    return (points, lines)
end

function convert_arguments(::Type{<:QQPlot}, x′, y; qqline = :none)
    x = maybefit(x′, y)
    points, line = fit_qqplot(x, y; qqline = qqline)
    return (points, line)
end

function convert_arguments(::Type{<:QQPlot}, y; qqline = :none, distribution = nothing)
    if distribution === nothing
        throw(ArgumentError("When calling QQPlot with a single array argument, the `distribution` keyword argument must be provided"))
    end
    x = maybefit(distribution, y)
    points, line = fit_qqplot(x, y; qqline = qqline)
    return (points, line)
end

convert_arguments(::Type{<:QQNorm}, y; qqline = :none) =
    convert_arguments(QQPlot, Distributions.Normal(0, 1), y; qqline = qqline)

used_attributes(::Type{<:QQNorm}, y) = (:qqline,)
used_attributes(::Type{<:QQPlot}, x, y) = (:qqline,)
used_attributes(::Type{<:QQPlot}, y) = (:qqline, :distribution)

plottype(::Type{<:QQNorm}, args...) = QQPlot
plottype(::Type{<:QQNorm}, ::Type{Plot{plot}}) = QQNorm # resolve ambiguity hit in AlgebraOfGraphics

function Makie.plot!(p::QQPlot)
    map!(default_automatic, p, [:markercolor, :color], :real_markercolor)
    map!(default_automatic, p, [:markercolormap, :colormap], :real_markercolormap)
    map!(default_automatic, p, [:markercolorrange, :colorrange], :real_markercolorrange)

    scatter!(
        p, Attributes(p), p[1];
        color = p.real_markercolor,
        colormap = p.real_markercolormap,
        colorrange = p.real_markercolorrange,
    )
    linesegments!(p, Attributes(p), p[2])

    return p
end
