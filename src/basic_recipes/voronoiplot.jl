"""
    voronoiplot(vorn::VoronoiTessellation; kwargs...)

Plots a Voronoi tessellation from the provided `VoronoiTessellation` from DelaunayTriangulation.jl.

## Attributes 

- `show_generators = true` determines whether to plot the individual generators.

- `markersize = 4` sets the size of the points.
- `marker = :circle` sets the shape of the points.
- `point_color = :black` sets the color of the points.

- `strokecolor = :black` sets the strokecolor of the polygons.
- `strokewidth = 1` sets the width of the polygon stroke.
- `polygon_color = automatic` sets the color of the polygons. If `automatic`, the polygons will be individually colored according to the colormap.
- `unbounded_edge_extension_factor = 0.1` sets the extension factor for the unbounded edges, used in `DelaunayTriangulation.polygon_bounds`.
- `bounding_box = automatic` sets the bounding box for the polygons. If `automatic`, the bounding box will be determined automatically based on the extension factor, otherwise it should be a `Tuple` of the form `(xmin, xmax, ymin, ymax)`.

- `colormap = :viridis` sets the colormap for the polygons.
- `colorrange = automatic` sets the colorrange for the polygons. If `nothing`, the colorrange will be determined automatically.
- `cycle = [:color => :patchcolor]` sets the cycle for the polygons.
"""
@recipe(Voronoiplot, vorn) do scene
    th = default_theme(scene, Mesh)
    sc = default_theme(scene, Scatter)
    return Attributes(;
                      # Toggles
                      show_generators=true,

                      # Point settings 
                      markersize=4,
                      marker=sc.marker,
                      point_color=sc.color,

                      # Polygon settings 
                      strokecolor=theme(scene, :patchstrokecolor),
                      strokewidth=1.0,
                      polygon_color=automatic,
                      unbounded_edge_extension_factor=0.1,
                      bounding_box=automatic,

                      # Colormap settings 
                      colormap=th.colormap,
                      colorrange=th.colorrange,
                      cycle=th.cycle)
end

function get_voronoi_tiles!(generators, polygons, vorn, bbox)
    empty!(generators)
    empty!(polygons)
    sizehint!(generators, DelTri.num_generators(vorn))
    sizehint!(polygons, DelTri.num_polygons(vorn))
    for i in DelTri.each_generator(vorn)
        g = DelTri.get_generator(vorn, i)
        x, y = DelTri.getxy(g)
        push!(generators, Point2f(x, y))
        polygon_coords = DelTri.get_polygon_coordinates(vorn, i, bbox)
        polygon_coords_2f = map(polygon_coords) do coords
            x, y = DelTri.getxy(coords)
            return Point2f(x, y)
        end
        push!(polygons, Polygon(polygon_coords_2f))
    end
    return generators, polygons
end
function get_voronoi_colors!(colors, vorn, cmap)
    empty!(colors)
    sizehint!(colors, DelTri.num_polygons(vorn))
    F = DelTri.number_type(vorn)
    gtr = [DelTri.get_generator(vorn, i) for i in DelTri.each_generator(vorn)]
    reverse!(gtr) # For some reason this is needed to get distinct colors for the tiles
    gtr_mat = reinterpret(reshape, F, gtr)
    _colors = get(cgrad(cmap), gtr_mat, :extrema)
    for c in eachcol(_colors)
        a, b = c
        push!(colors, (a + b) / 2)
    end
    return colors
end
function plot!(p::Voronoiplot)
    generators_2f = Observable(Point2f[])
    PolyType = typeof(Polygon(Point2f[], [Point2f[]]))
    polygons = Observable(PolyType[])
    colors = map(p.polygon_color) do polycol
        if polycol == automatic
            RGBA{Float64}[]
        else
            polycol
        end
    end
    function update_plot(vorn)
        bbox = map(p.unbounded_edge_extension_factor, p.bounding_box) do extent, bnd
            if bnd === automatic
                return DelTri.polygon_bounds(vorn, extent)
            else
                return p.bounding_box
            end
        end
        map(generators_2f, polygons, bbox) do gens, polys, box
            return get_voronoi_tiles!(gens, polys, vorn, box)
        end
        map(colors, p.polygon_color, p.colormap) do cols, polycol, cmap
            return polycol == automatic && get_voronoi_colors!(cols, vorn, cmap)
        end
        for obs in (generators_2f, polygons, colors)
            notify(obs)
        end
    end
    onany(update_plot, p[1])
    update_plot(p[1][])

    poly!(p, polygons; color=colors,
          strokecolor=p.strokecolor,
          strokewidth=p.strokewidth,
          colormap=p.colormap,
          colorrange=p.colorrange,
          cycle=p.cycle)
    map(p.show_generators) do sg
        return sg && scatter!(p, generators_2f;
                              markersize=p.markersize,
                              marker=p.marker,
                              color=p.point_color)
    end
    return p
end