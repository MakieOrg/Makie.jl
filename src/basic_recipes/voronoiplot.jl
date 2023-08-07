"""
    voronoiplot(x, y, values; kwargs...)
    voronoiplot(values; kwargs...)
    voronoiplot(x, y; kwargs...)
    voronoiplot(positions; kwargs...)
    voronoiplot(vorn::VoronoiTessellation; kwargs...)

Generates and plots a Voronoi tessalation from `heatmap`- or point-like data.
The tessellation can also be passed directly as a `VoronoiTessellation` from
DelaunayTriangulation.jl.

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

$(Base.Docs.doc(MakieCore.colormap_attributes!))
"""
@recipe(Voronoiplot, vorn) do scene
    th = default_theme(scene, Mesh)
    sc = default_theme(scene, Scatter)
    attr = Attributes(;
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
                      color=automatic,
                      unbounded_edge_extension_factor=0.1,
                      bounding_box=automatic,
                      )
    MakieCore.colormap_attributes!(attr, theme(scene, :colormap))
    return attr
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

# For heatmap-like inputs
function convert_arguments(::Type{<:Voronoiplot}, mat::AbstractMatrix)
    return convert_arguments(PointBased(), axes(mat, 1), axes(mat, 2), mat)
end
convert_arguments(::Type{<:Voronoiplot}, xs, ys, zs) = convert_arguments(PointBased(), xs, ys, zs)
# For scatter-like inputs
convert_arguments(::Type{<:Voronoiplot}, ps) = convert_arguments(PointBased(), ps)
convert_arguments(::Type{<:Voronoiplot}, xs, ys) = convert_arguments(PointBased(), xs, ys)
convert_arguments(::Type{<:Voronoiplot}, x::DelTri.VoronoiTessellation) = (x,)

function plot!(p::Voronoiplot{<:Tuple{<:Vector{<:Point{N}}}}) where {N}
    attr = copy(p.attributes)
    smooth = pop!(attr, :smooth)

    # from call pattern (::Vector, ::Vector, ::Matrix)
    if N == 3
        ps = map(ps -> Point2f.(ps), p[1])
        attr[:color] = map(ps -> last.(ps), p[1])
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

function plot!(p::Voronoiplot{<:Tuple{<:DelTri.VoronoiTessellation}})
    generators_2f = Observable(Point2f[])
    PolyType = typeof(Polygon(Point2f[], [Point2f[]]))
    polygons = Observable(PolyType[])

    p.attributes[:_calculated_colors] = map(p.color, p[1]) do color, vorn
        if color === automatic
            # generate some consistent distinguishable colors
            cs = [sum(DelTri.get_generator(vorn, i)) for i in DelTri.each_generator(vorn)]
            reverse!(cs)
        else
            @assert(
                length(color) == DelTri.num_points(DelTri.get_triangulation(vorn)),
                "Color vector must have the same length as the number of generators, including any not yet in the tessellation."
            )
            [color[i] for i in DelTri.each_generator(vorn)] # this matches the polygon order
        end
    end

    function update_plot(vorn)
        bbox = map(p.unbounded_edge_extension_factor, p.bounding_box) do extent, bnd
            isempty(DelTri.get_unbounded_polygons(vorn)) && return nothing
            if bnd === automatic
                # bb_ref = RefValue(Rect3f())
                # foreach(DelTri.get_generators(vorn)) do (_, p)
                #     update_boundingbox!(bb_ref, Point2f(p))
                # end

                # x0, y0, _ = minimum(bb_ref[]) .- extent .* widths(bb_ref[])
                # x1, y1, _ = maximum(bb_ref[]) .+ extent .* widths(bb_ref[])

                # return (x0, x1, y0, y1)
                return DelTri.polygon_bounds(vorn, extent)
            else
                return bnd
            end
        end
        map(generators_2f, polygons, bbox) do gens, polys, box
            _box = !isnothing(box) ? map(Float64, box) : box
            return get_voronoi_tiles!(gens, polys, vorn, _box)
        end
        for obs in (generators_2f, polygons)
            notify(obs)
        end
    end
    onany(update_plot, p[1])
    update_plot(p[1][])

    poly!(p, polygons;
        strokecolor=p.strokecolor,
        strokewidth=p.strokewidth,
        color=p._calculated_colors,
        colormap=p.colormap,
        colorscale=p.colorscale,
        colorrange=p.colorrange,
        lowclip=p.lowclip,
        highclip=p.highclip,
        nan_color=p.nan_color
    )

    scatter!(p, generators_2f;
             markersize=p.markersize,
             marker=p.marker,
             color=p.point_color,
             visible=p.show_generators)

    return p
end