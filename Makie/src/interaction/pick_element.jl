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
    element_or_accessor = get_accessor(first(plot_stack), idx, Base.tail(plot_stack))
    if element_or_accessor isa PlotElement
        # Allow get_accessor(plot, idx, plot_stack) to edit the plot_stack by
        # returning a PlotElement. Since those methods don't have the full
        # stack anymore we need to reconstruct the head
        head = Makie.plot_stack(parent(first(element_or_accessor.plot_stack)))
        full_stack = tuple(head..., element_or_accessor.plot_stack...)
        return PlotElement(full_stack, element_or_accessor)
    else # Accessor or Nothing
        return PlotElement(plot_stack, element_or_accessor)
    end
end

"""
    get_accessor(plot::Plot, index::Integer, plot_stack::Tuple)

Returns an `AbstractElementAccessor` describing the picked element of the given
root parent `plot`. This function is meant for overloading and should not be
called directly. Use `pick_element()` instead.

This function is called by `pick_element()` with

```julia
primitive, index = pick(...)
plot_stack = Makie.plot_stack(primitive)
get_accessor(first(plot_stack), index, Base.tail(plot_stack))
```

where the plot stack contains a trace of parent plots from the primitive to the
root parent parent plot, i.e. the plot created by a user. The accessor should
describe the picked element of the root plot.

By default this function will recursively fall back onto lower level plots. I.e.
it will call `get_accessor(first(plot_stack), index, Base.tail(plot_stack))` until
a specialized method is found. If a recipe and one or more of its children do
not share the same element format, a specialized method should be implemented.
This includes changes in interpretation (discrete vs continuous), changes in
indexing (the n-th element of the recipe does not match the n-th element of the
child plot) and potentially changes in the data format (e.g. flat array vs matrix).

Note that this function is not required to return the same accessor type for
a single `plot` type. For example `scatterlines` may return an `IndexedAccessor`
when a `scatter` marker was picked or a `InterpolatedAccessor` if `lines` was
picked.

Note that this function is also allowed to return a full `PlotElement` to
overwrite the (tail of the) `plot_stack`.
"""
function get_accessor(plot, index, child_stack)
    return get_accessor(first(child_stack), index, Base.tail(child_stack))
end

# Utilities
function pick_line_element(scene::Scene, plot, idx)
    # should be cheaper to inv transform one ray than N positions
    pos = plot.positions_transformed_f32c[]
    ray = transform(inv(plot.model_f32c[]), ray_at_cursor(scene))
    idx = max(2, idx)
    interpolation = closest_point_on_line_interpolation(pos[idx - 1], pos[idx], ray)
    return InterpolatedAccessor(idx-1, idx, interpolation, length(pos))
end

get_picked_model_space_rect(plot::Image, idx) = Rect2d(model_space_boundingbox(plot))

function get_picked_model_space_rect(plot::Heatmap, idx)
    # Workaround for Resampler
    if !isempty(plot.plots)
        return get_picked_model_space_rect(plot.plots[1], idx)
    end

    j, i = fldmod1(idx, size(plot.image[], 1))
    p0 = Point2d.(plot.x_transformed_f32c[][i], plot.y_transformed_f32c[][j])
    p1 = Point2d.(plot.x_transformed_f32c[][i+1], plot.y_transformed_f32c[][j+1])

    return Rect2d(p0, p1 .- p0)
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

function get_accessor(plot::Union{Scatter, MeshScatter}, idx, plot_stack)
    return IndexedAccessor(idx, length(plot.positions[]))
end

function get_accessor(plot::Text, idx, plot_stack)
    idx = findfirst(range -> idx in range, plot.text_blocks[])
    return IndexedAccessor(idx, length(plot.text_blocks[]))
end

function get_accessor(plot::Union{Lines, LineSegments}, idx, plot_stack)
    return pick_line_element(parent_scene(plot), plot, idx)
end

function interpolated_edge_to_cell_index(i_interp, size, one_based = false)
    # 0   1   2   3  i_interp
    # | , | , | , |
    #   1   2   3    cell index
    # ij_low should be i for ij_interp = i-0.5 .. i+0.5
    # ij_high should be i+1 in the same range
    i_low = clamp.(floor.(Int, i_interp .+ 0.5 .- one_based), 1, size)
    i_high = clamp.(ceil.(Int, i_interp .+ 0.5 .- one_based), 1, size)
    local_interpolation = i_interp .- i_low .+ 0.5 .- one_based
    return i_low, i_high, local_interpolation
end

