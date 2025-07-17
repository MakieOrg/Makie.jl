################################################################################
### Ray Generation
################################################################################

struct Ray{T}
    origin::Point3{T}
    direction::Vec3{T}

    function Ray(pos::VecTypes{3, T1}, dir::VecTypes{3, T2}) where {T1, T2}
        T = promote_type(Float32, T1, T2)
        return new{T}(to_ndim(Point3{T}, pos, 0), to_ndim(Vec3{T}, dir, 0))
    end
end

function Base.convert(::Type{Ray{Float32}}, ray::Ray)
    return Ray(Point3f(ray.origin), Vec3f(ray.direction))
end


"""
    ray_at_cursor(fig/ax/scene)

Returns a Ray into the scene starting at the current cursor position.
"""
ray_at_cursor(x) = ray_at_cursor(get_scene(x))
function ray_at_cursor(scene::Scene)
    return Ray(scene, mouseposition_px(scene))
end

"""
    Ray(scene[, cam = cameracontrols(scene)], xy)

Returns a `Ray` into the given `scene` passing through pixel position `xy`. Note
that the pixel position should be relative to the origin of the scene, as it is
when calling `mouseposition_px(scene)`.
"""
Ray(scene::Scene, xy::VecTypes{2}) = Ray(scene, cameracontrols(scene), xy)


function Ray(scene::Scene, cam::Camera3D, xy::VecTypes{2})
    lookat = cam.lookat[]
    eyepos = cam.eyeposition[]
    viewdir = lookat - eyepos

    u_z = normalize(viewdir)
    u_x = normalize(cross(u_z, cam.upvector[]))
    u_y = normalize(cross(u_x, u_z))

    px_width, px_height = widths(scene)
    aspect = px_width / px_height
    rel_pos = 2 .* xy ./ (px_width, px_height) .- 1

    if cam.settings.projectiontype[] === Perspective
        dir = (rel_pos[1] * aspect * u_x + rel_pos[2] * u_y) * tand(0.5 * cam.fov[]) + u_z
        return Ray(cam.eyeposition[], normalize(dir))
    else
        # Orthographic has consistent direction, but not starting point
        origin = norm(viewdir) * (rel_pos[1] * aspect * u_x + rel_pos[2] * u_y)
        return Ray(origin, normalize(viewdir))
    end
end

function Ray(scene::Scene, cam::Camera2D, xy::VecTypes{2})
    rel_pos = xy ./ widths(scene)
    pv = scene.camera.projectionview[]
    m = Vec2f(pv[1, 1], pv[2, 2])
    b = Vec2f(pv[1, 4], pv[2, 4])
    origin = (2 * rel_pos .- 1 - b) ./ m
    return Ray(to_ndim(Point3f, origin, 10_000f0), Vec3f(0, 0, -1))
end

function Ray(::Scene, ::PixelCamera, xy::VecTypes{2})
    return Ray(to_ndim(Point3f, xy, 10_000f0), Vec3f(0, 0, -1))
end

function Ray(scene::Scene, ::RelativeCamera, xy::VecTypes{2})
    origin = xy ./ widths(scene)
    return Ray(to_ndim(Point3f, origin, 10_000f0), Vec3f(0, 0, -1))
end

Ray(scene::Scene, cam, xy::VecTypes{2}) = ray_from_projectionview(scene, xy)

# This method should always work
function ray_from_projectionview(scene::Scene, xy::VecTypes{2})
    inv_view_proj = inv(camera(scene).projectionview[])
    area = viewport(scene)[]

    # This figures out the camera view direction from the projectionview matrix
    # and computes a ray from a near and a far point.
    # Based on ComputeCameraRay from ImGuizmo
    mp = 2.0f0 .* xy ./ widths(area) .- 1.0f0
    v = inv_view_proj * Vec4f(0, 0, -10, 1)
    reversed = v[3] < v[4]
    near = reversed ? 1.0f0 - 1.0e-6 : 0.0f0
    far = reversed ? 0.0f0 : 1.0f0 - 1.0e-6

    origin = inv_view_proj * Vec4f(mp[1], mp[2], near, 1.0f0)
    origin = origin[Vec(1, 2, 3)] ./ origin[4]

    p = inv_view_proj * Vec4f(mp[1], mp[2], far, 1.0f0)
    p = p[Vec(1, 2, 3)] ./ p[4]

    dir = normalize(p .- origin)

    return Ray(origin, dir)
