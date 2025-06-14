function convert_arguments(P::Type{<:AbstractPlot}, d::KernelDensity.UnivariateKDE)
    ptype = plottype(P, Lines) # choose the more concrete one
    to_plotspec(ptype, convert_arguments(ptype, d.x, d.density))
end

function convert_arguments(::Type{<:Poly}, d::KernelDensity.UnivariateKDE)
    points = Vector{Point2f}(undef, length(d.x) + 2)
    points[1] = Point2f(d.x[1], 0)
    points[2:end-1] .= Point2f.(d.x, d.density)
    points[end] = Point2f(d.x[end], 0)
    (points,)
end

function convert_arguments(P::Type{<:AbstractPlot}, d::KernelDensity.BivariateKDE)
    ptype = plottype(P, Heatmap)
    to_plotspec(ptype, convert_arguments(ptype, d.x, d.y, d.density))
end

"""
    density(values)

Plot a kernel density estimate of `values`.
"""
@recipe Density begin
    """
    Usually set to a single color, but can also be set to `:x` or
    `:y` to color with a gradient. If you use `:y` when `direction = :x` (or vice versa),
    note that only 2-element colormaps can work correctly.
    """
    color = @inherit patchcolor
    colormap = @inherit colormap
    colorscale = identity
    colorrange = Makie.automatic
    strokecolor = @inherit patchstrokecolor
    strokewidth = @inherit patchstrokewidth
    linestyle = nothing
    strokearound = false
    "The resolution of the estimated curve along the dimension set in `direction`."
    npoints = 200
    "Shift the density baseline, for layering multiple densities on top of each other."
    offset = 0.0
    "The dimension along which the `values` are distributed. Can be `:x` or `:y`."
    direction = :x
    "Boundary of the density estimation, determined automatically if `automatic`."
    boundary = automatic
    "Kernel density bandwidth, determined automatically if `automatic`."
    bandwidth = automatic
    "Assign a vector of statistical weights to `values`."
    weights = automatic
    cycle = [:color => :patchcolor]
    inspectable = @inherit inspectable
    """
    The alpha value of the colormap or color attribute. Multiple alphas like
    in plot(alpha=0.2, color=(:red, 0.5), will get multiplied.
    """
    alpha = 1.0
    visible = true
end

function plot!(plot::Density{<:Tuple{<:AbstractVector}})
    x = plot[1]

    lowerupper = lift(plot, x, plot.direction, plot.boundary, plot.offset,
        plot.npoints, plot.bandwidth, plot.weights) do x, dir, bound, offs, n, bw, weights

        k = KernelDensity.kde(x;
            npoints = n,
            (bound === automatic ? NamedTuple() : (boundary = bound,))...,
            (bw === automatic ? NamedTuple() : (bandwidth = bw,))...,
            (weights === automatic ? NamedTuple() : (weights = StatsBase.weights(weights),))...
        )

        if dir === :x
            lowerv = Point2f.(k.x, offs)
            upperv = Point2f.(k.x, offs .+ k.density)
        elseif dir === :y
            lowerv = Point2f.(offs, k.x)
            upperv = Point2f.(offs .+ k.density, k.x)
        else
            error("Invalid direction $dir, only :x or :y allowed")
        end
        (lowerv, upperv)
    end

    linepoints = lift(plot, lowerupper, plot.strokearound) do lu, sa
        if sa
            ps = copy(lu[2])
            push!(ps, lu[1][end])
            push!(ps, lu[1][1])
            push!(ps, lu[1][2])
            ps
        else
            lu[2]
        end
    end

    lower = Observable(Point2f[])
    upper = Observable(Point2f[])

    on(plot, lowerupper) do (l, u)
        lower.val = l
        upper[] = u
    end
    notify(lowerupper)

    colorobs = Observable{Any}()
    map!(plot, colorobs, plot.color, lowerupper, plot.direction) do c, lu, dir
        if (dir === :x && c === :x) || (dir === :y && c === :y)
            dim = dir === :x ? 1 : 2
            return Float32[l[dim] for l in lu[1]]
        elseif (dir === :y && c === :x) || (dir === :x && c === :y)
            o = Float32(plot.offset[])
            dim = dir === :x ? 2 : 1
            return vcat(Float32[l[dim] - o for l in lu[1]], Float32[l[dim] - o for l in lu[2]])::Vector{Float32}
        else
            return c
        end
    end

    band!(plot, lower, upper, color = colorobs, colormap = plot.colormap, colorscale = plot.colorscale,
        colorrange = plot.colorrange, inspectable = plot.inspectable, alpha = plot.alpha, visible = plot.visible)
    l = lines!(plot, linepoints, color = plot.strokecolor,
        linestyle = plot.linestyle, linewidth = plot.strokewidth,
        inspectable = plot.inspectable, alpha = plot.alpha, visible = plot.visible)
    plot
end
