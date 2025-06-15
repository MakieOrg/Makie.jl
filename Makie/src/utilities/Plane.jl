# For clipping Planes
struct Plane{N, T}
    normal::Vec{N, T}
    distance::T

    function Plane{N, T}(normal::Vec{N, T}, distance::T) where {N, T <: Real}
        # Functions using Plane assume `normal` to be normalized.
        # `normalize()` turns 0 vectors into NaN vectors which we don't want,
        # so we explicitly handle normalization here
        n = norm(normal)
        ϵ = 100 * max(eps.(normal)...)
        normalized = ifelse(n > ϵ, normal / n, Vec{N, T}(0))
        return new{N, T}(normalized, distance)
    end
end

"""
    Plane(point::Point, normal::Vec)
    Plane(normal::Vec, distance::Real)

Creates a Plane with the given `normal` containing the given `point`. The
internal representation uses a `distance = dot(point, normal)` which can also be
constructed directly.
"""
function Plane(point::Point{N, T1}, normal::Vec{N, T2}) where {N, T1, T2}
    return Plane{N, promote_type(T1, T2)}(point, normal)
end
function Plane{N}(point::Point{N, T1}, normal::Vec{N, T2}) where {N, T1, T2}
    return Plane{N, promote_type(T1, T2)}(point, normal)
end
function Plane{N, T}(point::Point{N}, normal::Vec{N}) where {N, T}
    normal = normalize(normal)
    return Plane{N, T}(normal, dot(point, normal))
end

function Plane(normal::VecTypes{N, T}, distance::Real) where {N, T <: Real}
    return Plane{N, T}(normal, T(distance))
end
function Plane{N}(normal::VecTypes{N, T}, distance::Real) where {N, T <: Real}
    return Plane{N, T}(normal, T(distance))
end
function Plane{N, T}(normal::VecTypes{N, T}, distance::Real) where {N, T <: Real}
    return Plane{N, T}(Vec{N, T}(normal), T(distance))
end

function Plane{N, T}(plane::Plane) where {N, T <: Real}
    return Plane{N, T}(to_ndim(Vec{N, T}, plane.normal, 0), T(plane.distance))
end

const Plane2{T} = Plane{2, T}
const Plane3{T} = Plane{3, T}
const Plane2f = Plane{2, Float32}
const Plane3f = Plane{3, Float32}
const Plane2d = Plane{2, Float64}
const Plane3d = Plane{3, Float64}

"""
    distance(plane, point)

Calculates the closest distance of a point from a plane.
"""
function distance(plane::Plane{N, T}, point::VecTypes) where {N, T}
    return dot(to_ndim(Point{N, T}, point, 0), plane.normal) - plane.distance
end

"""
    min_clip_distance(planes::Vector{<: Plane}, point)

Returns the smallest absolute distance between the point each clip plane. If
the point is clipped by any plane, only negative distances are considered.
"""
function min_clip_distance(planes::Vector{<:Plane}, point::VecTypes)
    min_dist = Inf
    for plane in planes
        d = distance(plane, point)
        if ((min_dist >= 0) && (d < min_dist)) || ((min_dist < 0) && (d < 0) && (d > min_dist))
            min_dist = d
        end
    end
    return min_dist
end

gl_plane_format(plane::Plane3) = to_ndim(Vec4f, plane.normal, plane.distance)

"""
    planes(rect::Rect3)

Converts a 3D rect into a set of planes. Using these as clip planes will remove
everything outside the rect.
"""
function planes(rect::Rect3)
    mini = minimum(rect)
    maxi = maximum(rect)
    return [
        Plane3f(Vec3f(1, 0, 0), mini[1]),
        Plane3f(Vec3f(0, 1, 0), mini[2]),
        Plane3f(Vec3f(0, 0, 1), mini[3]),
        Plane3f(Vec3f(-1, 0, 0), -maxi[1]),
        Plane3f(Vec3f(0, -1, 0), -maxi[2]),
        Plane3f(Vec3f(0, 0, -1), -maxi[3]),
    ]
end
function planes(rect::Rect2)
    mini = minimum(rect)
    maxi = maximum(rect)
    return [
        Plane3f(Vec3f(1, 0, 0), mini[1]),
        Plane3f(Vec3f(0, 1, 0), mini[2]),
        Plane3f(Vec3f(-1, 0, 0), -maxi[1]),
        Plane3f(Vec3f(0, -1, 0), -maxi[2]),
    ]
