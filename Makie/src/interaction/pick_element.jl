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

plot_stack(plot::Plot) = (plot, plot_stack(parent(plot))...)
plot_stack(::Scene) = tuple()
plot_stack(::Nothing) = tuple()


function pick_element(plot_stack::Tuple, idx)
    root = last(plot_stack)
    source = first(plot_stack)
    for i in length(plot_stack):-1:1
        element = pick_element(plot_stack[i], idx, source)
        if element !== nothing
            return PlotElement(root, element)
        end
    end
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

# Overload target

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
function pick_element(plot, idx, source)
    elem = pick_element(plot, idx)
    if elem === nothing
        @info "Hit default with $plot ($source)"
    end
    return elem
end
pick_element(::Plot, idx) = nothing

function pick_element(plot::Union{Scatter, MeshScatter, Text}, idx)
    return IndexedPlotElement(plot, idx)
end

function pick_element(plot::Union{Lines, LineSegments}, idx)
    return pick_line_element(parent_scene(plot), plot, idx)
end

function pick_element(plot::Union{Image, Heatmap}, idx)
    if plot.interpolate[]
        return pick_rect2D_element(parent_scene(plot), plot)
    else
        cart = CartesianIndices(size(plot.image[]))[idx]
        return IndexedPlotElement(plot, cart)
    end
end

function pick_element(plot::Mesh, idx)
    ray = transform(inv(plot.model_f32c[]), ray_at_cursor(parent_scene(plot)))
    f, pos = find_picked_triangle(
        plot.positions_transformed_f32c[], plot.faces[], ray, idx
    )
    uv = triangle_interpolation_parameters(f, plot.positions_transformed_f32c[], pos)
    return MeshPlotElement(plot, f, uv)
end


function pick_element(plot::Surface, idx)
    ray = transform(inv(plot.model_f32c[]), ray_at_cursor(parent_scene(plot)))
    f, pos = find_picked_surface_cell(plot, idx, ray)
    uv = triangle_interpolation_parameters(f, plot.positions_transformed_f32c[], pos)
    return MeshPlotElement(plot, f, uv)
end

function pick_element(plot::Voxels, idx)
    cart = CartesianIndices(size(plot.chunk_u8[]))[idx]
    return IndexedPlotElement(plot, cart)
end

# TODO:
pick_element(plot::Volume, idx) = false