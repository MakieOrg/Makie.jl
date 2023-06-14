struct Ray
    origin::Point3f
    direction::Vec3f
end

"""
    ray_at_cursor(scenelike)

Returns a Ray into the scene starting at the current cursor position.
"""
ray_at_cursor(x) = ray_at_cursor(get_scene(x))
function ray_at_cursor(scene::Scene)
    return ray_at_cursor(scene, cameracontrols(scene))
end

function ray_at_cursor(scene::Scene, cam::Camera3D)
    lookat = cam.lookat[]
    eyepos = cam.eyeposition[]
    viewdir = lookat - eyepos

    u_z = normalize(viewdir)
    u_x = normalize(cross(u_z, cam.upvector[]))
    u_y = normalize(cross(u_x, u_z))
    
    px_width, px_height = widths(scene.px_area[])
    aspect = px_width / px_height
    rel_pos = 2 .* mouseposition_px(scene) ./ (px_width, px_height) .- 1

    if cam.attributes.projectiontype[] === Perspective
        dir = (rel_pos[1] * aspect * u_x + rel_pos[2] * u_y) * tand(0.5 * cam.fov[]) + u_z
        return Ray(cam.eyeposition[], normalize(dir))
    else
        # Orthographic has consistent direction, but not starting point
        origin = norm(viewdir) * (rel_pos[1] * aspect * u_x + rel_pos[2] * u_y)
        return Ray(origin, normalize(viewdir))
    end
end

function ray_at_cursor(scene::Scene, cam::Camera2D)
    rel_pos = mouseposition_px(scene) ./ widths(scene.px_area[])
    origin = minimum(cam.area[]) .+ rel_pos .* widths(cam.area[])
    return Ray(to_ndim(Point3f, origin, 10_000f0), Vec3f(0,0,-1))
end

function ray_at_cursor(scene::Scene, ::PixelCamera)
    return Ray(to_ndim(Point3f, mouseposition_px(scene), 10_000f0), Vec3f(0,0,-1))
end

function ray_at_cursor(scene::Scene, ::RelativeCamera)
    origin = mouseposition_px(scene) ./ widths(scene.px_area[])
    return Ray(to_ndim(Point3f, origin, 10_000f0), Vec3f(0,0,-1))
end

ray_at_cursor(scene::Scene, cam) = _ray_at_cursor(scene, cam)

# This method should always work 
function _ray_at_cursor(scene::Scene, cam = scene.camera_controls)
    inv_view_proj = inv(camera(scene).projectionview[])
    mpos = events(scene).mouseposition[]
    area = pixelarea(scene)[]

    # This figures out the camera view direction from the projectionview matrix
    # and computes a ray from a near and a far point.
    # Based on ComputeCameraRay from ImGuizmo
    mp = 2f0 .* (mpos .- minimum(area)) ./ widths(area) .- 1f0
    v = inv_view_proj * Vec4f(0, 0, -10, 1)
    reversed = v[3] < v[4]
    near = reversed ? 1f0 - 1e-6 : 0f0
    far = reversed ? 0f0 : 1f0 - 1e-6

    origin = inv_view_proj * Vec4f(mp[1], mp[2], near, 1f0)
    origin = origin[Vec(1, 2, 3)] ./ origin[4]

    p = inv_view_proj * Vec4f(mp[1], mp[2], far, 1f0)
    p = p[Vec(1, 2, 3)] ./ p[4]

    dir = normalize(p .- origin)

    return Ray(origin, dir)
end


function transform(M::Mat4f, ray::Ray)
    p4d = M * to_ndim(Point4f, ray.origin, 1f0)
    dir = normalize(M[Vec(1,2,3), Vec(1,2,3)] * ray.direction)
    return Ray(p4d[Vec(1,2,3)] / p4d[4], dir)
end


##############################################


# These work in 2D and 3D
function closest_point_on_line(A::VecTypes, B::VecTypes, ray::Ray)
    return closest_point_on_line(to_ndim(Point3f, A, 0), to_ndim(Point3f, B, 0), ray)
end
function closest_point_on_line(A::Point3f, B::Point3f, ray::Ray)
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