end

"""
    is_clipped(plane, point)

Returns true if the given plane or vector of planes clips the given point.
"""
function is_clipped(plane::Plane3, p::VecTypes)
    return dot(plane.normal, to_ndim(Point3f, p, 0)) < plane.distance
end
function is_clipped(planes::Vector{<:Plane3}, p::VecTypes)
    return any(plane -> is_clipped(plane, p), planes)
end

"""
    is_clipped(plane, point)

Returns true if the given plane or vector of planes do not clip the given point.
"""
function is_visible(plane::Plane3, p::VecTypes)
    return dot(plane.normal, to_ndim(Point3f, p, 0)) >= plane.distance
end
function is_visible(planes::Vector{<:Plane3}, p::VecTypes)
    # TODO: this might be worth optimizing for CairoMakie
    return all(plane -> is_visible(plane, p), planes)
end

"""
    apply_clipping_planes(planes, bbox)

Cuts down a axis aligned bounding box to fit into the given clip planes.
"""
function apply_clipping_planes(planes::Vector{<:Plane3}, rect::Rect3{T}) where {T}
    bb = rect

    edges = [
        (1, 2), (1, 3), (1, 5),
        (2, 4), (2, 6),
        (3, 4), (3, 7),
        (5, 6), (5, 7),
        (4, 8), (6, 8), (7, 8),
    ]

    temp = sizehint!(Point3{T}[], length(edges))

    for plane in planes
        ps = corners(bb)
        distances = distance.((plane,), ps)

        if (all(distances .<= 0.0))
            return Rect3{T}()
        end

        empty!(temp)

        # find points on the clip plane
        for (i, j) in edges
            if distances[i] * distances[j] <= 0.0 # sign change
                # d(t) = m t + b, find t where distance d(t) = 0
                t = - distances[i] / (distances[j] - distances[i])
                p = (ps[j] - ps[i]) * t + ps[i]
                push!(temp, p)
            end
        end

        # unclipped points in bbox
        for i in 1:8
            if distances[i] > 0.0
                push!(temp, ps[i])
            end
        end

        # generate a axis aligned bbox >= projected points
        bb = Rect3{T}(temp)
    end

    return bb
end

function apply_transform(transform::Mat4, plane::Plane3{T}) where {T}
    origin = Point3{T}(transform * to_ndim(Point4{T}, plane.distance * plane.normal, 1))
    target = Point3{T}(transform * to_ndim(Point4{T}, (plane.distance + 1) * plane.normal, 1))
    normal = normalize(target - origin)
    return Plane3{T}(normal, dot(origin, normal))
end

function to_model_space(model::Mat4, planes::Vector{<:Plane3})
    imodel = inv(model)
    return apply_transform.((imodel,), planes)
end

function unclipped_indices(clip_planes::Vector{<:Plane3}, positions::AbstractArray, space::Symbol)
    if Makie.is_data_space(space) && !isempty(clip_planes)
        indices = sizehint!(UInt32[], length(positions))
        for i in eachindex(positions)
            if is_visible(clip_planes, to_ndim(Point3f, positions[i], 0))
                push!(indices, i)
            end
        end
        return sizehint!(indices, length(indices))
    else
        return UInt32[eachindex(positions)...]
    end
end

"""
    perpendicular_vector(vec::Vec3)

Generates a vector perpendicular to the given vector.
"""
function perpendicular_vector(v::Vec3)
    # https://math.stackexchange.com/a/4112622
    return Vec3(
        copysign(v[3], v[1]),
        copysign(v[3], v[2]),
        -copysign(abs(v[1]) + abs(v[2]), v[3]),
    )
end

function closest_point_on_plane(plane::Plane3, point::VecTypes)
    p = to_ndim(Point3f, point, 0)
    return p - plane.normal * distance(plane, p)
end

