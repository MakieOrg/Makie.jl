notchheight(q2, q4, N) = 1.58 * (q4 - q2) / sqrt(N)

#=
Taken from https://github.com/MakieOrg/StatPlots.jl/blob/master/src/boxplot.jl#L7
The StatPlots.jl package is licensed under the MIT "Expat" License:
    Copyright (c) 2016: Thomas Breloff.
=#
"""
    boxplot(x, y; kwargs...)
Draw a Tukey style boxplot.
The boxplot has 3 components:
- a `crossbar` spanning the interquartile (IQR) range with a midline marking the
    median
- an `errorbar` whose whiskers span `range * iqr`
- points marking outliers, that is, data outside the whiskers
## Arguments
- `x`: positions of the categories
- `y`: variables within the boxes
"""
@recipe BoxPlot (x, y) begin
    "Vector of statistical weights (length of data). By default, each observation has weight `1`."
    weights = automatic
    color = @inherit patchcolor
    colormap = @inherit colormap
    colorscale = identity
    colorrange = automatic
    "Orientation of box (`:vertical` or `:horizontal`)."
    orientation = :vertical
    # box and dodging
    "Width of the box before shrinking."
    width = automatic
    "Vector of `Integer` (length of data) of grouping variable to create multiple side-by-side boxes at the same `x` position."
    dodge = automatic
    n_dodge = automatic
    "Shrinking factor, `width -> width * (1 - gap)`."
    gap = 0.2
    "Spacing between dodged boxes."
    dodge_gap = 0.03
    strokecolor = @inherit patchstrokecolor
    strokewidth = @inherit patchstrokewidth
    # notch
    "Draw the notch."
    show_notch = false
    "Multiplier of `width` for narrowest width of notch."
    notchwidth = 0.5
    # median line
    "Show median as midline."
    show_median = true
    mediancolor = @inherit linecolor
    medianlinewidth = @inherit linewidth
    # whiskers
    "Multiple of IQR controlling whisker length. Setting to 0 extends whiskers to the range of the data."
    range = 1.5
    "Multiplier of `width` for width of T's on whiskers, or `:match` to match `width`."
    whiskerwidth = 0.0
    whiskercolor = @inherit linecolor
    whiskerlinewidth = @inherit linewidth
    # outliers points
    "Show outliers as points."
    show_outliers = true
    marker = @inherit marker
    markersize = @inherit markersize
    outliercolor = automatic
    outlierstrokecolor = @inherit markerstrokecolor
    outlierstrokewidth = @inherit markerstrokewidth
    cycle = [:color => :patchcolor]
    inspectable = @inherit inspectable
    visible = true
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
        if !(whiskerwidth === :match || whiskerwidth >= 0)
            error("whiskerwidth must be :match or a positive number. Found: $whiskerwidth")
        end
        t_segments = Point2f[]
        WT = widths isa AbstractVector ? eltype(widths) : typeof(widths)
        boxwidth = WT[]
        for ((center, idxs), q1, q, q5) in zip(groups, q1s, quantiles, q5s)
            bw = getuniquevalue(widths, idxs)
            ww = whiskerwidth === :match ? bw : whiskerwidth * bw
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
        plot,
        plot.centers,
        plot.medians,
        plot.boxmin,
        plot.boxmax,
        gap = 0,
        color = plot.boxcolor,
        colorrange = plot.colorrange,
        colormap = plot.colormap,
        colorscale = plot.colorscale,
        strokecolor = plot.strokecolor,
        strokewidth = plot.strokewidth,
        midlinecolor = plot.mediancolor,
        midlinewidth = plot.medianlinewidth,
        show_midline = plot.show_median,
        orientation = plot.orientation,
        width = plot.boxwidth,
        show_notch = plot.show_notch,
        notchmin = plot.notchmin,
        notchmax = plot.notchmax,
        notchwidth = plot.notchwidth,
        inspectable = plot.inspectable,
        visible = plot.visible
    )
    return plot
end
