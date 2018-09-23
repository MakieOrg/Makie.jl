using Makie, GeometryTypes
import AbstractPlotting: convert_arguments, plot!, convert_arguments, extrema_nan

@recipe(Bar, x, y) do scene
    Theme(;
        fillto = 0.0,
        color = theme(scene, :color),
        colormap = theme(scene, :colormap),
        colorrange = nothing,
        marker = Rect,
        width = nothing
    )
end

export bar

function AbstractPlotting.data_limits(p::Bar)
    xy = p.plots[1][1][]
    msize = p.plots[1][:markersize][]
    xybb = FRect3D(xy)
    y = last.(msize) .+ last.(xy)
    bb = AbstractPlotting.xyz_boundingbox(first.(xy), y)
    union(bb, xybb)
end


AbstractPlotting.convert_arguments(::Type{<: Bar}, x::AbstractVector{<: Number}, y::AbstractVector{<: Number}) = (x, y)
function AbstractPlotting.plot!(p::Bar)
    pos_scale = lift(p[1], p[2], p[:fillto], p[:width]) do x, y, fillto, hw
        nx, ny = length(x), length(y)
        cv = x
        x = if nx == ny
            cv
        elseif nx == ny + 1
            0.5diff(cv) + cv[1:end-1]
        else
            error("bar recipe: x must be same length as y (centers), or one more than y (edges).\n\t\tlength(x)=$(length(x)), length(y)=$(length(y))")
        end
        # compute half-width of bars
        if hw == nothing
            hw = mean(diff(x)) # TODO ignore nan?
        end
        # make fillto a vector... default fills to 0
        positions = Point2f0.(cv, Float32.(fillto))
        scales = Vec2f0.(abs.(hw), y)
        offset = Vec2f0.(hw ./ -2f0, 0)
        positions, scales, offset
    end
    scatter!(
        p, lift(first, pos_scale),
        marker = p[:marker], marker_offset = lift(last, pos_scale),
        markersize = lift(getindex, pos_scale, Node(2)),
        color = p[:color], colormap = p[:colormap], colorrange = p[:colorrange],
        transform_marker = true
    )
end

@recipe(Histogram) do scene
    Theme(;
        bins = 10,
    )
end
calcMidpoints(edges::AbstractVector) = Float64[0.5 * (edges[i] + edges[i+1]) for i in 1:length(edges)-1]

"Make histogram-like bins of data"
function binData(data, nbins)
  lo, hi = AbstractPlotting.extrema_nan(data)
  edges = collect(range(lo, stop=hi, length=nbins+1))
  midpoints = calcMidpoints(edges)
  buckets = Int[max(2, min(searchsortedfirst(edges, x), length(edges)))-1 for x in data]
  counts = zeros(Int, length(midpoints))
  for b in buckets
    counts[b] += 1
  end
  edges, midpoints, buckets, counts
end
AbstractPlotting.convert_arguments(::Type{<: Histogram}, x::AbstractVector{<: Number}) = (x,)
function AbstractPlotting.plot!(p::Histogram)
    # we assume that the y kwarg is set with the data to be binned, and nbins is also defined
    args = lift(p[1], p[:bins]) do y, bins
        edges, midpoints, buckets, counts = binData(y, bins)
        (midpoints, float(counts))
    end
    bar!(p, lift(first, args), lift(last, args))
end


notch_width(q2, q4, N) = 1.58 * (q4-q2)/sqrt(N)

pair_up(dict, key) = (key => dict[key])

@recipe(BoxPlot, x, y) do scene
    t = Theme(
        color = theme(scene, :color),
        notch = false,
        range = 1.5,
        outliers = true,
        whisker_width = :match,
        bar_width = 0.8,
        markershape = :circle,
        strokecolor = :black,
        strokewidth = 1.0,
    )
    t[:outliercolor] = t[:color]
    t
end

_cycle(v::AbstractVector, idx::Integer) = v[mod1(idx, length(v))]
_cycle(v, idx::Integer) = v


convert_arguments(::Type{<: BoxPlot}, x::AbstractVector{<: Number}, y::AbstractVector{<: Number}) = (x, y)