end


function transform(M::Mat4{T}, ray::Ray) where {T}
    p4d = M * to_ndim(Point4{T}, ray.origin, 1.0f0)
    dir = normalize(M[Vec(1, 2, 3), Vec(1, 2, 3)] * ray.direction)
    return Ray(p4d[Vec(1, 2, 3)] / p4d[4], dir)
end

f32_convert(::Nothing, ray::Ray) = ray
function f32_convert(ls::LinearScaling, ray::Ray)
    return Ray(f32_convert(ls, ray.origin), normalize(ls.scale .* ray.direction))
end

inv_f32_convert(::Nothing, ray::Ray) = ray
inv_f32_convert(c::Float32Convert, ray::Ray) = inv_f32_convert(c.scaling[], ray)
function inv_f32_convert(ls::LinearScaling, ray::Ray)
    ils = inv(ls)
    return Ray(ils(ray.origin), normalize(ils.scale .* ray.direction))
end


################################################################################
### Ray - object intersections
################################################################################


# These work in 2D and 3D
function closest_point_on_line(A::VecTypes, B::VecTypes, ray::Ray)
    return closest_point_on_line(to_ndim(Point3d, A, 0), to_ndim(Point3d, B, 0), ray)
end
function closest_point_on_line(A::Point3, B::Point3, ray::Ray)
    # See:
    # https://en.wikipedia.org/wiki/Line%E2%80%93plane_intersection
    AB_norm = norm(B .- A)
    u_AB = (B .- A) / AB_norm
    u_perp = normalize(cross(ray.direction, u_AB))
    # e_RD, e_perp defines a plane with normal n
    n = normalize(cross(ray.direction, u_perp))
    t = dot(ray.origin .- A, n) / dot(u_AB, n)
    return A .+ clamp(t, 0.0, AB_norm) * u_AB
end

function ray_triangle_intersection(A::VecTypes, B::VecTypes, C::VecTypes, ray::Ray, ϵ = 1.0e-6)
    return ray_triangle_intersection(
        to_ndim(Point3d, A, 0), to_ndim(Point3d, B, 0), to_ndim(Point3d, C, 0),
        ray, ϵ
    )
end

function ray_triangle_intersection(
        A::VecTypes{3, T1}, B::VecTypes{3, T2}, C::VecTypes{3, T3}, ray::Ray{T4}, ϵ = 1.0e-6
    ) where {T1, T2, T3, T4}
    T = promote_type(T1, T2, T3, T4, Float32)
    # See: https://www.iue.tuwien.ac.at/phd/ertl/node114.html
    # Alternative: https://en.wikipedia.org/wiki/M%C3%B6ller%E2%80%93Trumbore_intersection_algorithm
    AO = A .- ray.origin
    BO = B .- ray.origin
    CO = C .- ray.origin
    A1 = 0.5 * dot(cross(BO, CO), ray.direction)
    A2 = 0.5 * dot(cross(CO, AO), ray.direction)
    A3 = 0.5 * dot(cross(AO, BO), ray.direction)

    # all positive or all negative
    if (A1 > -ϵ && A2 > -ϵ && A3 > -ϵ) || (A1 < ϵ && A2 < ϵ && A3 < ϵ)
        return Point3{T}((A1 * A .+ A2 * B .+ A3 * C) / (A1 + A2 + A3))
    else
        return Point3{T}(NaN)
    end
end

function ray_rect_intersection(rect::Rect2, ray::Ray)
    possible_hit = ray.origin - ray.origin[3] / ray.direction[3] * ray.direction
    min = minimum(rect); max = maximum(rect)
    if all(min <= possible_hit[Vec(1, 2)] <= max)
        return possible_hit
    end
    return Point3f(NaN)
