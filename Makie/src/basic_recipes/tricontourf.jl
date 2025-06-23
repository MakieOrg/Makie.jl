struct DelaunayTriangulation end

"""
    tricontourf(triangles::Triangulation, zs; kwargs...)
    tricontourf(xs, ys, zs; kwargs...)

Plots a filled tricontour of the height information in `zs` at the horizontal positions `xs` and
vertical positions `ys`. A `Triangulation` from DelaunayTriangulation.jl can also be provided instead of `xs` and `ys`
for specifying the triangles, otherwise an unconstrained triangulation of `xs` and `ys` is computed.
"""
@recipe Tricontourf begin
    "Can be either an `Int` which results in n bands delimited by n+1 equally spaced levels, or it can be an `AbstractVector{<:Real}` that lists n consecutive edges from low to high, which result in n-1 bands."
    levels = 10
    """
    Sets the way in which a vector of levels is interpreted,
    if it's set to `:relative`, each number is interpreted as a fraction
    between the minimum and maximum values of `zs`.
    For example, `levels = 0.1:0.1:1.0` would exclude the lower 10% of data.
    """
    mode = :normal
    "Sets the colormap from which the band colors are sampled."
    colormap = @inherit colormap
    "Color transform function"
    colorscale = identity
    "The alpha value of the colormap or color attribute."
    alpha = 1.0
    """
    This sets the color of an optional additional band from
    `minimum(zs)` to the lowest value in `levels`.
    If it's `:auto`, the lower end of the colormap is picked
    and the remaining colors are shifted accordingly.
    If it's any color representation, this color is used.
    If it's `nothing`, no band is added.
    """
    extendlow = nothing
    """
    This sets the color of an optional additional band from
    the highest value of `levels` to `maximum(zs)`.
    If it's `:auto`, the high end of the colormap is picked
    and the remaining colors are shifted accordingly.
    If it's any color representation, this color is used.
    If it's `nothing`, no band is added.
    """
    extendhigh = nothing
    nan_color = :transparent
    """
    The mode with which the points in `xs` and `ys` are triangulated.
    Passing `DelaunayTriangulation()` performs a Delaunay triangulation.
    You can also pass a preexisting triangulation as an `AbstractMatrix{<:Int}`
    with size (3, n), where each column specifies the vertex indices of one triangle,
    or as a `Triangulation` from DelaunayTriangulation.jl.
    """
    triangulation = DelaunayTriangulation()
    edges = nothing
    mixin_generic_plot_attributes()...
end

function Makie.used_attributes(::Type{<:Tricontourf}, ::AbstractVector{<:Real}, ::AbstractVector{<:Real}, ::AbstractVector{<:Real})
    return (:triangulation,)
end

function Makie.convert_arguments(
        ::Type{<:Tricontourf}, x::AbstractVector{<:Real}, y::AbstractVector{<:Real}, z::AbstractVector{<:Real};
        triangulation = DelaunayTriangulation()
    )
    T = float_type(x, y, z)
    z = elconvert(T, z)
    points = [elconvert(T, x)'; elconvert(T, y)']
    if triangulation isa DelaunayTriangulation
        tri = DelTri.triangulate(points, randomise = false)
    elseif !(triangulation isa DelTri.Triangulation)
        # Wrap user's provided triangulation into a Triangulation. Their triangulation must be such that DelTri.add_triangle! is defined.
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

function Makie.plot!(c::Tricontourf{<:Tuple{<:DelTri.Triangulation, <:AbstractVector{<:Real}}})
    graph = c.attributes

    # prepare levels, colormap related nodes
    register_contourf_computations!(graph, :converted_2)

    function calculate_polys!(polys, colors, triangulation, zs, levels::Vector{Float32}, is_extended_low, is_extended_high)
        levels = copy(levels)
        # adjust outer levels to be inclusive
        levels[1] = prevfloat(levels[1])
        levels[end] = nextfloat(levels[end])
        @assert issorted(levels)
        is_extended_low && pushfirst!(levels, -Inf)
        is_extended_high && push!(levels, Inf)
        lows = levels[1:(end - 1)]
        highs = levels[2:end]

        xs = [DelTri.getx(p) for p in DelTri.each_point(triangulation)] # each_point preserves indices
        ys = [DelTri.gety(p) for p in DelTri.each_point(triangulation)]

        trianglelist = compute_triangulation(triangulation)
        filledcontours = filled_tricontours(xs, ys, zs, trianglelist, levels)

        levelcenters = (highs .+ lows) ./ 2

        for (fc, lc) in zip(filledcontours, levelcenters)
            pointvecs = map(fc.polylines) do vecs
                map(Point2f, vecs)
            end
            if isempty(pointvecs)
                continue
            end

            for pointvec in pointvecs
                p = Makie.Polygon(pointvec)
                push!(polys, p)
                push!(colors, lc)
            end
        end
        return
    end

    register_computation!(
        graph,
        [:converted_1, :converted_2, :computed_levels, :computed_lowcolor, :computed_highcolor],
        [:polys, :computed_colors]
    ) do (tri, zs, levels, low, high), changed, cached
        is_extended_low = !isnothing(low)
        is_extended_high = !isnothing(high)
        if isnothing(cached)
            polys = Polygon{2, Float32}[]
            colors = Float64[]
        else
            polys, colors = empty!.(values(cached))
        end
        calculate_polys!(polys, colors, tri, zs, levels, is_extended_low, is_extended_high)
        return (polys, colors)
    end

    return poly!(
        c,
        c.polys,
        colormap = c.computed_colormap,
        colorscale = c.colorscale,
        colorrange = c.computed_colorrange,
        alpha = c.alpha,
        highclip = c.computed_highcolor,
        lowclip = c.computed_lowcolor,
        nan_color = c.nan_color,
        color = c.computed_colors,
        strokewidth = 0,
        strokecolor = :transparent,
        inspectable = c.inspectable,
        transparency = c.transparency
    )
end

function compute_triangulation(tri)
    return [T[j] for T in DelTri.each_solid_triangle(tri), j in 1:3]'
end

# FIXME: TriplotBase augments levels so here the implementation is just repeated without that step
function filled_tricontours(x, y, z, t, levels)
    m = TriplotBase.TriMesh(x, y, t)
    return filled_tricontours(m, z, levels)
end

function filled_tricontours(m::TriplotBase.TriMesh, z, levels)
    @assert issorted(levels)
    nlevels = length(levels)
    filled_contours = TriplotBase.FilledContour{eltype(levels)}[]
    for i in 1:(nlevels - 1)
        lower = levels[i]
        upper = levels[i + 1]
        push!(filled_contours, TriplotBase.generate_filled_contours(m, z, lower, upper))
    end
    return filled_contours
end