function ray_triangle_intersection(A::VecTypes{3}, B::VecTypes{3}, C::VecTypes{3}, ray::Ray, ϵ = 1e-6)
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
        return Point3f((A1 * A .+ A2 * B .+ A3 * C) / (A1 + A2 + A3))
    else
        return Point3f(NaN)
    end
end

function ray_rect_intersection(rect::Rect2f, ray::Ray)
    possible_hit = ray.origin - ray.origin[3] / ray.direction[3] * ray.direction
    min = minimum(rect); max = maximum(rect)
    if all(min <= possible_hit[Vec(1,2)] <= max)
        return possible_hit
    end
    return Point3f(NaN)
end


function ray_rect_intersection(rect::Rect3f, ray::Ray)
    mins = (minimum(rect) - ray.origin) ./ ray.direction
    maxs = (maximum(rect) - ray.origin) ./ ray.direction
    x, y, z = min.(mins, maxs)
    possible_hit = max(x, y, z)
    if possible_hit < minimum(max.(mins, maxs))
        return ray.origin + possible_hit * ray.direction
    end
    return Point3f(NaN)
end

### Surface positions
########################################

surface_x(xs::ClosedInterval, i, j, N) = minimum(xs) + (maximum(xs) - minimum(xs)) * (i-1) / (N-1)
surface_x(xs, i, j, N) = xs[i]
surface_x(xs::AbstractMatrix, i, j, N) = xs[i, j]

surface_y(ys::ClosedInterval, i, j, N) = minimum(ys) + (maximum(ys) - minimum(ys)) * (j-1) / (N-1)
surface_y(ys, i, j, N) = ys[j]
surface_y(ys::AbstractMatrix, i, j, N) = ys[i, j]

function surface_pos(xs, ys, zs, i, j)
    N, M = size(zs)
    return Point3f(surface_x(xs, i, j, N), surface_y(ys, i, j, M), zs[i, j])
end


#################################################


"""
    get_position(scene; kwargs...) = get_position(pick(scene)...; kwargs...)
    get_position(plot, index, apply_transform = true)

Given the result of `pick(...)` this function returns a relevant position 
for the given input. If `plot = nothing` (i.e pick did not find a plot)
the function will return `Point3f(NaN)`. If `apply_transform = true` the 
transform_func (e.g. `log`) and the model matrix (i.e. `translate!()`, 
`scale!()` and `rotate!()`) will be applied to the output.

For most plot types the returned position is interpolated to match up with the 
cursor position exactly. Exceptions:
- `scatter` and `meshscatter` return the position of the clicked marker/mesh
- `text` is excluded, always returning `Point3f(NaN)`
- `volume` returns a relevant position on its bounding box
"""
get_position(scene::Scene) = get_position(pick(scene)...)
function get_position(plot::AbstractPlot, idx; apply_transform = true)
    pos = to_ndim(Point3f, _get_position(plot, idx), 0f0)
    if apply_transform && !isnan(pos)
        return apply_transform_and_model(plot, pos)
    else
        return pos
    end
end

_get_position(plot::Union{Scatter, MeshScatter}, idx) = plot[1][][idx]

function get_position(plot::Union{Lines, LineSegments}, idx; apply_transform = true)
    p0, p1 = apply_transform_and_model(plot, plot[1][][idx-1:idx])

    pos = closest_point_on_line(p0, p1, ray_at_cursor(parent_scene(plot)))
    
    if apply_transform
        return pos
    else
        p4d = inv(plot.model[]) * to_ndim(Point4f, pos, 1f0)
        p3d = p4d[Vec(1, 2, 3)] / p4d[4]
        return Makie.apply_transform(inverse_transform(transform_func(plot)), p3d, get(plot, :space, :data))
    end
end

function get_position(plot::Union{Heatmap, Image}, idx; apply_transform = true)
    # Heatmap and Image are always a Rect2f. The transform function is currently 
    # not allowed to change this, so applying it should be fine. Applying the 
    # model matrix may add a z component to the Rect2f, which we can't represent.
    # So we instead inverse-transform the ray
    space = to_value(get(plot, :space, :data))
    p0, p1 = map(Point2f.(extrema(plot.x[]), extrema(plot.y[]))) do p
        return Makie.apply_transform(transform_func(plot), p, space)
    end
    ray = transform(inv(plot.model[]), ray_at_cursor(parent_scene(plot)))
    pos = ray_rect_intersection(Rect2f(p0, p1 - p0), ray)
    
    if apply_transform
        p4d = plot.model[] * to_ndim(Point4f, to_ndim(Point3f, pos, 0), 1)
        return p4d[Vec(1, 2, 3)] / p4d[4]
    else
        pos = Makie.apply_transform(inverse_transform(transform_func(plot)), pos, space)
        return to_ndim(Point3f, pos, 0)
    end
