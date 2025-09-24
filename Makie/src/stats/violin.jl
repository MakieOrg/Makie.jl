"""
    violin(x, y)
Draw a violin plot.
## Arguments
- `x`: positions of the categories
- `y`: variables whose density is computed
"""
@recipe Violin (x, y) begin
    npoints = 200
    boundary = automatic
    bandwidth = automatic
    "vector of statistical weights (length of data). By default, each observation has weight `1`."
    weights = automatic
    "Specify `:left` or `:right` to only plot the violin on one side."
    side = :both
    "Scale density by area (`:area`), count (`:count`), or width (`:width`)."
    scale = :area
    "Orientation of the violins (`:vertical` or `:horizontal`)"
    orientation = :vertical
    "Width of the box before shrinking."
    width = automatic
    dodge = automatic
    n_dodge = automatic
    "Shrinking factor, `width -> width * (1 - gap)`."
    gap = 0.2
    dodge_gap = 0.03
    "Specify values to trim the `violin`. Can be a `Tuple` or a `Function` (e.g. `datalimits=extrema`)."
    datalimits = (-Inf, Inf)
    max_density = automatic
    "Show median as midline."
    show_median = false
    mediancolor = @inherit linecolor
    medianlinewidth = @inherit linewidth
    color = @inherit patchcolor
    strokecolor = @inherit patchstrokecolor
    strokewidth = @inherit patchstrokewidth
    mixin_generic_plot_attributes()...
    cycle = [:color => :patchcolor]
end

conversion_trait(::Type{<:Violin}) = SampleBased()

getuniquevalue(v, idxs) = v

function getuniquevalue(v::AbstractVector, idxs)
    u = view(v, idxs)
    f = first(u)
    msg = "Collection must have the same value across all indices"
    all(isequal(f), u) || throw(ArgumentError(msg))
    return f
end

function plot!(plot::Violin)
    map!(
        compute_x_and_width, plot,
        [:x, :width, :gap, :dodge, :n_dodge, :dodge_gap],
        [:x̂, :violinwidth]
    )

    map!(plot, [:x̂, :side], :sides) do x̂, side
        options = (left = -1, right = +1, both = 0)
        return broadcast(x̂, side) do _, s
            if hasproperty(options, s)
                return getproperty(options, s)
            else
                error("Invalid side $(repr(s)), only :left, :right or :both are allowed.")
            end
        end
    end

    map!(
        plot,
        [:x̂, :y, :sides, :npoints, :boundary, :bandwidth, :weights, :datalimits, :color],
        :specs
    ) do x̂, y, sides, npoints, bound, bw, w, limits, color
        sa = StructArray((x = x̂, side = sides))

        map(StructArrays.finduniquesorted(sa)) do (key, idxs)
            v = view(y, idxs)
            k = KernelDensity.kde(
                v;
                npoints = npoints,
                (bound === automatic ? NamedTuple() : (boundary = bound,))...,
                (bw === automatic ? NamedTuple() : (bandwidth = bw,))...,
                (w === automatic ? NamedTuple() : (weights = StatsBase.weights(view(w, idxs)),))...
            )
            l1, l2 = limits isa Function ? limits(v) : limits
            i1, i2 = searchsortedfirst(k.x, l1), searchsortedlast(k.x, l2)
            kde = (x = view(k.x, i1:i2), density = view(k.density, i1:i2))
            c = getuniquevalue(color, idxs)
            return (x = key.x, side = key.side, color = to_color(c), kde = kde, median = median(v), amount = length(idxs))
        end
    end

    map!(plot, :specs, :colors) do specs
        colors = RGBA{Float32}[]
        for spec in specs
            push!(colors, spec.color)
        end
        return colors
    end

    map!(
        plot,
        [:specs, :scale, :show_median, :max_density, :orientation, :violinwidth],
        [:vertices, :lines]
    ) do specs, scale_type, show_median, max_density, orientation, violinwidth
        @assert scale_type ∈ [:area, :count, :width] "Invalid scale type: $(scale_type)"

        # for horizontal violin just flip all components
        point_func = Point2f
        if orientation === :horizontal
            point_func = flip_xy ∘ point_func
        end

        max = if max_density === automatic
            maximum(specs) do spec
                if scale_type === :area
                    return extrema_nan(spec.kde.density) |> last
                elseif scale_type === :count
                    return extrema_nan(spec.kde.density .* spec.amount) |> last
                elseif scale_type === :width
                    return NaN
                end
            end
        else
            max_density
        end

        vertices = Vector{Point2f}[]
        lines = Pair{Point2f, Point2f}[]

        for spec in specs
            scale = 0.5 * violinwidth
            if scale_type === :area
                scale = scale / max
            elseif scale_type === :count
                scale = scale / max * spec.amount
            elseif scale_type === :width
                scale = scale / (extrema_nan(spec.kde.density) |> last)
            end
            xl = reverse(spec.x .- spec.kde.density .* scale)
            xr = spec.x .+ spec.kde.density .* scale
            yl = reverse(spec.kde.x)
            yr = spec.kde.x

            x_coord, y_coord = if spec.side == -1 # left violin
                [spec.x; xl; spec.x], [yl[1]; yl; yl[end]]
            elseif spec.side == 1 # right violin
                [spec.x; xr; spec.x], [yr[1]; yr; yr[end]]
            else
                [spec.x; xr; spec.x; xl], [yr[1]; yr; yl[1]; yl]
            end
            verts = point_func.(x_coord, y_coord)
            push!(vertices, verts)

            # interpolate median bounds between corresponding points
            if show_median
                xm = spec.median
                ip = Base.max(2, something(findfirst(>(xm), spec.kde.x), length(spec.kde.x)))
                ym₋, ym₊ = spec.kde.density[Base.max(1, ip - 1)], spec.kde.density[ip]
                xm₋, xm₊ = spec.kde.x[Base.max(1, ip - 1)], spec.kde.x[ip]
                ym = (xm * (ym₊ - ym₋) + xm₊ * ym₋ - xm₋ * ym₊) / (xm₊ - xm₋)
                median_left = point_func(spec.side == 1 ? spec.x : spec.x - ym * scale, xm)
                median_right = point_func(spec.side == -1 ? spec.x : spec.x + ym * scale, xm)
                push!(lines, median_left => median_right)
            end
        end

        return vertices, lines
    end

    poly!(
        plot,
        plot.vertices;
        color = plot.colors,
        strokecolor = plot.strokecolor,
        strokewidth = plot.strokewidth,
    )
    linesegments!(
        plot,
        plot.lines;
        color = plot.mediancolor,
        linewidth = plot.medianlinewidth,
        visible = plot.show_median,
        inspectable = plot.inspectable
    )
    return plot
end
