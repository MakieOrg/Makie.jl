"""
    triplot(x, y; kwargs...)
    triplot(positions; kwargs...)
    triplot(triangles::Triangulation; kwargs...)

Plots a triangulation based on the provided position or `Triangulation` from DelaunayTriangulation.jl.

## Attributes

- `show_points = false` determines whether to plot the individual points. Note that this will only plot points included in the triangulation.
- `show_convex_hull = false` determines whether to plot the convex hull.
- `show_ghost_edges = false` determines whether to plot the ghost edges.
- `show_constrained_edges = false` determines whether to plot the constrained edges.
- `recompute_centers = false` determines whether to recompute the representative points for the ghost edge orientation. Note that this will mutate `tri.representative_point_list` directly.

- `markersize = 12` sets the size of the points.
- `marker = :circle` sets the shape of the points.
- `markercolor = :black` sets the color of the points.
- `strokecolor = :black` sets the color of triangle edges.
- `strokewidth = 1` sets the linewidth of triangle edges.
- `linestyle = :solid` sets the linestyle of triangle edges.
- `triangle_color = (:white, 0.0)` sets the color of the triangles.

- `convex_hull_color = :red` sets the color of the convex hull.
- `convex_hull_linestyle = :dash` sets the linestyle of the convex hull.
- `convex_hull_linewidth = 1` sets the width of the convex hull.

- `ghost_edge_color = :blue` sets the color of the ghost edges.
- `ghost_edge_linestyle = :solid` sets the linestyle of the ghost edges.
- `ghost_edge_linewidth = 1` sets the width of the ghost edges.
- `ghost_edge_extension_factor = 0.1` sets the extension factor for the rectangle that the exterior ghost edges are extended onto.
- `bounding_box::Union{Automatic, Rect2, Tuple} = automatic`: Sets the bounding box for truncating ghost edges which can be a `Rect2` (or `BBox`) or a tuple of the form `(xmin, xmax, ymin, ymax)`. By default, the rectangle will be given by `[a - eΔx, b + eΔx] × [c - eΔy, d + eΔy]` where `e` is the `ghost_edge_extension_factor`, `Δx = b - a` and `Δy = d - c` are the lengths of the sides of the rectangle, and `[a, b] × [c, d]` is the bounding box of the points in the triangulation.

- `constrained_edge_color = :magenta` sets the color of the constrained edges.
- `constrained_edge_linestyle = :solid` sets the linestyle of the constrained edges.
- `constrained_edge_linewidth = 1` sets the width of the constrained edges.
"""
@recipe(Triplot, triangles) do scene
    sc = default_theme(scene, Scatter)
    return Attributes(;
                      # Toggles
                      show_points=false,
                      show_convex_hull=false,
                      show_ghost_edges=false,
                      show_constrained_edges=false,
                      recompute_centers=false,

                      # Mesh settings
                      markersize=theme(scene, :markersize),
                      marker=theme(scene, :marker),
                      markercolor=sc.color,
                      strokecolor=theme(scene, :patchstrokecolor),
                      strokewidth=1,
                      linestyle=:solid,
                      triangle_color=(:white, 0.0),

                      # Convex hull settings
                      convex_hull_color=:red,
                      convex_hull_linestyle=:dash,
                      convex_hull_linewidth=theme(scene, :linewidth),

                      # Ghost edge settings
                      ghost_edge_color=:blue,
                      ghost_edge_linestyle=theme(scene, :linestyle),
                      ghost_edge_linewidth=theme(scene, :linewidth),
                      ghost_edge_extension_factor=0.1,
                      bounding_box=automatic,

                      # Constrained edge settings
                      constrained_edge_color=:magenta,
                      constrained_edge_linestyle=theme(scene, :linestyle),
                      constrained_edge_linewidth=theme(scene, :linewidth))
end

function get_all_triangulation_points!(points, tri)
    empty!(points)
    sizehint!(points, DelTri.num_points(tri))
    for p in DelTri.each_point(tri)
        x, y = DelTri.getxy(p)
        push!(points, Point2f(x, y))
    end
    return points
