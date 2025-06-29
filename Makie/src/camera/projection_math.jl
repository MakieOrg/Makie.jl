function scalematrix(s::Vec{3, T}) where {T}
    T0, T1 = zero(T), one(T)
    return Mat{4}(
        s[1], T0, T0, T0,
        T0, s[2], T0, T0,
        T0, T0, s[3], T0,
        T0, T0, T0, T1,
    )
end

translationmatrix_x(x::T) where {T} = translationmatrix(Vec{3, T}(x, 0, 0))
translationmatrix_y(y::T) where {T} = translationmatrix(Vec{3, T}(0, y, 0))
translationmatrix_z(z::T) where {T} = translationmatrix(Vec{3, T}(0, 0, z))

function translationmatrix(t::Vec{3, T}) where {T}
    T0, T1 = zero(T), one(T)
    return Mat{4}(
        T1, T0, T0, T0,
        T0, T1, T0, T0,
        T0, T0, T1, T0,
        t[1], t[2], t[3], T1,
    )
end

rotate(angle, axis::Vec{3}) = rotationmatrix4(qrotation(convert(Array, axis), angle))
rotate(::Type{T}, angle::Number, axis::Vec{3}) where {T} = rotate(T(angle), convert(Vec{3, T}, axis))

function rotationmatrix_x(angle::Number)
    T0, T1 = (0, 1)
    return Mat{4}(
        T1, T0, T0, T0,
        T0, cos(angle), sin(angle), T0,
        T0, -sin(angle), cos(angle), T0,
        T0, T0, T0, T1
    )
end
function rotationmatrix_y(angle::Number)
    T0, T1 = (0, 1)
    return Mat{4}(
        cos(angle), T0, -sin(angle), T0,
        T0, T1, T0, T0,
        sin(angle), T0, cos(angle), T0,
        T0, T0, T0, T1
    )
end
function rotationmatrix_z(angle::Number)
    T0, T1 = (0, 1)
    return Mat{4}(
        cos(angle), sin(angle), T0, T0,
        -sin(angle), cos(angle), T0, T0,
        T0, T0, T1, T0,
        T0, T0, T0, T1
    )
end

"""
    Create view frustum

    Parameters
    ----------
        left : float
         Left coordinate of the field of view.
        right : float
         Left coordinate of the field of view.
        bottom : float
         Bottom coordinate of the field of view.
        top : float
         Top coordinate of the field of view.
        znear : float
         Near coordinate of the field of view.
        zfar : float
         Far coordinate of the field of view.

    Returns
    -------
        M : array
         View frustum matrix (4x4).
"""
function frustum(left::T, right::T, bottom::T, top::T, znear::T, zfar::T) where {T}
    (right == left || bottom == top || znear == zfar) && return Mat{4, 4, T}(I)
    T0, T1, T2 = zero(T), one(T), T(2)
    return Mat{4}(
        T2 * znear / (right - left), T0, T0, T0,
        T0, T2 * znear / (top - bottom), T0, T0,
        (right + left) / (right - left), (top + bottom) / (top - bottom), -(zfar + znear) / (zfar - znear), -T1,
        T0, T0, (-T2 * znear * zfar) / (zfar - znear), T0
    )
end

"""
`proj = perspectiveprojection([T], fovy, aspect, znear, zfar)` defines
a projection matrix with a given angular field-of-view `fovy` along
the y-axis (measured in degrees), the specified `aspect` ratio, and
near and far clipping planes `znear`, `zfar`. Optionally specify the
element type `T` of the matrix.
"""
function perspectiveprojection(fovy::T, aspect::T, znear::T, zfar::T) where {T}
    (znear == zfar) && error("znear ($znear) must be different from tfar ($zfar)")
    h = T(tan(fovy / 360.0 * pi) * znear)
    w = T(h * aspect)
    return frustum(-w, w, -h, h, znear, zfar)
end

function perspectiveprojection(
        ::Type{T}, fovy::Number, aspect::Number, znear::Number, zfar::Number
    ) where {T}
    return perspectiveprojection(T(fovy), T(aspect), T(znear), T(zfar))
