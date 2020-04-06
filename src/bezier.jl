
@AbstractPlotting.recipe(Bezier) do scene
    merge(
        default_theme(scene, Lines),
        Attributes(npoints = 30)
    )
end

AbstractPlotting.conversion_trait(::Type{<: Bezier}) = AbstractPlotting.PointBased()

# used in the pipeline too (for poly)
function from_nansep_vec(v::Vector{T}) where T
    idxs = findall(isnan, v)

    if isempty(idxs)
        return [v]
    end
    vs = Vector{Vector{T}}(undef, length(idxs))
    prev = 1
    num = 1
    for i in idxs
        vs[num] = v[prev:i-1]

        prev = i + 1
        num += 1
    end

    return vs
end

function bezier_value(pts::AbstractVector, t::Real)
    val = 0.0
    n = length(pts) - 1
    for (i, p) in enumerate(pts)
        val += p * binomial(n, i - 1) * (1 - t)^(n - i + 1) * t^(i - 1)
    end
    val
end


function to_bezier(p::Vector{Point2f0}, npoints::Int)
    curves = Point2f0[]

    rawvecs = [getindex.(p, n) for n in 1:2]

    for rng in from_nansep_vec(p)
        ts = LinRange(0, 1, npoints)
        xs = map(t -> bezier_value(getindex.(rng, 1), t), ts)
        ys = map(t -> bezier_value(getindex.(rng, 2), t), ts)

        append!(curves, Point2f0.(xs, ys))

        push!(curves, Point2f0(NaN))
    end

    return curves
end

function AbstractPlotting.plot!(plot::Bezier)
    positions = plot[1]

    @extract plot (npoints,)

    curves = lift(to_bezier, positions, npoints)

    lines!(
        plot,
        curves;
        linestyle = plot.linestyle,
        linewidth = plot.linewidth,
        color = plot.color,
        colormap = plot.colormap,
        colorrange = plot.colorrange
    )
end
