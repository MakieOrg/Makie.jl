################################################################################
#                        Transformation matrix builders                        #
################################################################################

function scalematrix(s::Vec{3, T}) where T
    T0, T1 = zero(T), one(T)
    Mat{4}(
        s[1],T0,  T0,  T0,
        T0,  s[2],T0,  T0,
        T0,  T0,  s[3],T0,
        T0,  T0,  T0,  T1,
    )
end

translationmatrix_x(x::T) where {T} = translationmatrix(Vec{3, T}(x, 0, 0))
translationmatrix_y(y::T) where {T} = translationmatrix(Vec{3, T}(0, y, 0))
translationmatrix_z(z::T) where {T} = translationmatrix(Vec{3, T}(0, 0, z))

function translationmatrix(t::Vec{3, T}) where T
    T0, T1 = zero(T), one(T)
    Mat{4}(
        T1,  T0,  T0,  T0,
        T0,  T1,  T0,  T0,
        T0,  T0,  T1,  T0,
        t[1],t[2],t[3],T1,
    )
end

rotate(angle, axis::Vec{3}) = rotationmatrix4(qrotation(convert(Array, axis), angle))
rotate(::Type{T}, angle::Number, axis::Vec{3}) where {T} = rotate(T(angle), convert(Vec{3, T}, axis))

function rotationmatrix_x(angle::Number)
    T0, T1 = (0, 1)
    Mat{4}(
        T1, T0, T0, T0,
        T0, cos(angle), sin(angle), T0,
        T0, -sin(angle), cos(angle),  T0,
        T0, T0, T0, T1
    )
end
function rotationmatrix_y(angle::Number)
    T0, T1 = (0, 1)
    Mat{4}(
        cos(angle), T0, -sin(angle),  T0,
        T0, T1, T0, T0,
        sin(angle), T0, cos(angle), T0,
        T0, T0, T0, T1
    )