end


function ray_rect_intersection(rect::Rect3, ray::Ray)
    mins = (minimum(rect) - ray.origin) ./ ray.direction
    maxs = (maximum(rect) - ray.origin) ./ ray.direction
    x, y, z = min.(mins, maxs)
    possible_hit = max(x, y, z)
    if possible_hit < minimum(max.(mins, maxs))
        return ray.origin + possible_hit * ray.direction
    end
    return Point3f(NaN)
end

function is_point_on_ray(p::Point3{T1}, ray::Ray{T2}) where {T1 <: Real, T2 <: Real}
    diff = ray.origin - p
    return isapprox(
        abs(dot(diff, ray.direction)),
        abs(norm(diff)),
        # use lower eps of the input types so we don't have to bother converting
        # Float64 Rays to Float32
        rtol = sqrt(max(eps(T1), eps(T2)))
    )
end


function ray_plane_intersection(plane::Plane3{T1}, ray::Ray{T2}, epsilon = 1.0e-6) where {T1 <: Real, T2 <: Real}
    # --- p ---   plane with normal (assumed normalized)
    #     ↓
    #     :  distance d along plane normal direction
    #   ↖ :
    #     r       ray with direction (assumed normalized)

    d = distance(plane, ray.origin) # signed distance
    cos_angle = dot(-plane.normal, ray.direction)

    if abs(cos_angle) > epsilon
        return ray.origin + d / cos_angle * ray.direction
    else
        return Point3f(NaN)
    end
end

################################################################################
### Ray casting (positions from ray-plot intersections)
################################################################################


"""
    ray_assisted_pick(fig/ax/scene[, xy = events(fig/ax/scene).mouseposition[], apply_transform = true])

This function performs a `pick` at the given pixel position `xy` and returns the
picked `plot`, `index` and data or input space `position::Point3f`. It is equivalent to
```
plot, idx = pick(fig/ax/scene, xy)
ray = Ray(parent_scene(plot), xy .- minimum(viewport(parent_scene(plot))[]))
position = position_on_plot(plot, idx, ray, apply_transform = true)
```
See [`position_on_plot`](@ref) for more information.
"""
function ray_assisted_pick(obj, xy = events(obj).mouseposition[]; apply_transform = true)
    plot, idx = pick(get_scene(obj), xy)
    isnothing(plot) && return (plot, idx, Point3f(NaN))
    scene = parent_scene(plot)
    ray = Ray(scene, xy .- minimum(viewport(scene)[]))
    pos = position_on_plot(plot, idx, ray, apply_transform = apply_transform)
    return (plot, idx, pos)
end


"""
    position_on_plot(plot, index[, ray::Ray; apply_transform = true])

This function calculates the data or input space position of a ray - plot
intersection with the result `plot, idx = pick(...)` and a ray cast from the
picked position. If there is no intersection `Point3f(NaN)` will be returned.

This should be called as
```
plot, idx = pick(ax, px_pos)
pos_in_ax = position_on_plot(plot, idx, Ray(ax, px_pos .- minimum(viewport(ax.scene)[])))
```
or more simply `plot, idx, pos_in_ax = ray_assisted_pick(ax, px_pos)`.

You can switch between getting a position in data space (after applying
transformations like `log`, `translate!()`, `rotate!()` and `scale!()`) and
input space (the raw position data of the plot) by adjusting `apply_transform`.

Note that `position_on_plot` is only implemented for primitive plot types, i.e.
the  possible return types of `pick`. Depending on the plot type the calculation
differs:
- `scatter` and `meshscatter` return the position of the picked marker/mesh
- `text` is excluded, always returning `Point3f(NaN)`
- `volume` calculates the ray - rect intersection for its bounding box
- `lines` and `linesegments` return the closest point on the line to the ray
- `mesh` and `surface` check for ray-triangle intersections for every triangle containing the picked vertex
- `image` and `heatmap` check for ray-rect intersection
"""
function position_on_plot(plot::AbstractPlot, idx::Integer; apply_transform = true)
    return position_on_plot(
        plot, idx, ray_at_cursor(parent_scene(plot));
        apply_transform = apply_transform
    )
