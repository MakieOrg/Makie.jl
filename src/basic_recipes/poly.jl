const PolyElements = Union{Polygon, MultiPolygon, Circle, Rect, AbstractMesh, VecTypes, AbstractVector{<:VecTypes}}

convert_arguments(::Type{<: Poly}, v::AbstractVector{<: PolyElements}) = (v,)
convert_arguments(::Type{<: Poly}, v::Union{Polygon, MultiPolygon}) = (v,)


function convert_pointlike(args...)
    return convert_arguments(PointBased(), args...)
end

function convert_arguments(::Type{<:Poly}, x::RealVector, y::RealVector)
    return convert_pointlike(x, y)
end

function convert_arguments(::Type{<:Poly}, path::AbstractVector{<:VecTypes})
    return convert_pointlike(path)
end

function convert_arguments(::Type{<:Poly}, path::BezierPath)
    return convert_pointlike(path)
end

function convert_arguments(::Type{<:Poly}, path::AbstractMatrix{<:Number})
    return convert_pointlike(path)
end

function convert_arguments(::Type{<:Poly}, vertices::AbstractArray, indices::AbstractArray)
    return convert_arguments(Mesh, vertices, indices)
end

convert_arguments(::Type{<: Poly}, m::GeometryBasics.Mesh) = (m,)
convert_arguments(::Type{<: Poly}, m::GeometryBasics.GeometryPrimitive) = (m,)

function plot!(plot::Poly{<: Tuple{Union{GeometryBasics.Mesh, GeometryPrimitive}}})
    mesh!(plot, shared_attributes(plot, Mesh), plot[1])
    wf_attr = shared_attributes(
        plot, Wireframe,
        color = plot.strokecolor, linewidth = plot.strokewidth, fxaa = false,
        colormap = plot.strokecolormap, depth_shift = plot.stroke_depth_shift
    )
    wireframe!(plot, wf_attr, plot[1])

    return plot
end

# Poly conversion
function poly_convert(geometries::AbstractVector, transform_func=identity)
    # TODO is this a problem with Float64 meshes?
    isempty(geometries) && return typeof(GeometryBasics.Mesh(Point2f[], GLTriangleFace[]))[]
    return poly_convert.(geometries, (transform_func,))
end

function poly_convert(geometry::AbstractGeometry{N, T}, transform_func=identity) where {N, T}
    return GeometryBasics.mesh(geometry; pointtype=Point{N,float_type(T)}, facetype=GLTriangleFace)
end

poly_convert(meshes::AbstractVector{<:AbstractMesh}, transform_func=identity) = poly_convert.(meshes, (transform_func,))

function poly_convert(polys::AbstractVector{<:Polygon}, transform_func=identity)
    # GLPlainMesh2D is not concrete?
    # TODO is this a problem with Float64 meshes?
    T = GeometryBasics.Mesh{2, Float32, GeometryBasics.Ngon{2, Float32, 3, Point2f}, SimpleFaceView{2, Float32, 3, GLIndex, Point2f, GLTriangleFace}}
    return isempty(polys) ? T[] : poly_convert.(polys, (transform_func,))
end

function poly_convert(multipolygons::AbstractVector{<:MultiPolygon}, transform_func=identity)
    return [merge(poly_convert.(multipoly.polygons, (transform_func,))) for multipoly in multipolygons]
end

poly_convert(mesh::GeometryBasics.Mesh, transform_func=identity) = mesh

function poly_convert(polygon::Polygon, transform_func=identity)
    outer = metafree(coordinates(polygon.exterior))
    # TODO consider applying f32 convert here too. We would need to identify this though...
    PT = float_type(outer)
    points = Vector{PT}[apply_transform(transform_func, outer)]
    points_flat = PT[outer;]
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

function poly_convert(polygon::AbstractVector{<:VecTypes{2, T}}, transform_func=identity) where {T}
    points = convert(Vector{Point2{float_type(T)}}, polygon)
    points_transformed = apply_transform(transform_func, points)
    faces = GeometryBasics.earcut_triangulate([points_transformed])
    # TODO, same as above!
    return GeometryBasics.Mesh(points, faces)
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
    line = Point2d[]
    for (i, mesh) in enumerate(meshes)
        points = to_lines(mesh)
        append!(line, points)
        # push!(line, points[1])
        # dont need to separate the last line segment
        if i != length(meshes)
            push!(line, Point2d(NaN))
        end
    end
    return line
end

function to_lines(polygon::AbstractVector{<: VecTypes})
    result = Point2d.(polygon)
    if !isempty(result) && !(result[1] ≈ result[end])
        push!(result, polygon[1])
    end
    return result
end

function plot!(plot::Poly{<: Tuple{<: Union{Polygon, AbstractVector{<: PolyElements}}}})
    geometries = plot[1]
    transform_func = plot.transformation.transform_func
    meshes = lift(poly_convert, plot, geometries, transform_func)
    mesh!(plot, shared_attributes(plot, Mesh), meshes)

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
    l_attr = shared_attributes(
        plot, Lines,
        linewidth = plot.strokewidth, color = stroke, fxaa = false, 
        colormap = plot.strokecolormap, depth_shift = plot.stroke_depth_shift
    )
    lines!(plot, l_attr, outline)
    return plot
end

function plot!(plot::Mesh{<: Tuple{<: AbstractVector{P}}}) where P <: Union{AbstractMesh, Polygon}
    meshes = plot[1]
    attrs = shared_attributes(plot, Mesh)

    num_meshes = lift(plot, meshes; ignore_equal_values=true) do meshes
        return Int[length(coordinates(m)) for m in meshes]
    end

    mesh_colors = Observable{Union{AbstractPattern, Matrix{RGBAf}, RGBColors, Float32}}()

    interpolate_in_fragment_shader = Observable(false)

    lift!(plot, mesh_colors, plot.color, num_meshes) do colors, num_meshes
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
            interpolate_in_fragment_shader[] = false
            return result
        else
            # If we have colors per vertex, we need to interpolate in fragment shader
            interpolate_in_fragment_shader[] = true
            return to_color(colors)
        end
    end
    attrs[:color] = mesh_colors
    transform_func = plot.transformation.transform_func
    bigmesh = lift(plot, meshes, transform_func) do meshes, tf
        if isempty(meshes)
            # TODO: Float64
            return GeometryBasics.Mesh(Point2f[], GLTriangleFace[])
        else
            triangle_meshes = map(mesh -> poly_convert(mesh, tf), meshes)
            return merge(triangle_meshes)
        end
    end
    mpl = mesh!(plot, attrs, bigmesh)
    # splice in internal attribute after creation to avoid validation
    attributes(mpl)[:interpolate_in_fragment_shader] = interpolate_in_fragment_shader
    return plot
end
