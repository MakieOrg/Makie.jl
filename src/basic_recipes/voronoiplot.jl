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
                      markersize=4,
                      marker=sc.marker,
                      markercolor=sc.color,

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

function clip_polygon(poly::Polygon, edges::Vector{<: Line})
    # Sutherland-Hodgman algorithm
    # assuming edges clockwise
    @assert isempty(poly.interiors) "Polygon must not have holes for clipping."

    # TODO: GeometryBasics has some rotations in this. Do we need that here too?
    function intersection(A, B, edge)
        # assuming both infinite
        e1, e2 = edge
        alpha = A - e1
        beta = A - B
        v = e2 - e1
        t1, t2 = inv(Mat2f(beta[1], beta[2], v[1], v[2])) * alpha
        return e1 + t2 * v
    end

    output = Point2f.(first.(poly.exterior))
    input = sizehint!(Point2f[], length(output))

    for edge in edges
        # swap references
        temp = input
        input = output
        output = temp

        empty!(output)
        v = edge[2] - edge[1]
        right = Vec2f(v[2], -v[1])

        for i in eachindex(input)
            p1 = input[mod1(i-1, end)]
            p2 = input[i]
            p = intersection(p1, p2, edge)
            if dot(p2 - edge[1], right) > 0 # p2 inside
                if dot(p1 - edge[1], right) < 0 # p1 outside
                    push!(output, p)
                end
                push!(output, p2)
            elseif dot(p1 - edge[1], right) > 0 # p1 inside
                push!(output, p)
            end
        end
    end

    return Polygon(output)
end


function clip_polygon(poly::Polygon, rect::Rect2)
    lb = Point2f(minimum(rect))
    rt = Point2f(maximum(rect))
    lt = Point2f(lb[1], rt[2])
    rb = Point2f(rt[1], lb[2])
    return clip_polygon(poly, [Line(lb, lt), Line(lt, rt), Line(rt, rb), Line(rb, lb)])
end

function clip_polygon(poly::Polygon, ::Nothing)
    return poly
end

function get_voronoi_tiles!(generators, polygons, vorn, bbox)
    empty!(generators)
    empty!(polygons)
    sizehint!(generators, DelTri.num_generators(vorn))
    sizehint!(polygons, DelTri.num_polygons(vorn))
    # TODO: get_polygon_coordinates() errors without a bbox tuple.
    pseudo_bbox = DelTri.polygon_bounds(vorn, 0.1)
    for i in DelTri.each_generator(vorn)
        g = DelTri.get_generator(vorn, i)
        p = Point2f(DelTri.getxy(g))
        p in bbox && push!(generators, p)
        polygon_coords = DelTri.get_polygon_coordinates(vorn, i, pseudo_bbox)
        polygon_coords_2f = map(polygon_coords) do coords
            x, y = DelTri.getxy(coords)
            return Point2f(x, y)
        end
        push!(polygons, clip_polygon(Polygon(polygon_coords_2f), bbox))
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
        elseif color isa AbstractArray
            @assert(
                length(color) == DelTri.num_points(DelTri.get_triangulation(vorn)),
                "Color vector must have the same length as the number of generators, including any not yet in the tessellation."
            )
            [color[i] for i in DelTri.each_generator(vorn)] # this matches the polygon order
        else
            color
        end
    end

    function update_plot(vorn)
        bbox = map(p.unbounded_edge_extension_factor, p.bounding_box) do extent, bnd
            isempty(DelTri.get_unbounded_polygons(vorn)) && return nothing
            if bnd === automatic
                bb_ref = RefValue(Rect3f())
                foreach(DelTri.get_generators(vorn)) do (_, p)
                    update_boundingbox!(bb_ref, Point2f(p))
                end

                x0, y0, _ = minimum(bb_ref[]) .- extent .* widths(bb_ref[])
                w, h, _ = (1 + 2extent) .* widths(bb_ref[])
                return Rect2f(x0, y0, w, h)
            else
                return bnd
            end
        end
        map(generators_2f, polygons, bbox) do gens, polys, box
            # _box = !isnothing(box) ? map(Float64, box) : box
            return get_voronoi_tiles!(gens, polys, vorn, box)
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
             color=p.markercolor,
             visible=p.show_generators,
             depth_shift=-2f-5)

    return p
end