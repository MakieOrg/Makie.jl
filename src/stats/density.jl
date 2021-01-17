function convert_arguments(P::PlotFunc, d::KernelDensity.UnivariateKDE)
    ptype = plottype(P, Lines) # choose the more concrete one
    to_plotspec(ptype, convert_arguments(ptype, d.x, d.density))
end

function convert_arguments(::Type{<:Poly}, d::KernelDensity.UnivariateKDE)
    points = Vector{Point2f0}(undef, length(d.x) + 2)
    points[1] = Point2f0(d.x[1], 0)
    points[2:end-1] .= Point2f0.(d.x, d.density)
    points[end] = Point2f0(d.x[end], 0)
    (points,)
end

function convert_arguments(P::PlotFunc, d::KernelDensity.BivariateKDE)
    ptype = plottype(P, Heatmap)
    to_plotspec(ptype, convert_arguments(ptype, d.x, d.y, d.density))
end

function searchrange(x, xlims)
    min, max = xlims
    i1 = searchsortedfirst(x, min)
    i2 = searchsortedlast(x, max)
    return i1:i2
end

function trim_density(k::KernelDensity.UnivariateKDE, xlims)
    range = searchrange(k.x, xlims)
    KernelDensity.UnivariateKDE(k.x[range], k.density[range])
end

function _density(x; trim = false)
    k = KernelDensity.kde(x)
    return trim ? trim_density(k, extrema_nan(x)) : k
end


"""
    density(values; npoints = 200, offset = 0.0, direction = :x)

Plot a kernel density estimate of `values`.
`npoints` controls the resolution of the estimate, the baseline can be
shifted with `offset` and the `direction` set to :x or :y.
`bandwidth` and `boundary` are determined automatically by default. 

## Attributes
$(ATTRIBUTES)
"""
@recipe(Density) do scene
    Theme(
        color = :gray85,
        strokecolor = :black,
        strokewidth = 1,
        strokearound = false,
        npoints = 200,
        offset = 0.0,
        direction = :x,
        boundary = automatic,
        bandwidth = automatic,
    )
end

function plot!(plot::Density{<:Tuple{<:AbstractVector}})
    x = plot[1]

    points = lift(x, plot.direction, plot.boundary, plot.offset,
        plot.npoints, plot.bandwidth) do x, dir, bound, offs, n, bw

        k = KernelDensity.kde(x;
            npoints = n,
            (bound === automatic ? NamedTuple() : (boundary = bound,))...,
            (bw === automatic ? NamedTuple() : (bandwidth = bw,))...,
        )

        ps = Vector{Point2f0}(undef, length(k.x) + 2)
        if dir === :x
            ps[1] = Point2f0(k.x[1], offs)
            ps[2:end-1] .= Point2f0.(k.x, k.density .+ offs)
            ps[end] = Point2f0(k.x[end], offs)
        elseif dir === :y
            ps[1] = Point2f0(offs, k.x[1])
            ps[2:end-1] .= Point2f0.(k.density .+ offs, k.x)
            ps[end] = Point2f0(offs, k.x[end])
        else
            error("Invalid direction $dir, only :x or :y allowed")
        end
        ps
    end

    linepoints = lift(points, plot.strokearound) do ps, sa
        if sa
            push!(copy(ps), ps[1])
        else
            ps[2:end-1]
        end
    end

    poly!(plot, points, color = plot.color, strokewidth = 0)
    lines!(plot, linepoints, color = plot.strokecolor, linewidth = plot.strokewidth)
end