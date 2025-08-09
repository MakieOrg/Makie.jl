# Related file: utilities/PlotElement.jl

"""
    pick_element()

Return a PlotElement relevant to the plot a t the picked position.
"""
pick_element(obj) = pick_element(get_scene(obj), events(obj).mouseposition[])

function pick_element(scene::Scene, mouseposition::VecTypes{2})
    plt, idx = pick(scene, mouseposition)
    if plt === nothing
        return nothing
    else
        return pick_element(plot_stack(plt), idx)
    end
end

plot_stack(plot::Plot) = (plot_stack(parent(plot))..., plot)
plot_stack(::Scene) = tuple()
plot_stack(::Nothing) = tuple()

function pick_element(plot_stack::Tuple, idx)
    element = pick_element(first(plot_stack), idx, Base.tail(plot_stack))
    return PlotElement(first(plot_stack), element)
end

# TODO: update docs
"""
    pick_element(plot::Plot, index::Integer, source::Plot)

Overload method for plot element picking. Given the top level recipe plot `plot`
and the picked `source` plot and `index`, this should return a `PlotElement` that
represents picked element in the recipe plot.

If this method is not implemented for a given recipe, it will fallback onto
`pick_element()` for the next highest level plot. For example, if we pick the
`mesh` plot in `barplot` this function will be called in this order until it
hits a valid method:
```
BarPlot # 1. attempt `pick_element(::BarPlot, ::Int64, ::Mesh)`
    Poly # 2. attempt `pick_element(::Poly, ::Int64, ::Mesh)`
        Mesh # 3. attempt `pick_element(::Mesh, ::Int64, ::Mesh)`
        Lines
```
If there is no method for the top level recipe plot, the result from a lower
level `pick_element` will be re-wrapped to refer to the top level recipe plot.

"""
function pick_element(plot, index, child_stack)
    pick_element(first(child_stack), index, Base.tail(child_stack))
end

# Utilities
function pick_line_element(scene::Scene, plot, idx)
    # should be cheaper to inv transform one ray than N positions
    pos = plot.positions_transformed_f32c[]
    ray = transform(inv(plot.model_f32c[]), ray_at_cursor(scene))
    idx = max(2, idx)
    interpolation = closest_point_on_line_interpolation(pos[idx - 1], pos[idx], ray)
    return InterpolatedPlotElement(plot, idx-1, idx, interpolation)
end

function model_space_boundingbox(plot::Heatmap)
    # Workaround for Resampler
    if !isempty(plot.plots)
        return model_space_boundingbox(plot.plots[1])
    end

    p0, p1 = Point2d.(
        extrema(plot.x_transformed_f32c[]),
        extrema(plot.y_transformed_f32c[])
    )
    # using Rect3d in case we generalize this
    return Rect3d(Point3d(p0..., 0), Vec3d((p1 .- p0)..., 0))
end

model_space_boundingbox(plot::Image) = Rect3d(plot.positions_transformed_f32c[])

function pick_rect2D_element(scene::Scene, plot)
    # Heatmap and Image are always a Rect2f. The transform function is currently
    # not allowed to change this, so applying it should be fine. Applying the
    # model matrix may add a z component to the Rect2f, which we can't represent,
    # so we instead inverse-transform the ray
    p0, p1 = Point2d.(extrema(model_space_boundingbox(plot)))
    ray = transform(inv(plot.model_f32c[]), ray_at_cursor(scene))
    pos = Vec2d(ray_rect_intersection(Rect2(p0, p1 - p0), ray))
    _size = size(plot.image[])
    uv = (pos - p0) ./ (p1 - p0)
    ij_interp = uv .* _size
    ij_low = clamp.(floor.(Int, ij_interp), 1, _size .- 1)
    return InterpolatedPlotElement(plot, ij_low, ij_low .+ 1, ij_interp .- ij_low)
end

function triangle_interpolation_parameters(face::TriangleFace, positions::AbstractArray{<: VecTypes{2}}, ref::VecTypes)
    a, b, c = positions[face]
    # ref = a + (b-a) * u + (c-a) * v
    # ref - a = Mat2f(b-a, c-a) * Vec(u, v)
    # (u, v) = inv(Mat2f(b-a, c-a)) * (ref - a)
    M = Mat2f((b-a)..., (c-a)...)
    uv = inv(M) * (ref[Vec(1,2)] - a)
    return uv
end

