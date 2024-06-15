
# For clipping Planes
# TODO: Consider moving this to GeometryBasics?
struct Plane{N, T}
    normal::Vec{N, T}
    distance::T
end

Plane(point::Point{N}, normal::Vec{N}) where N = Plane(normal, dot(point, normal))

const Plane2{T} = Plane{2, T}
const Plane3{T} = Plane{3, T}
const Plane2f = Plane{2, Float32}
const Plane3f = Plane{3, Float32}
const Plane2d = Plane{2, Float64}
const Plane3d = Plane{3, Float64}

function distance(plane::Plane{N}, point::VecTypes{N}) where N
    return dot(point, plane.normal) - plane.distance
end

gl_plane_format(plane::Plane3) = to_ndim(Vec4f, plane.normal, plane.distance)

function planes(rect::Rect3f)
    mini = minimum(rect)
    maxi = maximum(rect)
    return [
        Plane3f(Vec3f( 1,  0,  0),  mini[1]),
        Plane3f(Vec3f( 0,  1,  0),  mini[2]),
        Plane3f(Vec3f( 0,  0,  1),  mini[3]),
        Plane3f(Vec3f(-1,  0,  0), -maxi[1]),
        Plane3f(Vec3f( 0, -1,  0), -maxi[2]),
        Plane3f(Vec3f( 0,  0, -1), -maxi[3])
    ]
end

function is_clipped(plane::Plane3, p::VecTypes)
    return dot(plane.normal, to_ndim(Point3f, p, 0)) < plane.distance
end
function is_clipped(planes::Vector{<: Plane3}, p::VecTypes)
    return any(plane -> is_clipped(plane, p), planes)
end
function is_visible(plane::Plane3, p::VecTypes)
    return dot(plane.normal, to_ndim(Point3f, p, 0)) >= plane.distance
end
function is_visible(planes::Vector{<: Plane3}, p::VecTypes)
    # TODO: this might be worth optimizing for CairoMakie
    return all(plane -> is_visible(plane, p), planes)
end

function apply_clipping_planes(planes::Vector{<: Plane3}, rect::Rect3{T}) where T
    ps = corners(rect)
    temp = copy(ps)
    mini = minimum(rect)
    maxi = maximum(rect)

    for plane in planes
        # project corner points so that none get clipped
        copyto!(temp, ps)
        for i in eachindex(temp)
            d = distance(plane, temp[i])
            temp[i] -= min(0.0, d) * plane.normal
        end

        # generate a axis aligned bbox >= projected points
        bb = Rect3{T}(temp)

        # reductively combine with other bboxes
        mini = max.(minimum(bb), mini)
        maxi = min.(maximum(bb), maxi)
    end

    widths = maxi .- mini
    dim_valid = widths .> -100.0 * eps(widths[1])

    return Rect3{T}(ifelse.(dim_valid, mini, NaN), ifelse.(dim_valid, widths, NaN))
end

function apply_transform(transform::Mat4, plane::Plane3{T}) where T
    origin = Point3{T}(transform * to_ndim(Point4{T}, plane.distance * plane.normal, 1))
    target = Point3{T}(transform * to_ndim(Point4{T}, (plane.distance + 1) * plane.normal, 1))
    normal = normalize(target - origin)
    return Plane3{T}(normal, dot(origin, normal))
end

function to_model_space(model::Mat4, planes::Vector{<: Plane3})
    imodel = inv(model)
    return apply_transform.((imodel,), planes)
end

function unclipped_indices(clip_planes::Vector{<: Plane3}, positions::AbstractArray, space::Symbol)
    if space == :data && !isempty(clip_planes)
        indices = sizehint!(UInt32[], length(positions))
        for i in eachindex(positions)
            if is_visible(clip_planes, to_ndim(Point3f, positions[i], 0))
                push!(indices, i)
            end
        end
        return sizehint!(indices, length(indices))
    else
        return eachindex(positions)
    end
end

function perpendicular_vector(v::Vec3)
    # https://math.stackexchange.com/a/4112622
    return Vec3(
        copysign(v[3], v[1]),
        copysign(v[3], v[2]),
        -copysign(abs(v[1]) + abs(v[2]), v[3]),
    )
end

function to_mesh(plane::Plane3{T}; origin = plane.distance * plane.normal, size = 1) where T
    scale = size isa VecTypes ? size : Vec2f(size)
    v1 = scale[1] * normalize(perpendicular_vector(plane.normal))
    v2 = scale[2] * normalize(cross(v1, plane.normal))
    ps = Point3f[origin - v1 - v2, origin - v1 + v2, origin + v1 - v2, origin + v1 + v2]
    ns = [plane.normal for _ in 1:4]
    fs = GLTriangleFace[(1,2,3), (2, 3, 4)]
    return GeometryBasics.Mesh(GeometryBasics.meta(ps; normals=ns), fs)
end