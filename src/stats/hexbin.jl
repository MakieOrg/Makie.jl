"""
    hexbin(xs, ys; kwargs...)

Plots a heatmap with hexagonal bins for the observations `xs` and `ys`.

## Attributes
### Specific to `Hexbin`
* `gridsize::Int = 20` sets the number of bins in x-direction
* `mincnt::Int = 0` sets the minimal number of observations in the bin to be shown. If 0 all bins are shown, if 1 all with at least 1 observation.
* `scale = identity` scales the number of data in the bins, eg. log10.
### Generic
* `colormap::Union{Symbol, Vector{<:Colorant}} = :viridis` sets the colormap that is sampled for numeric colors.
* `colorrange::Tuple(<:Real,<:Real} = Makie.automatic`  sets the values representing the start and end points of `colormap`.
"""
@recipe(Hexbin) do scene
    return Attributes(;
        colormap=theme(scene, :colormap),
        colorrange=Makie.automatic,
        bins=20,
        mincnt=1,
        scale=identity
    )
end

function Makie.plot!(hb::Hexbin{<:Tuple{<:AbstractVector{<:Point2}}})
    xy = hb[1]

    points = Observable(Point2f[])
    count_hex = Observable(Float64[])
    markersize = Observable(Vec2f(1, 1))

    function calculate_grid(xy, bins, mincnt, scale)
        empty!(points[])
        empty!(count_hex[])

        isempty(xy) && return

        sqrt3 = sqrt(3)

        # enclose data in limits
        _expand((lo, hi)) = prevfloat(lo), nextfloat(hi)

        xmi, xma = _expand(extrema((p[1] for p in xy)))
        ymi, yma = _expand(extrema((p[2] for p in xy)))

        x_diff = xma - xmi
        y_diff = yma - ymi

        xspacing = x_diff / bins
        yspacing = y_diff / bins

        ysize = yspacing / 3 * 4
        ry = ysize / 2

        xsize = xspacing * 2
        rx = xsize / sqrt3

        d = Dict{Tuple{Int, Int, Bool}, Int}()

        # for the distance measurement, the y dimension must be weighted relative to the x
        # dimension according to the different sizes in each, otherwise the attribution to hexagonal
        # cells is wrong
        yweight = xsize / ysize

        for (_x, _y) in xy
            nx, nxs, dvx = nearest_center(_x, 2 * xspacing, xmi)
            ny, nys, dvy = nearest_center(_y, 2 * yspacing, ymi)

            d1 = ((_x - nx) ^ 2 + (yweight * (_y - ny)) ^ 2)
            d2 = ((_x - nxs) ^ 2 + (yweight * (_y - nys)) ^ 2)

            is_grid1 = d1 < d2

            id = (dvx, dvy, is_grid1)

            d[id] = get(d, id, 0) + 1
        end

        for ix in 0:bins-1
            for iy in 0:bins-1
                for is_grid1 in (true, false)
                    _x = center_value(ix, 2 * xspacing, xmi, is_grid1)
                    _y = center_value(iy, 2 * yspacing, ymi, is_grid1)
                    c = get(d, (ix, iy, is_grid1), 0)
                    if c >= mincnt
                        push!(points[], Point2f(_x, _y))
                        push!(count_hex[], c)
                    end
                end
            end
        end

        @show sum(last, pairs(d))

        markersize[] = Vec2f(rx, ry)
        notify(points)
        notify(count_hex)
    end
    onany(calculate_grid, xy, hb.bins, hb.mincnt, hb.scale)
    # trigger once
    notify(hb.bins)

    replace_automatic!(hb, :colorrange) do
        if isempty(count_hex[])
            (0, 1)
        else
            @show (minimum(count_hex[]), maximum(count_hex[]))
        end
    end

    hexmarker = Polygon(Point2f[(cos(a), sin(a)) for a in range(pi/6, 13pi/6, length = 7)[1:6]])

    scatter!(hb, points; color=count_hex, colormap=hb.colormap, marker = hexmarker, markersize = markersize, markerspace = :data)
end

function center_value(dv, scale, offset, is_grid1)
    if is_grid1
        offset + scale / 2 * (dv + (isodd(dv) ? 1 : 0))
    else
        offset + scale / 2 * (dv + (iseven(dv) ? 1 : 0))
    end
end

function nearest_center(val, scale, offset)
    dv = Int(fld(val - offset, scale / 2))
    rounded = offset + scale / 2 * (dv + isodd(dv))
    rounded_scaled = offset + scale / 2 * (dv + iseven(dv))
    return rounded, rounded_scaled, dv
end