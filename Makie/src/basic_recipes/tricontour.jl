"""
    tricontour(triangulation, zs; kwargs...)
    tricontour(xs, ys, zs; kwargs...)

Plots isolines of the scalar field `zs` at the horizontal positions `xs` and vertical
positions `ys` on an unstructured triangular grid. A `Triangulation` from
DelaunayTriangulation.jl can also be provided instead of `xs` and `ys`, otherwise an
unconstrained Delaunay triangulation of `xs` and `ys` is computed.
"""
@recipe Tricontour begin
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
    "Color transform function."
    colorscale = identity
    "Sets the width of the contour lines."
    linewidth = 1.5
    "Sets the dash pattern of the contour lines. See `?lines`."
    linestyle = nothing
    """
    The mode with which the points in `xs` and `ys` are triangulated.
    Passing `DelaunayTriangulation()` performs a Delaunay triangulation.
    You can also pass a preexisting triangulation as an `AbstractMatrix{<:Int}`
    with size (3, n), where each column specifies the vertex indices of one triangle,
    or as a `Triangulation` from DelaunayTriangulation.jl.
    """
    triangulation = DelaunayTriangulation()
    mixin_generic_plot_attributes()...
end

function Makie.used_attributes(::Type{<:Tricontour}, ::AbstractVector{<:Real}, ::AbstractVector{<:Real}, ::AbstractVector{<:Real})
    return (:triangulation,)
end

function Makie.convert_arguments(
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

function _get_tricontour_levels(zs, levels)
    levels isa Integer || return Float32.(levels)
    zmin, zmax = extrema_nan(zs)
    isapprox(zmin, zmax) && return Float32[]
    return Float32.(range(zmin, zmax; length = levels))
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

function Makie.plot!(c::Tricontour{<:Tuple{<:DelTri.Triangulation, <:AbstractVector{<:Real}}})
    graph = c.attributes

    map!(graph, [:converted_2, :levels], :computed_levels) do zs, levels
        return _get_tricontour_levels(zs, levels)
    end
    map!(graph, [:computed_levels, :converted_2], :computed_colorrange) do levels, zs
        isempty(levels) || return extrema_nan(levels)
        c = Float32(first(zs))
        delta = max(one(c), abs(c))
        return (c - delta, c + delta)
    end

    register_computation!(
        graph,
        [:converted_1, :converted_2, :computed_levels],
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

    final_color = lift(c.color, c.line_colors) do col, lc
        isnothing(col) ? lc : col
    end

    lines!(c, c.line_xs, c.line_ys;
        color = final_color,
        colormap = c.colormap,
        colorscale = c.colorscale,
        colorrange = c.computed_colorrange,
        linewidth = c.linewidth,
        linestyle = c.linestyle,
        inspectable = c.inspectable,
        transparency = c.transparency)

    return c
end
