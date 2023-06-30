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
### Old Projection code
################################################################################

# function to_world(scene::Scene, point::T) where T <: StaticVector
#     cam = scene.camera
#     x = to_world(
#         point,
#         inv(transformationmatrix(scene)[]) *
#         inv(cam.view[]) *
#         inv(cam.projection[]),
#         T(widths(pixelarea(scene)[]))
#     )
#     Point2f(x[1], x[2])
# end

# w_component(x::Point) = 1.0
# w_component(x::Vec) = 0.0

# function to_world(
#         p::StaticVector{N, T},
#         prj_view_inv::Mat4,
#         cam_res::StaticVector
#     ) where {N, T}
#     VT = typeof(p)
#     clip_space = ((VT(p) ./ VT(cam_res)) .* T(2)) .- T(1)
#     pix_space = Vec{4, T}(
#         clip_space[1],
#         clip_space[2],
#         T(0), w_component(p)
#     )
#     ws = prj_view_inv * pix_space
#     ws ./ ws[4]
# end

# function to_world(
#         p::Vec{N, T},
#         prj_view_inv::Mat4,
#         cam_res::StaticVector
#     ) where {N, T}
#     to_world(Point(p), prj_view_inv, cam_res) .-
#         to_world(zeros(Point{N, T}), prj_view_inv, cam_res)
# end

# function project(scene::Scene, point::T) where T<:StaticVector
#     cam = scene.camera
#     area = pixelarea(scene)[]
#     # TODO, I think we need  .+ minimum(area)
#     # Which would be semi breaking at this point though, I suppose
#     return project(
#         cam.projectionview[] *
#         transformationmatrix(scene)[],
#         Vec2f(widths(area)),
#         Point(point)
#     )
# end

# function project(matrix::Mat4f, p::T, dim4 = 1.0) where T <: VecTypes
#     p = to_ndim(Vec4f, to_ndim(Vec3f, p, 0.0), dim4)
#     p = matrix * p
#     to_ndim(T, p, 0.0)
# end

# function project(proj_view::Mat4f, resolution::Vec2, point::Point)
#     p4d = to_ndim(Vec4f, to_ndim(Vec3f, point, 0f0), 1f0)
#     clip = proj_view * p4d
#     p = (clip ./ clip[4])[Vec(1, 2)]
#     p = Vec2f(p[1], p[2])
#     return (((p .+ 1f0) ./ 2f0) .* (resolution .- 1f0)) .+ 1f0
# end

# function project_point2(mat4::Mat4, point2::Point2)
#     Point2f(mat4 * to_ndim(Point4f, to_ndim(Point3f, point2, 0), 1))
# end

# function transform(model::Mat4, x::T) where T
#     x4d = to_ndim(Vec4f, x, 0.0)
#     to_ndim(T, model * x4d, 0.0)
# end

# function project(cam::Camera, input_space::Symbol, output_space::Symbol, pos)
#     input_space === output_space && return to_ndim(Point3f, pos, 0)
#     p4d = to_ndim(Point4f, to_ndim(Point3f, pos, 0), 1)
#     transformed = space_to_space_matrix(cam, input_space, output_space) * p4d
#     return Point3f(transformed[Vec(1, 2, 3)] ./ transformed[4])
# end

################################################################################
### new projection code
################################################################################


"""
    space_to_space_matrix(scenelike, spaces::Pair)
    space_to_space_matrix(scenelike, input_space::Symbol, output_space::Symbol)

Returns a matrix which transforms positional data from a given input space to a 
given output space. This will not include the transform function, as it is not
representable as a matrix, but will include the model matrix if applicable. 
(I.e. this includes `scale!()`, `translate!()` and `rotate!()`.)

If you wish to exclude the model matrix, call 
`_space_to_space_matrix(camera(scenelike), ...)`.
"""
function space_to_space_matrix(obj, input_space::Symbol, output_space::Symbol)
    return space_to_space_matrix(obj, Pair(input_space, output_space))
end

# this method does Axis -> Scene conversions
function space_to_space_matrix(obj, space2space::Pair{Symbol, Symbol})
    return space_to_space_matrix(get_scene(obj), space2space)
end

function space_to_space_matrix(scene_or_plot::SceneLike, s2s::Pair{Symbol, Symbol})
    mat = _space_to_space_matrix(camera(scene_or_plot), s2s)
    model = to_value(transformationmatrix(scene_or_plot))
    if s2s[1] in (:data, :transformed)
        return mat * model
    elseif s2s[2] in (:data, :transformed)
        return inv(model) * mat
    else
        return mat
    end
end

# function space_to_space_matrix(cam::Camera, s2s::Pair{Symbol, Symbol})
#     @warn "No trans_func, no model"
#     return _space_to_space_matrix(cam, s2s)
# end

