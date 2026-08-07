"""
    tricontour(triangulation, zs; kwargs...)
    tricontour(xs, ys, zs; kwargs...)

Plots isolines of the scalar field `zs` at the horizontal positions `xs` and vertical
positions `ys` on an unstructured triangular grid. A `Triangulation` from
DelaunayTriangulation.jl can also be provided instead of `xs` and `ys`, otherwise an
unconstrained Delaunay triangulation of `xs` and `ys` is computed.
"""
@recipe Tricontour begin
    mixin_colormap_attributes()...
    filtered_attributes(Lines, allow = (:linestyle, :linewidth, :joinstyle, :miter_limit))...
    """
    Can be either an `Int` which results in n equally-spaced isolines between the
    minimum and maximum of `zs`, or an `AbstractVector{<:Real}` that lists explicit
    isoline values from low to high.
    """
    levels = 10
    """
    The color of the contour lines. If `nothing`, colors are sampled from `colormap`
    according to each isoline's level value. Otherwise all lines use this single color.
    """
    color = nothing
    "Sets the colormap from which isoline colors are sampled when `color` is `nothing`."
    colormap = @inherit colormap
    """
    The mode with which the points in `xs` and `ys` are triangulated.
    Passing `DelaunayTriangulation()` performs a Delaunay triangulation.
    You can also pass a preexisting triangulation as an `AbstractMatrix{<:Int}`
    with size (3, n), where each column specifies the vertex indices of one triangle,
    or as a `Triangulation` from DelaunayTriangulation.jl.
    """
    triangulation = DelaunayTriangulation()
    mixin_generic_plot_attributes()...
    fxaa = false
end

function used_attributes(::Type{<:Tricontour}, ::AbstractVector{<:Real}, ::AbstractVector{<:Real}, ::AbstractVector{<:Real})
    return (:triangulation,)
end

function convert_arguments(
        ::Type{<:Tricontour}, x::AbstractVector{<:Real}, y::AbstractVector{<:Real}, z::AbstractVector{<:Real};
        triangulation = DelaunayTriangulation()
    )
    T = float_type(x, y, z)
    z = elconvert(T, z)
    points = [elconvert(T, x)'; elconvert(T, y)']
    if triangulation isa DelaunayTriangulation
        tri = DelTri.triangulate(points, randomise = false)
    elseif !(triangulation isa DelTri.Triangulation)
        if typeof(triangulation) <: AbstractMatrix{<:Int} && size(triangulation, 1) != 3
            triangulation = triangulation'
        end
        tri = DelTri.Triangulation(points)
        triangles = DelTri.get_triangles(tri)
        for τ in eachcol(triangulation)
            DelTri.add_triangle!(triangles, τ)
        end
    end
    return (tri, z)
end

function _get_tricontour_levels(zs, scale, levels)
    if levels isa Integer
        zmin, zmax = extrema_nan(zs)
        isapprox(zmin, zmax) && return Float32[]
        return Float32.(range(zmin, zmax; length = levels))
    else
        return Float32.(apply_scale(scale, levels))
    end
end

function _calculate_tricontour_lines!(xs_out, ys_out, colors, triangulation, zs, levels)
    tlist = compute_triangulation(triangulation)
    x_pts = [DelTri.getx(p) for p in DelTri.each_point(triangulation)]
    y_pts = [DelTri.gety(p) for p in DelTri.each_point(triangulation)]
    m = TriplotBase.TriMesh(x_pts, y_pts, tlist)
    contours = TriplotBase.tricontour(m, zs, levels)
    for c in contours
        for polyline in c.polylines
            isempty(polyline) && continue
            for (x, y) in polyline
                push!(xs_out, Float32(x))
                push!(ys_out, Float32(y))
                push!(colors, c.level)
            end
            push!(xs_out, NaN32)
            push!(ys_out, NaN32)
            push!(colors, c.level)
        end
    end
    return
end

function plot!(c::Tricontour{<:Tuple{<:DelTri.Triangulation, <:AbstractVector{<:Real}}})
    map!(apply_scale, c, [:colorscale, :converted_2], :scaled_zs)
    map!(_get_tricontour_levels, c, [:scaled_zs, :colorscale, :levels], :computed_levels)

    map!(
        c, [:colorrange, :colorscale, :computed_levels, :scaled_zs], :computed_colorrange
    ) do colorrange, scale, levels, zs
        autorange = if isempty(levels)
            c = Float32(first(zs))
            delta = max(one(c), abs(c))
            (c - delta, c + delta)
        else
            extrema_nan(levels)
        end
        return combined_colorrange(scale, colorrange, autorange)
    end

    register_computation!(
        c,
        [:converted_1, :scaled_zs, :computed_levels],
        [:line_xs, :line_ys, :line_colors]
    ) do (tri, zs, levels), _, cached
        if isnothing(cached)
            xs = Float32[]
            ys = Float32[]
            colors = eltype(levels)[]
        else
            xs, ys, colors = empty!.(values(cached))
        end
        _calculate_tricontour_lines!(xs, ys, colors, tri, zs, levels)
        return (xs, ys, colors)
    end

    map!(c, [:color, :line_colors], :final_color) do col, lc
        return isnothing(col) ? lc : col
    end

    lines!(
        c, c.attributes, c.line_xs, c.line_ys;
        color = c.final_color, colorrange = c.computed_colorrange,
        colorscale = identity
    )

    return c
end
