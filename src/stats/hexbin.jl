"""
    hexbin(xs, ys; kwargs...)

Plots a heatmap with hexagonal bins for the observations `xs` and `ys`.
"""
@recipe Hexbin begin
    "If an `Int`, sets the number of bins in x and y direction. If a `Tuple{Int, Int}`, sets the number of bins for x and y separately."
    bins=20
    "Weights for each observation.  Can be `nothing` (each observation carries weight 1) or any `AbstractVector{<: Real}` or `StatsBase.AbstractWeights`."
    weights=nothing
    "If a `Real`, makes equally-sided hexagons with width `cellsize`. If a `Tuple{Real, Real}` specifies hexagon width and height separately."
    cellsize=nothing
    "The minimal number of observations in the bin to be shown. If 0, all zero-count hexagons fitting into the data limits will be shown."
    threshold=1
    strokewidth=0
    strokecolor=:black
    MakieCore.mixin_colormap_attributes()...
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

conversion_trait(::Type{<:Hexbin}) = PointBased()

function data_limits(hb::Hexbin)
    bb = Rect3d(hb.plots[1][1][])
    fn(num::Real) = Float64(num)
    fn(tup::Union{Tuple,Vec2}) = Vec2d(tup...)

    ms = 2.0 .* fn(hb.plots[1].markersize[])
    nw = widths(bb) .+ (ms..., 0.0)
    no = bb.origin .- ((0.5 .* ms)..., 0.0)

    return Rect3d(no, nw)
end
boundingbox(p::Hexbin, space::Symbol = :data) = transform_bbox(p, data_limits(hb))

get_weight(weights, i) = Float64(weights[i])
get_weight(::StatsBase.UnitWeights, i) = 1e0
get_weight(::Nothing, i) = 1e0

function plot!(hb::Hexbin{<:Tuple{<:AbstractVector{<:Point2}}})
    xy = hb[1]

    points = Observable(Point2f[])
    count_hex = Observable(Float64[])
    markersize = Observable(Vec2f(1, 1))

    function calculate_grid(xy, weights, bins, cellsize, threshold)
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

        xspacing, yspacing, xoff, yoff, nbinsx, nbinsy =
            spacings_offsets_nbins(bins, cellsize, xmi, xma, ymi, yma)

        ysize = yspacing / 3 * 4
        ry = ysize / 2

        xsize = xspacing * 2
        rx = xsize / sqrt3

        d = Dict{Tuple{Int,Int}, Float64}()

        # for the distance measurement, the y dimension must be weighted relative to the x
        # dimension according to the different sizes in each, otherwise the attribution to hexagonal
        # cells is wrong
        yweight = xsize / ysize

        i = 1
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

            d[id] = get(d, id, 0) + (get_weight(weights, i))
            i += 1
        end

        if threshold == 0
            for iy in 0:nbinsy-1
                _nx = isodd(iy) ? fld(nbinsx, 2) : cld(nbinsx, 2)
                for ix in 0:_nx-1
                    _x = xoff + 2 * ix * xspacing + (isodd(iy) * xspacing)
                    _y = yoff + iy * yspacing
                    c = get(d, (ix, iy), 0.0)
                    push!(points[], Point2f(_x, _y))
                    push!(count_hex[], c)
                end
            end
        else
            # If we don't plot zero cells, we only have to iterate the sparse entries in the dict
            for ((ix, iy), value) in d
                if value >= threshold
                    _x = xoff + 2 * ix * xspacing + (isodd(iy) * xspacing)
                    _y = yoff + iy * yspacing
                    push!(points[], Point2f(_x, _y))
                    push!(count_hex[], value)
                end
            end
        end

        markersize[] = Vec2f(rx, ry)
        notify(points)
        return notify(count_hex)
    end
    onany(calculate_grid, xy, hb.weights, hb.bins, hb.cellsize, hb.threshold)

    # trigger once
    notify(hb.bins)

    replace_automatic!(hb, :colorrange) do
        if isempty(count_hex[])
            (0, 1)
        else
            mi, ma = extrema(count_hex[])
            # if we have only one unique value (usually happens) when there are very few points
            # and every cell has only 1 entry, then we set the minimum to 0 so we do not get
            # a singular colorrange error down the line.
            if mi == ma
                if ma == 0
                    (0, 1)
                else
                    (0, ma)
                end
            else
                (mi, ma)
            end
        end
    end

    hexmarker = Polygon(Point2f[(cos(a), sin(a)) for a in range(pi / 6, 13pi / 6; length=7)[1:6]])
    scale = if haskey(hb, :scale)
        @warn("`hexbin(..., scale=$(hb.scale[]))` is deprecated, use `hexbin(..., colorscale=$(hb.scale[]))` instead")
        hb.scale
    else
        hb.colorscale
    end
    return scatter!(hb, points;
                    colorrange=hb.colorrange,
                    color=count_hex,
                    colormap=hb.colormap,
                    colorscale=scale,
                    lowclip=hb.lowclip,
                    highclip=hb.highclip,
                    nan_color=hb.nan_color,
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
