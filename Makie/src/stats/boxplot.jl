notchheight(q2, q4, N) = 1.58 * (q4 - q2) / sqrt(N)

#=
Taken from https://github.com/MakieOrg/StatPlots.jl/blob/master/src/boxplot.jl#L7
The StatPlots.jl package is licensed under the MIT "Expat" License:
    Copyright (c) 2016: Thomas Breloff.
=#
"""
    boxplot(x, y; kwargs...)

Draw a Tukey style boxplot.The boxplot has 3 components:
- a `crossbar` spanning the interquartile (IQR) range (values from the 25th to
the 75% percentile) with a midline marking the median
- an `errorbar` including values from the interquartile range extended by `range * iqr`
- points marking outliers, that is, data outside the errorbar

## Arguments
- `x`: positions of the categories
- `y`: variables within the boxes
"""
@recipe BoxPlot (x, y) begin
    filtered_attributes(CrossBar, exclude = (:notchmin, :notchmax, :show_midline, :midlinecolor, :midlinewidth))...

    "Vector of statistical weights (length of data). By default, each observation has weight `1`."
    weights = automatic

    # median line
    "Shows the median as the midline of the crossbar."
    show_median = true
    "Sets the color of median line."
    mediancolor = @inherit linecolor
    "Sets the width of the median line."
    medianlinewidth = @inherit linewidth

    # whiskers
    """
    Sets how far the errorbar range expands beyond the interquartile range as a
    multiple of it. The final value range for errorbars is `Q2 - range * (Q4 - Q2)`
    to `Q4 + range * (Q4 - Q2)` where `Q2` and `Q4` include 25% and 75% of the
    values respectively.
    Setting to 0 extends whiskers to the range of the data.
    """
    range = 1.5
    "Sets the width of whiskers on errorbars as a multiplier of the crossbar width."
    whiskerwidth = 0.0
    "Sets the color of errorbars."
    whiskercolor = @inherit linecolor
    "Sets the linewidth of errorbars."
    whiskerlinewidth = @inherit linewidth

    # outliers points
    "Show outliers as points. Any point outside the errorbars is consider one."
    show_outliers = true
    "Sets the marker for outliers."
    marker = @inherit marker
    "Sets the markersize for outliers."
    markersize = @inherit markersize
    "Sets the color for outliers."
    outliercolor = automatic
    "Sets the marker strokecolor for outliers."
    outlierstrokecolor = @inherit markerstrokecolor
    "Sets the marker strokewidth for outliers."
    outlierstrokewidth = @inherit markerstrokewidth
end

conversion_trait(x::Type{<:BoxPlot}) = SampleBased()

_cycle(v::AbstractVector, idx::Integer) = v[mod1(idx, length(v))]
_cycle(v, idx::Integer) = v

flip_xy(p::Point2f) = reverse(p)
flip_xy(r::Rect{2, T}) where {T} = Rect{2, T}(reverse(r.origin), reverse(r.widths))

