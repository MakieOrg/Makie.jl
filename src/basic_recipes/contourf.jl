"""
    contourf(xs, ys, zs; kwargs...)

Plots a filled contour of the height information in `zs` at horizontal grid positions `xs`
and vertical grid positions `ys`.

The attribute `levels` can be either
- an `Int` that produces n equally wide levels or bands
- an `AbstractVector{<:Real}` that lists n consecutive edges from low to high, which result in n-1 levels or bands

You can also set the `mode` attribute to `:relative`.
In this mode you specify edges by the fraction between minimum and maximum value of `zs`.
This can be used for example to draw bands for the upper 90% while excluding the lower 10% with `levels = 0.1:0.1:1.0, mode = :relative`.

In :normal mode, if you want to show a band from `-Inf` to the low edge,
set `extendlow` to `:auto` for the same color as the first level,
or specify a different color (default `nothing` means no extended band)
If you want to show a band from the high edge to `Inf`, set `extendhigh`
to `:auto` for the same color as the last level, or specify a different color
(default `nothing` means no extended band).

If `levels` is an `Int`, the contour plot will be rectangular as all `zs` will be covered.
This is why `Axis` defaults to tight limits for such contourf plots.
If you specify `levels` as an `AbstractVector{<:Real}`, however, note that the axis limits include the default margins because the contourf plot can have an irregular shape.
You can use `tightlimits!(ax)` to tighten the limits similar to the `Int` behavior.

## Attributes
$(ATTRIBUTES)
"""
@recipe(Contourf) do scene
    Theme(
        levels = 10,
        mode = :normal,
        colormap = theme(scene, :colormap),
        extendlow = nothing,
        extendhigh = nothing,
        # TODO, Isoband doesn't seem to support nans?
        nan_color = :transparent,
        inspectable = theme(scene, :inspectable),
        transparency = false
    )
end

# these attributes are computed dynamically and needed for colorbar e.g.
# _computed_levels
# _computed_colormap
# _computed_extendlow
# _computed_extendhigh

function _get_isoband_levels(levels::Int, mi, ma)
    edges = Float32.(LinRange(mi, ma, levels+1))
end

function _get_isoband_levels(levels::AbstractVector{<:Real}, mi, ma)
    edges = Float32.(levels)
    @assert issorted(edges)
    edges
end

function convert_arguments(::Type{<: Contourf}, args...)
    _x, _y, z = convert_arguments(ContinuousSurface(), args...)
    x = to_vector(_x, size(z, 1), Float32)
    y = to_vector(_y, size(z, 2), Float32)
    return (x, y, z)
end

function _get_isoband_levels(::Val{:normal}, levels, values)
    _get_isoband_levels(levels, extrema_nan(values)...)
end

function _get_isoband_levels(::Val{:relative}, levels::AbstractVector, values)
    mi, ma = extrema_nan(values)
    Float32.(levels .* (ma - mi) .+ mi)
end


