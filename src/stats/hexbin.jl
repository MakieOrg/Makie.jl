"""
    hexbin(xs, ys; kwargs...)

Plots a heatmap with hexagonal bins for the observations `xs` and `ys`.

## Attributes

### Specific to `Hexbin`

- `bins = 20`: If an `Int`, sets the number of bins in x and y direction. If a `Tuple{Int, Int}`, sets the number of bins for x and y separately.
- `cellsize = nothing`: If a `Real`, makes equally-sided hexagons with width `cellsize`. If a `Tuple{Real, Real}` specifies hexagon width and height separately.
- `threshold::Int = 1`: The minimal number of observations in the bin to be shown. If 0, all zero-count hexagons fitting into the data limits will be shown.
- `scale = identity`: A function to scale the number of observations in a bin, eg. log10.

### Generic

- `colormap::Union{Symbol, Vector{<:Colorant}} = :viridis`
- `colorrange::Tuple(<:Real,<:Real} = Makie.automatic`  sets the values representing the start and end points of `colormap`.
"""
@recipe(Hexbin) do scene
    return Attributes(;
                      colormap=theme(scene, :colormap),
                      colorrange=Makie.automatic,
                      bins=20,
                      cellsize=nothing,
                      threshold=1,
                      scale=identity,
                      strokewidth=0,
                      strokecolor=:black)
end

function spacings_offsets_nbins(bins::Tuple{Int,Int}, cellsize::Nothing, xmi, xma, ymi, yma)
    any(<(2), bins) && error("Minimum number of bins in one direction is 2, got $bins.")
    x_diff = xma - xmi
    y_diff = yma - ymi

    xspacing, yspacing = (x_diff, y_diff) ./ (bins .- 1)
    return xspacing, yspacing, xmi, ymi, bins...
end

function spacings_offsets_nbins(bins, cellsize::Real, xmi, xma, ymi, yma)
    return spacings_offsets_nbins(bins, (cellsize, cellsize * 2 / sqrt(3)), xmi, xma, ymi, yma)
end
function spacings_offsets_nbins(bins::Int, cellsize::Nothing, xmi, xma, ymi, yma)
    return spacings_offsets_nbins((bins, bins), cellsize, xmi, xma, ymi, yma)
end

function spacings_offsets_nbins(bins, cellsizes::Tuple{<:Real,<:Real}, xmi, xma, ymi, yma)
    x_diff = xma - xmi
    y_diff = yma - ymi
    xspacing = cellsizes[1] / 2
    yspacing = cellsizes[2] * 3 / 4
    (nx, restx), (ny, resty) = fldmod.((x_diff, y_diff), (xspacing, yspacing))
    return xspacing, yspacing, xmi - (restx > 0 ? (xspacing - restx) / 2 : 0),
           ymi - (resty > 0 ? (yspacing - resty) / 2 : 0), Int(nx) + (restx > 0), Int(ny) + (resty > 0)
end

Makie.conversion_trait(::Type{<:Hexbin}) = PointBased()

function data_limits(hb::Hexbin)
    bb = Rect3f(hb.plots[1][1][])
    fn(num::Real) = Float32(num)
    fn(tup::Union{Tuple,Vec2}) = Vec2f(tup...)

    ms = 2 .* fn(hb.plots[1].markersize[])
    nw = widths(bb) .+ (ms..., 0.0f0)
    no = bb.origin .- ((ms ./ 2.0f0)..., 0.0f0)

    return Rect3f(no, nw)
end

function Makie.plot!(hb::Hexbin{<:Tuple{<:AbstractVector{<:Point2}}})
    xy = hb[1]

    points = Observable(Point2f[])
    count_hex = Observable(Float64[])
    markersize = Observable(Vec2f(1, 1))

    function calculate_grid(xy, bins, cellsize, threshold, scale)
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

        xspacing, yspacing, xoff, yoff, nbinsx, nbinsy = spacings_offsets_nbins(bins, cellsize, xmi, xma, ymi,
                                                                                yma)                                                                     

        ysize = yspacing / 3 * 4
        ry = ysize / 2

        xsize = xspacing * 2
        rx = xsize / sqrt3

        d = Dict{Tuple{Int,Int},Int}()

        # for the distance measurement, the y dimension must be weighted relative to the x
        # dimension according to the different sizes in each, otherwise the attribution to hexagonal
        # cells is wrong
        yweight = xsize / ysize

        for (_x, _y) in xy
            nx, nxs, dvx = nearest_center(_x, xspacing, xoff)
            ny, nys, dvy = nearest_center(_y, yspacing, yoff)

            d1 = ((_x - nx)^2 + (yweight * (_y - ny))^2)
            d2 = ((_x - nxs)^2 + (yweight * (_y - nys))^2)

            is_grid1 = d1 < d2

            # _xy = is_grid1 ? (nx, ny) : (nxs, nys)
            
            id = if is_grid1
                (
                    cld(dvx, 2),
                    iseven(dvy) ? dvy : dvy+1
                )
            else
                (
                    fld(dvx, 2),
                    iseven(dvy) ? dvy+1 : dvy,
                )
            end

            d[id] = get(d, id, 0) + 1
        end

        # this iteration scheme misses points at the edges and I don't understand why
        # for plotting a whole field
        # with zeros something like this would be needed, though..
        if threshold == 0
            for iy in 0:nbinsy-1
                _nx = isodd(iy) ? fld(nbinsx, 2) : cld(nbinsx, 2)
                for ix in 0:_nx-1
                    _x = xoff + 2 * ix * xspacing + (isodd(iy) * xspacing)
                    _y = yoff + iy * yspacing
                    c = get(d, (ix, iy), 0)
                    push!(points[], Point2f(_x, _y))
                    push!(count_hex[], scale(c))
                end
            end
        else
            # we only need to iterate dict values if we don't plot zero cells
            for ((ix, iy), value) in d
                if value >= threshold
                    _x = xoff + 2 * ix * xspacing + (isodd(iy) * xspacing)
                    _y = yoff + iy * yspacing
                    push!(points[], Point2f(_x, _y))
                    push!(count_hex[], scale(value))
                end
            end
        end

        markersize[] = Vec2f(rx, ry)
        notify(points)
        return notify(count_hex)
    end
    onany(calculate_grid, xy, hb.bins, hb.cellsize, hb.threshold, hb.scale)
    # trigger once
    notify(hb.bins)

    replace_automatic!(hb, :colorrange) do
        if isempty(count_hex[])
            (0, 1)
        else
            (minimum(count_hex[]), maximum(count_hex[]))
        end
    end

    hexmarker = Polygon(Point2f[(cos(a), sin(a)) for a in range(pi / 6, 13pi / 6; length=7)[1:6]])

    return scatter!(hb, points;
                    colorrange=hb.colorrange,
                    color=count_hex,
                    colormap=hb.colormap,
                    marker=hexmarker,
                    markersize=markersize,
                    markerspace=:data,
                    strokewidth=hb.strokewidth,
                    strokecolor=hb.strokecolor)
end

function center_value(dv, spacing, offset, is_grid1)
    if is_grid1
        offset + spacing * (dv + isodd(dv))
    else
        offset + spacing * (dv + iseven(dv))
    end
end

function nearest_center(val, spacing, offset)
    dv = Int(fld(val - offset, spacing))
    rounded = offset + spacing * (dv + isodd(dv))
    rounded_scaled = offset + spacing * (dv + iseven(dv))
    return rounded, rounded_scaled, dv
end