function triangle_interpolation_parameters(face::TriangleFace, positions::AbstractArray{<: VecTypes{3}}, ref::VecTypes{3})
    # same thing, but with a throw-away surface normal to complete the Mat3
    a, b, c = positions[face]
    v1 = b - a
    v2 = c - a
    n = cross(v1, v2)
    M = Mat3f(v1..., v2..., n...)
    uvw = inv(M) * (ref - a)
    return Vec2f(uvw)
end

################################################################################
# Primitives
################################################################################

function pick_element(plot::Union{Scatter, MeshScatter}, idx, plot_stack)
    return IndexedPlotElement(plot, idx)
end

function pick_element(plot::Text, idx, plot_stack)
    idx = findfirst(range -> idx in range, plot.text_blocks[])
    return IndexedPlotElement(plot, idx)
end

function pick_element(plot::Union{Lines, LineSegments}, idx, plot_stack)
    return pick_line_element(parent_scene(plot), plot, idx)
end

function pick_element(plot::Union{Image, Heatmap}, idx, plot_stack)
    if plot.interpolate[]
        return pick_rect2D_element(parent_scene(plot), plot)
    else
        cart = CartesianIndices(size(plot.image[]))[idx]
        return IndexedPlotElement(plot, cart)
    end
end

function pick_element(plot::Mesh, idx, plot_stack)
    ray = transform(inv(plot.model_f32c[]), ray_at_cursor(parent_scene(plot)))
    f, pos = find_picked_triangle(
        plot.positions_transformed_f32c[], plot.faces[], ray, idx
    )
    uv = triangle_interpolation_parameters(f, plot.positions_transformed_f32c[], pos)
    return MeshPlotElement(plot, f, uv)
end


function pick_element(plot::Surface, idx, plot_stack)
    ray = transform(inv(plot.model_f32c[]), ray_at_cursor(parent_scene(plot)))
    f, pos = find_picked_surface_cell(plot, idx, ray)
    uv = triangle_interpolation_parameters(f, plot.positions_transformed_f32c[], pos)
    return MeshPlotElement(plot, f, uv)
end

function pick_element(plot::Voxels, idx, plot_stack)
    cart = CartesianIndices(size(plot.chunk_u8[]))[idx]
    return IndexedPlotElement(plot, cart)
end

# TODO:
pick_element(plot::Volume, idx, plot_stack) = false

################################################################################
# Overloads
################################################################################

function pick_mesh_array_index(merged_mesh::GeometryBasics.Mesh, vertex_index::Integer)
    # When multiple meshes get merged via GeometryBasics, the faces of each
    # input mesh will get tracked by mesh.views. Faces of the first input are
    # mesh.faces[mesh.views[1]] etc. If we have 0 or 1 views, we have only one
    # mesh present. Otherwise we have multiple, and we need to find which mesh
    # a the vertex index `idx` belongs to. (Vertices don't get reused)
    if length(merged_mesh.views) < 2
        return 1
    else
        fs = faces(merged_mesh)
        for (face_idx, face) in enumerate(fs)
            if vertex_index in face
                return findfirst(range -> face_idx in range, merged_mesh.views)
            end
        end
    end
end

function pick_mesh_array_index(plot::Mesh, vertex_index::Integer, plot_stack)
    return pick_mesh_array_index(plot.mesh[], vertex_index)
end

function pick_mesh_array_index(::Wireframe, ::Integer, plot_stack)
    return 1 # TODO: compute this
end

function pick_mesh_array_index(::Poly, vertex_index::Integer, plot_stack)
    return pick_mesh_array_index(first(plot_stack), vertex_index, plot_stack)
end

function pick_mesh_array_index(plot::Poly, idx::Integer, plot_stack::Tuple{<:Lines, Vararg{Plot}})
    # increment_at marks the NaN points which separate outline of each mesh
    # If only one mesh is present, increment_at will be [typemax(Int)]
    return findfirst(separation_idx -> idx < separation_idx, plot.increment_at[])
end

# Text produces the element we want so we just need to handle Poly
function pick_element(plot::TextLabel, idx, plot_stack::Tuple{<:Poly, Vararg{Plot}})
    idx = pick_mesh_array_index(first(plot_stack), idx, Base.tail(plot_stack))
    return IndexedPlotElement(plot, idx)
end

function pick_element(plot::BarPlot, idx, plot_stack)
    idx = pick_mesh_array_index(first(plot_stack), idx, Base.tail(plot_stack))
    return IndexedPlotElement(plot, idx)
end