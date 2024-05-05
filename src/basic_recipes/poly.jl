const PolyElements = Union{Polygon, MultiPolygon, Circle, Rect, AbstractMesh, VecTypes, AbstractVector{<:VecTypes}}

convert_arguments(::Type{<: Poly}, v::AbstractVector{<: PolyElements}) = (v,)
convert_arguments(::Type{<: Poly}, v::Union{Polygon, MultiPolygon}) = (v,)

convert_arguments(::Type{<: Poly}, args...) = ([convert_arguments(Scatter, args...)[1]],)
convert_arguments(::Type{<: Poly}, vertices::AbstractArray, indices::AbstractArray) = convert_arguments(Mesh, vertices, indices)
convert_arguments(::Type{<: Poly}, m::GeometryBasics.Mesh) = (m,)
convert_arguments(::Type{<: Poly}, m::GeometryBasics.GeometryPrimitive) = (m,)

function plot!(plot::Poly{<: Tuple{Union{GeometryBasics.Mesh, GeometryPrimitive}}})

    mesh!(
        plot, lift(triangle_mesh, plot, plot[1]),
        color = plot.color,
        colormap = plot.colormap,
        colorscale = plot.colorscale,
        colorrange = plot.colorrange,
        alpha = plot.alpha,
        lowclip = plot.lowclip,
        highclip = plot.highclip,
        nan_color = plot.nan_color,
        shading = plot.shading,
        visible = plot.visible,
        overdraw = plot.overdraw,
        inspectable = plot.inspectable,
        transparency = plot.transparency,
        space = plot.space
    )
    wireframe!(
        plot, plot[1],
        color = plot[:strokecolor], linestyle = plot[:linestyle], space = plot[:space],
        linewidth = plot[:strokewidth], visible = plot[:visible], overdraw = plot[:overdraw],
        inspectable = plot[:inspectable], transparency = plot[:transparency],
        colormap = plot[:strokecolormap]
    )
end

# Poly conversion
function poly_convert(geometries::AbstractVector, transform_func=identity)
    isempty(geometries) && return typeof(GeometryBasics.Mesh(Point2f[], GLTriangleFace[]))[]
    return poly_convert.(geometries, (transform_func,))
end

function poly_convert(geometry::AbstractGeometry, transform_func=identity)
    return GeometryBasics.triangle_mesh(geometry)
end

poly_convert(meshes::AbstractVector{<:AbstractMesh}, transform_func=identity) = poly_convert.(meshes, (transform_func,))

function poly_convert(polys::AbstractVector{<:Polygon}, transform_func=identity)
    # GLPlainMesh2D is not concrete?
    T = GeometryBasics.Mesh{2, Float32, GeometryBasics.Ngon{2, Float32, 3, Point2f}, SimpleFaceView{2, Float32, 3, GLIndex, Point2f, GLTriangleFace}}
    return isempty(polys) ? T[] : poly_convert.(polys, (transform_func,))
end

function poly_convert(multipolygons::AbstractVector{<:MultiPolygon}, transform_func=identity)
    return [merge(poly_convert.(multipoly.polygons, (transform_func,))) for multipoly in multipolygons]
end

poly_convert(mesh::GeometryBasics.Mesh, transform_func=identity) = mesh

function poly_convert(polygon::Polygon, transform_func=identity)
    outer = metafree(coordinates(polygon.exterior))
    points = Vector{Point2f}[apply_transform(transform_func, outer)]
    points_flat = Point2f[outer;]
    for inner in polygon.interiors
        inner_points = metafree(coordinates(inner))
        append!(points_flat, inner_points)
        push!(points, apply_transform(transform_func, inner_points))
    end
    # Triangulate on transformed points, but leave the original points in the mesh
    # We sadly need to do this right now, since otherwise
    # The transformed points will mess with data_limits and the axes.
    # TODO, leave triangulations to the backend, and just pass the untransformed points
    faces = GeometryBasics.earcut_triangulate(points)
    return GeometryBasics.Mesh(points_flat, faces)
end

function poly_convert(polygon::AbstractVector{<:VecTypes}, transform_func=identity)
    point2f = convert(Vector{Point2f}, polygon)
    points_transformed = apply_transform(transform_func, point2f)
    faces = GeometryBasics.earcut_triangulate([points_transformed])
    # TODO, same as above!
    return GeometryBasics.Mesh(point2f, faces)
end

function poly_convert(polygons::AbstractVector{<:AbstractVector{<:VecTypes}}, transform_func=identity)
    return map(polygons) do poly
        return poly_convert(poly, transform_func)
    end
end