"""
    to_mesh(plane[; origin = Point3f(0), scale = 1])

Generates a mesh corresponding to a finite section of the `plane` centered at
`origin` and extending by `scale` in each direction.
"""
function to_mesh(plane::Plane3{T}; origin = Point3f(0), scale = 1) where {T}
    _scale = scale isa VecTypes ? scale : Vec2f(scale)
    _origin = origin - plane.normal * distance(plane, origin)
    v1 = _scale[1] * normalize(perpendicular_vector(plane.normal))
    v2 = _scale[2] * normalize(cross(v1, plane.normal))
    ps = Point3f[_origin - v1 - v2, _origin - v1 + v2, _origin + v1 - v2, _origin + v1 + v2]
    ns = [plane.normal for _ in 1:4]
    fs = GLTriangleFace[(1, 2, 3), (2, 3, 4)]
    return GeometryBasics.Mesh(ps, fs; normal = ns)
end

function to_clip_space(cam::Camera, planes::Vector{<:Plane3})
    return to_clip_space(cam.projectionview[], planes)
end

function to_clip_space(pv::Mat4, planes::Vector{T}) where {T <: Plane3}
    ipv = inv(pv)
    return T[to_clip_space(pv, ipv, plane) for plane in planes]
end

to_clip_space(cam::Camera, plane::Plane3) = to_clip_space(cam.projectionview[], plane)
to_clip_space(pv::Mat4, plane::Plane3) = to_clip_space(pv, inv(pv), plane)

function to_clip_space(pv::Mat4, ipv::Mat4, plane::Plane3)
    # clip plane is always or never pass
    if norm(plane.normal) < 0.01
        return plane
    end

    # corners of what's always clipped
    clip_corners = [Point3f(x, y, z) for x in (-1, 1), y in (-1, 1), z in (0, 1)]
    world_corners = map(clip_corners) do p
        p4d = ipv * to_ndim(Point4f, p, 1)
        Point3f(p4d) / p4d[4]
    end

    distances = distance.((plane,), world_corners)
    w = maximum(distances) - minimum(distances)
    w = ifelse(abs(w) < 1000.0 * eps(w), 1.0f0, w)

    # clip plane transformation may fail if plane is too close to bbox corner/line/plane
    # so we handle this explicitly here:
    if all(distances .>= -0.01w) # bbox is not clipped
        return Plane(Vec3f(0), -1.0f9) # always pass
    elseif all(distances .< 0.01w) # bbox is clipped
        return Plane(Vec3f(0), 1.0f9) # never pass

    else
        # edges of the bbox cube
        edges = [
            (1, 2), (1, 3), (1, 5),
            (2, 4), (2, 6),
            (3, 4), (3, 7),
            (5, 6), (5, 7),
            (4, 8), (6, 8), (7, 8),
        ]

        # find points on the clip plane in clip space
        zero_points = Point3f[]
        dir = Vec3f(0)
        for (i, j) in edges
            if distances[i] * distances[j] <= 0.0 # sign change
                # d(t) = m t + b, find t where distance d(t) = 0
                t = - distances[i] / (distances[j] - distances[i])

                # interpolating in clip_space does not work
                p = pv * to_ndim(Point4f, (world_corners[j] - world_corners[i]) * t + world_corners[i], 1)
                push!(zero_points, p[Vec(1, 2, 3)] / p[4])

                # normal estimate used to find direction
                dir += ifelse(distances[i] < distances[j], +1, -1) * normalize(clip_corners[j] - clip_corners[i])
            end
        end
        origin = sum(zero_points) / length(zero_points)

        # with at least one point < or > 0.0 and each point having 3 connections
        # it should be impossible to get less than 3 points. Should...
        # @assert length(zero_points) > 2
        if length(zero_points) < 3
            return Plane(Vec3f(0), sum(distances) > 0.0 ? -1.0f9 : 1.0f9)
        end

        # Get plane normal vectors from zero points (using all points because why not)
        normals = Vec3f[]
        for i in 1:length(zero_points)
            for j in (i + 1):length(zero_points)
                v1 = zero_points[j] - zero_points[i]
                for k in (j + 1):length(zero_points)
                    v2 = zero_points[k] - zero_points[i]
                    n = normalize(cross(v1, v2))
                    n *= sign(dot(dir, n)) # correct direction (n can be ± the normal we want)
                    push!(normals, n)
                end
            end
        end
        normal = normalize(sum(normals))

        return Plane(origin, normal)
    end
end