end

function get_present_triangulation_points!(points, tri)
    empty!(points)
    sizehint!(points, DelTri.num_solid_vertices(tri))
    for i in DelTri.each_solid_vertex(tri)
        p = DelTri.get_point(tri, i)
        x, y = DelTri.getxy(p)
        push!(points, Point2f(x, y))
    end
    return points
end

function get_triangulation_triangles!(triangles, tri)
    empty!(triangles)
    sizehint!(triangles, DelTri.num_solid_triangles(tri))
    for T in DelTri.each_solid_triangle(tri)
        i, j, k = DelTri.triangle_vertices(T)
        push!(triangles, TriangleFace(i, j, k))
    end
    return triangles
end

function get_triangulation_ghost_edges!(ghost_edges, extent, tri, bounding_box)
    @assert extent > 0.0 "The ghost_edge_extension_factor must be positive."
    empty!(ghost_edges)
    sizehint!(ghost_edges, 2DelTri.num_ghost_edges(tri))
    if bounding_box === automatic
        if DelTri.has_boundary_nodes(tri)
            xmin, xmax, ymin, ymax = DelTri.polygon_bounds(DelTri.get_points(tri),
                                                           DelTri.get_boundary_nodes(tri),
                                                           Val(true))
        else
            xmin, xmax, ymin, ymax = DelTri.polygon_bounds(DelTri.get_points(tri),
                                                           DelTri.get_convex_hull_vertices(tri),
                                                           Val(true))
        end
        Δx = xmax - xmin
        Δy = ymax - ymin
        a, b, c, d = (xmin - extent * Δx, xmax + extent * Δx, ymin - extent * Δy, ymax + extent * Δy)
    elseif bounding_box isa Rect2
        a, c = minimum(bounding_box)
        b, d = maximum(bounding_box)
    else
        a, b, c, d = bounding_box
    end
    a, b, c, d = map(Float64, (a, b, c, d))
    @assert a < b && c < d "Bounding box must be of the form (xmin, xmax, ymin, ymax)."
    for e in DelTri.each_ghost_edge(tri)
        u, v = DelTri.edge_vertices(e)
        if DelTri.is_ghost_vertex(v)
            u, v = v, u # Make sure that u is the boundary index
        end
        curve_index = DelTri.get_curve_index(tri, u)
        representative_coordinates = DelTri.get_representative_point_coordinates(tri, curve_index)
        rx, ry = DelTri.getxy(representative_coordinates)
        @assert a ≤ rx ≤ b && c ≤ ry ≤ d "The representative point is not in the bounding box."
        p = DelTri.get_point(tri, v)
        px, py = DelTri.getxy(p)
        if !DelTri.is_positively_oriented(tri, curve_index)
            ex, ey = rx, ry
        else
            e = DelTri.intersection_of_ray_with_bounding_box(representative_coordinates, p, a, b, c, d)
            ex, ey = DelTri.getxy(e)
        end
        push!(ghost_edges, Point2f(px, py), Point2f(ex, ey))
    end
    return ghost_edges
end

function get_triangulation_convex_hull!(convex_hull, tri)
    idx = DelTri.get_convex_hull_vertices(tri)
    empty!(convex_hull)
    sizehint!(convex_hull, length(idx))
    for i in idx
        p = DelTri.get_point(tri, i)
        x, y = DelTri.getxy(p)
        push!(convex_hull, Point2f(x, y))
    end
    return convex_hull
end

function get_triangulation_constrained_edges!(constrained_edges, tri)
    empty!(constrained_edges)
    sizehint!(constrained_edges, DelTri.num_edges(DelTri.get_all_segments(tri)))
    for e in DelTri.each_segment(tri)
        u, v = DelTri.edge_vertices(e)
        p = DelTri.get_point(tri, u)
        q = DelTri.get_point(tri, v)
        px, py = DelTri.getxy(p)
        qx, qy = DelTri.getxy(q)
        push!(constrained_edges, Point2f(px, py), Point2f(qx, qy))
    end
    return constrained_edges
