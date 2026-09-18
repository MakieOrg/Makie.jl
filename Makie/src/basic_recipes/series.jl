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
    filtered_attributes(Lines, exclude = (:cycle,))...
    # TODO: All the scatter attributes should probably work but need to be
    # implemented. May also need a logic rework on the lines-scatterlines switch
    # documented_attributes(Scatter)...

    # TODO: This should probably get updated to rely on colormap + integer colors?
    "Sets a categorical colormap to sample colors per curve."
    color = :lighttest
    "Sets a constant color for all curves. This acts as an overwrite for `color`"
    solid_color = nothing

    "Sets a label per curve. By default, curves are labeled `series \$i`."
    labels = nothing

    # Scatterlines vs Lines
    """
    Sets the marker for scatter. Setting this to a value other than `nothing`
    at construction will include a scatter plot in the visualization.
    """
    marker = nothing
    """
    Sets the markersize for scatter. Setting this to a value other than `nothing`
    at construction will include a scatter plot in the visualization.
    """
    markersize = nothing
    """
    Sets the outline color for scatter markers. Setting this to a value other than
    `nothing` at construction will include a scatter plot in the visualization.
    """
    strokecolor = nothing
    """
    Sets the outline width for scatter markers. Setting this to a value other than
    `nothing` at construction will include a scatter plot in the visualization.
    """
    strokewidth = nothing

    """
    Sets the colors of scatter markers when they are drawn. This defaults to the
    same color that is used for lines.
    """
    markercolor = automatic

    # Value overwrite
    linewidth = 2
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

function convert_arguments(::Type{<:Series}, arg::AbstractVector{<:RealVector})
    return (map(ys -> Point.(eachindex(ys), ys), arg),)
end

function plot!(plot::Series)
    # TODO: Maybe consider doing all of this with a single NaN separated
    # lines or scatterlines plot?

    map!(length, plot, :curves, :nseries)

    map!(plot, [:color, :solid_color, :nseries], :series_color) do color, scolor, N
        if isnothing(scolor)
            return categorical_colors(color, N)
        else
            return scolor
        end
    end

    map!(plot, [:nseries, :labels], :series_labels) do N, labels
        return isnothing(labels) ? ["series $i" for i in 1:N] : labels
    end

    map!(plot, [:marker, :markersize, :strokewidth, :strokecolor], :plottype) do args...
        return all(isnothing, args) ? :Lines : :ScatterLines
    end

    map!(default_automatic, plot, [:markercolor, :series_color], :series_markercolor)

    map!(
        plot,
        [
            :curves, :nseries, :plottype,
            :labels, :series_color, :space, :visible,
            :series_markercolor, :marker, :markersize, :strokecolor, :strokewidth,
            :linewidth, :linecap, :joinstyle, :miter_limit, :linestyle,
        ],
        :specs
    ) do curves, N, plottype, labels, series_color, space, visible,
            series_markercolor, marker, markersize, strokecolor, strokewidth,
            linewidth, linecap, joinstyle, miter_limit, linestyles

        specs = Vector{PlotSpec}(undef, N)
        visible || return specs

        uses_scatter = plottype === :ScatterLines
        scatter_kwargs = Dict{Symbol, Any}()
        if uses_scatter
            for (k, v) in pairs((; marker, markersize, strokewidth, strokecolor))
                if !isnothing(v)
                    scatter_kwargs[k] = v
                end
            end
        end

        broadcast_foreach(
            1:N, curves, labels, series_color, series_markercolor, linestyles
        ) do i, positions, label, color, markercolor, linestyle

            if uses_scatter
                scatter_kwargs[:markercolor] = markercolor
            end

            specs[i] = PlotSpec(
                plottype, positions;
                linewidth, linecap, joinstyle, miter_limit, linestyle,
                color, label, space, scatter_kwargs...
            )
        end

        return specs
    end

    plotlist!(plot, plot.specs)

    return
end

get_plots(plot::Series) = plot.plots[1].plots