end
function rotationmatrix_z(angle::Number)
    T0, T1 = (0, 1)
    Mat{4}(
        cos(angle), sin(angle), T0, T0,
        -sin(angle), cos(angle),  T0, T0,
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
function frustum(left::T, right::T, bottom::T, top::T, znear::T, zfar::T) where T
    (right == left || bottom == top || znear == zfar) && return Mat{4,4,T}(I)
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
function perspectiveprojection(fovy::T, aspect::T, znear::T, zfar::T) where T
    (znear == zfar) && error("znear ($znear) must be different from tfar ($zfar)")
    h = T(tan(fovy / 360.0 * pi) * znear)
    w = T(h * aspect)
    return frustum(-w, w, -h, h, znear, zfar)
end

function perspectiveprojection(
        ::Type{T}, fovy::Number, aspect::Number, znear::Number, zfar::Number
    ) where T
    perspectiveprojection(T(fovy), T(aspect), T(znear), T(zfar))
end
"""
`proj = perspectiveprojection([T], rect, fov, near, far)` defines the
projection ratio in terms of the rectangular view size `rect` rather
than the aspect ratio.
"""
function perspectiveprojection(wh::Rect2, fov::T, near::T, far::T) where T
    perspectiveprojection(fov, T(wh.w/wh.h), near, far)
end

function perspectiveprojection(
        ::Type{T}, wh::Rect2, fov::Number, near::Number, far::Number
    ) where T
    perspectiveprojection(T(fov), T(wh.w/wh.h), T(near), T(far))
end

"""
`view = lookat(eyeposition, lookat, up)` creates a view matrix with
the eye located at `eyeposition` and looking at position `lookat`,
with the top of the window corresponding to the direction `up`. Only
the component of `up` that is perpendicular to the vector pointing
from `eyeposition` to `lookat` will be used.  All inputs must be
supplied as 3-vectors.
"""
function lookat(eyePos::Vec{3, T}, lookAt::Vec{3, T}, up::Vec{3, T}) where T
    zaxis  = normalize(eyePos-lookAt)
    xaxis  = normalize(cross(up,    zaxis))
    yaxis  = normalize(cross(zaxis, xaxis))
    T0, T1 = zero(T), one(T)
    return Mat{4}(
        xaxis[1], yaxis[1], zaxis[1], T0,
        xaxis[2], yaxis[2], zaxis[2], T0,
        xaxis[3], yaxis[3], zaxis[3], T0,
        T0,       T0,       T0,       T1
    ) * translationmatrix(-eyePos)
end

function lookat(::Type{T}, eyePos::Vec{3}, lookAt::Vec{3}, up::Vec{3}) where T
    lookat(Vec{3,T}(eyePos), Vec{3,T}(lookAt), Vec{3,T}(up))
end

function orthographicprojection(wh::Rect2, near::T, far::T) where T
    w, h = widths(wh)
    orthographicprojection(zero(T), T(w), zero(T), T(h), near, far)
end

function orthographicprojection(
        ::Type{T}, wh::Rect2, near::Number, far::Number
    ) where T
    orthographicprojection(wh, T(near), T(far))
end

function orthographicprojection(
        left::T, right::T,
        bottom::T, top::T,
        znear::T, zfar::T
    ) where T
    (right==left || bottom==top || znear==zfar) && return Mat{4,4,T}(I)
    T0, T1, T2 = zero(T), one(T), T(2)
    Mat{4}(
        T2/(right-left), T0, T0,  T0,
        T0, T2/(top-bottom), T0,  T0,
        T0, T0, -T2/(zfar-znear), T0,
        -(right+left)/(right-left), -(top+bottom)/(top-bottom), -(zfar+znear)/(zfar-znear), T1
    )
end

function orthographicprojection(::Type{T},
        left  ::Number, right::Number,
        bottom::Number, top  ::Number,
        znear ::Number, zfar ::Number
    ) where T
    orthographicprojection(
        T(left),   T(right),
        T(bottom), T(top),
        T(znear),  T(zfar)
    )
end

mutable struct Pivot{T}
    origin      ::Vec{3, T}
    xaxis       ::Vec{3, T}
    yaxis       ::Vec{3, T}
    zaxis       ::Vec{3, T}
    rotation    ::Quaternion
    translation ::Vec{3, T}
    scale       ::Vec{3, T}
end

GeometryBasics.origin(p::Pivot) = p.origin

rotationmatrix4(q::Quaternion{T}) where {T} = Mat4{T}(q)

function transformationmatrix(p::Pivot)
    translationmatrix(p.origin) * #go to origin
    rotationmatrix4(p.rotation) * #apply rotation
    translationmatrix(-p.origin)* # go back to origin
    translationmatrix(p.translation) #apply translation
end

function transformationmatrix(translation, scale)
    T = eltype(translation)
    T0, T1 = zero(T), one(T)
    return Mat{4}(
        scale[1],T0,  T0,  T0,
        T0,  scale[2],T0,  T0,
        T0,  T0,  scale[3],T0,
        translation[1], translation[2], translation[3], T1
    )
end

function transformationmatrix(translation, scale, rotation::Quaternion)
    trans_scale = transformationmatrix(translation, scale)
    rotation = Mat4f(rotation)
    trans_scale*rotation
end

#Calculate rotation between two vectors
function rotation(u::Vec{3, T}, v::Vec{3, T}) where T
    # It is important that the inputs are of equal length when
    # calculating the half-way vector.
    u, v = normalize(u), normalize(v)
    # Unfortunately, we have to check for when u == -v, as u + v
    # in this case will be (0, 0, 0), which cannot be normalized.
    if (u == -v)
        # 180 degree rotation around any orthogonal vector
        other = (abs(dot(u, Vec{3, T}(1,0,0))) < 1.0) ? Vec{3, T}(1,0,0) : Vec{3, T}(0,1,0)
        return qrotation(normalize(cross(u, other)), T(180))
    end
    half = normalize(u+v)
    return Quaternion(cross(u, half)..., dot(u, half))
end

################################################################################
#                              Projection methods                              #
################################################################################

########################################
#           Efficient matmul           #
########################################

# The following code is just handwritten matrix multiplication.
# Could theoretically be optimized, but the idea was more to cut 
# down on `to_ndim`, which avoids allocations and dimension changes.

# As an example (and a benchmark), 
# ```julia
# using Makie, BenchmarkTools
# f, a, p = scatter(randn(Point2f, 1_000_000)) # scatter 1M random points
# @benchmark Makie.project(camera(scene), )

# using Symbolics
# mat = Makie.Mat4(Symbolics.variable.(("mat",), 1:16))
# 
# mat * Point4(Symbolics.variable.(("point",), 1:4))

"""
    apply_matrix(mat::Mat4, point::Point; dim4 = 1f0)::Point3f

Transform a point by a matrix, i.e., ``mat * point``. 

`point` may be a `Point2` or a `Point3`.

This is an efficient implementation because the matrix multiplication 
is written out by hand, avoiding unnecessary allocations and dimension changes.

Always returns a Point3f.
"""
function apply_matrix(mat::Mat4{<: Number}, point::T; dim4 = 1f0) where {T <: VecTypes{2, <: Number}}
    # NOTE: this is the 2d case.

    # First, compute the fourth dimension transformation, since we 
    # will divide the other dimensions by it.
    # Here, we know that the fourth dimension of the point must have value 1,
    # so we are able to write the matrix multiplication out and obtain quite a bit of 
    # efficiency that way.
    transformed_dim4 = mat[4]*point[1] + mat[8]*point[2] #=+ mat[12]*point[3]=# + mat[16] * dim4# * point[4]
    # Now, we perform the written-out matrix multiplication.
    # For Point2f, the 3rd dimension will always be 0 by definition, so we can skip 
    # those calculations which involve that dimension.
    return Point3f(
        (mat[1] * point[1] + mat[5]*point[2] + #=mat[9]*point[3] +=# mat[13]*dim4 #= * point[4] =#)/transformed_dim4,
        (#=mat[10]*point₃ +=# mat[14]*dim4 #=*point[4]=# + mat[2]*point[1] + mat[6]*point[2])/transformed_dim4,
        (mat[3]*point[1] + mat[7]*point[2] #=+ mat[11]*point[3]=# + mat[15]*dim4 #=*point[4]=#)/transformed_dim4,
    )
end

function apply_matrix(mat::Mat4{<: Number}, point::T; dim4 = 1f0) where {T <: VecTypes{3, <: Number}}
    # NOTE: this is the 3d case.

    # First, compute the fourth dimension transformation, since we 
    # will divide the other dimensions by it.
    # Here, we know that the fourth dimension of the point must have value 1,
    # so we are able to write the matrix multiplication out and obtain quite a bit of 
    # efficiency that way.
    transformed_dim4 = mat[4]*point[1] + mat[8]*point[2] + mat[12]*point[3] + mat[16] * dim4# * point[4]
    # Now, we perform the written-out matrix multiplication.
    return Point3f(
        (mat[1] * point[1] + mat[5]*point[2] + mat[9]*point[3] + mat[13]*dim4#= * point[4] =#)/transformed_dim4,
        (mat[10]*point[3] + mat[14]*dim4#=*point[4]=# + mat[2]*point[1] + mat[6]*point[2])/transformed_dim4,
        (mat[3]*point[1] + mat[7]*point[2] + mat[11]*point[3] + mat[15]*dim4#=*point[4]=#)/transformed_dim4,
    )
end

apply_matrix(mat::Mat4{<: Number}, point::Point4{<: Number}) = mat * point

########################################
#               to_world               #
########################################

function to_world(scene::Scene, point::T) where T <: StaticVector
    cam = scene.camera
    x = to_world(
        point,
        inv(transformationmatrix(scene)[]) *
        inv(cam.view[]) *
        inv(cam.projection[]),
        T(widths(pixelarea(scene)[]))
    )
    Point2f(x[1], x[2])
end

w_component(x::Point) = 1.0
w_component(x::Vec) = 0.0

function to_world(
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
    ws ./ ws[4]
end

function to_world(
        p::Vec{N, T},
        prj_view_inv::Mat4,
        cam_res::StaticVector
    ) where {N, T}
    to_world(Point(p), prj_view_inv, cam_res) .-
        to_world(zeros(Point{N, T}), prj_view_inv, cam_res)
end

########################################
#               project                #
########################################

# Projects from scene dataspace to pixel space (I think)
function project(scene::Scene, point::T) where T<:StaticVector
    cam = scene.camera
    area = pixelarea(scene)[]
    # TODO, I think we need  .+ minimum(area)
    # Which would be semi breaking at this point though, I suppose
    return project(
        cam.projectionview[] *
        transformationmatrix(scene)[],
        Vec2f(widths(area)),
        Point(point)
    )
end

function project(matrix::Mat4f, p::T, dim4 = 1.0) where T <: VecTypes
    p = apply_matrix(matrix, p; dim4)
    to_ndim(T, p, 0.0)
end

function project(proj_view::Mat4f, resolution::Vec2, point::Point)
    p = Vec2f(apply_matrix(proj_view, point)[Vec2{Int}(1, 2)])
    return (((p .+ 1f0) ./ 2f0) .* (resolution .- 1f0)) .+ 1f0
end

function project_point2(mat4::Mat4, point2::Point2)
    Point2f(apply_matrix(mat4, point2))
end

function transform(model::Mat4, x::T) where T
    to_ndim(T, apply_matrix(model, x; dim4 = 0.0), 0.0)
end

# project between different coordinate systems/spaces
function space_to_clip(cam::Camera, space::Symbol, projectionview::Bool=true)
    if is_data_space(space)
        return projectionview ? cam.projectionview[] : cam.projection[]
    elseif is_pixel_space(space)
        return cam.pixel_space[]
    elseif is_relative_space(space)
        return Mat4f(2, 0, 0, 0, 0, 2, 0, 0, 0, 0, 1, 0, -1, -1, 0, 1)
    elseif is_clip_space(space)
        return Mat4f(I)
    else
        error("Space $space not recognized. Must be one of $(spaces())")
    end
end

function clip_to_space(cam::Camera, space::Symbol)
    if is_data_space(space)
        return inv(cam.projectionview[])
    elseif is_pixel_space(space)
        w, h = cam.resolution[]
        return Mat4f(0.5w, 0, 0, 0, 0, 0.5h, 0, 0, 0, 0, -10_000, 0, 0.5w, 0.5h, 0, 1) # -10_000
    elseif is_relative_space(space)
        return Mat4f(0.5, 0, 0, 0, 0, 0.5, 0, 0, 0, 0, 1, 0, 0.5, 0.5, 0, 1)
    elseif is_clip_space(space)
        return Mat4f(I)
    else
        error("Space $space not recognized. Must be one of $(spaces())")
    end
end

function project(cam::Camera, input_space::Symbol, output_space::Symbol, pos)
    input_space === output_space && return to_ndim(Point3f, pos, 0)
    clip_from_input = space_to_clip(cam, input_space)
    output_from_clip = clip_to_space(cam, output_space)
    transformed = apply_matrix(output_from_clip * clip_from_input, pos)
    return Point3f(transformed[Vec(1, 2, 3)] ./ transformed[4])
end

function project(cam::Camera, input_space::Symbol, output_space::Symbol, pos::AbstractArray{<: VecTypes{<: Number}})
    input_space === output_space && return to_ndim.(Point3f, pos, 0)
    clip_from_input = space_to_clip(cam, input_space)
    output_from_clip = clip_to_space(cam, output_space)
    return apply_matrix.((output_from_clip * clip_from_input,), pos)
end