end

function get_position(plot::Mesh, idx; apply_transform = true)
    positions = coordinates(plot.mesh[])
    ray = transform(inv(plot.model[]), ray_at_cursor(parent_scene(plot)))
    tf = transform_func(plot)
    space = to_value(get(plot, :space, :data))

    for f in faces(plot.mesh[])
        if idx in f
            p1, p2, p3 = positions[f]
            p1, p2, p3 = Makie.apply_transform.(tf, (p1, p2, p3), space)
            pos = ray_triangle_intersection(p1, p2, p3, ray)
            if pos !== Point3f(NaN)
                if apply_transform
                    p4d = plot.model[] * to_ndim(Point3f, pos, 1)
                    return Point3f(p4d) / p4d[4]
                else
                    return Makie.apply_transform(inverse_transform(tf), pos, space)
                end
            end
        end
    end

    return Point3f(NaN)
end

function get_position(plot::Surface, idx; apply_transform = true)
    xs = plot[1][]
    ys = plot[2][]
    zs = plot[3][]
    w, h = size(zs)
    _i = mod1(idx, w); _j = div(idx-1, w)

    ray = transform(inv(plot.model[]), ray_at_cursor(parent_scene(plot)))
    tf = transform_func(plot)
    space = to_value(get(plot, :space, :data))
    
    # This isn't the most accurate so we include some neighboring faces
    pos = Point3f(NaN)
    for i in _i-1:_i+1, j in _j-1:_j+1
        (1 <= i <= w) && (1 <= j < h) || continue

        if i - 1 > 0
            # transforms only apply to x and y coordinates of surfaces
            A = surface_pos(xs, ys, zs, i,   j)
            B = surface_pos(xs, ys, zs, i-1, j)
            C = surface_pos(xs, ys, zs, i, j+1)
            A, B, C = map((A, B, C)) do p
                xy = Makie.apply_transform(tf, Point2f(p), space)
                Point3f(xy[1], xy[2], p[3])
            end
            pos = ray_triangle_intersection(A, B, C, ray)
        end

        if i + 1 <= w && isnan(pos)
            A = surface_pos(xs, ys, zs, i,   j)
            B = surface_pos(xs, ys, zs, i,   j+1)
            C = surface_pos(xs, ys, zs, i+1, j+1)
            A, B, C = map((A, B, C)) do p
                xy = Makie.apply_transform(tf, Point2f(p), space)
                Point3f(xy[1], xy[2], p[3])
            end
            pos = ray_triangle_intersection(A, B, C, ray)
        end

        isnan(pos) || break
    end

    if apply_transform
        p4d = plot.model[] * to_ndim(Point4f, pos, 1)
        return p4d[Vec(1, 2, 3)] / p4d[4]
    else
        xy = Makie.apply_transform(inverse_transform(tf), Point2f(pos), space)
        return Point3f(xy[1], xy[2], pos[3])
    end
end

function get_position(plot::Volume, idx; apply_transform = true)
    min, max = Point3f.(extrema(plot.x[]), extrema(plot.y[]), extrema(plot.z[]))
    ray = ray_at_cursor(parent_scene(plot))

    if apply_transform
        min = apply_transform_and_model(plot, min)
        max = apply_transform_and_model(plot, max)
        return ray_rect_intersection(Rect3f(min, max .- min), ray)
    else
        min = Makie.apply_transform(transform_func(plot), min, get(plot, :space, :data))
        max = Makie.apply_transform(transform_func(plot), max, get(plot, :space, :data))
        ray = transform(inv(plot.model[]), ray)
        pos = ray_rect_intersection(Rect3f(min, max .- min), ray)
        return Makie.apply_transform(inverse_transform(plot), pos, get(plot, :space, :data))
    end
end

_get_position(plot::Text, idx) = Point3f(NaN)
_get_position(plot::Nothing, idx) = Point3f(NaN)