function _space_to_space_matrix(cam::Camera, s2s::Pair{Symbol, Symbol})
    # identities
    if s2s[1] === s2s[2]
        return Mat4f(I)
    elseif s2s[1] in (:data, :transformed) && s2s[2] === :world
        return Mat4f(I)
    
    # direct conversions (no calculations)
    elseif s2s === Pair(:world, :eye)
        return cam.view[]
    elseif s2s === Pair(:eye, :clip)
        return cam.projection[]
    elseif s2s[1] in (:data, :transformed, :world) && s2s[2] === :clip
        return cam.projectionview[]
    elseif s2s === Pair(:pixel, :clip)
        return cam.pixel_space[]
    elseif s2s === Pair(:relative, :clip)
        return Mat4f(2, 0, 0, 0, 0, 2, 0, 0, 0, 0, 1, 0, -1, -1, 0, 1)

    # simple inversions
    elseif s2s === Pair(:clip, :relative)
        return Mat4f(0.5, 0, 0, 0, 0, 0.5, 0, 0, 0, 0, 1, 0, 0.5, 0.5, 0, 1)
    elseif s2s === Pair(:clip, :pixel)
        w, h = cam.resolution[]
        return Mat4f(0.5w, 0, 0, 0, 0, 0.5h, 0, 0, 0, 0, -10_000, 0, 0.5w, 0.5h, 0, 1)

    # calculation neccessary
    elseif s2s[1] === :clip
        return inv(_space_to_space_matrix(cam, Pair(s2s[2], s2s[1])))
    elseif s2s[1] in spaces() && s2s[2] in spaces()
        return _space_to_space_matrix(cam, Pair(:clip, s2s[2])) * 
                _space_to_space_matrix(cam, Pair(s2s[1], :clip))
    else
        error("Space $space not recognized. Must be one of $(spaces())")
    end
end

@deprecate space_to_clip(cam, space, pv) space_to_space_matrix(cam, space, :clip) false
@deprecate clip_to_space(cam, space) space_to_space_matrix(cam, :clip, space) false

# For users/convenient project functions:

"""
    project(scenelike, pos[; input_space, output_space = :pixel, type = Point3f])

Projects the given positional data from the space of the given plot, scene or 
axis (`scenelike`) to pixel space. Optionally the input and output space can be
changed via the respective keyword arguments.

## Notes

Depending on the `scenelike` object passed the context of what data,
transformed, world and eye space is may change. A `scene` with a pixel-space 
camera will yield different results than a `scene` with a 3D camera, for example.

Transformations and the input space can be different between a plot and its 
parent scene and also between child plots and their parent plots. In some cases
you may also see varying results because of this.

If this function projects to pixel space it returns the pixel positions relative
to the scene most closely related to `scenelike` (i.e. the given scene or parent
scene). If you want the pixel position relative to the screen/figure/window, you
may need to add `minimum(pixelarea(scene))`. `project_to_screen` does this for
you.
"""
function project(
        plot::AbstractPlot, pos; 
        input_space::Symbol = to_value(get(plot, :space, :data)), 
        output_space::Symbol = :pixel, type = _point3_type(pos)
    )

    tf = transform_func(plot)
    mat = space_to_space_matrix(plot, input_space => output_space)
    return project(mat, tf, input_space, output_space, pos, type)
end

function project(
        obj, pos; 
        input_space::Symbol = :data, output_space::Symbol = :pixel,
        type = _point3_type(pos)
    )

    tf = transform_func(get_scene(obj)) # this should error with a camera
    mat = space_to_space_matrix(obj, input_space => output_space)
    return project(mat, tf, input_space, output_space, pos, type)
end

function project(cam::Camera, input_space::Symbol, output_space::Symbol, pos; type = _point3_type(pos))
    @assert input_space !== :data "Cannot transform from :data space with just the camera."
    @assert output_space !== :data "Cannot transform to :data space with just the camera."
    mat = space_to_space_matrix(cam, input_space => output_space)
    return project(mat, indentity, input_space, output_space, pos, type)
end

_point3_type(::VecTypes{N, T}) where {N, T} = Point3{T}
_point3_type(::AbstractArray{<: VecTypes{N, T}}) where {N, T} = Point3{T}

# Internal / Implementations

"""
    project(projection_matrix::Mat4f, transform_func, input_space::Symbol, output_space::Symbol, pos)

Projects the given position or positions according to the given projection matrix,
transform function and input space.

For a simpler interface, use `project(scenelike, pos)`.
"""
function project(
        mat::Mat4, tf, input_space::Symbol, output_space::Symbol, 
        pos::AbstractArray{<: VecTypes{N, T}}, type = Point3{T}
    ) where {N, T}
    if input_space === output_space
        return to_ndim.(type, pos, 0)
    elseif output_space !== :data
        return map(p -> project(mat, tf, input_space, p, type), pos)
    else
        itf = inverse_transform(tf)
        return map(p -> inv_project(mat, itf, p, type), pos)
    end
