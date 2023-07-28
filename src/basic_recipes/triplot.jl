"""
    triplot(triangles::Triangulation; kwargs...)

Plots the triangles from the provided `Triangulation` from DelaunayTriangulation.jl. 

## Attributes 

- `show_points = false` determines whether to plot the individual points. Note that this will only plot points included in the triangulation.
- `show_convex_hull = false` determines whether to plot the convex hull.
- `show_ghost_edges = false` determines whether to plot the ghost edges.
- `show_constrained_edges = false` determines whether to plot the constrained edges.
- `recompute_centers = false` determines whether to recompute the representative points for the ghost edge orientation. Note that this will mutate `tri.representative_point_list` directly.

- `markersize = 12` sets the size of the points.
- `marker = :circle` sets the shape of the points.
- `strokecolor = :black` sets the strokecolor of the points.
- `strokewidth = 1` sets the width of the point stroke.
- `linestyle = :solid` sets the linestyle of the triangles.
- `triangle_color = (:white, 0.0)` sets the color of the triangles.
- `point_color = :black` sets the color of the points.

- `convex_hull_color = :red` sets the color of the convex hull.
- `convex_hull_linestyle = :dash` sets the linestyle of the convex hull.
- `convex_hull_linewidth = 1` sets the width of the convex hull.

- `ghost_edge_color = :blue` sets the color of the ghost edges.
- `ghost_edge_linestyle = :solid` sets the linestyle of the ghost edges.
- `ghost_edge_linewidth = 1` sets the width of the ghost edges.
- `ghost_edge_extension_factor = 10.0` sets the extension factor for the ghost edges.

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
                      strokecolor=theme(scene, :patchstrokecolor),
                      strokewidth=1,
                      linestyle=:solid,
                      triangle_color=(:white, 0.0),
                      point_color=sc.color, # not just color so that it's clear what color we are referring to

                      # Convex hull settings 
                      convex_hull_color=:red,
                      convex_hull_linestyle=:dash,
                      convex_hull_linewidth=theme(scene, :linewidth),

                      # Ghost edge settings 
                      ghost_edge_color=:blue,
                      ghost_edge_linestyle=theme(scene, :linestyle),
                      ghost_edge_linewidth=theme(scene, :linewidth),
                      ghost_edge_extension_factor=10.0,

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
        i, j, k = DelTri.indices(T)
        push!(triangles, TriangleFace(i, j, k))
    end
    return triangles
end

function get_triangulation_ghost_edges!(ghost_edges, extent, tri)
    empty!(ghost_edges)
    sizehint!(ghost_edges, 2DelTri.num_ghost_edges(tri))
    for e in DelTri.each_ghost_edge(tri)
        u, v = DelTri.edge_indices(e)
        if DelTri.is_boundary_index(v)
            u, v = v, u # Make sure that u is the boundary index 
        end
        curve_index = DelTri.get_curve_index(tri, u)
        representative_coordinates = DelTri.get_representative_point_coordinates(tri, curve_index)
        rx, ry = DelTri.getxy(representative_coordinates)
        p = DelTri.get_point(tri, v)
        px, py = DelTri.getxy(p)
        if DelTri.is_interior_curve(curve_index)
            ex, ey = rx, ry
        else
            ex = rx * (1 - extent) + extent * px
            ey = ry * (1 - extent) + extent * py
        end
        push!(ghost_edges, Point2f(px, py), Point2f(ex, ey))
    end
    return ghost_edges
end

function get_triangulation_convex_hull!(convex_hull, tri)
    idx = DelTri.get_convex_hull_indices(tri)
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
    sizehint!(constrained_edges, DelTri.num_edges(DelTri.get_all_constrained_edges(tri)))
    for e in DelTri.each_constrained_edge(tri)
        u, v = DelTri.edge_indices(e)
        p = DelTri.get_point(tri, u)
        q = DelTri.get_point(tri, v)
        px, py = DelTri.getxy(p)
        qx, qy = DelTri.getxy(q)
        push!(constrained_edges, Point2f(px, py), Point2f(qx, qy))
    end
    return constrained_edges
end

function plot!(p::Triplot)
    points_2f = Observable(Point2f[])
    present_points_2f = Observable(Point2f[]) # Points might not be in the triangulation yet, so points_2f is not what we want for scatter
    triangles_3f = Observable(TriangleFace{Int}[])
    ghost_edges_2f = Observable(Point2f[])
    convex_hull_2f = Observable(Point2f[])
    constrained_edges_2f = Observable(Point2f[])
    function update_plot(tri)
        map(p.recompute_centers) do rc
            return rc && DelTri.compute_representative_points!(tri)
        end
        map(points_2f) do pts
            return get_all_triangulation_points!(pts, tri)
        end
        map(p.show_points, present_points_2f) do sp, pts
            return sp && get_present_triangulation_points!(pts, tri)
        end
        map(triangles_3f) do tris
            return get_triangulation_triangles!(tris, tri)
        end
        map(p.show_ghost_edges, p.ghost_edge_extension_factor, ghost_edges_2f) do sge, extent, ge
            return sge && get_triangulation_ghost_edges!(ge, extent, tri)
        end
        map(p.show_convex_hull, convex_hull_2f) do sch, ch
            return sch && get_triangulation_convex_hull!(ch, tri)
        end
        map(p.show_constrained_edges, constrained_edges_2f) do sce, ce
            return sce && get_triangulation_constrained_edges!(ce, tri)
        end
        for obs in (points_2f, triangles_3f, ghost_edges_2f, convex_hull_2f, constrained_edges_2f)
            notify(obs)
        end
        return nothing
    end
    onany(update_plot, p[1])
    update_plot(p[1][])

    poly!(p, points_2f, triangles_3f; strokewidth=p.strokewidth, strokecolor=p.strokecolor,
          color=p.triangle_color)
    linesegments!(p, ghost_edges_2f; color=p.ghost_edge_color, linewidth=p.ghost_edge_linewidth,
                  linestyle=p.ghost_edge_linestyle, xautolimits=false, yautolimits=false)
    lines!(p, convex_hull_2f; color=p.convex_hull_color, linewidth=p.convex_hull_linewidth,
           linestyle=p.convex_hull_linestyle)
    linesegments!(p, constrained_edges_2f; color=p.constrained_edge_color,
                  linewidth=p.constrained_edge_linewidth, linestyle=p.constrained_edge_linestyle)
    map(p.show_points) do sp
        return sp &&
               scatter!(p, present_points_2f; markersize=p.markersize, color=p.point_color,
                        strokecolor=p.strokecolor, marker=p.marker)
    end # Do last so that points go over the lines
    return p
end