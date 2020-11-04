"""
    contourf(xs, ys, zs; kwargs...)

Plots a filled contour of the height information in `zs` at horizontal grid positions `xs`
and vertical grid positions `ys`.

## Attributes
$(ATTRIBUTES)
"""
@recipe(Contourf) do scene
    Theme(
        levels = 10,
        colormap = :viridis,
    )
end

function _get_isoband_levels(levels::Int, mi, ma)
    Float32.(LinRange(mi, ma, levels+1))
end

function _get_isoband_levels(levels::AbstractVector{<:Real}, mi, ma)
    Float32.(levels)
end

function AbstractPlotting.plot!(c::Contourf{<:Tuple{Any, Any, Any}})
    xs, ys, zs = c[1:3]

    levels = lift(zs, c.levels) do zs, levels
        _get_isoband_levels(levels, extrema(zs)...)
    end


    poly_and_colors = lift(xs, ys, zs, levels) do xs, ys, zs, levels
        lows, highs = levels[1:end-1], levels[2:end]
        isos = Isoband.isobands(xs, ys, zs, lows, highs)

        allvertices = Point2f0[]
        allfaces = NgonFace{3,OffsetInteger{-1,UInt32}}[]
        allids = Int[]

        # TODO: this is ugly
        polys = Vector{typeof(Polygon(rand(Point2f0, 3), [rand(Point2f0, 3)]))}()
        colors = Int[]

        foreach(enumerate(isos)) do (i, group)

            points = Point2f0.(group.x, group.y)
            polygroups = _group_polys(points, group.id)

            for polygroup in polygroups

                outline = polygroup[1]
                holes = polygroup[2:end]

                poly = GeometryBasics.Polygon(outline, holes)

                push!(polys, poly)
                # use index as color. what about unequal levels, how should that be reflected in the color
                push!(colors, i)
            end

        end

        GeometryBasics.MultiPolygon(polys), colors
    end

    mesh!(c, @lift($poly_and_colors[1]),
        shading = false,
        colormap = c.colormap,
        color = @lift($poly_and_colors[2]))
    c
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