function Makie.plot!(c::PlotObject, ::Contourf, ::AbstractVector{<:Real}, ::AbstractVector{<:Real}, ::AbstractMatrix{<:Real})
    xs, ys, zs = c[1:3]

    c.attributes[:_computed_levels] = lift(c, zs, c.levels, c.mode) do zs, levels, mode
        _get_isoband_levels(Val(mode), levels, vec(zs))
    end

    colorrange = lift(c, c._computed_levels) do levels
        minimum(levels), maximum(levels)
    end
    computed_colormap = lift(compute_contourf_colormap, c, c._computed_levels, c.colormap, c.extendlow,
                             c.extendhigh)
    c.attributes[:_computed_colormap] = computed_colormap

    lowcolor = Observable{RGBAf}()
    map!(compute_lowcolor, c, lowcolor, c.extendlow, c.colormap)
    c.attributes[:_computed_extendlow] = lowcolor
    is_extended_low = lift(!isnothing, c, lowcolor)

    highcolor = Observable{RGBAf}()
    map!(compute_highcolor, c, highcolor, c.extendhigh, c.colormap)
    c.attributes[:_computed_extendhigh] = highcolor
    is_extended_high = lift(!isnothing, c, highcolor)

    PolyType = typeof(Polygon(Point2f[], [Point2f[]]))

    polys = Observable(PolyType[])
    colors = Observable(Float64[])

    function calculate_polys(xs, ys, zs, levels::Vector{Float32}, is_extended_low, is_extended_high)
        empty!(polys[])
        empty!(colors[])

        levels = copy(levels)
        @assert issorted(levels)
        is_extended_low && pushfirst!(levels, -Inf)
        is_extended_high && push!(levels, Inf)
        lows = levels[1:end-1]
        highs = levels[2:end]

        # zs needs to be transposed to match rest of makie
        isos = Isoband.isobands(xs, ys, zs', lows, highs)

        levelcenters = (highs .+ lows) ./ 2

        for (i, (center, group)) in enumerate(zip(levelcenters, isos))
            points = Point2f.(group.x, group.y)
            polygroups = _group_polys(points, group.id)
            for polygroup in polygroups
                outline = polygroup[1]
                holes = polygroup[2:end]
                push!(polys[], GeometryBasics.Polygon(outline, holes))
                # use contour level center value as color
                push!(colors[], center)
            end
        end
        polys[] = polys[]
        return
    end

    onany(calculate_polys, c, xs, ys, zs, c._computed_levels, is_extended_low, is_extended_high)
    # onany doesn't get called without a push, so we call
    # it on a first run!
    calculate_polys(xs[], ys[], zs[], c._computed_levels[], is_extended_low[], is_extended_high[])

    poly!(c,
        polys,
        colormap = c._computed_colormap,
        colorrange = colorrange,
        highclip = highcolor,
        lowclip = lowcolor,
        nan_color = c.nan_color,
        color = colors,
        strokewidth = 0,
        strokecolor = :transparent,
        shading = false,
        inspectable = c.inspectable,
        transparency = c.transparency
    )
end

"""
    _group_polys(points, ids)

Given a vector of polygon vertices, and one vector of group indices, which
are assumed to be returned from the isoband algorithm, return
a vector of groups, where each group has one outer polygon and zero or more
inner polygons which are holes in the outer polygon. It is possible that one
group has multiple outer polygons with multiple holes each.
"""
function _group_polys(points, ids)

    polys = [points[ids .== i] for i in unique(ids)]
    npolys = length(polys)

    polys_lastdouble = [push!(p, first(p)) for p in polys]

    # this matrix stores whether poly i is contained in j
    # because the marching squares algorithm won't give us any
    # intersecting or overlapping polys, it should be enough to
    # check if a single point is contained, saving some computation time
    containment_matrix = [
        p1 != p2 &&
        PolygonOps.inpolygon(first(p1), p2) == 1
        for p1 in polys_lastdouble, p2 in polys_lastdouble]

    unclassified_polyindices = collect(1:size(containment_matrix, 1))
    # @show unclassified_polyindices

    # each group has first an outer polygon, and then its holes
    # TODO: don't specifically type this 2f0?
    groups = Vector{Vector{Point2f}}[]

    # a dict that maps index in `polys` to index in `groups` for outer polys
    outerindex_groupdict = Dict{Int, Int}()

    # all polys have to be classified
    while !isempty(unclassified_polyindices)
        to_keep = ones(Bool, length(unclassified_polyindices))

        # go over unclassifieds and find outer polygons in the remaining containment matrix
        for (ii, i) in enumerate(unclassified_polyindices)
            # an outer polygon is not inside any other polygon of the matrix
            if sum(containment_matrix[ii, :]) == 0
                # an outer polygon
                # println(i, " is an outer polygon")
                push!(groups, [polys_lastdouble[i]])
                outerindex_groupdict[i] = length(groups)
                # delete this poly from further rounds
                to_keep[ii] = false
            end
        end

        # go over unclassifieds and find hole polygons
        for (ii, i) in enumerate(unclassified_polyindices)
            # the hole polygons can only be in one polygon from the current group
            # if they are in more than one, they are "inner outer" or inner hole polys
            # and will be handled in one of the following passes
            if sum(containment_matrix[ii, :]) == 1
                outerpolyindex_of_unclassified = findfirst(containment_matrix[ii, :])
                outerpolyindex = unclassified_polyindices[outerpolyindex_of_unclassified]
                # a hole
                # println(i, " is an inner polygon of ", outerpolyindex)
                groupindex = outerindex_groupdict[outerpolyindex]
                push!(groups[groupindex], polys_lastdouble[i])
                # delete this poly from further rounds
                to_keep[ii] = false
            end
        end

        unclassified_polyindices = unclassified_polyindices[to_keep]
        containment_matrix = containment_matrix[to_keep, to_keep]
    end
    groups
end
