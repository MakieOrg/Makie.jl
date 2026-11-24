"""
Plots a filled contour where each pixel in the grid defined by `xs` and `ys` is
colored based on the level its `data` values map to.
"""
@recipe Contourf (x, y, z) begin
    """
    Can be either
    - an `Int` that produces n equally wide levels or bands
    - an `AbstractVector{<:Real}` that lists n consecutive edges from low to high, which result in n-1 levels or bands

    If `levels` is an `Int`, the contourf plot will be rectangular as all `zs` values will be covered edge to edge.
    This is why `Axis` defaults to tight limits for such contourf plots.
    If you specify `levels` as an `AbstractVector{<:Real}`, however, note that the axis limits include the default margins because the contourf plot can have an irregular shape.
    You can use `tightlimits!(ax)` to tighten the limits similar to the `Int` behavior.
    """
    levels = 10
    """
    Determines how the `levels` attribute is interpreted, either `:normal` or `:relative`.
    In `:normal` mode, the levels correspond directly to the z values.
    In `:relative` mode, you specify edges by the fraction between minimum and maximum value of `zs`.
    This can be used for example to draw bands for the upper 90% while excluding the lower 10% with `levels = 0.1:0.1:1.0, mode = :relative`.
    """
    mode = :normal
    """
    In `:normal` mode, if you want to show a band from `-Inf` to the low edge,
    set `extendlow` to `:auto` to give the extension the same color as the first level,
    or specify a color directly (default `nothing` means no extended band).
    """
    extendlow = nothing
    """
    In `:normal` mode, if you want to show a band from the high edge to `Inf`, set `extendhigh`
    to `:auto` to give the extension the same color as the last level, or specify a color directly
    (default `nothing` means no extended band).
    """
    extendhigh = nothing
    mixin_generic_plot_attributes()...
    # TODO, Isoband doesn't seem to support nans?
    mixin_colormap_attributes(exclude = (:lowclip, :highclip))...
end

_get_isoband_levels(levels::Int, mi, ma) = collect(range(Float32(mi), nextfloat(Float32(ma)), length = levels + 1))

function _get_isoband_levels(levels::AbstractVector{<:Real}, mi, ma)
    edges = Float32.(levels)
    @assert issorted(edges)
    return edges
end

conversion_trait(::Type{<:Contourf}) = VertexGrid()

function _get_isoband_levels(::Val{:normal}, levels, values)
    return _get_isoband_levels(levels, extrema_nan(values)...)
end

function _get_isoband_levels(::Val{:relative}, levels::AbstractVector, values)
    mi, ma = extrema_nan(values)
    return Float32.(levels .* (ma - mi) .+ mi)
end

