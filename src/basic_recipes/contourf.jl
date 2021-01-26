"""
    contourf(xs, ys, zs; kwargs...)

Plots a filled contour of the height information in `zs` at horizontal grid positions `xs`
and vertical grid positions `ys`.

The attribute `levels` can be either
- an `Int` that produces n equally wide levels or bands
- an `AbstractVector{<:Real}` that lists n consecutive edges from low to high, which result in n-1 levels or bands

If you want to show a band from `-Inf` to the low edge, set `extendlow` to `:auto` for the same color as the first level, or specify a different color (default `nothing` means no extended band)
If you want to show a band from the high edge to `Inf`, set `extendhigh` to `:auto` for the same color as the last level, or specify a different color (default `nothing` means no extended band)

## Attributes
$(ATTRIBUTES)
"""
@recipe(Contourf) do scene
    Theme(
        levels = 10,
        colormap = :viridis,
        extendlow = nothing,
        extendhigh = nothing,
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

conversion_trait(::Type{<:Contourf}) = SurfaceLike()

function AbstractPlotting.plot!(c::Contourf{<:Tuple{<:AbstractVector{<:Real}, <:AbstractVector{<:Real}, <:AbstractMatrix{<:Real}}})
    xs, ys, zs = c[1:3]


    c.attributes[:_computed_levels] = lift(zs, c.levels) do zs, levels
        _get_isoband_levels(levels, extrema_nan(zs)...)
    end

    colorrange = lift(c._computed_levels) do levels
        minimum(levels), maximum(levels)
    end

    c.attributes[:_computed_colormap] = lift(c._computed_levels, c.colormap) do levels, cmap
        levels_scaled = (levels .- minimum(levels)) ./ (maximum(levels) - minimum(levels))
        cgrad(cmap, levels_scaled, categorical = true)
    end


    lowcolor = lift(c.extendlow, typ = Union{Nothing, RGBAf0}) do el
        if el === nothing
            nothing
        elseif el === automatic || el == :auto
            RGBAf0(get(c._computed_colormap[], 0))
        else
            convert_attribute(el, key"color"())::RGBAf0
        end
    end
    c.attributes[:_computed_extendlow] = lowcolor
    is_extended_low = lift(x -> !isnothing(x), lowcolor)

    highcolor = lift(c.extendhigh, typ = Union{Nothing, RGBAf0}) do eh
        if eh === nothing
            nothing
        elseif eh === automatic || eh == :auto
            RGBAf0(get(c._computed_colormap[], 1))
        else
            convert_attribute(eh, key"color"())::RGBAf0
        end
    end
    c.attributes[:_computed_extendhigh] = highcolor
    is_extended_high = lift(x -> !isnothing(x), highcolor)



    PolyType = typeof(Polygon(Point2f0[], [Point2f0[]]))

    polys = Observable(PolyType[])
    colors = Observable(RGBAf0[])

    function calculate_polys(xs, ys, zs, levels::Vector{Float32}, is_extended_low, is_extended_high)
        empty!(polys[])
        empty!(colors[])

        levels = copy(levels)
        @assert issorted(levels)
        is_extended_low && pushfirst!(levels, -Inf)
        is_extended_high && push!(levels, Inf)
        lows = levels[1:end-1]
        highs = levels[2:end]

        nbands = length(lows)

        # zs needs to be transposed to match rest of abstractplotting
        isos = Isoband.isobands(xs, ys, zs', lows, highs)

        allvertices = Point2f0[]
        allfaces = NgonFace{3,OffsetInteger{-1,UInt32}}[]
        allids = Int[]
        levelcenters = (highs .+ lows) ./ 2

        for (i, (center, group)) in enumerate(zip(levelcenters, isos))
            points = Point2f0.(group.x, group.y)
            polygroups = _group_polys(points, group.id)
            for polygroup in polygroups
                outline = polygroup[1]
                holes = polygroup[2:end]
                push!(polys[], GeometryBasics.Polygon(outline, holes))
                # use contour level center value as color
                center_scaled = (center - colorrange[][1]) / (colorrange[][2] - colorrange[][1])
                color::RGBAf0 = if i == 1 && is_extended_low
                    lowcolor[]
                elseif i == nbands && is_extended_high
                    highcolor[]
                else
                    get(c._computed_colormap[], center_scaled)
                end
                push!(colors[], color)
            end
        end
        polys[] = polys[]
        return
    end

    onany(calculate_polys, xs, ys, zs, c._computed_levels, is_extended_low, is_extended_high)
    # onany doesn't get called without a push, so we call
    # it on a first run!
    calculate_polys(xs[], ys[], zs[], c._computed_levels[], is_extended_low[], is_extended_high[])

    mesh!(c,
        polys,
        # colormap = c._computed_colormap,
        # colorrange = colorrange,
        color = colors,
        shading=false)
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
    groups = Vector{Vector{Point2f0}}[]

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