function InterpolatedAccessor(
        plot::Plot, rect::Rect2, idx::Integer;
        edge_based = false,
        model = plot.model_f32c[],
        ray = transform(inv(model), ray_at_cursor(parent_scene(plot))),
        size = Base.size(plot.image[])
    )
    pos = Vec2d(ray_rect_intersection(rect, ray))
    isnan(pos) && return nothing

    if !edge_based
        ij_interp = (pos - origin(rect)) ./ widths(rect) .* size
        ij_low, ij_high, interp = interpolated_edge_to_cell_index(ij_interp, size, edge_based)
        return InterpolatedAccessor(ij_low, ij_high, interp, size)
    else
        j, i = fldmod1(idx, size[1]) # cell index
        local_interpolation = (pos - origin(rect)) ./ widths(rect)
        return InterpolatedAccessor(
            Vec2i(i, j), Vec2i(i+1, j+1), local_interpolation, size, edge_based
        )
    end
end

function get_accessor(plot::Union{Image, Heatmap}, idx, plot_stack::Tuple{})
    if plot.interpolate[]
        # Heatmap and Image are always a Rect2f. The transform function is currently
        # not allowed to change this, so applying it should be fine. Applying the
        # model matrix may add a z component to the Rect2f, which we can't represent,
        # so we instead inverse-transform the ray
        rect = get_picked_model_space_rect(plot, idx)
        return InterpolatedAccessor(plot, rect, idx, edge_based = plot isa Heatmap)
    else
        _size = size(plot.image[])
        cart = CartesianIndices(_size)[idx]
        return IndexedAccessor(cart, _size)
    end
end

function get_accessor(plot::Mesh, idx, plot_stack)
    ray = transform(inv(plot.model_f32c[]), ray_at_cursor(parent_scene(plot)))
    face, face_index, pos = find_picked_triangle(
        plot.positions_transformed_f32c[], plot.faces[], ray, idx
    )
    if isnan(pos)
        return nothing
    else
        uv = triangle_interpolation_parameters(face, plot.positions_transformed_f32c[], pos)
        submesh_index = findfirst(range -> face_index in range, plot.mesh[].views)
        return MeshAccessor(
            length(plot.positions_transformed_f32c[]), length(plot.mesh[].views),
            something(submesh_index, 1), face, uv
        )
    end
end


function get_accessor(plot::Surface, idx, plot_stack)
    ray = transform(inv(plot.model_f32c[]), ray_at_cursor(parent_scene(plot)))
    # the face picked here is always (pos, change first matrix index, change second matrix index)
    # so calculated uv's match first and second matrix index too
    face, pos = find_picked_surface_cell(plot, idx, ray)
    if isnan(pos)
        return nothing
    else
        # TODO: This should probably be a InterpolatedPlotElement{Surface, 2},
        # but how do we calculate the interpolated indices safely and quickly?
        # j, i = fldmod1(idx, size(z, 1)) should give us the closest matrix element
        # which means we can be somewhere between i-0.5 .. i+0.5 and j-0.5 .. j+0.5
        # this gives us 4 quads to search
        # each quad can be an irregular shape and any dimension could be constant
        # and we need to ray cast to get an accurate position on the quad
        # for now just triangulate...
        uv = triangle_interpolation_parameters(face, plot.positions_transformed_f32c[], pos)
        return MeshAccessor(length(plot.positions_transformed_f32c[]), 1, 1, face, uv)
    end
end

function get_accessor(plot::Voxels, idx, plot_stack)
    _size = size(plot.chunk_u8[])
    cart = CartesianIndices(_size)[idx]
    return IndexedAccessor(cart, _size)
end

# TODO:
get_accessor(plot::Volume, idx, plot_stack) = nothing

################################################################################
# Overloads
################################################################################

function find_triangle_in_submesh(
        positions::AbstractArray{<:VecTypes},
        faces::AbstractArray{<:GeometryBasics.AbstractFace},
        ray::Ray
    )
    for (face_index, face) in enumerate(faces)
        p1, p2, p3 = positions[face]
        pos = ray_triangle_intersection(p1, p2, p3, ray)
        if !isnan(pos)
            return face, face_index, pos
        end
    end
    return GLTriangleFace(1, 1, 1), 0, Point3d(NaN)
end

function get_accessor(plot::Poly, idx, plot_stack::Tuple{<:Wireframe, Vararg{Plot}})
    ray = transform(inv(plot.model_f32c[]), ray_at_cursor(parent_scene(plot)))
    meshplot = plot.plots[1]
    positions = meshplot.positions_transformed_f32c[]

    face, face_index, pos = find_triangle_in_submesh(
        positions, meshplot.faces[], ray
    )

    if isnan(pos)
        return nothing
    else
        submesh_index = findfirst(range -> face_index in range, meshplot.mesh[].views)
        uv = triangle_interpolation_parameters(face, positions, pos)
        accessor = MeshAccessor(
            length(positions), length(meshplot.mesh[].views), submesh_index, face, uv
        )
        # Edit stack so Poly always traces to mesh for simplicity
        return PlotElement((plot, plot.plots[1]), accessor)
    end