function Makie.plot!(plot::BoxPlot)

    map!(
        compute_x_and_width, plot,
        [:x, :width, :gap, :dodge, :n_dodge, :dodge_gap],
        [:x̂, :widths]
    )

    map!(StructArrays.finduniquesorted, plot, :x̂, :groups)

    map!(plot, :groups, :centers) do groups
        return Float32[center for (center, _) in groups]
    end

    map!(plot, [:y, :weights, :groups], [:quantiles, :Ns]) do y, weights, groups
        quantiles = Vector{Float64}[]
        Ns = Int64[]
        for (_, idxs) in groups
            values = view(y, idxs)
            w = weights === automatic ? () : (StatsBase.weights(view(weights, idxs)),)
            push!(quantiles, quantile(values, w..., LinRange(0, 1, 5)))
            push!(Ns, length(values))
        end
        return quantiles, Ns
    end

    map!(plot, [:quantiles, :Ns, :show_notch], [:notchmin, :notchmax]) do quantiles, Ns, show_notch
        if show_notch
            notchmin, notchmax = Float32[], Float32[]
            for (q, N) in zip(quantiles, Ns)
                _, q2, q3, q4, _ = q
                nh = notchheight(q2, q4, N)
                push!(notchmin, q3 - nh)
                push!(notchmax, q3 + nh)
            end
            return notchmin, notchmax
        else
            return automatic, automatic
        end
    end

    map!(
        plot,
        [:y, :groups, :quantiles, :range, :show_outliers, :orientation],
        [:outlier_points, :outlier_indices, :q1s, :q5s]
    ) do y, groups, quantiles, range, show_outliers, orientation
        outlier_points, outlier_indices = Point2f[], Int[]
        q1s, q5s = Float32[], Float32[]
        for (q, (center, idxs)) in zip(quantiles, groups)
            q1, q2, _, q4, q5 = q
            values = view(y, idxs)
            if !iszero(range)
                limit = range * (q4 - q2)
                inside = Float64[]
                for (value, idx) in zip(values, idxs)
                    if (value < (q2 - limit)) || (value > (q4 + limit))
                        if show_outliers
                            pt = orientation === :horizontal ? (value, center) : (center, value)
                            push!(outlier_points, pt)
                            push!(outlier_indices, idx)
                        end
                    else
                        push!(inside, value)
                    end
                end
                # change q1 and q5 to show outliers using maximum and minimum values inside the limits
                q1, q5 = extrema_nan(inside)
            end
            push!(q1s, q1)
            push!(q5s, q5)
        end
        return outlier_points, outlier_indices, q1s, q5s
    end

    map!(
        plot,
        [:groups, :widths, :q1s, :quantiles, :q5s, :whiskerwidth, :orientation],
        [:t_segments, :boxwidth]
    ) do groups, widths, q1s, quantiles, q5s, whiskerwidth, orientation
        whiskerwidth = ifelse(whiskerwidth === :match, 1.0, whiskerwidth)
        if !(whiskerwidth isa Real) || !(whiskerwidth >= 0)
            error("whiskerwidth must be :match or a positive number. Found: $whiskerwidth")
        end
        t_segments = Point2f[]
        WT = widths isa AbstractVector ? eltype(widths) : typeof(widths)
        boxwidth = WT[]
        for ((center, idxs), q1, q, q5) in zip(groups, q1s, quantiles, q5s)
            bw = getuniquevalue(widths, idxs)
            ww = whiskerwidth * bw
            lw, rw = center - ww / 2, center + ww / 2
            push!(boxwidth, bw)
            push!(
                t_segments,
                (center, q[2]), (center, q1), (lw, q1), (rw, q1), # lower T
                (center, q[4]), (center, q5), (rw, q5), (lw, q5), # upper T
            )
        end
        if orientation === :horizontal
            t_segments = flip_xy.(t_segments)
        elseif orientation !== :vertical
            error("Invalid orientation $orientation. Valid options: :horizontal or :vertical.")
        end
        return t_segments, boxwidth
    end

    map!(plot, [:color, :groups], :boxcolor) do color, groups
        return [getuniquevalue(color, idxs) for (_, idxs) in groups]
    end

    map!(plot, :quantiles, [:boxmin, :medians, :boxmax]) do quantiles
        boxmin = getindex.(quantiles, 2)
        medians = getindex.(quantiles, 3)
        boxmax = getindex.(quantiles, 4)
        return boxmin, medians, boxmax
    end

    map!(plot, [:outliercolor, :color, :outlier_indices], :outlier_color) do outliercolor, color, outlier_indices
        c = outliercolor === automatic ? color : outliercolor
        return c isa AbstractVector ? c[outlier_indices] : c
    end

    scatter!(
        plot,
        plot.outlier_points,
        color = plot.outlier_color,
        marker = plot.marker,
        markersize = plot.markersize,
        strokecolor = plot.outlierstrokecolor,
        strokewidth = plot.outlierstrokewidth,
        inspectable = plot.inspectable,
        # if only one group has outliers, the colorrange will be width 0 otherwise, if it's not an array, it shouldn't matter
        colorrange = plot.boxcolor isa AbstractArray{<:Real} ? extrema(plot.boxcolor) : automatic,
        visible = plot.visible,
    )
    linesegments!(
        plot,
        plot.t_segments,
        color = plot.whiskercolor,
        linewidth = plot.whiskerlinewidth,
        inspectable = plot.inspectable,
        visible = plot.visible
    )
    crossbar!(
        plot, Attributes(plot),
        plot.centers, plot.medians, plot.boxmin, plot.boxmax,
        gap = 0, color = plot.boxcolor, width = plot.boxwidth,
        show_midline = plot.show_median, midlinecolor = plot.mediancolor, midlinewidth = plot.medianlinewidth,
        # These should not be passed/defaulted
        n_dodge = automatic, dodge = automatic
    )
    return plot
end