function plot!(plot::BoxPlot)
    args = @extract plot (bar_width, range, outliers, whisker_width, notch)

    signals = lift(plot[1], plot[2], args...) do x, y, bw, range, outliers, whisker_width, notch
        glabels = sort(collect(unique(x)))
        warning = false
        outlier_points = Point2f0[]
        if !(whisker_width == :match || whisker_width >= 0)
            error("whisker_width must be :match or a positive number. Found: $whisker_width")
        end
        ww = whisker_width == :match ? bw : whisker_width
        boxes = FRect2D[]
        t_segments = Point2f0[]
        for (i, glabel) in enumerate(glabels)
            # filter y
            values = y[filter(i -> _cycle(x, i) == glabel, 1:length(y))]
            # compute quantiles
            q1, q2, q3, q4, q5 = quantile(values, range(0, stop=1, length=5))
            # notch
            n = notch_width(q2, q4, length(values))
            # warn on inverted notches?
            if notch && !warning && ( (q2>(q3-n)) || (q4<(q3+n)) )
                @warn("Boxplot's notch went outside hinges. Set notch to false.")
                warning = true # Show the warning only one time
            end

            # make the shape
            center = glabel
            hw = 0.5 * _cycle(bw, i) # Box width
            HW = 0.5 * _cycle(ww, i) # Whisker width
            l, m, r = center - hw, center, center + hw
            lw, rw = center - HW, center + HW

            # internal nodes for notches
            L, R = center - 0.5 * hw, center + 0.5 * hw

            # outliers
            if Float64(range) != 0.0  # if the range is 0.0, the whiskers will extend to the data
                limit = range*(q4-q2)
                inside = Float64[]
                for value in values
                    if (value < (q2 - limit)) || (value > (q4 + limit))
                        if outliers
                            push!(outlier_points, (center, value))
                        end
                    else
                        push!(inside, value)
                    end
                end
                # change q1 and q5 to show outliers
                # using maximum and minimum values inside the limits
                q1, q5 = extrema_nan(inside)
            end
            # Box
            if notch
                push!(t_segments, (m, q1), (l, q1), (r, q1), (m, q1), (m, q2))# lower T
                push!(boxes, FRect(l, q2, hw, n)) # lower box
                # push!(boxes, FRect(l, q4, hw, n)) # lower box
                push!(t_segments, (m, q5), (l, q5), (r, q5), (m, q5), (m, q4))# upper T
            else
                push!(t_segments, (m, q2), (m, q1), (l, q1), (r, q1))# lower T
                if abs(q3 - q2) > 0.0
                    push!(boxes, FRect(l, q2, 2hw, (q3 - q2)))
                end
                if abs(q3 - q4) > 0.0
                    push!(boxes, FRect(l, q4, 2hw, (q3 - q4)))
                end
                push!(t_segments, (m, q4), (m, q5), (r, q5), (l, q5))# upper T
            end
        end
        boxes, outlier_points, t_segments
    end
    outliers = lift(getindex, signals, Node(2))
    scatter!(
        plot,
        color = plot[:outliercolor],
        strokecolor = plot[:strokecolor],
        markersize = bar_width,
        strokewidth = plot[:strokewidth],
        outliers,
    )
    linesegments!(
        plot,
        color = plot[:strokecolor],
        linewidth = plot[:strokewidth],
        # extract(plot, (:color, :strokecolor, :markershape))
        lift(last, signals),
    )
    poly!(
        plot, lift(first, signals),
        color = plot[:color],
        strokecolor = plot[:strokecolor],
        strokewidth = plot[:strokewidth]
    )
end



@recipe(CorrPlot) do scene
    Theme(
        link = :x,  # need custom linking for y
        legend = false,
        margin = 1,
        fillcolor = theme(scene, :color),
        linecolor = theme(scene, :color),
        # indices = reshape(1:n^2, n, n)',
        title = "",
    )
end
AbstractPlotting.convert_arguments(::Type{<: CorrPlot}, x) = (x,)



function AbstractPlotting.plot!(scene::Scene, ::Type{CorrPlot}, attributes::Attributes, mat)
    n = size(mat, 2)
    C = cor(mat)
    plotgrid = broadcast(1:n, (1:n)') do i, j
        vi = view(mat, :, i)
        vj = view(mat, :, j)
        s = Scene(scene, pixelarea(scene)[])
        if i == j # histograms are on the diagonal
            histogram!(s, vi)
        elseif i > j
            scatter!(s, vj, vi)
        else
            scatter!(s, vj, vi)
        end
        s
    end
    grid!(scene, plotgrid)
    scene
end

M = randn(1000, 4)
M[:,2] += 0.8sqrt.(abs.(M[:,1])) - 0.5M[:,3] + 5
M[:,3] -= 0.7M[:,1].^2 + 2

scene = corrplot(M)
center!(scene)
scene.plots[1] |> AbstractPlotting.data_limits
translate!(scene.plots[1], 26, 0, 0)
