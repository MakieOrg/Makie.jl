const PolyElements = Union{Polygon, MultiPolygon, Circle, Rect, AbstractMesh, VecTypes, AbstractVector{<:VecTypes}}

convert_arguments(::Type{<:Poly}, v::AbstractVector{<:PolyElements}) = (v,)
convert_arguments(::Type{<:Poly}, v::Union{Polygon, MultiPolygon}) = (v,)


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

convert_arguments(::Type{<:Poly}, m::GeometryBasics.Mesh) = (m,)
convert_arguments(::Type{<:Poly}, m::GeometryBasics.GeometryPrimitive) = (m,)

function plot!(plot::Poly{<:Tuple{Union{GeometryBasics.Mesh, GeometryPrimitive}}})
    mesh!(
        plot, plot[1],
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
        space = plot.space,
        depth_shift = plot.depth_shift
    )
    wireframe!(
        plot, plot[1],
        color = plot.strokecolor, linestyle = plot.linestyle, space = plot.space,
        linewidth = plot.strokewidth, linecap = plot.linecap,
        visible = plot.visible, overdraw = plot.overdraw,
        inspectable = plot.inspectable, transparency = plot.transparency,
        colormap = plot.strokecolormap, depth_shift = plot.stroke_depth_shift
    )
    return plot
end

# Poly conversion
function poly_convert(geometries::AbstractVector, transform_func = identity)
    isempty(geometries) && return GeometryBasics.SimpleMesh{2, Float64, GLTriangleFace}[]
    return poly_convert.(geometries, (transform_func,))
end

function poly_convert(geometry::AbstractGeometry{N, T}, transform_func = identity) where {N, T}
    return GeometryBasics.mesh(geometry; pointtype = Point{N, float_type(T)}, facetype = GLTriangleFace)
end

poly_convert(meshes::AbstractVector{<:AbstractMesh}, transform_func = identity) = poly_convert.(meshes, (transform_func,))

function poly_convert(polys::AbstractVector{<:Polygon{N, T}}, transform_func = identity) where {N, T}
    MeshType = GeometryBasics.SimpleMesh{N, float_type(T), GLTriangleFace}
    return isempty(polys) ? MeshType[] : poly_convert.(polys, (transform_func,))
end

function poly_convert(multipolygons::AbstractVector{<:MultiPolygon}, transform_func = identity)
    return [merge(poly_convert.(multipoly.polygons, (transform_func,))) for multipoly in multipolygons]
end

function poly_convert(multipolygon::MultiPolygon, transform_func = identity)
    return poly_convert.(multipolygon.polygons, (transform_func,))
end

poly_convert(mesh::GeometryBasics.Mesh, transform_func = identity) = mesh

function poly_convert(polygon::Polygon, transform_func = identity)
    outer = coordinates(polygon.exterior)
    # TODO consider applying f32 convert here too. We would need to identify this though...
    PT = float_type(outer)
    # Note that this should not be coerced to be a `Vector{PT}`,
    # since `apply_transform` can change points from e.g 2D to 3D.
    points = [apply_transform(transform_func, outer)]
    points_flat = PT[outer;]
    for inner in polygon.interiors
        inner_points = coordinates(inner)
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

function poly_convert(polygon::AbstractVector{<:VecTypes{N, T}}, transform_func = identity) where {N, T}
    points2d = convert(Vector{Point2{float_type(T)}}, polygon)
    points_transformed = apply_transform(transform_func, points2d)
    faces = GeometryBasics.earcut_triangulate([points_transformed])
    # TODO, same as above!
    points = convert(Vector{Point{N, float_type(T)}}, polygon)
    return GeometryBasics.Mesh(points, faces)::GeometryBasics.SimpleMesh{N, float_type(T), GLTriangleFace}
end

function poly_convert(polygons::AbstractVector{<:AbstractVector{<:VecTypes}}, transform_func = identity)
    return map(polygons) do poly
        return poly_convert(poly, transform_func)
    end
end

to_lines(polygon) = (convert_arguments(Lines, polygon)[1], [typemax(Int)])
# Need to explicitly overload for Mesh, since otherwise, Mesh will dispatch to AbstractVector
to_lines(polygon::GeometryBasics.Mesh) = (convert_arguments(PointBased(), polygon)[1], [typemax(Int)])

function to_lines(meshes::AbstractVector)
    get_dim(::AbstractVector{<:VecTypes{N}}) where {N} = N
    get_dim(::Any) = 3
    N = mapreduce(get_dim, max, meshes, init = 2)
    line = Point{N, Float64}[]
    separation_indices = Int[]
    for (i, mesh) in enumerate(meshes)
        points = to_ndim.(Point{N, Float64}, to_lines(mesh)[1], 0)
        append!(line, points)
        push!(separation_indices, length(line) + 1)
        # push!(line, points[1])
        # dont need to separate the last line segment
        if i != length(meshes)
            push!(line, Point{N, Float64}(NaN))
        end
    end
    return (line, separation_indices)
end