end
"""
`proj = perspectiveprojection([T], rect, fov, near, far)` defines the
projection ratio in terms of the rectangular view size `rect` rather
than the aspect ratio.
"""
function perspectiveprojection(wh::Rect2, fov::T, near::T, far::T) where {T}
    return perspectiveprojection(fov, T(wh.w / wh.h), near, far)
end

function perspectiveprojection(
        ::Type{T}, wh::Rect2, fov::Number, near::Number, far::Number
    ) where {T}
    return perspectiveprojection(T(fov), T(wh.w / wh.h), T(near), T(far))
end

"""
`view = lookat(eyeposition, lookat, up)` creates a view matrix with
the eye located at `eyeposition` and looking at position `lookat`,
with the top of the window corresponding to the direction `up`. Only
the component of `up` that is perpendicular to the vector pointing
from `eyeposition` to `lookat` will be used.  All inputs must be
supplied as 3-vectors.
"""
function lookat(eyePos::Vec{3, T}, lookAt::Vec{3, T}, up::Vec{3, T}) where {T}
    return lookat_basis(eyePos, lookAt, up) * translationmatrix(-eyePos)
end
function lookat_basis(eyePos::Vec{3, T}, lookAt::Vec{3, T}, up::Vec{3, T}) where {T}
    zaxis = normalize(eyePos - lookAt)
    xaxis = normalize(cross(up, zaxis))
    yaxis = normalize(cross(zaxis, xaxis))
    T0, T1 = zero(T), one(T)
    return Mat{4}(
        xaxis[1], yaxis[1], zaxis[1], T0,
        xaxis[2], yaxis[2], zaxis[2], T0,
        xaxis[3], yaxis[3], zaxis[3], T0,
        T0, T0, T0, T1
    )
end

function lookat(::Type{T}, eyePos::Vec{3}, lookAt::Vec{3}, up::Vec{3}) where {T}
    return lookat(Vec{3, T}(eyePos), Vec{3, T}(lookAt), Vec{3, T}(up))
end

function orthographicprojection(wh::Rect2, near::T, far::T) where {T}
    w, h = widths(wh)
    return orthographicprojection(zero(T), T(w), zero(T), T(h), near, far)
end

function orthographicprojection(
        ::Type{T}, wh::Rect2, near::Number, far::Number
    ) where {T}
    return orthographicprojection(wh, T(near), T(far))
end

function orthographicprojection(
        left::T, right::T,
        bottom::T, top::T,
        znear::T, zfar::T
    ) where {T}
    (right == left || bottom == top || znear == zfar) && return Mat{4, 4, T}(I)
    T0, T1, T2 = zero(T), one(T), T(2)
    return Mat{4}(
        T2 / (right - left), T0, T0, T0,
        T0, T2 / (top - bottom), T0, T0,
        T0, T0, -T2 / (zfar - znear), T0,
        -(right + left) / (right - left), -(top + bottom) / (top - bottom), -(zfar + znear) / (zfar - znear), T1
    )
end

function orthographicprojection(
        ::Type{T},
        left::Number, right::Number,
        bottom::Number, top::Number,
        znear::Number, zfar::Number
    ) where {T}
    return orthographicprojection(
        T(left), T(right),
        T(bottom), T(top),
        T(znear), T(zfar)
    )
end

mutable struct Pivot{T}
    origin::Vec{3, T}
    xaxis::Vec{3, T}
    yaxis::Vec{3, T}
    zaxis::Vec{3, T}
    rotation::Quaternion
    translation::Vec{3, T}
    scale::Vec{3, T}
end

GeometryBasics.origin(p::Pivot) = p.origin

rotationmatrix4(q::Quaternion{T}) where {T} = Mat4{T}(q)

function transformationmatrix(p::Pivot)
    return translationmatrix(p.origin) * #go to origin
        rotationmatrix4(p.rotation) * #apply rotation
        translationmatrix(-p.origin) * # go back to origin
        translationmatrix(p.translation) #apply translation
end

function transformationmatrix(translation, scale)
    T = eltype(translation)
    T0, T1 = zero(T), one(T)
    return Mat{4}(
        scale[1], T0, T0, T0,
        T0, scale[2], T0, T0,
        T0, T0, scale[3], T0,
        translation[1], translation[2], translation[3], T1
    )
end

function transformationmatrix(translation, scale, rotation::Quaternion{T}) where {T}
    trans_scale = transformationmatrix(translation, scale)
    rotation = Mat4{T}(rotation)
    return trans_scale * rotation
