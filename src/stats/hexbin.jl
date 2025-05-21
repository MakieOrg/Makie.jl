"""
    hexbin(xs, ys; kwargs...)

Plots a heatmap with hexagonal bins for the observations `xs` and `ys`.
"""
@recipe Hexbin begin
    "If an `Int`, sets the number of bins in x and y direction. If a `NTuple{2, Int}`, sets the number of bins for x and y separately."
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

# xy hardcoded scale factors
@inline _hexbin_size_fact() = Float64(2), Float64(4 / 3)
@inline _hexbin_msize_fact() = Float64(1 / sqrt(3)), Float64(1 / 2)

function _spacings_offsets_nbins(bins::NTuple{2,Int}, cellsize::Nothing, lims::Rect2d)
    any(<(2), bins) && error("Minimum number of bins in one direction is 2, got $bins.")
    return widths(lims) ./ (bins .- 1), origin(lims), bins
end

_spacings_offsets_nbins(bins::Int, cellsize::Nothing, lims::Rect2d) =
    _spacings_offsets_nbins((bins, bins), cellsize, lims)

function _spacings_offsets_nbins(bins, cellsize::Real, lims::Rect2d)
    mx, my = _hexbin_msize_fact()
    return _spacings_offsets_nbins(bins, (cellsize, cellsize * mx / my), lims)
end

function _spacings_offsets_nbins(bins, cellsizes::Tuple{<:Real,<:Real}, lims::Rect2d)
    spacing = cellsizes ./ _hexbin_size_fact()
    nbins = fld.(widths(lims), spacing)
    rest = mod.(widths(lims), spacing)
    offset = collect(origin(lims))
    for dim in eachindex(rest)
        rest[dim] > 0 && (offset[dim] -= (spacing[dim] - rest[dim]) / 2)
    end
    return spacing, offset, @. Int(nbins) + (rest > 0)
end

conversion_trait(::Type{<:Hexbin}) = PointBased()

data_limits(hb::Hexbin) = Rect3d(hb[1][])
function boundingbox(hb::Hexbin, space::Symbol = :data)
    bb = Rect3d(hb.plots[1][1][])
    fn(num::Real) = Float64(num)
    fn(tup::Union{Tuple,Vec2}) = Vec2d(tup...)

    ms = 2.0 .* fn(hb.plots[1].markersize[])
    nw = widths(bb) .+ (ms..., 0.0)
    no = bb.origin .- ((0.5 .* ms)..., 0.0)
    return apply_model(hb.model[], Rect3d(no, nw))
end

get_weight(weights, i) = Float64(weights[i])
get_weight(::Union{Nothing,StatsBase.UnitWeights}, _) = 1.0

function plot!(hb::Hexbin{<:Tuple{<:AbstractVector{<:Point2}}})
    tf = transform_func(hb)

    points = Observable(Point2f[])
    count_hex = Observable(Float64[])
    markersize = Observable(Vec2f(1, 1))

    function add_hex_point((ix, iy), spacing, offset, count)
        pt = Point2f(offset .+ (2 * ix + isodd(iy), iy) .* spacing)
        push!(points[], pt)
        push!(count_hex[], count)
    end

    function calculate_grid(xy, weights, bins, cellsize, threshold)
        empty!(points[])
        empty!(count_hex[])

        isempty(xy) && return

        # enclose data in limits
        lox, hix = extrema(p -> p[1], xy)
        loy, hiy = extrema(p -> p[2], xy)
        _origin = Point(prevfloat(lox), prevfloat(loy))
        width = Point(nextfloat(hix), nextfloat(hiy)) - _origin
        lims = apply_transform(tf, Rect2d(_origin, width))

        spacing, offset, (nbinsx, nbinsy) = _spacings_offsets_nbins(bins, cellsize, lims)

        size = spacing .* _hexbin_size_fact()
        msize = size .* _hexbin_msize_fact()

        # for the distance measurement, the y dimension must be weighted relative to the x
        # dimension according to the different sizes in each, otherwise the attribution to hexagonal
        # cells is wrong
        yweight = size[1] / size[2]

        bin_map = Dict{NTuple{2,Int}, Float64}()

        i = 1
        for _xy in xy
            tx, ty = txy = apply_transform(tf, _xy)
            (nx, ny), (nxs, nys), (dvx, dvy) = _nearest_center(txy, spacing, offset)

            d1 = (tx - nx)^2 + (yweight * (ty - ny))^2
            d2 = (tx - nxs)^2 + (yweight * (ty - nys))^2

            id = if d1 < d2
                (cld(dvx, 2), ifelse(iseven(dvy), dvy, dvy + 1))
            else
                (fld(dvx, 2), ifelse(iseven(dvy), dvy + 1, dvy))
            end

            bin_map[id] = get(bin_map, id, 0.0) + get_weight(weights, i)
            i += 1
        end

        if threshold == 0
            for iy in 0:nbinsy-1
                _nx = isodd(iy) ? fld(nbinsx, 2) : cld(nbinsx, 2)
                for ix in 0:_nx-1
                    add_hex_point((ix, iy), spacing, offset, get(bin_map, (ix, iy), 0.0))
                end
            end
        else
            # if we don't plot zero cells, we only have to iterate the sparse entries in the dict
            for (xy, value) in bin_map
                value ≥ threshold && add_hex_point(xy, spacing, offset, value)
            end
        end

        markersize[] = Vec2f(msize)
        notify(points)
        return notify(count_hex)
    end
    onany(calculate_grid, hb[1], hb.weights, hb.bins, hb.cellsize, hb.threshold)

    notify(hb.bins)  # trigger once

    computed_colorrange = map!(hb, hb.colorrange) do colorrange
        if colorrange === automatic
            if isempty(count_hex[])
                (0, 1)
            else
                mi, ma = extrema(count_hex[])
                # if we have only one unique value (usually happens) when there are very few points
                # and every cell has only 1 entry, then we set the minimum to 0 so we do not get
                # a singular colorrange error down the line.
                if mi == ma
                    (0, ifelse(ma == 0, 1, ma))
                else
                    (mi, ma)
                end
            end
        else
            colorrange
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
                    colorrange=computed_colorrange,
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
                    strokecolor=hb.strokecolor,
                    transformation = :inherit_model)
end

function _nearest_center(val, spacing, offset)
    dv = @. Int(fld(val - offset, spacing))
    rounded = @. offset + spacing * (dv + isodd(dv))
    rounded_scaled = @. offset + spacing * (dv + iseven(dv))
    return rounded, rounded_scaled, dv
end
