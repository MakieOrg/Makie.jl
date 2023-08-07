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
- `bounding_box = automatic` sets the bounding box for the polygons. If `automatic`, the bounding box will be determined automatically based on the extension factor, otherwise it should be a `Tuple` of the form `(xmin, xmax, ymin, ymax)`. If any of the generators or polygons are outside of the polygon, the plot will error.

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
                      smooth=false,

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
    if !isnothing(bbox)
        a, b, c, d = bbox
        @assert a < b && c < d "Bounding box must be of the form (xmin, xmax, ymin, ymax)."
    end
    for i in DelTri.each_generator(vorn)
        g = DelTri.get_generator(vorn, i)
        x, y = DelTri.getxy(g)
        push!(generators, Point2f(x, y))
        !isnothing(bbox) &&
            @assert a ≤ x ≤ b && c ≤ y ≤ d "Generator $(i) with coordinates ($x, $y) is outside the bounding box."
        polygon_coords = DelTri.get_polygon_coordinates(vorn, i, bbox)
        polygon_coords_2f = map(polygon_coords) do coords
            x, y = DelTri.getxy(coords)
            !isnothing(bbox) &&
                @assert a ≤ x ≤ b && c ≤ y ≤ d "Polygon vertex $(i) with coordinates ($x, $y) is outside the bounding box."
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
    gtr = [DelTri.get_generator(vorn, i) for i in DelTri.each_generator(vorn)] # same as get_generators(vorn)
    reverse!(gtr) # For some reason this is needed to get distinct colors for the tiles
    gtr_mat = reinterpret(reshape, F, gtr)
    _colors = get(cgrad(cmap), gtr_mat, :extrema)
    for c in eachcol(_colors)
        a, b = c
        push!(colors, (a + b) / 2)
    end
    return colors
end

Makie.convert_arguments(::Type{<:Voronoiplot}, ps) = convert_arguments(PointBased(), ps)
Makie.convert_arguments(::Type{<:Voronoiplot}, xs, ys) = convert_arguments(PointBased(), xs, ys)
Makie.convert_arguments(::Type{<:Voronoiplot}, xs, ys, zs) = convert_arguments(PointBased(), xs, ys, zs)
Makie.convert_arguments(::Type{<:Voronoiplot}, x::DelTri.VoronoiTessellation) = (x,)

function Makie.plot!(p::Voronoiplot{<:Tuple{<:Vector{<:Point{N}}}}) where {N}
    attr = copy(p.attributes)
    smooth = pop!(attr, :smooth)

    # from call pattern (::Vector, ::Vector, ::Matrix)
    if N == 3
        ps = map(ps -> Point2f.(ps), p[1])
        attr[:polygon_color] = map(ps -> last.(ps), p[1])
    else
        ps = p[1]
    end

    # Handle transform_func early so tessellation is in cartesian space.
    vorn = map(p.transformation.transform_func, ps, smooth) do tf, ps, smooth
        transformed = Makie.apply_transform(tf, ps)

        # TODO: Make this work with Point2f directly
        M = Matrix{Float64}(undef, 2, length(transformed))
        for (i, p) in enumerate(transformed)
            M[:, i] .= p
        end

        tri = DelTri.triangulate(M)
        vorn = DelTri.voronoi(tri)
        if smooth
            vorn = DelTri.centroidal_smooth(vorn)
        end

        return vorn
    end

    transform = Transformation(p.transformation; transform_func=identity)
    return voronoiplot!(p, attr, vorn; transformation=transform)
end

function Makie.plot!(p::Voronoiplot{<:Tuple{<:DelTri.VoronoiTessellation}})
    generators_2f = Observable(Point2f[])
    PolyType = typeof(Polygon(Point2f[], [Point2f[]]))
    polygons = Observable(PolyType[])
    colors = map(p.polygon_color, p[1]) do polycol, vorn
        if polycol == automatic
            RGBA{Float64}[]
        else
            if polycol isa AbstractArray
                @assert length(polycol) == DelTri.num_points(DelTri.get_triangulation(vorn)) "Color vector must have the same length as the number of generators, including any not yet in the tessellation."
                [polycol[i] for i in DelTri.each_generator(vorn)] # this matches the polygon order 
            else
                polycol
            end
        end
    end
    function update_plot(vorn)
        bbox = map(p.unbounded_edge_extension_factor, p.bounding_box) do extent, bnd
            isempty(DelTri.get_unbounded_polygons(vorn)) && return nothing
            if bnd === automatic
                return DelTri.polygon_bounds(vorn, extent)
            else
                return bnd
            end
        end
        map(generators_2f, polygons, bbox) do gens, polys, box
            _box = !isnothing(box) ? map(Float64, box) : box
            return get_voronoi_tiles!(gens, polys, vorn, _box)
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

    scatter!(p, generators_2f;
             markersize=p.markersize,
             marker=p.marker,
             color=p.point_color,
             visible=p.show_generators)

    return p
end