end

function is_translation_scale_matrix(mat::Mat4{T}) where {T}
    # Checks that matrix has form: (* being any number)
    #   *  0  0  *
    #   0  *  0  *
    #   0  0  *  *
    #   0  0  0  1
    T0 = zero(T)
    return (mat[2, 1] == T0) && (mat[3, 1] == T0) && (mat[4, 1] == T0) &&
        (mat[1, 2] == T0) && (mat[3, 2] == T0) && (mat[4, 2] == T0) &&
        (mat[1, 3] == T0) && (mat[2, 3] == T0) && (mat[4, 3] == T0) &&
        (mat[4, 4] == one(T))
end

"""
    decompose_translation_scale_rotation_matrix(transform::Mat4)

Decomposes a transformation matrix into a translation vector, scale vector and
rotation Quaternion. Note that this is only valid for a transformation matrix
created with matching order, i.e.
`transform = translation_matrix * scale_matrix * rotation_matrix`. The model
matrix created by `Transformation` is one such matrix.
"""
function decompose_translation_scale_rotation_matrix(model::Mat4{T}) where {T}
    trans = Vec3{T}(model[Vec(1, 2, 3), 4])
    m33 = model[Vec(1, 2, 3), Vec(1, 2, 3)]
    if m33[1, 2] ≈ m33[1, 3] ≈ m33[2, 3] ≈ 0
        scale = Vec3{T}(diag(m33))
        rot = Quaternion{T}(0, 0, 0, 1)
        return trans, scale, rot
    else
        # m33 = Scale * Rotation; Scale * Rotation * Rotation' * Scale' = Scale^2
        scale = Vec3{T}(sqrt.(diag(m33 * m33')))
        R = Diagonal(1 ./ scale) * m33

        # inverse of Mat4(q::Quaternion)
        xz = 0.5 * (R[1, 3] + R[3, 1])
        sy = 0.5 * (R[1, 3] - R[3, 1])
        yz = 0.5 * (R[2, 3] + R[3, 2])
        sx = 0.5 * (R[3, 2] - R[2, 3])
        xy = 0.5 * (R[1, 2] + R[2, 1])
        sz = 0.5 * (R[2, 1] - R[1, 2])

        m = max(abs(xy), abs(xz), abs(yz))
        if abs(xy) == m
            q4 = sqrt(0.5 * sx * sy / xy)
        elseif abs(xz) == m
            q4 = sqrt(0.5 * sx * sz / xz)
        else
            q4 = sqrt(0.5 * sy * sz / yz)
        end

        q1 = 0.5 * sx / q4
        q2 = 0.5 * sy / q4
        q3 = 0.5 * sz / q4
        rot = Quaternion{T}(q1, q2, q3, q4)

        return trans, scale, rot
    end
end

"""
    decompose_translation_scale_matrix(transform::Mat4)

Like `decompose_translation_scale_rotation_matrix(transform)` but skips the
extraction of the rotation component. This still works if a rotation is involved
and requires the same order of operations, i.e.
`transform = translation_matrix * scale_matrix * rotation_matrix`.
"""
function decompose_translation_scale_matrix(model::Mat4{T}) where {T}
    trans = Vec3{T}(model[Vec(1, 2, 3), 4])
    m33 = model[Vec(1, 2, 3), Vec(1, 2, 3)]
    if m33[1, 2] ≈ m33[1, 3] ≈ m33[2, 3] ≈ 0
        scale = Vec3{T}(diag(m33))
        return trans, scale
    else
        # m33 = Scale * Rotation; Scale * Rotation * Rotation' * Scale' = Scale^2
        scale = Vec3{T}(sqrt.(diag(m33 * m33')))
        return trans, scale
    end
end

#Calculate rotation between two vectors
function rotation(u::Vec{3, T}, v::Vec{3, T}) where {T}
    # It is important that the inputs are of equal length when
    # calculating the half-way vector.
    u, v = normalize(u), normalize(v)
    # Unfortunately, we have to check for when u == -v, as u + v
    # in this case will be (0, 0, 0), which cannot be normalized.
    if (u == -v)
        # 180 degree rotation around any orthogonal vector
        other = (abs(dot(u, Vec{3, T}(1, 0, 0))) < 1.0) ? Vec{3, T}(1, 0, 0) : Vec{3, T}(0, 1, 0)
        return qrotation(normalize(cross(u, other)), T(180))
    end
    half = normalize(u + v)
    return Quaternion(cross(u, half)..., dot(u, half))
end

function to_world(scene::SceneLike, point::VecTypes{2})
    cam = camera(scene)
    x = _to_world(
        Point2d(point[1], point[2]),
        inv(Mat4d(cam.projectionview[])),
        Vec2d(cam.resolution[])
    )
    return inv_f32_convert(scene, Point2d(x[1], x[2]))
end

w_component(x::Point) = 1.0
w_component(x::Vec) = 0.0

@deprecate to_world(p::VecTypes, M::Mat4, res::Vec2) to_world(scene::Scene, p::VecTypes) false

function _to_world(
        p::StaticVector{N, T},
        prj_view_inv::Mat4,
        cam_res::StaticVector
    ) where {N, T}
    VT = typeof(p)
    clip_space = ((VT(p) ./ VT(cam_res)) .* T(2)) .- T(1)
    pix_space = Vec{4, T}(
        clip_space[1],
        clip_space[2],
        T(0), w_component(p)
    )
    ws = prj_view_inv * pix_space
    return ws ./ ws[4]
end

function _to_world(
        p::Vec{N, T},
        prj_view_inv::Mat4,
        cam_res::StaticVector
    ) where {N, T}
    return to_world(Point(p), prj_view_inv, cam_res) .-
        to_world(zeros(Point{N, T}), prj_view_inv, cam_res)
end


"""
    _project([TargetType], matrix::Mat4, positions[, dim4 = 1])

Projects one or multiple `positions` using the given `matrix`.

`dim4` controls the fill value for 4th component of each positions (if they are
not 4D positions). `TargetType` controls the final output type. If the target
type is not 4 dimensional, each output position will be divided by `p[4]`.
"""
@inline _project(::Type{OT}, M::Mat4, p) where {OT} = _project(OT, M, p, 1)
@inline _project(M::Mat4, p) = _project(M, p, 1)
@inline function _project(M::Mat4{T1}, p::VecTypes{N, T2}, dim4::Real) where {N, T1, T2}
    T = promote_type(Float32, T1, T2)
    return _project(Point{3, T}, M, p, dim4, T)
end
@inline function _project(M::Mat4{T1}, ps::AbstractArray{<:VecTypes{N, T2}}, dim4::Real) where {N, T1, T2}
    T = promote_type(Float32, T1, T2)
    return _project(Point{3, T}, M, ps, dim4, T)
end

@inline function _project(
        ::Type{OT}, matrix::Mat4{T1}, p::VecTypes{N, T2}, dim4::Real
    ) where {OT <: VecTypes, N, T1 <: Real, T2 <: Real}

    T = promote_type(Float32, T1, T2)
    return _project(OT, matrix, p, dim4, T)
end

@inline function _project(::Type{OT}, matrix::Mat4, p::VecTypes, dim4::Real, ::Type{ET}) where {OT, ET}
    p4 = to_ndim(Point4{ET}, to_ndim(Point3{ET}, p, 0.0), dim4)
    p4 = matrix * p4
    return to_ndim(OT, p4[Vec(1, 2, 3)] / p4[4], 0)
end

@inline function _project(::Type{OT}, matrix::Mat4, p::VecTypes, dim4::Real, ::Type{ET}) where {OT <: VecTypes{4}, ET}
    p4 = to_ndim(Point4{ET}, to_ndim(Point3{ET}, p, 0.0), dim4)
    p4 = matrix * p4
    return to_ndim(OT, p4, 0)
end

function _project(
        ::Type{OT}, matrix::Mat4{T1}, ps::AbstractArray{<:VecTypes{N, T2}}, dim4::Real
    ) where {OT <: VecTypes, N, T1 <: Real, T2 <: Real}

    T = promote_type(Float32, T1, T2)
    return _project(OT, matrix, ps, dim4, T)
end

function _project(::Type{OT}, matrix::Mat4, ps::AbstractArray{<:VecTypes}, dim4::Real, ::Type{ET}) where {OT <: VecTypes, ET}
    matrix == I && return to_ndim.(OT, ps, 0)

    output = similar(ps, OT)
    @inbounds for i in eachindex(ps)
        output[i] = _project(OT, matrix, ps[i], dim4, ET)
    end
    return output
end

@inline function _project(matrix::Mat4{T1}, r::Rect{N, T2}, dim4::Real) where {N, T1, T2}
    T = promote_type(Float32, T1, T2)
    if matrix == I
        return Rect{N, T}(origin(r), widths(r))
    else
        ps = _project(Point{N, T}, matrix, coordinates(r), dim4)
        return Rect{N, T}(ps)
    end
end

function _project(matrix::Mat4, pos::Vector{<:VecTypes}, clip_planes::Vector{Plane3f}, space::Symbol = :data, dim4::Real = 1)
    return _project(Point3f, matrix, pos::Vector{<:VecTypes}, clip_planes, space, dim4)
end
function _project(
        ::Type{OT}, matrix::Mat4, pos::Vector{<:VecTypes}, clip_planes::Vector{Plane3f},
        space::Symbol = :data, dim4::Real = 1
    ) where {OT}
    projected = _project(OT, matrix, pos)
    if is_data_space(space)
        @assert projected !== pos "Input data should not be overwritten"
        nan_point = OT(NaN)
        @inbounds for i in eachindex(projected)
            projected[i] = ifelse(is_clipped(clip_planes, pos[i]), nan_point, projected[i])
        end
    end
    return projected
end

# TODO: consider warning here to discourage risky functions
function project(matrix::Mat4{T1}, p::VT, dim4::Real = 1.0) where {N, T1 <: Real, T2 <: Real, VT <: VecTypes{N, T2}}
    T = promote_type(Float32, T1, T2)
    p = to_ndim(Vec4{T}, to_ndim(Vec3{T}, p, 0.0), dim4)
    p = matrix * p
    return to_ndim(VT, p, 0.0)
end

function project(scene::Scene, point::VecTypes)
    cam = scene.camera
    area = viewport(scene)[]
    # TODO, I think we need  .+ minimum(area)
    # Which would be semi breaking at this point though, I suppose
    return project(
        cam.projectionview[] *
            f32_convert_matrix(scene.float32convert, :data) *
            transformationmatrix(scene)[],
        Vec2f(widths(area)),
        Point(point)
    )
end

# TODO: consider warning here to discourage risky functions
function project(proj_view::Mat4{T1}, resolution::Vec2, point::Point{N, T2}) where {N, T1, T2}
    T = promote_type(Float32, T1, T2)
    p4d = to_ndim(Vec4{T}, to_ndim(Vec3{T}, point, 0), 1)
    clip = proj_view * p4d
    # at this point the visible range is strictly -1..1 so FLoat64 doesn't matter
    p = (clip ./ clip[4])[Vec(1, 2)]
    p = Vec2{T}(p[1], p[2])
    return 0.5 .* (p .+ 1) .* resolution
end

# TODO: consider warning here to discourage risky functions
function project_point2(mat4::Mat4{T1}, point2::Point2{T2}) where {T1, T2}
    T = promote_type(Float32, T1, T2)
    return Point2{T2}(mat4 * to_ndim(Point4{T}, to_ndim(Point3{T}, point2, 0), 1))
end

# TODO: consider warning here to discourage risky functions
function transform(model::Mat4{T1}, x::VT) where {T1, VT <: VecTypes}
    T = promote_type(Float32, T1, eltype(VT))
    # TODO: no w = 1? Is this meant to skip translations?
    x4d = to_ndim(Vec4{T}, x, 0.0)
    return to_ndim(VT, model * x4d, 0.0)
end

################################################################################

# project between different coordinate systems/spaces
function space_to_clip(cam::Camera, space::Symbol, projectionview::Bool = true)
    if is_data_space(space)
        return projectionview ? cam.projectionview[] : cam.projection[]
    elseif space == :eye
        return cam.projection[]
    elseif is_pixel_space(space)
        return cam.pixel_space[]
    elseif is_relative_space(space)
        return Mat4d(2, 0, 0, 0, 0, 2, 0, 0, 0, 0, 1, 0, -1, -1, 0, 1)
    elseif is_clip_space(space)
        return Mat4d(I)
    else
        error("Space $space not recognized. Must be one of $(spaces())")
    end
end

function clip_to_space(cam::Camera, space::Symbol)
    if is_data_space(space)
        return inv(cam.projectionview[])
    elseif space == :eye
        return inv(cam.projection[])
    elseif is_pixel_space(space)
        w, h = cam.resolution[]
        return Mat4d(0.5w, 0, 0, 0, 0, 0.5h, 0, 0, 0, 0, -10_000, 0, 0.5w, 0.5h, 0, 1) # -10_000
    elseif is_relative_space(space)
        return Mat4d(0.5, 0, 0, 0, 0, 0.5, 0, 0, 0, 0, 1, 0, 0.5, 0.5, 0, 1)
    elseif is_clip_space(space)
        return Mat4d(I)
    else
        error("Space $space not recognized. Must be one of $(spaces())")
    end
end

function get_space(scene::Scene)
    space = get_space(cameracontrols(scene))::Symbol
    return Makie.is_data_space(space) ? (:data,) : (:data, space)
end
get_space(::AbstractCamera) = :data
function get_space(plot::Plot)
    space = to_value(get(plot, :space, :data))::Symbol
    # :data should resolve based on the parent scene/camera
    if Makie.is_data_space(space) && (parent_scene(plot) !== nothing)
        return get_space(parent_scene(plot))
    end
    return space
end

is_space_compatible(a, b) = is_space_compatible(get_space(a), get_space(b))
is_space_compatible(a::Symbol, b::Symbol) = a === b
is_space_compatible(a::Symbol, b::Union{Tuple, Vector}) = a in b
function is_space_compatible(a::Union{Tuple, Vector}, b::Union{Tuple, Vector})
    return any(x -> is_space_compatible(x, b), a)
end
is_space_compatible(a::Union{Tuple, Vector}, b::Symbol) = is_space_compatible(b, a)

# TODO: consider warning here to discourage risky functions
function project(cam::Camera, input_space::Symbol, output_space::Symbol, pos::VecTypes{N, T1}) where {N, T1}
    T = promote_type(Float32, T1) # always float, maybe Float64
    input_space === output_space && return to_ndim(Point3{T}, pos, 0)
    clip_from_input = space_to_clip(cam, input_space)
    output_from_clip = clip_to_space(cam, output_space)
    p4d = to_ndim(Point4{T}, to_ndim(Point3{T}, pos, 0), 1)
    transformed = output_from_clip * clip_from_input * p4d
    return Point3{T}(transformed[Vec(1, 2, 3)] ./ transformed[4])
end

function project(scenelike::SceneLike, input_space::Symbol, output_space::Symbol, pos::VecTypes{N, T1}) where {N, T1}
    T = promote_type(Float32, T1) # always float, maybe Float64
    input_space === output_space && return to_ndim(Point3{T}, pos, 0)
    cam = camera(scenelike)

    input_f32c = f32_convert_matrix(scenelike, input_space)
    clip_from_input = space_to_clip(cam, input_space)
    output_from_clip = clip_to_space(cam, output_space)
    output_f32c = inv_f32_convert_matrix(scenelike, output_space)

    p4d = to_ndim(Point4{T}, to_ndim(Point3{T}, pos, 0), 1)
    transformed = output_f32c * output_from_clip * clip_from_input * input_f32c * p4d
    return Point3{T}(transformed[Vec(1, 2, 3)] ./ transformed[4])
end

function transform_and_project(
        scenelike::SceneLike, input_space::Symbol, output_space::Symbol,
        pos::Vector{<:VecTypes{N, T1}}, target_type = Point{N, promote_type(Float32, T1)}
    ) where {N, T1}

    T = promote_type(Float32, T1) # always float, maybe Float64
    transformed = apply_transform_and_model(scenelike, pos)
    transformed_f32 = to_ndim.(Point3{T}, f32_convert(scenelike, transformed), 0)

    input_space === output_space && return to_ndim.(target_type, transformed_f32, 1)

    cam = camera(scenelike)
    projection_matrix = clip_to_space(cam, output_space) * space_to_clip(cam, input_space)
    return map(transformed_f32) do point
        p4d = projection_matrix * to_ndim(Point4{T}, point, 1)
        return target_type(p4d[Vec(1, 2, 3)] / p4d[4])
    end
end