"""
    calculate_contourf_polys!(polys, colors, xs, ys, zs, lows, highs)

Calculate the polygons and colors for a contourf plot, and store them in `polys` and `colors`.
This mutates the `polys` and `colors` vectors to contain the new data.

The mutating nature of the function enables efficient reuse of previously allocated memory!

This is an internal function, not public API and should not be treated as such.  Note that it currently
uses Isoband.jl internally.
"""
function calculate_contourf_polys!(
        polys::AbstractVector{<:GeometryBasics.Polygon}, colors::AbstractVector,
        xs::AbstractVector, ys::AbstractVector, zs::AbstractMatrix,
        lows::AbstractVector, highs::AbstractVector
    )
    # zs needs to be transposed to match rest of makie
    isos = Isoband.isobands(xs, ys, zs', lows, highs)

    levelcenters = (highs .+ lows) ./ 2

    for (i, (center, group)) in enumerate(zip(levelcenters, isos))
        points = Point2d.(group.x, group.y)
        polygroups = _group_polys(points, group.id)
        for polygroup in polygroups
            outline = polygroup[1]
            holes = polygroup[2:end]
            push!(polys, GeometryBasics.Polygon(outline, holes))
            # use contour level center value as color
            push!(colors, center)
        end
    end

    return (polys, colors)
end

# The x-vector/y-vector version is above.  Now for the x-matrix/y-matrix version.
# Here, we simply use a linear interpolation to transform the points before storing them.

function calculate_contourf_polys!(
        polys::AbstractVector{<:GeometryBasics.Polygon}, colors::AbstractVector,
        xs::AbstractMatrix, ys::AbstractMatrix, zs::AbstractMatrix,
        lows::AbstractVector, highs::AbstractVector
    )
    # A brief note on terminology:
    # - **rectilinear** space: the space of the z matrix, or the space of cartesian indices.
    #   This is usually `(1:n, 1:m)` for a `n x m` matrix.
    # - **curvilinear** space: the space defined by the `xs` and `ys` matrices.  This is the
    #   space of the points `(xs[i, j], ys[i, j])` for `i in 1:n` and `j in 1:m`.

    # We compute the isobands in rectilinear space first, and then transform
    # the polygons to curvilinear space.  This is a lossless procedure because
    # the algorithm is based on the isobands of the z matrix, which is defined in
    # rectilinear space.

    # zs needs to be transposed to match rest of makie
    # This is computing the isobands in rectilinear space.
    isos = Isoband.isobands(axes(zs, 1), axes(zs, 2), zs', lows, highs)
    # Now, we construct a 2-D linear interpolation from the rectilinear grid space
    # to the curvilinear grid space (FastInterpolations; matches Interpolations to ulp).
    point_interp = Makie.FastInterpolations.interp(
        axes(zs), Point2d.(xs, ys); method = Makie.FastInterpolations.LinearInterp()
    )

    levelcenters = (highs .+ lows) ./ 2

    for (i, (center, group)) in enumerate(zip(levelcenters, isos))
        points = Point2d.(group.x, group.y)
        polygroups = _group_polys(points, group.id)
        for rectilinear_polygroup in polygroups
            # NOTE: This is the only major change between the two versions
            # of the function `calculate_contourf_polys!`.
            # we reproject the lines to curvilinear space
            polygroup = map(rectilinear_polygroup) do ring
                map(ring) do point
                    point_interp(point[1], point[2])
                end
            end
            outline = polygroup[1]
            holes = polygroup[2:end]
            push!(polys, GeometryBasics.Polygon(outline, holes))
            # use contour level center value as color
            push!(colors, center)
        end
    end

    return (polys, colors)
end

function compute_lowcolor(el, cmap)
    if isnothing(el)
        return RGBAf(0, 0, 0, 0)
    elseif el === automatic || el === :auto
        return RGBAf(to_colormap(cmap)[begin])
    else
        return to_color(el)::RGBAf
    end
end

function compute_highcolor(eh, cmap)
    if isnothing(eh)
        return RGBAf(0, 0, 0, 0)
    elseif eh === automatic || eh === :auto
        return RGBAf(to_colormap(cmap)[end])
    else
        return to_color(eh)::RGBAf
    end
end


function register_contourf_computations!(graph, argname)
    map!(apply_scale, graph, [:colorscale, argname], :scaled_zs)

    map!(
        graph, [:scaled_zs, :colorscale, :levels, :mode],
        [:computed_levels, :auto_colorrange]
    ) do zs, scale, levels, mode
        combined_levels = if levels isa Integer
            mi, ma = extrema_nan(vec(zs))
            if isapprox(mi, ma)
                delta = max(one(mi), abs(mi))
                # An odd number of bands puts the constant value in the middle of a band.
                # With an even number it coincides with a band edge, where floating point noise
                # in `zs` splits the field over two neighbouring bands.
                nbands = isodd(levels) ? levels : levels + 1
                Float32.(range(mi - delta, ma + delta; length = nbands + 1))
            else
                _get_isoband_levels(Val(mode), levels, vec(zs))
            end
        else
            _get_isoband_levels(Val(mode), apply_scale(scale, levels), vec(zs))
        end
        return combined_levels, extrema(combined_levels)
    end
    map!(edges -> length(edges) - 1, graph, :computed_levels, :nlevels)

    register_colorrange!(graph, output = :computed_colorrange)

    map!(graph, [:nlevels, :colormap, :extendlow, :extendhigh], :base_colormap) do n, cmap, elow, ehigh
        _cmap = to_colormap(cmap)

        if elow === :auto && ehigh !== :auto
            return cgrad(_cmap, n + 1; categorical = true)[2:end]
        elseif ehigh === :auto && elow !== :auto
            return cgrad(_cmap, n + 1; categorical = true)[1:(end - 1)]
        elseif ehigh === :auto && elow === :auto
            return cgrad(_cmap, n + 2; categorical = true)[2:(end - 1)]
        else
            return _cmap
        end
    end
    map!(graph, [:base_colormap, :computed_levels], :computed_colormap) do base_cmap, edges
        edges_scaled = (edges .- minimum(edges)) ./ (maximum(edges) - minimum(edges))
        return cgrad(base_cmap, edges_scaled; categorical = true)
    end
    map!(compute_lowcolor, graph, [:extendlow, :colormap], :computed_lowcolor)
    map!(compute_highcolor, graph, [:extendhigh, :colormap], :computed_highcolor)

    return
end

function _calculate_polys!(polys, colors, xs, ys, zs, levels, is_extended_low, is_extended_high)
    levels = copy(levels)
    @assert issorted(levels)
    is_extended_low && pushfirst!(levels, -Inf)
    is_extended_high && push!(levels, Inf)
    lows = levels[1:(end - 1)]
    highs = levels[2:end]

    calculate_contourf_polys!(polys, colors, xs, ys, zs, lows, highs)
    return
end

function Makie.plot!(c::Contourf{<:Union{<:Tuple{<:AbstractVector{<:Real}, <:AbstractVector{<:Real}, <:AbstractMatrix{<:Real}}, <:Tuple{<:AbstractMatrix{<:Real}, <:AbstractMatrix{<:Real}, <:AbstractMatrix{<:Real}}}})
    graph = c.attributes

    register_contourf_computations!(graph, :z)

    register_computation!(
        graph,
        [:x, :y, :scaled_zs, :computed_levels, :extendlow, :extendhigh],
        [:polys, :computed_colors]
    ) do (xs, ys, zs, levels, _low, _high), changed, cached
        is_extended_low = !isnothing(_low)
        is_extended_high = !isnothing(_high)
        if isnothing(cached)
            polys = Polygon{2, Float64}[]
            colors = Float64[]
        else
            polys, colors = empty!.(values(cached))
        end
        _calculate_polys!(polys, colors, xs, ys, zs, levels, is_extended_low, is_extended_high)
        return (polys, colors)
    end

    return poly!(
        c, c.attributes, c.polys,
        colormap = c.computed_colormap,
        colorrange = c.computed_colorrange,
        colorscale = identity,
        highclip = c.computed_highcolor,
        lowclip = c.computed_lowcolor,
        color = c.computed_colors,
        strokewidth = 0,
        strokecolor = :transparent,
        shading = NoShading,
    )
end

# As rings don't cross, the first vertex or edge midpoint not on `outer`'s boundary decides whether `inner` ⊆ `outer`
# (midpoints catch rings whose vertices all lie on `outer`'s boundary, #5651)
function _is_ring_contained(inner, outer)
    for p in inner
        location = PolygonOps.inpolygon(p, outer)
        location == -1 || return location == 1
    end
    @inbounds for i in firstindex(inner):(lastindex(inner) - 1)
        location = PolygonOps.inpolygon((inner[i] .+ inner[i + 1]) ./ 2, outer)
        location == -1 || return location == 1
    end
    return false
end

# axis-aligned bounding box of a ring as `(xmin, ymin, xmax, ymax)`
function _ring_bbox(ring)
    xmin, xmax = extrema(p -> p[1], ring)
    ymin, ymax = extrema(p -> p[2], ring)
    return (xmin, ymin, xmax, ymax)
end

# whether bounding box `inner` lies within bounding box `outer` (boundaries may touch)
_bbox_contains(outer, inner) = outer[1] <= inner[1] && outer[2] <= inner[2] && inner[3] <= outer[3] && inner[4] <= outer[4]

"""
    _group_polys(points, ids)

Group the closed rings of one isoband into polygons. `points` holds the vertices of all rings,
`ids` the ring each vertex belongs to. Returns one vector of rings per polygon: its outer boundary
first, then its holes.

A ring enclosed by an even number of other rings (0, 2, ...) is an outer boundary, one enclosed by
an odd number is a hole. A hole belongs to the polygon whose outer boundary directly encloses it,
which is the enclosing ring with one less enclosing ring itself.
"""
function _group_polys(points, ids)
    rings = _closed_rings_by_id(points, ids)
    enclosing = _indices_of_enclosing_rings(rings)
    nesting_depth = length.(enclosing)
    is_outer_boundary(i) = iseven(nesting_depth[i])

    outer_boundaries = filter(is_outer_boundary, eachindex(rings))
    polygon_of_outer_boundary = Dict(outer => k for (k, outer) in enumerate(outer_boundaries))
    polygons = [[rings[outer]] for outer in outer_boundaries]

    for hole in eachindex(rings)
        is_outer_boundary(hole) && continue
        outer = _directly_enclosing_ring(enclosing[hole], nesting_depth)
        push!(polygons[polygon_of_outer_boundary[outer]], rings[hole])
    end
    return polygons
end

function _closed_rings_by_id(points, ids)
    unique_ids = unique(ids)
    ring_index = Dict(id => k for (k, id) in enumerate(unique_ids))
    rings = [eltype(points)[] for _ in unique_ids]
    for (p, id) in zip(points, ids)
        push!(rings[ring_index[id]], p)
    end
    return [push!(ring, first(ring)) for ring in rings]
end

# As marching squares rings don't cross, ring i can only be inside ring j if its bounding box is inside that of ring j
function _indices_of_enclosing_rings(rings)
    bboxes = map(_ring_bbox, rings)
    return [
        [j for j in eachindex(rings) if i != j && _bbox_contains(bboxes[j], bboxes[i]) && _is_ring_contained(rings[i], rings[j])]
            for i in eachindex(rings)
    ]
end

function _directly_enclosing_ring(enclosing, nesting_depth)
    innermost_depth = length(enclosing) - 1
    candidates = filter(j -> nesting_depth[j] == innermost_depth, enclosing)
    length(candidates) == 1 || error("Could not find the outer ring of a contour hole, the contour rings seem to intersect.")
    return only(candidates)
end