end

function get_accessor(plot::Poly, idx, plot_stack::Tuple{<:Lines, Vararg{Plot}})
    # reproduce mesh result
    submesh_index = findfirst(separation_idx -> idx < separation_idx, plot.increment_at[])
    meshplot = plot.plots[1]
    ray = transform(inv(meshplot.model_f32c[]), ray_at_cursor(parent_scene(plot)))
    positions = meshplot.positions_transformed_f32c[]
    range = meshplot.mesh[].views[submesh_index]

    face, face_index, pos = find_triangle_in_submesh(
        positions, view(meshplot.faces[], range), ray
    )

    if isnan(pos)
        return nothing
    else
        face_index = range[face_index]
        submesh_index = findfirst(range -> face_index in range, meshplot.mesh[].views)
        uv = triangle_interpolation_parameters(face, positions, pos)
        accessor = MeshAccessor(
            length(positions), length(meshplot.mesh[].views), submesh_index, face, uv
        )
        return PlotElement((plot, plot.plots[1]), accessor)
    end
end

function fast_submesh_index(plot::Mesh, idx::Integer, plot_stack = nothing)
    # When multiple meshes get merged via GeometryBasics, the faces of each
    # input mesh will get tracked by mesh.views. Faces of the first input are
    # mesh.faces[mesh.views[1]] etc. If we have 0 or 1 views, we have only one
    # mesh present. Otherwise we have multiple, and we need to find which mesh
    # a the vertex index `idx` belongs to. (Vertices don't get reused)
    if length(plot.mesh[].views) > 1
        ray = transform(inv(plot.model_f32c[]), ray_at_cursor(parent_scene(plot)))
        faces = plot.faces[]
        for (face_index, face) in enumerate(plot.faces[])
            if idx in face
                views = plot.mesh[].views
                submesh_index = findfirst(range -> face_index in range, views)
                return submesh_index, length(views)
            end
        end
    end
    return 1, 1
end

function fast_submesh_index(plot::Poly, idx, plot_stack::Tuple{<:Mesh, Vararg{Plot}})
    return fast_submesh_index(first(plot_stack), idx)
end

function fast_submesh_index(plot::Poly, idx, plot_stack::Tuple{<:Lines, Vararg{Plot}})
    # increment_at marks the NaN points which separate outline of each mesh
    # If only one mesh is present, increment_at will be [typemax(Int)]
    increment_at = plot.increment_at[]
    return findfirst(separation_idx -> idx < separation_idx, increment_at), length(increment_at)
end
function fast_submesh_index(plot::Poly, idx, plot_stack::Tuple{<:Wireframe, Vararg{Plot}})
    return 1, 1
end

# Text produces the element we want so we just need to handle Poly
function get_accessor(plot::TextLabel, idx, plot_stack::Tuple{<:Poly, Vararg{Plot}})
    idx, N = fast_submesh_index(first(plot_stack), idx, Base.tail(plot_stack))
    return IndexedAccessor(idx, N)
end

function get_accessor(plot::BarPlot, idx, plot_stack)
    idx, N = fast_submesh_index(first(plot_stack), idx, Base.tail(plot_stack))
    return IndexedAccessor(idx, N)
end

function get_accessor(plot::Arrows2D, idx, plot_stack)
    idx, N = fast_submesh_index(first(plot_stack), idx, Base.tail(plot_stack))
    N_components = sum(plot.should_component_render[])
    idx = fld1(idx, N_components)
    N = fld1(N, N_components)
    return IndexedAccessor(idx, N)
end

function get_accessor(plot::Band, idx, plot_stack)
    meshplot = first(plot_stack)

    # find selected triangle
    ray = transform(inv(meshplot.model_f32c[]), ray_at_cursor(parent_scene(plot)))
    ps = meshplot.positions_transformed_f32c[]
    face, face_index, pos = find_picked_triangle(ps, meshplot.faces[], ray, idx)
    isnan(pos) && return nothing

    # Get index of of the quad/first point in ps1/ps2
    N = div(length(ps), 2)
    idx = mod1(face_index, N-1)

    # interpolate to quad paramater
    f = point_in_quad_parameter(ps[idx], ps[idx + 1], ps[idx + N + 1], ps[idx + N], to_ndim(Point2d, pos, 0))

    return InterpolatedAccessor(idx, idx+1, f, N)
end

get_accessor(plot::Spy, idx, plot_stack::Tuple{<:Lines}) = nothing
