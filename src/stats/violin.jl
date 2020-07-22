@recipe(Violin, x, y) do scene
    Theme(;
        default_theme(scene, Poly)...,
        side = :both,
        width = 0.8,
        trim = false,
        strokecolor = :white,
        show_median = false,
        mediancolor = automatic,
        medianlinewidth = 1.0,
    )
end

conversion_trait(x::Type{<:Violin}) = SampleBased()

function plot!(plot::Violin)
    width, side, trim, show_median = plot[:width], plot[:side], plot[:trim], plot[:show_median]

    signals = lift(plot[1], plot[2], width, side, trim, show_median) do x, y, bw, vside, trim, show_median
        vertices = Vector{Point2f0}[]
        lines = Pair{Point2f0, Point2f0}[]
        for (key, idxs) in StructArrays.finduniquesorted(x)
            v = view(y, idxs)
            
            spec = (x = key, kde = density(v; trim = trim), median = median(v))
            min, max = extrema_nan(spec.kde.density)
            scale = 0.5*bw/max
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