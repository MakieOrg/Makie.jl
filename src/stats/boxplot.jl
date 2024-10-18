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
    colorscale=identity
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
    "Multiple of IQR controlling whisker length."
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
end

conversion_trait(x::Type{<:BoxPlot}) = SampleBased()

_cycle(v::AbstractVector, idx::Integer) = v[mod1(idx, length(v))]
_cycle(v, idx::Integer) = v

flip_xy(p::Point2f) = reverse(p)
flip_xy(r::Rect{2,T}) where {T} = Rect{2,T}(reverse(r.origin), reverse(r.widths))

function Makie.plot!(plot::BoxPlot)
    args = @extract plot (weights, width, range, show_outliers, whiskerwidth, show_notch, orientation, gap, dodge, n_dodge, dodge_gap)

    signals = lift(
        plot,
        plot[1],
        plot[2],
        plot[:color],
        args...,
    ) do x, y, color, weights, width, range, show_outliers, whiskerwidth, show_notch, orientation, gap, dodge, n_dodge, dodge_gap
        x̂, boxwidth = compute_x_and_width(x, width, gap, dodge, n_dodge, dodge_gap)
        if !(whiskerwidth === :match || whiskerwidth >= 0)
            error("whiskerwidth must be :match or a positive number. Found: $whiskerwidth")
        end
        ww = whiskerwidth === :match ? boxwidth : whiskerwidth * boxwidth
        outlier_points = Point2f[]
        centers = Float32[]
        medians = Float32[]
        boxmin = Float32[]
        boxmax = Float32[]
        notchmin = Float32[]
        notchmax = Float32[]
        t_segments = Point2f[]
        outlier_indices = Int[]
        T = color isa AbstractVector ? eltype(color) : typeof(color)
        boxcolor = T[]
        for (i, (center, idxs)) in enumerate(StructArrays.finduniquesorted(x̂))
            values = view(y, idxs)

            # compute quantiles
            w = weights === automatic ? () : (StatsBase.weights(view(weights, idxs)),)
            q1, q2, q3, q4, q5 = quantile(values, w..., LinRange(0, 1, 5))

            # notches
            if show_notch
                nh = notchheight(q2, q4, length(values))
                nmin, nmax = q3 - nh, q3 + nh
                push!(notchmin, nmin)
                push!(notchmax, nmax)
            end

            # outliers
            if Float64(range) != 0.0  # if the range is 0.0, the whiskers will extend to the data
                limit = range * (q4 - q2)
                inside = Float64[]
                for (value, idx) in zip(values,idxs)
                    if (value < (q2 - limit)) || (value > (q4 + limit))
                        if show_outliers
                            push!(outlier_points, (center, value))
                            # register outlier box indices
                            push!(outlier_indices, idx)
                        end
                    else
                        push!(inside, value)
                    end
                end
                # change q1 and q5 to show outliers
                # using maximum and minimum values inside the limits
                q1, q5 = extrema_nan(inside)
                # register boxcolor
                push!(boxcolor, getuniquevalue(color, idxs))
            end

            # whiskers
            HW = 0.5 * _cycle(ww, i) # Whisker width
            lw, rw = center - HW, center + HW
            push!(t_segments, (center, q2), (center, q1), (lw, q1), (rw, q1)) # lower T
            push!(t_segments, (center, q4), (center, q5), (rw, q5), (lw, q5)) # upper T

            # box
            push!(centers, center)
            push!(boxmin, q2)
            push!(medians, q3)
            push!(boxmax, q4)
        end

        # for horizontal boxplots just flip all components
        if orientation === :horizontal
            outlier_points = flip_xy.(outlier_points)
            t_segments = flip_xy.(t_segments)
        elseif orientation !== :vertical
            error("Invalid orientation $orientation. Valid options: :horizontal or :vertical.")
        end

        return (
            centers = centers,
            boxmin = boxmin,
            boxmax = boxmax,
            medians = medians,
            notchmin = notchmin,
            notchmax = notchmax,
            outliers = outlier_points,
            t_segments = t_segments,
            boxwidth = boxwidth,
            outlier_indices = outlier_indices,
            boxcolor = boxcolor,
        )
    end
    centers = @lift($signals.centers)
    boxmin = @lift($signals.boxmin)
    boxmax = @lift($signals.boxmax)
    medians = @lift($signals.medians)
    notchmin = @lift($show_notch ? $signals.notchmin : automatic)
    notchmax = @lift($show_notch ? $signals.notchmax : automatic)
    outliers = @lift($signals.outliers)
    t_segments = @lift($signals.t_segments)
    boxwidth = @lift($signals.boxwidth)
    outlier_indices = @lift($signals.outlier_indices)
    boxcolor = @lift($signals.boxcolor)

    outliercolor = lift(plot[:outliercolor], plot[:color], outlier_indices) do outliercolor, color, outlier_indices
        c = outliercolor === automatic ? color : outliercolor
        if c isa AbstractVector
            return c[outlier_indices]
        else
            return c
        end
    end

    scatter_attr = shared_attributes(
        plot, Scatter, 
        strokecolor = plot[:outlierstrokecolor], 
        strokewidth = plot[:outlierstrokewidth],
        # if only one group has outliers, the colorrange will be width 0 otherwise, if it's not an array, it shouldn't matter
        colorrange = @lift($boxcolor isa AbstractArray{<:Real} ? extrema($boxcolor) : automatic), 
        color = outliercolor
    )
    scatter!(plot, scatter_attr, outliers)

    line_attr = shared_attributes(plot, LineSegments, 
        color = plot[:whiskercolor], linewidth = plot[:whiskerlinewidth]
    )
    linesegments!(plot, line_attr, t_segments,)

    cb_attr = shared_attributes(plot, CrossBar,
        color = boxcolor,
        midlinecolor = plot[:mediancolor],
        midlinewidth = plot[:medianlinewidth],
        orientation = orientation,
        width = boxwidth,
        gap = 0,
        show_notch = show_notch,
        notchmin = notchmin, 
        notchmax = notchmax,
    )
    crossbar!(plot, cb_attr, centers, medians, boxmin, boxmax)

    return plot
end
