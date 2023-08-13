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
- `markercolor = :black` sets the color of the points.

- `strokecolor = :black` sets the strokecolor of the polygons.
- `strokewidth = 1` sets the width of the polygon stroke.
- `color = automatic` sets the color of the polygons. If `automatic`, the polygons will be individually colored according to the colormap.
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
                      markersize=sc.markersize,
                      marker=sc.marker,
                      markercolor=sc.color,

                      # Polygon settings
                      strokecolor=theme(scene, :patchstrokecolor),
                      strokewidth=1.0,
                      color=automatic,
                      unbounded_edge_extension_factor=0.1,
                      bounding_box=automatic)
    MakieCore.colormap_attributes!(attr, theme(scene, :colormap))
    return attr
end

function _clip_polygon(poly::Polygon, circle::Circle)
    # Sutherland-Hodgman adjusted
    @assert isempty(poly.interiors) "Polygon must not have holes for clipping."

    function intersection(A, B, circle)
        CA = A - origin(circle)
        AB = B - A
        a = dot(AB, AB) # > 0
        b = 2 * dot(CA, AB) # > 0
        c = dot(CA, CA) - radius(circle) * radius(circle)
        t = (sqrt(b * b - 4 * a * c) - b) / (2a) # only solution > 0 matters
        return A + AB * t
    end

    input = Point2f.(first.(poly.exterior))
    output = sizehint!(Point2f[], length(input))

    for i in eachindex(input)
        p1 = input[mod1(i - 1, end)]
        p2 = input[i]

        Cp1 = p1 - origin(circle)
        Cp2 = p2 - origin(circle)
        r2 = radius(circle) * radius(circle)
        if dot(Cp1, Cp1) < r2 # p1 inside
            if dot(Cp2, Cp2) > r2 # p2 outside
                p = intersection(p1, p2, circle)
                push!(output, p)
            else # both inside
                push!(output, p2)
            end
        elseif dot(Cp2, Cp2) < r2 # p1 outside, p2 inside
            p = intersection(p2, p1, circle)
            push!(output, p, p2)
        end
    end

    return Polygon(output)
end
_clip_polygon(poly::Polygon, ::Any) = poly

function get_voronoi_tiles!(generators, polygons, vorn, bbox)
    function voronoi_bbox(c::Circle)
        o = Float64.(origin(c))
        r = Float64(radius(c))
        return (o[1] - r, o[1] + r, o[2] - r, o[2] + r)
    end
    function voronoi_bbox(r::Rect2)
        mini = Float64.(minimum(r))
        maxi = Float64.(maximum(r))
        return (mini[1], maxi[1], mini[2], maxi[2])
    end
    voronoi_bbox(t::Tuple) = Float64.(t)
    voronoi_bbox(::Nothing) = nothing

    empty!(generators)
    empty!(polygons)
    sizehint!(generators, DelTri.num_generators(vorn))
    sizehint!(polygons, DelTri.num_polygons(vorn))

    for i in DelTri.each_generator(vorn)
        polygon_coords = DelTri.get_polygon_coordinates(vorn, i, voronoi_bbox(bbox))
        polygon_coords_2f = map(polygon_coords) do coords
            return Point2f(DelTri.getxy(coords))
        end
        push!(polygons, _clip_polygon(Polygon(polygon_coords_2f), bbox))
        gp = Point2f(DelTri.getxy(DelTri.get_generator(vorn, i)))
        !isempty(polygon_coords) && push!(generators, gp)
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
        ps = map(ps -> Point2f.(ps), p, p[1])
        attr[:color] = map(ps -> last.(ps), p, p[1])
    else
        ps = p[1]
    end

    # Handle transform_func early so tessellation is in cartesian space.
    vorn = map(p, p.transformation.transform_func, ps, smooth) do tf, ps, smooth
        transformed = Makie.apply_transform(tf, ps)
        tri = DelTri.triangulate(transformed)
        vorn = DelTri.voronoi(tri)
        if smooth
            vorn = DelTri.centroidal_smooth(vorn)
        end
        return vorn
    end

    # Default to circular clip for polar transformed data
    attr[:bounding_box] = map(p, pop!(attr, :bounding_box), p.unbounded_edge_extension_factor,
                              transform_func_obs(p), ps) do bb, ext, tf, ps
        if bb === automatic && tf isa Polar
            rscaled = maximum(first, ps) * (1 + ext)
            return Circle(Point2f(0), rscaled)
        else
            return bb
        end
    end

    transform = Transformation(p.transformation; transform_func=identity)
    return voronoiplot!(p, attr, vorn; transformation=transform)
end

function plot!(p::Voronoiplot{<:Tuple{<:DelTri.VoronoiTessellation}})
    generators_2f = Observable(Point2f[])
    PolyType = typeof(Polygon(Point2f[], [Point2f[]]))
    polygons = Observable(PolyType[])

    p.attributes[:_calculated_colors] = map(p, p.color, p[1]) do color, vorn
        if color === automatic
            # generate some consistent distinguishable colors
            cs = [i for i in DelTri.each_generator(vorn)]
            return cs
        elseif color isa AbstractArray
            @assert(length(color) == DelTri.num_points(DelTri.get_triangulation(vorn)),
                    "Color vector must have the same length as the number of generators, including any not yet in the tessellation.")
            return [color[i] for i in DelTri.each_generator(vorn)] # this matches the polygon order
        else
            return color # constant color
        end
    end

    function update_plot(vorn)
        if isempty(DelTri.get_unbounded_polygons(vorn))
            bbox = nothing
        elseif p.bounding_box[] === automatic
            extent = p.unbounded_edge_extension_factor[]
            bbox = DelTri.polygon_bounds(vorn, extent; include_polygon_vertices=false)
        else
            bbox = p.bounding_box[]
        end
        get_voronoi_tiles!(generators_2f[], polygons[], vorn, bbox)
        foreach(notify, (generators_2f, polygons))
        return
    end
    onany(update_plot, p, p[1])
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
          nan_color=p.nan_color)

    scatter!(p, generators_2f;
             markersize=p.markersize,
             marker=p.marker,
             color=p.markercolor,
             visible=p.show_generators,
             depth_shift=-2.0f-5)

    return p
end