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
        binsize=nothing,
        mincnt=1,
        scale=identity
    )
end

function spacings_offsets_nbins(bins::Tuple{Int, Int}, binsize::Nothing, xmi, xma, ymi, yma)
    x_diff = xma - xmi
    y_diff = yma - ymi

    xspacing, yspacing = (x_diff, y_diff) ./ bins
    xspacing, yspacing, xmi, ymi, bins...
end

spacings_offsets_nbins(bins, binsize::Real, xmi, xma, ymi, yma) = spacings_offsets_nbins(bins, (binsize, binsize*2/sqrt(3)), xmi, xma, ymi, yma)
spacings_offsets_nbins(bins::Int, binsize::Nothing, xmi, xma, ymi, yma) = spacings_offsets_nbins((bins, bins), binsize, xmi, xma, ymi, yma)

function spacings_offsets_nbins(bins, binsizes::Tuple{Real, Real}, xmi, xma, ymi, yma)
    x_diff = xma - xmi
    y_diff = yma - ymi
    xspacing = binsizes[1]/2
    yspacing = binsizes[2]*3/4
    (nx, restx), (ny, resty) = fldmod.((x_diff, y_diff), (xspacing, yspacing))

    xspacing, yspacing, xmi - (restx > 0 ? xspacing/2 : 0), ymi - (resty > 0 ? yspacing/2 : 0), nx + (restx > 0), ny + (resty > 0)
end

Makie.conversion_trait(::Type{<:Hexbin}) = PointBased()

function Makie.plot!(hb::Hexbin{<:Tuple{<:AbstractVector{<:Point2}}})
    xy = hb[1]

    points = Observable(Point2f[])
    count_hex = Observable(Float64[])
    markersize = Observable(Vec2f(1, 1))

    function calculate_grid(xy, bins, binsize, mincnt, scale)
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

        xspacing, yspacing, xoff, yoff, nbinsx, nbinsy = spacings_offsets_nbins(bins, binsize, xmi, xma, ymi, yma)

        ysize = yspacing / 3 * 4
        ry = ysize / 2

        xsize = xspacing * 2
        rx = xsize / sqrt3

        d = Dict{Tuple{Float64, Float64}, Int}()

        # for the distance measurement, the y dimension must be weighted relative to the x
        # dimension according to the different sizes in each, otherwise the attribution to hexagonal
        # cells is wrong
        yweight = xsize / ysize

        for (_x, _y) in xy
            nx, nxs, dvx = nearest_center(_x, xspacing, xoff)
            ny, nys, dvy = nearest_center(_y, yspacing, yoff)

            d1 = ((_x - nx) ^ 2 + (yweight * (_y - ny)) ^ 2)
            d2 = ((_x - nxs) ^ 2 + (yweight * (_y - nys)) ^ 2)

            is_grid1 = d1 < d2

            _xy = is_grid1 ? (nx, ny) : (nxs, nys)

            d[_xy] = get(d, _xy, 0) + 1
        end

        # this iteration scheme misses points at the edges and I don't understand why
        # for plotting a whole field
        # with zeros something like this would be needed, though..
        #
        # for ix in 0:2:nbinsx
        #     for iy in 0:2:nbinsy
        #         _x = center_value(ix, xspacing, xoff, false)
        #         _y = center_value(iy, yspacing, yoff, false)
        #         c = get(d, (_x, _y), 0)
        #         if c >= mincnt
        #             push!(points[], Point2f(_x, _y))
        #             push!(count_hex[], c)
        #         end
        #     end
        # end
        # for ix in 1:2:nbinsx
        #     for iy in 1:2:nbinsy
        #         _x = center_value(ix, xspacing, xoff, true)
        #         _y = center_value(iy, yspacing, yoff, true)
        #         c = get(d, (_x, _y), 0)
        #         if c >= mincnt
        #             push!(points[], Point2f(_x, _y))
        #             push!(count_hex[], c)
        #         end
        #     end
        # end

        for (key, value) in d
            push!(points[], key)
            push!(count_hex[], value)
        end

        sum(count_hex[]) != length(xy) && error("Length of points mismatching count vector")

        markersize[] = Vec2f(rx, ry)
        notify(points)
        notify(count_hex)
    end
    onany(calculate_grid, xy, hb.bins, hb.binsize, hb.mincnt, hb.scale)
    # trigger once
    notify(hb.bins)

    replace_automatic!(hb, :colorrange) do
        if isempty(count_hex[])
            (0, 1)
        else
            (minimum(count_hex[]), maximum(count_hex[]))
        end
    end

    hexmarker = Polygon(Point2f[(cos(a), sin(a)) for a in range(pi/6, 13pi/6, length = 7)[1:6]])

    scatter!(hb, points; colorrange = hb.colorrange, color=count_hex, colormap=hb.colormap, marker = hexmarker, markersize = markersize, markerspace = :data)
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