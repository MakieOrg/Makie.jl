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
    return InterpolatedPlotElement(plot, idx-1, idx, interpolation, length(pos))
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

function pick_element(plot::Union{Scatter, MeshScatter}, idx, plot_stack)
    return IndexedPlotElement(plot, idx, length(plot.positions[]))
end

function pick_element(plot::Text, idx, plot_stack)
    idx = findfirst(range -> idx in range, plot.text_blocks[])
    return IndexedPlotElement(plot, idx, length(plot.text_blocks[]))
end

function pick_element(plot::Union{Lines, LineSegments}, idx, plot_stack)
    return pick_line_element(parent_scene(plot), plot, idx)
end

function interpolated_edge_to_cell_index(i_interp, _size, one_based = false)
    # 0   1   2   3  i_interp
    # | , | , | , |
    #   1   2   3    cell index
    # ij_low should be i for ij_interp = i-0.5 .. i+0.5
    # ij_high should be i+1 in the same range
    i_low = clamp.(floor.(Int, i_interp .+ 0.5 .- one_based), 1, _size)
    i_high = clamp.(ceil.(Int, i_interp .+ 0.5 .- one_based), 1, _size)
    local_interpolation = i_interp .- i_low .+ 0.5 .- one_based
    return i_low, i_high, local_interpolation
end

function pick_element(plot::Union{Image, Heatmap}, idx, plot_stack)
    if plot.interpolate[]
        # Heatmap and Image are always a Rect2f. The transform function is currently
        # not allowed to change this, so applying it should be fine. Applying the
        # model matrix may add a z component to the Rect2f, which we can't represent,
        # so we instead inverse-transform the ray
        rect = get_picked_model_space_rect(plot, idx)
        ray = transform(inv(plot.model_f32c[]), ray_at_cursor(parent_scene(plot)))
        pos = Vec2d(ray_rect_intersection(rect, ray))
        isnan(pos) && return nothing

        _size = size(plot.image[])
        if plot isa Image
            # cell based indices
            ij_interp = (pos - origin(rect)) ./ widths(rect) .* _size
            ij_low, ij_high, interp = interpolated_edge_to_cell_index(ij_interp, _size, false)
            return InterpolatedPlotElement(plot, ij_low, ij_high, interp, _size)
        else
            j, i = fldmod1(idx, _size[1]) # cell index
            local_interpolation = (pos - origin(rect)) ./ widths(rect)
            # edge based indices
            return InterpolatedPlotElement(plot, Vec2i(i, j), Vec2i(i+1, j+1), local_interpolation, _size, true)
        end

        return pick_rect2D_element(parent_scene(plot), plot)
    else
        _size = size(plot.image[])
        cart = CartesianIndices(_size)[idx]
        return IndexedPlotElement(plot, cart, _size)
    end
end

function pick_element(plot::Mesh, idx, plot_stack)
    ray = transform(inv(plot.model_f32c[]), ray_at_cursor(parent_scene(plot)))
    face, face_index, pos = find_picked_triangle(
        plot.positions_transformed_f32c[], plot.faces[], ray, idx
    )
    if isnan(pos)
        return nothing
    else
        uv = triangle_interpolation_parameters(face, plot.positions_transformed_f32c[], pos)
        submesh_index = findfirst(range -> face_index in range, plot.mesh[].views)
        return MeshPlotElement(
            plot, length(plot.positions_transformed_f32c[]), length(plot.mesh[].views),
            something(submesh_index, 1), face, uv
        )
    end
end


function pick_element(plot::Surface, idx, plot_stack)
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
        return MeshPlotElement(plot, length(plot.positions_transformed_f32c[]), 1, 1, face, uv)
    end
end

function pick_element(plot::Voxels, idx, plot_stack)
    _size = size(plot.chunk_u8[])
    cart = CartesianIndices(_size)[idx]
    return IndexedPlotElement(plot, cart, _size)
end

# TODO:
pick_element(plot::Volume, idx, plot_stack) = nothing

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

function pick_element(plot::Poly, idx, plot_stack::Tuple{<:Wireframe, Vararg{Plot}})
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
        return MeshPlotElement(
            plot, length(positions), length(meshplot.mesh[].views), submesh_index, face, uv
        )
    end
end

function pick_element(plot::Poly, idx, plot_stack::Tuple{<:Lines, Vararg{Plot}})
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
        return MeshPlotElement(
            plot, length(positions), length(meshplot.mesh[].views), submesh_index, face, uv
        )
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
function pick_element(plot::TextLabel, idx, plot_stack::Tuple{<:Poly, Vararg{Plot}})
    idx, N = fast_submesh_index(first(plot_stack), idx, Base.tail(plot_stack))
    return IndexedPlotElement(plot, idx, N)
end

function pick_element(plot::BarPlot, idx, plot_stack)
    idx, N = fast_submesh_index(first(plot_stack), idx, Base.tail(plot_stack))
    return IndexedPlotElement(plot, idx, N)
end

function pick_element(plot::Arrows2D, idx, plot_stack)
    idx, N = fast_submesh_index(first(plot_stack), idx, Base.tail(plot_stack))
    N_components = sum(plot.should_component_render[])
    idx = fld1(idx, N_components)
    N = fld1(N, N_components)
    return IndexedPlotElement(plot, idx, N)
end

function pick_element(plot::Band, idx, plot_stack)
    meshplot = first(plot_stack)

    # find selected triangle
    ray = transform(inv(meshplot.model_f32c[]), ray_at_cursor(parent_scene(plot)))
    face, face_index, pos = find_picked_triangle(
        meshplot.positions_transformed_f32c[], meshplot.faces[], ray, idx
    )
    isnan(pos) && return nothing

    # Get index of of the quad/first point in ps1/ps2
    ps1 = plot.lowerpoints[]
    ps2 = plot.upperpoints[]
    N = length(ps1)
    idx = mod1(face_index, N-1)

    # interpolate to quad paramater
    # TODO: These should not be in different spaces (input space vs post f32c world space)
    f = point_in_quad_parameter(ps1[idx], ps1[idx + 1], ps2[idx + 1], ps2[idx], to_ndim(Point2d, pos, 0))

    return InterpolatedPlotElement(plot, idx, idx+1, f, N)
end
