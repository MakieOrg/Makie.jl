"""
    series(curves)

Curves can be:
* `AbstractVector{<: AbstractVector{<: Point2}}`: the native representation of a series as a vector of lines
* `AbstractMatrix`: each row represents y coordinates of the line, while `x` goes from `1:size(curves, 1)`
* `AbstractVector, AbstractMatrix`: the same as the above, but the first argument sets the x values for all lines
* `AbstractVector{<: Tuple{X<: AbstractVector, Y<: AbstractVector}}`: A vector of tuples, where each tuple contains a vector for the x and y coordinates

If any of `marker`, `markersize`, `markercolor`, `strokecolor` or `strokewidth` is set != nothing, a scatterplot is added.
"""
@recipe Series (curves::AbstractVector{<:Union{BezierPath, AbstractVector{<:Point}}},) begin
    linewidth = 2
    color = :lighttest
    solid_color = nothing
    labels = nothing
    linestyle = :solid
    linecap = @inherit linecap
    joinstyle = @inherit joinstyle
    miter_limit = @inherit miter_limit
    marker = nothing
    markersize = nothing
    markercolor = automatic
    strokecolor = nothing
    strokewidth = nothing
    space = :data
end

replace_missing(x) = ismissing(x) ? NaN : x

function convert_arguments(T::Type{<:Series}, y::RealMatrix)
    return convert_arguments(T, 1:size(y, 2), y)
end

function convert_arguments(::Type{<:Series}, x::RealVector, ys::RealMatrix)
    T = float_type(x, ys)
    return (
        map(1:size(ys, 1)) do i
            Point2{T}.(replace_missing.(x), replace_missing.(view(ys, i, :)))
        end,
    )
end

function convert_arguments(
        ::Type{<:Series},
        arg::AbstractVector{<:Tuple{X, Y}}
    ) where {X <: RealVector, Y <: RealVector}
    # TODO: is this problematic with varying tuple types?
    return (
        map(arg) do (x, y)
            T = float_type(x, y)
            Point2{T}.(replace_missing.(x), replace_missing.(y))
        end,
    )
end

function convert_arguments(T::Type{<:Series}, arg::Tuple{<:RealVector, <:RealVector})
    return convert_arguments(T, [arg])
end

function convert_arguments(::Type{<:Series}, arg::AbstractVector{<:AbstractVector{<:Point2}})
    return (
        map(arg) do points
            T = float_type(points)
            T.(replace_missing.(first.(points)), replace_missing.(last.(points)))
        end,
    )
end

function plot!(plot::Series)
    @extract plot (curves, labels, linewidth, linecap, joinstyle, miter_limit, color, solid_color, space, linestyle)
    sargs = [:marker, :markersize, :strokecolor, :strokewidth]
    scatter = Dict((f => plot[f] for f in sargs if !isnothing(plot[f][])))
    nseries = length(curves[])
    colors = lift(plot, color, solid_color) do color, scolor
        if isnothing(scolor)
            return categorical_colors(color, nseries)
        else
            return scolor
        end
    end
    # TODO if nseries = 0, we get a nasty Backend error that there is no overload for Series{...}
    # since series.plots will be empty, which is currently the distinguishing factor for atomic vs not atomic
    for i in 1:nseries
        label = lift(l -> isnothing(l) ? "series $(i)" : l[i], plot, labels)
        positions = lift(c -> c[i], plot, curves)
        series_color = lift(c -> c isa AbstractVector ? c[i] : c, plot, colors)
        series_linestyle = lift(ls -> ls isa AbstractVector ? ls[i] : ls, plot, linestyle)
        if !isempty(scatter)
            mcolor = plot.markercolor
            markercolor = lift((mc, sc) -> mc == automatic ? sc : mc, plot, mcolor, series_color)
            scatterlines!(
                plot, positions;
                linewidth = linewidth, linecap = plot.linecap, joinstyle = joinstyle,
                miter_limit = miter_limit, color = series_color, markercolor = series_color,
                label = label[], scatter..., space = space, linestyle = series_linestyle
            )
        else
            lines!(
                plot, positions; linewidth = linewidth, linecap = plot.linecap,
                joinstyle = joinstyle, miter_limit = miter_limit, color = series_color,
                label = label, space = space, linestyle = series_linestyle
            )
        end
    end
    return
end

function Makie.get_plots(plot::Series)
    return plot.plots
end