end
function project(
        mat::Mat4, tf, input_space::Symbol, output_space::Symbol, 
        pos::VecTypes{N, T}, type = Point3{T}) where {N, T}
    if input_space === output_space
        return to_ndim(type, pos, 0)
    elseif output_space !== :data
        return project(mat, tf, input_space, pos, type)
    else
        itf = inverse_transform(tf)
        return inv_project(mat, itf, pos, type)
    end
end


function project(mat::Mat4, tf, space::Symbol, pos::VecTypes{N, T}, type = Point3{T}) where {N, T}
    return project(mat, apply_transform(tf, pos, space), type)
end

function inv_project(mat::Mat4f, itf, pos::VecTypes{N, T}, type = Point3{T}) where {N, T}
    p = project(mat, pos, type)
    return apply_transform(itf, p)
end

function project(mat::Mat4, pos::VecTypes{N, T}, type = Point3{T}) where {N, T}
    # TODO is to_ndim slow? It alone seems to 
    p4d = to_ndim(Point4{T}, to_ndim(Point3{T}, pos, 0), 1)
    p4d = mat * p4d
    return to_ndim(type, p4d[Vec(1,2,3)] ./ p4d[4], 1f0)
end

# TODO - should we use p4d[4] = 0 here?
# function project(mat::Mat4, pos::Vec{N, T}, type = Vec3{T}) where {N, T}
#     p4d = to_ndim(Vec4{T}, to_ndim(Vec3{T}, pos, 0), 1)
#     p4d = mat * p4d
#     return to_ndim(type, p4d[Vec(1,2,3)] ./ p4d[4], 1f0)
# end


# in-place version
# function project!(target::AbstractArray, mat::Mat4f, tf, space::Symbol, pos::AbstractArray)
#     resize!(target, length(pos))
#     return map!(p -> project(mat, tf, space, p), target, pos)
# end


# Named project functions

"""
    project_to_world(scenelike[, input_space], pos)

Transforms the given position(s) to world space, using the space of `scenelike`
as the default input space.
"""
project_to_world(obj, pos) = project(obj, pos, output_space = :world)
project_to_world(obj, input_space::Symbol, pos) = project(obj, pos, input_space = input_space, output_space = :world)

@deprecate to_world project_to_world false

"""
    project_to_screen(scenelike[, input_space], pos)

Transforms the given position(s) to (2D) screen/pixel space, using the space of 
`scenelike` as the default input space. The returned positions will be relative
to the screen/window/figure origin, rather than the (parent) scene.
"""
function project_to_screen(obj, pos)
    scene = get_scene(obj)
    offset = minimum(to_value(pixelarea(scene)))
    return apply_offset!(project(obj, pos, type = Point2f), offset)
end

function project_to_screen(obj, input_space::Symbol, pos)
    scene = get_scene(obj)
    offset = minimum(to_value(pixelarea(scene)))
    return apply_offset!(project(obj, pos, input_space = input_space, type = Point2f), offset)
end

function apply_offset!(pos::VT, off::VecTypes) where {VT <: VecTypes}
    return pos + to_ndim(VT, off, 0)
end

function apply_offset!(pos::AbstractArray{VT}, off::VecTypes) where {VT}
    off = to_ndim(VT, off, 0)
    for i in eachindex(pos)
        pos[i] = pos[i] + off
    end
    return pos
end

@deprecate shift_project(scene, plot, pos) project_to_screen(plot, pos) false

"""
    project_to_pixel(scenelike[, input_space], pos[; type = Point2f])

Transforms the given position(s) to (2D) pixel space, using the space of `scenelike`
as the default input space. The returned positions will be relative to the 
scene derived from scenelike, not the screen/window/figure origin.

This is equivalent to `project(scenelike, pos[; input_space], type = Point2f)`.
"""
project_to_pixel(obj, pos; type = Point2f) = project(obj, pos; type = type)
function project_to_pixel(obj, input_space::Symbol, pos; type = Point2f)
    return project(obj, pos, input_space = input_space, type = type)
end

# Helper function
"""
    projection_obs(plot)

Returns an observable that triggers whenever the result of `project` could change
"""
function projection_obs(plot::AbstractPlot)
    return lift(
        (_, _, _, _, _, _) -> nothing,
        plot,
        camera(plot).view, 
        camera(plot).projection,
        get_scene(plot).px_area,
        transformationmatrix(plot),
        transform_func(plot),
        get(plot, :space, Observable(:data)),
    )
end
function projection_obs(scene::Scene)
    return lift(
        (_, _, _, _, _, _) -> nothing,
        scene,
        camera(scene).view, 
        camera(scene).projection,
        scene.px_area,
        transformationmatrix(scene),
        transform_func(scene)
    )
end