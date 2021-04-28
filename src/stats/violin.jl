"""
    violin(x, y; kwargs...)
Draw a violin plot.
# Arguments
- `x`: positions of the categories
- `y`: variables whose density is computed
# Keywords
- `orientation=:vertical`: orientation of the violins (`:vertical` or `:horizontal`)
- `width=0.8`: width of the violin
- `show_median=true`: show median as midline
"""
@recipe(Violin, x, y) do scene
    Theme(;
        default_theme(scene, Poly)...,
        npoints = 200,
        boundary = automatic,
        bandwidth = automatic,
        side = :both,
        width = automatic,
        dodge = automatic,
        n_dodge = automatic,
        x_gap = 0.2,
        dodge_gap = 0.03,
        trim = false,
        strokecolor = :white,
        show_median = false,
        mediancolor = automatic,
        medianlinewidth = 1.0,
    )
end

conversion_trait(x::Type{<:Violin}) = SampleBased()

function plot!(plot::Violin)
    x, y, width, side, show_median = plot[1], plot[2], plot[:width], plot[:side], plot[:show_median]
    npoints, boundary, bandwidth = plot[:npoints], plot[:boundary], plot[:bandwidth]
    dodge, n_dodge, x_gap, dodge_gap = plot[:dodge], plot[:n_dodge], plot[:x_gap], plot[:dodge_gap]

    signals = lift(x, y, width, dodge, n_dodge, x_gap, dodge_gap, side, show_median, npoints, boundary, bandwidth) do x, y, width, dodge, n_dodge, x_gap, dodge_gap, vside, show_median, n, bound, bw
        x̂, violinwidth = xw_from_dodge(x, width, 1, x_gap, dodge, n_dodge, dodge_gap)
        vertices = Vector{Point2f0}[]
        lines = Pair{Point2f0, Point2f0}[]
        for (key, idxs) in StructArrays.finduniquesorted(x̂)
            v = view(y, idxs)
            k = KernelDensity.kde(v;
                npoints = n,
                (bound === automatic ? NamedTuple() : (boundary = bound,))...,
                (bw === automatic ? NamedTuple() : (bandwidth = bw,))...,
            )
            spec = (x = key, kde = k, median = median(v))
            min, max = extrema_nan(spec.kde.density)
            scale = 0.5*violinwidth/max
            xl = reverse(spec.x .- spec.kde.density .* scale)
            xr = spec.x .+ spec.kde.density .* scale
            yl = reverse(spec.kde.x)
            yr = spec.kde.x

            x_coord, y_coord = if vside == :left
                [spec.x; xl; spec.x], [yl[1]; yl; yl[end]]
            elseif vside == :right
                [spec.x; xr; spec.x], [yr[1]; yr; yr[end]]
            else
                [spec.x; xr; spec.x; xl], [yr[1]; yr; yl[1]; yl]
            end
            verts = Point2f0.(x_coord, y_coord)
            push!(vertices, verts)

            if show_median
                # interpolate median bounds between corresponding points
                xm = spec.median
                ip = findfirst(>(xm), spec.kde.x)
                ym₋, ym₊ = spec.kde.density[ip-1], spec.kde.density[ip]
                xm₋, xm₊ = spec.kde.x[ip-1], spec.kde.x[ip]
                ym = (xm * (ym₊ - ym₋) + xm₊ * ym₋ - xm₋ * ym₊) / (xm₊ - xm₋)
                median_left = Point2f0(vside == :right ? spec.x : spec.x - ym * scale, xm)
                median_right = Point2f0(vside == :left ? spec.x : spec.x + ym * scale, xm)
                push!(lines, median_left => median_right)
            end
        end
        return vertices, lines
    end
    t = copy(Theme(plot))
    mediancolor = pop!(t, :mediancolor)
    poly!(plot, t, lift(first, signals))
    linesegments!(
        plot,
        lift(last, signals),
        color = lift(
            (mc, sc) -> mc === automatic ? sc : mc,
            mediancolor,
            plot[:strokecolor],
        ),
        linewidth = plot[:medianlinewidth],
        visible = plot[:show_median],
    )
end