end

function position_on_plot(plot::Union{Scatter, MeshScatter}, idx, ray::Ray; apply_transform = true)
    if apply_transform
        return _project(plot.model_f32c[], plot.positions_transformed_f32c[][idx])
    else
        return to_ndim(Point3d, plot.positions[][idx], 0)
    end
end

function position_on_plot(plot::Union{Lines, LineSegments}, idx, ray::Ray; apply_transform = true)
    if idx == 1
        idx = 2
    end
    p0, p1 = apply_transform_and_model(plot, plot[1][][(idx - 1):idx])

    pos = closest_point_on_line(f32_convert(plot, p0), f32_convert(plot, p1), ray)

    if apply_transform
        return inv_f32_convert(plot, Point3d(pos))
    else
        p4d = inv(plot.model[]) * to_ndim(Point4d, inv_f32_convert(plot, Point3d(pos)), 1)
        p3d = p4d[Vec(1, 2, 3)] / p4d[4]
        itf = inverse_transform(transform_func(plot))
        out = Makie.apply_transform(itf, p3d)
        return out
    end
end

function position_on_plot(plot::Union{Heatmap, Image}, idx, ray::Ray; apply_transform = true)
    # Heatmap and Image are always a Rect2f. The transform function is currently
    # not allowed to change this, so applying it should be fine. Applying the
    # model matrix may add a z component to the Rect2f, which we can't represent.
    # So we instead inverse-transform the ray
    p0, p1 = map(Point2d.(extrema(plot.x[]), extrema(plot.y[]))) do p
        return Makie.apply_transform(transform_func(plot), p)
    end
    ray = transform(inv(plot.model[]), inv_f32_convert(plot, ray))
    pos = ray_rect_intersection(Rect2(p0, p1 - p0), ray)

    if apply_transform
        p4d = plot.model[] * to_ndim(Point4d, to_ndim(Point3d, pos, 0), 1)
        return p4d[Vec(1, 2, 3)] / p4d[4]
    else
        pos = Makie.apply_transform(inverse_transform(transform_func(plot)), pos)
        return to_ndim(Point3d, pos, 0)
    end
end

function position_on_plot(plot::Mesh, idx, ray::Ray; apply_transform = true)
    positions = decompose(Point3d, plot.mesh[])
    ray = transform(inv(plot.model[]), inv_f32_convert(plot, ray))
    tf = transform_func(plot)

    for f in faces(plot.mesh[])
        if idx in f
            p1, p2, p3 = positions[f]
            p1 = Makie.apply_transform(tf, p1)
            p2 = Makie.apply_transform(tf, p2)
            p3 = Makie.apply_transform(tf, p3)
            pos = ray_triangle_intersection(p1, p2, p3, ray)
            if !isnan(pos)
                if apply_transform
                    p4d = plot.model[] * to_ndim(Point4d, pos, 1)
                    return Point3d(p4d) / p4d[4]
                else
                    return Makie.apply_transform(inverse_transform(tf), pos)
                end
            end
        end
    end

    @debug "Did not find intersection for index = $idx when casting a ray on mesh."

    return Point3d(NaN)
end

# Handling indexing into different surface input types
surface_x(xs::ClosedInterval, i, j, N) = minimum(xs) + (maximum(xs) - minimum(xs)) * (i - 1) / (N - 1)
surface_x(xs, i, j, N) = xs[i]
surface_x(xs::AbstractMatrix, i, j, N) = xs[i, j]

surface_y(ys::ClosedInterval, i, j, N) = minimum(ys) + (maximum(ys) - minimum(ys)) * (j - 1) / (N - 1)
surface_y(ys, i, j, N) = ys[j]
surface_y(ys::AbstractMatrix, i, j, N) = ys[i, j]

function surface_pos(xs, ys, zs, i, j)
    N, M = size(zs)
    return Point3d(surface_x(xs, i, j, N), surface_y(ys, i, j, M), zs[i, j])