to_lines(polygon) = convert_arguments(Lines, polygon)[1]
# Need to explicitly overload for Mesh, since otherwise, Mesh will dispatch to AbstractVector
to_lines(polygon::GeometryBasics.Mesh) = convert_arguments(PointBased(), polygon)[1]

function to_lines(meshes::AbstractVector)
    line = Point2f[]
    for (i, mesh) in enumerate(meshes)
        points = to_lines(mesh)
        append!(line, points)
        # push!(line, points[1])
        # dont need to separate the last line segment
        if i != length(meshes)
            push!(line, Point2f(NaN))
        end
    end
    return line
end

function to_lines(polygon::AbstractVector{<: VecTypes})
    result = Point2f.(polygon)
    isempty(result) || push!(result, polygon[1])
    return result
end

function plot!(plot::Poly{<: Tuple{<: Union{Polygon, AbstractVector{<: PolyElements}}}})
    geometries = plot[1]
    transform_func = plot.transformation.transform_func
    meshes = lift(poly_convert, plot, geometries, transform_func)
    mesh!(plot, meshes;
        visible = plot.visible,
        shading = plot.shading,
        color = plot.color,
        colormap = plot.colormap,
        colorscale = plot.colorscale,
        colorrange = plot.colorrange,
        lowclip = plot.lowclip,
        highclip = plot.highclip,
        nan_color=plot.nan_color,
        alpha=plot.alpha,
        overdraw = plot.overdraw,
        fxaa = plot.fxaa,
        transparency = plot.transparency,
        inspectable = plot.inspectable,
        space = plot.space,
    )

    outline = lift(to_lines, plot, geometries)
    stroke = lift(plot, outline, plot.strokecolor) do outline, sc
        if !(meshes[] isa Mesh) && meshes[] isa AbstractVector && sc isa AbstractVector && length(sc) == length(meshes[])
            idx = 1
            return map(outline) do point
                if isnan(point)
                    idx += 1
                end
                return sc[idx]
            end
        else
            return sc
        end
    end

    lines!(
        plot, outline, visible = plot.visible,
        color = stroke, linestyle = plot.linestyle, alpha = plot.alpha,
        colormap = plot.strokecolormap,
        linewidth = plot.strokewidth, space = plot.space,
        overdraw = plot.overdraw, transparency = plot.transparency,
        inspectable = plot.inspectable, depth_shift = -1f-5
    )
end

function plot!(plot::Mesh{<: Tuple{<: AbstractVector{P}}}) where P <: Union{AbstractMesh, Polygon}
    meshes = plot[1]
    attributes = Attributes(
        visible = plot.visible, shading = plot.shading, fxaa = plot.fxaa,
        inspectable = plot.inspectable, transparency = plot.transparency,
        space = plot.space, ssao = plot.ssao,
        alpha=plot.alpha,
        lowclip = get(plot, :lowclip, automatic),
        highclip = get(plot, :highclip, automatic),
        nan_color = get(plot, :nan_color, :transparent),
        colormap = get(plot, :colormap, nothing),
        colorscale = get(plot, :colorscale, identity),
        colorrange = get(plot, :colorrange, automatic)
    )

    num_meshes = lift(plot, meshes; ignore_equal_values=true) do meshes
        return Int[length(coordinates(m)) for m in meshes]
    end

    mesh_colors = Observable{Union{AbstractPattern, Matrix{RGBAf}, RGBColors, Float32}}()

    map!(plot, mesh_colors, plot.color, num_meshes) do colors, num_meshes
        # one mesh per color
        if colors isa AbstractVector && length(colors) == length(num_meshes)
            ccolors = colors isa AbstractArray{<: Number} ? colors : to_color(colors)
            result = similar(ccolors, float32type(ccolors), sum(num_meshes))
            i = 1
            for (cs, len) in zip(ccolors, num_meshes)
                for j in 1:len
                    result[i] = cs
                    i += 1
                end
            end
            # For GLMakie (right now), to not interpolate between the colors (which are meant to be per mesh)
            attributes[:interpolate_in_fragment_shader] = false
            return result
        else
            # If we have colors per vertex, we need to interpolate in fragment shader
            attributes[:interpolate_in_fragment_shader] = true
            return to_color(colors)
        end
    end
    attributes[:color] = mesh_colors
    transform_func = plot.transformation.transform_func
    bigmesh = lift(plot, meshes, transform_func) do meshes, tf
        if isempty(meshes)
            return GeometryBasics.Mesh(Point2f[], GLTriangleFace[])
        else
            triangle_meshes = map(mesh -> poly_convert(mesh, tf), meshes)
            return merge(triangle_meshes)
        end
    end
    return mesh!(plot, attributes, bigmesh)
end