end

Makie.convert_arguments(::Type{<:Triplot}, ps) = convert_arguments(PointBased(), ps)
Makie.convert_arguments(::Type{<:Triplot}, xs, ys) = convert_arguments(PointBased(), xs, ys)
Makie.convert_arguments(::Type{<:Triplot}, x::DelTri.Triangulation) = (x,)

function Makie.plot!(p::Triplot{<:Tuple{<:Vector{<:Point}}})
    attr = copy(p.attributes)

    # Handle transform_func early so tessellation is in cartesian space.
    tri = map(p, p.transformation.transform_func, p[1]) do tf, ps
        transformed = Makie.apply_transform(tf, ps)
        return DelTri.triangulate(transformed)
    end

    attr[:transformation] = Transformation(p.transformation; transform_func=identity)
    triplot!(p, attr, tri)
    return
end

function Makie.plot!(p::Triplot{<:Tuple{<:DelTri.Triangulation}})
    points_2f = Observable(Point2f[])
    present_points_2f = Observable(Point2f[]) # Points might not be in the triangulation yet, so points_2f is not what we want for scatter
    triangles_3f = Observable(Makie.TriangleFace{Int}[])
    ghost_edges_2f = Observable(Point2f[])
    convex_hull_2f = Observable(Point2f[])
    constrained_edges_2f = Observable(Point2f[])

    function update_plot(tri)
        p.recompute_centers[] && DelTri.compute_representative_points!(tri)
        get_all_triangulation_points!(points_2f[], tri)

        p.show_points[] && get_present_triangulation_points!(present_points_2f[], tri)
        get_triangulation_triangles!(triangles_3f[], tri)

        if p.show_ghost_edges[]
            ge = ghost_edges_2f[]
            extent = p.ghost_edge_extension_factor[]
            bbox = p.bounding_box[]
            get_triangulation_ghost_edges!(ge, extent, tri, bbox)
        end

        p.show_convex_hull[] && get_triangulation_convex_hull!(convex_hull_2f[], tri)
        p.show_constrained_edges[] && get_triangulation_constrained_edges!(constrained_edges_2f[], tri)

        foreach(notify,
                (points_2f, present_points_2f, triangles_3f, ghost_edges_2f, convex_hull_2f,
                 constrained_edges_2f))
        return nothing
    end
    onany(update_plot, p, p[1])
    update_plot(p[1][])

    poly!(p, points_2f, triangles_3f; strokewidth=p.strokewidth, strokecolor=p.strokecolor,
          color=p.triangle_color)
    linesegments!(p, ghost_edges_2f; color=p.ghost_edge_color, linewidth=p.ghost_edge_linewidth,
                  linestyle=p.ghost_edge_linestyle, xautolimits=false, yautolimits=false)
    lines!(p, convex_hull_2f; color=p.convex_hull_color, linewidth=p.convex_hull_linewidth,
           linestyle=p.convex_hull_linestyle, depth_shift=-1.0f-5)
    linesegments!(p, constrained_edges_2f; color=p.constrained_edge_color, depth_shift=-2.0f-5,
                  linewidth=p.constrained_edge_linewidth, linestyle=p.constrained_edge_linestyle)
    scatter!(p, present_points_2f; markersize=p.markersize, color=p.markercolor,
             strokecolor=p.strokecolor, marker=p.marker, visible=p.show_points, depth_shift=-3.0f-5)
    return p
end


function data_limits(p::Triplot{<:Tuple{<:Vector{<:Point}}})
    if transform_func(p) isa Polar
        # Because the Polar transform is handled explicitly we cannot rely
        # on the default data_limits. (data limits are pre transform)
        iter = (to_ndim(Point3f, p, 0f0) for p in p.converted[1][])
        limits_from_transformed_points(iter)
    else
        # First component is either another Voronoiplot or a poly plot. Both
        # cases span the full limits of the plot
        data_limits(p.plots[1])
    end
end