end

function position_on_plot(plot::Surface, idx, ray::Ray; apply_transform = true)
    xs = plot[1][]
    ys = plot[2][]
    zs = plot[3][]
    w, h = size(zs)
    _i = mod1(idx, w); _j = div(idx - 1, w)

    ray = transform(inv(plot.model[]), inv_f32_convert(plot, ray))
    tf = transform_func(plot)

    # This isn't the most accurate so we include some neighboring faces
    pos = Point3f(NaN)
    for i in (_i - 1):(_i + 1), j in (_j - 1):(_j + 1)
        (1 <= i <= w) && (1 <= j < h) || continue

        if i - 1 > 0
            # transforms only apply to x and y coordinates of surfaces
            A = surface_pos(xs, ys, zs, i, j)
            B = surface_pos(xs, ys, zs, i - 1, j)
            C = surface_pos(xs, ys, zs, i, j + 1)
            A, B, C = map((A, B, C)) do p
                xy = Makie.apply_transform(tf, Point2d(p))
                Point3d(xy[1], xy[2], p[3])
            end
            pos = ray_triangle_intersection(A, B, C, ray)
        end

        if i + 1 <= w && isnan(pos)
            A = surface_pos(xs, ys, zs, i, j)
            B = surface_pos(xs, ys, zs, i, j + 1)
            C = surface_pos(xs, ys, zs, i + 1, j + 1)
            A, B, C = map((A, B, C)) do p
                xy = Makie.apply_transform(tf, Point2d(p))
                Point3d(xy[1], xy[2], p[3])
            end
            pos = ray_triangle_intersection(A, B, C, ray)
        end

        isnan(pos) || break
    end

    if apply_transform
        p4d = plot.model[] * to_ndim(Point4d, pos, 1)
        return p4d[Vec(1, 2, 3)] / p4d[4]
    else
        xy = Makie.apply_transform(inverse_transform(tf), Point2d(pos))
        return Point3d(xy[1], xy[2], pos[3])
    end
end

function position_on_plot(plot::Volume, idx, ray::Ray; apply_transform = true)
    min, max = Point3d.(extrema(plot.x[]), extrema(plot.y[]), extrema(plot.z[]))
    tf = transform_func(plot)

    if tf === nothing

        ray = transform(inv(plot.model[]), ray)
        pos = ray_rect_intersection(Rect3(min, max .- min), ray)
        if apply_transform
            return to_ndim(Point3d, apply_model(transformationmatrix(plot), pos), NaN)
        else
            return pos
        end

    else # Note: volume doesn't actually support transform_func but this should work anyway

        # TODO: After GeometryBasics refactor this can just use triangle_mesh(Rect3d(min, max - min))
        w = max - min
        ps = Point3d[min + (x, y, z) .* w for x in (0, 1) for y in (0, 1) for z in (0, 1)]
        fs = decompose(
            GLTriangleFace, QuadFace{Int}[
                (1, 2, 4, 3), (7, 8, 6, 5), (5, 6, 2, 1),
                (3, 4, 8, 7), (1, 3, 7, 5), (6, 8, 4, 2),
            ]
        )

        if apply_transform
            ps = apply_transform_and_model(plot, ps)
        else
            ps = Makie.apply_transform(tf, ps)
            ray = transform(inv(plot.model[]), ray)
        end

        for f in fs
            p1, p2, p3 = ps[f]
            pos = ray_triangle_intersection(p1, p2, p3, ray)
            if !isnan(pos) # hit
                n = GeometryBasics.orthogonal_vector(p1, p2, p3)
                if dot(n, ray.direction) < 0.0 # front facing
                    if apply_transform # already did
                        return pos
                    else # undo transform_func
                        return Makie.apply_transform(inverse_transform(tf), pos)
                    end
                end
            end
        end

        return Point3d(NaN)
    end
end

position_on_plot(plot::Text, args...; kwargs...) = Point3d(NaN)
position_on_plot(plot::Nothing, args...; kwargs...) = Point3d(NaN)