function to_lines(polygon::AbstractVector{<:VecTypes{N}}) where {N}
    result = Point{N, Float64}.(polygon)
    if !isempty(result) && result[1] != result[end]
        push!(result, polygon[1])
    end
    return (result, [typemax(Int)])
end

"""
Return `true` if `poly` must use one `mesh!` per `(meshes[i], colors[i])` instead of a merged
mesh: mixed [`AbstractPattern`](@ref) and non-pattern paint, or multiple distinct patterns.
"""
function poly_mesh_patterns_need_split(meshes, colors)::Bool
    if !(meshes isa AbstractVector && colors isa AbstractVector)
        return false
    end
    if length(meshes) != length(colors) || isempty(colors)
        return false
    end
    has_pattern = any(c -> c isa AbstractPattern, colors)
    has_non_pattern = any(c -> !(c isa AbstractPattern), colors)
    if has_pattern && has_non_pattern
        return true
    end
    if all(c -> c isa AbstractPattern, colors)
        return !allequal(colors)
    end
    return false
end

function poly_remove_mesh_subplots!(poly::Plot)
    scene = parent_scene(poly)
    i = 1
    while i <= length(poly.plots)
        sub = poly.plots[i]
        if plotkey(sub) === :mesh
            delete!(scene, sub)
            deleteat!(poly.plots, i)
        else
            i += 1
        end
    end
    return
end

function poly_reorder_mesh_plots_first!(poly::Plot)
    is_mesh = map(p -> plotkey(p) === :mesh, poly.plots)
    if !any(is_mesh)
        return
    end
    mesh_plots = poly.plots[is_mesh]
    non_mesh = poly.plots[.!is_mesh]
    empty!(poly.plots)
    append!(poly.plots, mesh_plots)
    return append!(poly.plots, non_mesh)
end

function poly_update_mesh_children!(plot::Poly, meshes, colors)
    poly_remove_mesh_subplots!(plot)
    if poly_mesh_patterns_need_split(meshes, colors)
        for (m, c) in zip(meshes, colors)
            mesh!(
                plot, m;
                visible = plot.visible,
                shading = plot.shading,
                color = c,
                colormap = plot.colormap,
                colorscale = plot.colorscale,
                colorrange = plot.colorrange,
                lowclip = plot.lowclip,
                highclip = plot.highclip,
                nan_color = plot.nan_color,
                alpha = plot.alpha,
                overdraw = plot.overdraw,
                fxaa = plot.fxaa,
                transparency = plot.transparency,
                inspectable = plot.inspectable,
                space = plot.space,
                depth_shift = plot.depth_shift,
            )
        end
    else
        mesh!(
            plot, plot.meshes;
            visible = plot.visible,
            shading = plot.shading,
            color = plot.color,
            colormap = plot.colormap,
            colorscale = plot.colorscale,
            colorrange = plot.colorrange,
            lowclip = plot.lowclip,
            highclip = plot.highclip,
            nan_color = plot.nan_color,
            alpha = plot.alpha,
            overdraw = plot.overdraw,
            fxaa = plot.fxaa,
            transparency = plot.transparency,
            inspectable = plot.inspectable,
            space = plot.space,
            depth_shift = plot.depth_shift,
        )
    end
    return poly_reorder_mesh_plots_first!(plot)
end

function plot!(plot::Poly{<:Tuple{<:Union{Polygon, MultiPolygon, Rect2, Circle, AbstractVector{<:PolyElements}}}})
    map!(poly_convert, plot, [:polygon, :transform_func], :meshes)

    poly_update_mesh_children!(plot, to_value(plot.meshes), to_value(plot.color))

    onany(plot, plot.meshes, plot.color; update = false) do meshes, colors
        poly_update_mesh_children!(plot, meshes, colors)
    end

    map!(to_lines, plot, :polygon, [:outline, :increment_at])
    map!(plot, [:outline, :increment_at, :strokecolor, :meshes], :computed_strokecolor) do outline, increment_at, sc, meshes
        if meshes isa AbstractVector && sc isa AbstractVector && length(sc) == length(meshes)
            new_colors = similar(sc, length(outline))
            mesh_idx = 1
            next_switch = isempty(increment_at) ? -1 : increment_at[1]
            for point_idx in eachindex(outline)
                if point_idx == next_switch
                    mesh_idx += 1
                    next_switch = increment_at[mesh_idx]
                end
                new_colors[point_idx] = sc[mesh_idx]
            end
            return new_colors
        else
            return sc
        end
    end
    return lines!(
        plot, plot.outline, visible = plot.visible,
        color = plot.computed_strokecolor, linestyle = plot.linestyle, alpha = plot.alpha,
        colormap = plot.strokecolormap,
        linewidth = plot.strokewidth, linecap = plot.linecap,
        joinstyle = plot.joinstyle, miter_limit = plot.miter_limit,
        space = plot.space,
        overdraw = plot.overdraw, transparency = plot.transparency,
        inspectable = plot.inspectable, depth_shift = plot.stroke_depth_shift
    )
end
