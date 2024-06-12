
# For clipping Planes
# TODO: Consider moving this to GeometryBasics?
struct Plane{N, T}
    point::Point{N, T}
    normal::Vec{N, T}
end

const Plane2{T} = Plane{2, T}
const Plane3{T} = Plane{3, T}
const Plane2f = Plane{2, Float32}
const Plane3f = Plane{3, Float32}
const Plane2d = Plane{2, Float64}
const Plane3d = Plane{3, Float64}

function distance(plane::Plane{N}, point::VecTypes{N}) where N
    return sqrt(dot(plane.point - point, plane.normal))
end

# Compressed format for shaders
# point = dist * normal for valid normals
function gl_plane_format(plane::Plane3)
    dist = dot(plane.point, plane.normal)
    return to_ndim(Vec4f, plane.normal, dist)
end

function planes(rect::Rect3f)
    mini = minimum(rect)
    maxi = maximum(rect)
    return [
        Plane3f(mini, Vec3f(1, 0, 0)),
        Plane3f(mini, Vec3f(0, 1, 0)),
        Plane3f(mini, Vec3f(0, 0, 1)),
        Plane3f(maxi, Vec3f(-1, 0, 0)),
        Plane3f(maxi, Vec3f(0, -1, 0)),
        Plane3f(maxi, Vec3f(0, 0, -1))
    ]
end