#=
`apply_transform` Interface for custom transformations:
- can be a struct holding information about the transformation or a function
- should implement `inverse_transform(transformation)`
- for struct: must implement `apply_transform(transform, ::VecTypes)` (for 2d and 3d points)
- for struct: must implement `apply_transform(transform, ::Rect3d)` for bounding boxes
=#

Base.parent(t::Transformation) = isassigned(t.parent) ? t.parent[] : nothing

function parent_transform(x)
    p = parent(transformation(x))
    return isnothing(p) ? Mat4f(I) : p.model[]
end

function Observables.connect!(parent::Transformation, child::Transformation; connect_func=true)
    tfuncs = []
    # Observables.clear(child.parent_model)
    obsfunc = on(parent.model; update=true) do m
        return child.parent_model[] = m
    end
    push!(tfuncs, obsfunc)
    if connect_func
        # Observables.clear(child.transform_func)
        t2 = on(parent.transform_func; update=true) do f
            child.transform_func[] = f
            return
        end
        push!(tfuncs, t2)
    end
    child.parent[] = parent
    return tfuncs
end

function free(transformation::Transformation)
    # clear parent...Needs to be same type, so just use itself
    transformation.parent[] = transformation
    for name in [:translation, :scale, :rotation, :model, :transform_func]
        obs = getfield(transformation, name)
        Observables.clear(obs)
    end
    return
end

function model_transform(transformation::Transformation)
    return transformationmatrix(transformation.translation[], transformation.scale[], transformation.rotation[])
end

function translated(scene::Scene, translation...)
    tscene = Scene(scene, transformation = Transformation())
    transform!(tscene, translation...)
    tscene
end

function translated(scene::Scene; kw_args...)
    tscene = Scene(scene, transformation = Transformation())
    transform!(tscene; kw_args...)
     tscene
end

function transform!(
        t::Transformable;
        translation = Vec3d(0),
        scale = Vec3d(1),
        rotation = 0.0,
    )
    translate!(t, to_value(translation))
    scale!(t, to_value(scale))
    rotate!(t, to_value(rotation))
end

function transform!(
        t::Transformable, attributes::Union{Attributes, AbstractDict, NamedTuple}
    )
    transform!(t; attributes...)
end

transformation(t::Scene) = t.transformation
transformation(t::AbstractPlot) = t.transformation
transformation(t::Transformation) = t

"""
    Accum

Force transformation to be relative to the current state, not absolute.
"""
struct Accum end

"""
    Absolute

Force transformation to be absolute, not relative to the current state.
This is the default setting.
"""
struct Absolute end

scale(t::Transformable) = transformation(t).scale

function scale!(::Type{T}, t::Transformable, s::VecTypes) where {T}
    factor = to_ndim(Vec3d, s, 1)
    if T === Accum
        scale(t)[] = scale(t)[] .* factor
    elseif T == Absolute
        scale(t)[] = factor
    else
        error("Unknown transformation: $T")
    end
end

"""
    scale!([mode = Absolute], t::Transformable, xyz...)
    scale!([mode = Absolute], t::Transformable, xyz::VecTypes)

Scale the given `t::Transformable` (a Scene or Plot) to the given arguments `xyz`.
Any missing dimension will be scaled by 1. If `mode == Accum` the given scaling
will be multiplied with the previous one.
"""
scale!(t::Transformable, xyz...) = scale!(Absolute, t, xyz)
scale!(t::Transformable, xyz::VecTypes) = scale!(Absolute, t, xyz)
scale!(::Type{T}, t::Transformable, xyz...) where {T} = scale!(T, t, xyz)

rotation(t::Transformable) = transformation(t).rotation

function rotate!(::Type{T}, t::Transformable, q) where T
    rot = convert_attribute(q, key"rotation"())
    if T === Accum
        rot1 = rotation(t)[]
        rotation(t)[] = rot1 * rot
    elseif T == Absolute
        rotation(t)[] = rot
    else
        error("Unknown transformation: $T")
    end
end

"""
    rotate!(Accum, t::Transformable, axis_rot...)

Apply a relative rotation to the transformable, by multiplying by the current rotation.
"""
rotate!(::Type{T}, t::Transformable, axis_rot...) where T = rotate!(T, t, axis_rot)

"""
    rotate!(t::Transformable, axis_rot::Quaternion)
    rotate!(t::Transformable, axis_rot::Real)
    rotate!(t::Transformable, axis_rot...)

Apply an absolute rotation to the transformable. Rotations are all internally converted to `Quaternion`s.
"""
rotate!(t::Transformable, axis_rot...) = rotate!(Absolute, t, axis_rot)
rotate!(t::Transformable, axis_rot::Quaternion) = rotate!(Absolute, t, axis_rot)
rotate!(t::Transformable, axis_rot::Real) = rotate!(Absolute, t, axis_rot)

translation(t::Transformable) = transformation(t).translation

function translate!(::Type{T}, t::Transformable, trans) where T
    offset = to_ndim(Vec3d, trans, 0)
    if T === Accum
        translation(t)[] = translation(t)[] .+ offset
    elseif T === Absolute
        translation(t)[] = offset
    else
        error("Unknown translation type: $T")
    end
end
"""
    translate!(t::Transformable, xyz::VecTypes)
    translate!(t::Transformable, xyz...)

Apply an absolute translation to the given `Transformable` (a Scene or Plot), translating it to `x, y, z`.
"""
translate!(t::Transformable, xyz::VecTypes) = translate!(Absolute, t, xyz)
translate!(t::Transformable, xyz...) = translate!(Absolute, t, xyz)

"""
    translate!(Accum, t::Transformable, xyz...)

Translate the given `Transformable` (a Scene or Plot), relative to its current position.
"""
translate!(::Type{T}, t::Transformable, xyz...) where T = translate!(T, t, xyz)


GeometryBasics.origin(t::Transformable) = transformation(t).origin

"""
    origin!([mode = Absolute], t::Transformable, xyz...)
    origin!([mode = Absolute], t::Transformable, xyz::VecTypes)

Sets the origin of the transformable `t` to the given `xyz` value. This affects
the origin of `rotate!(t, ...)` and `scale!(t, ...)`. If `mode` is given as
`Accum` the origin is translated by the given `xyz` instead.
"""
origin!(t::Transformable, xyz...) = origin!(Absolute, t, xyz)
origin!(t::Transformable, xyz::VecTypes) = origin!(Absolute, t, xyz)
origin!(::Type{T}, t::Transformable, xyz...) where {T} = origin!(T, t, xyz)

function origin!(::Type{T}, t::Transformable, xyz::VecTypes) where T
    offset = to_ndim(Vec3d, xyz, 0)
    if T === Accum
        origin(t)[] = origin(t)[] + offset
    elseif T === Absolute
        origin(t)[] = offset
    else
        error("Unknown origin translation type: $T")
    end
end

function transform!(t::Transformable, x::Tuple{Symbol, <: Number})
    plane, dimval = string(x[1]), Float64(x[2])
    if length(plane) != 2 || (!all(x-> x in ('x', 'y', 'z'), plane))
        error("plane needs to define a 2D plane in xyz. It should only contain 2 symbols out of (:x, :y, :z). Found: $plane")
    end
    if all(x-> x in ('x', 'y'), plane) # xy plane
        translate!(t, 0, 0, dimval)
    elseif all(x-> x in ('x', 'z'), plane) # xz plane
        rotate!(t, Vec3f(1, 0, 0), 0.5pi)
        translate!(t, 0, dimval, 0)
    else #yz plane
        r1 = qrotation(Vec3f(0, 1, 0), 0.5pi)
        r2 = qrotation(Vec3f(1, 0, 0), 0.5pi)
        rotate!(t,  r2 * r1)
        translate!(t, dimval, 0, 0)
    end
    t
end

transformationmatrix(x)::Observable{Mat4d} = transformation(x).model
transformation(x::Attributes) = x.transformation[]
transform_func(x) = transform_func_obs(x)[]
transform_func_obs(x) = transformation(x).transform_func

"""
    apply_transform_and_model(plot, data, output_type = Point3d)
    apply_transform_and_model(model, transfrom_func, data, output_type = Point3d)

Applies the transform function and model matrix (i.e. transformations from
`translate!`, `rotate!` and `scale!`) to the given input.
"""
function apply_transform_and_model(plot::AbstractPlot, data, output_type = Point3d)
    return apply_transform_and_model(
        plot.model[], transform_func(plot), data,
        to_value(get(plot, :space, :data)),
        output_type
    )
end
function apply_transform_and_model(model::Mat4, f, data, space = :data, output_type = Point3d)
    transformed = promoted = promote_geom(output_type, data)
    try
        transformed = apply_transform(f, promoted, space)
    catch
    end
    world = apply_model(model, transformed, space)
    return promote_geom(output_type, world)
end

function unchecked_apply_model(model::Mat4, transformed::VecTypes{N, T}) where {N, T}
    p4d = to_ndim(Point4d, to_ndim(Point3d, transformed, 0), 1)
    p4d = model * p4d
    p4d = p4d ./ p4d[4]
    return to_ndim(Point{N, T}, p4d, NaN)
end
@inline function apply_model(model::Mat4, transformed::AbstractArray, space::Symbol)
    if space in (:data, :transformed)
        return unchecked_apply_model.((model,), transformed)
    else
        return transformed
    end
end
function apply_model(model::Mat4, transformed::VecTypes, space::Symbol)
    if space in (:data, :transformed)
        return unchecked_apply_model(model, transformed)
    else
        return transformed
    end
end
function apply_model(model::Mat4, transformed::Rect{N, T}, space::Symbol) where {N, T}
    if space in (:data, :transformed)
        bb = Rect{N, T}()
        if is_translation_scale_matrix(model)
            # With no rotation in model we can safely treat NaNs like this.
            # (And finite values as well, of course)
            scale = to_ndim(Vec{N, T}, Vec3(model[1, 1], model[2, 2], model[3, 3]), 1.0)
            trans = to_ndim(Vec{N, T}, Vec3(model[1, 4], model[2, 4], model[3, 4]), 0.0)
            mini = scale .* minimum(transformed) .+ trans
            maxi = scale .* maximum(transformed) .+ trans
            return Rect{N, T}(mini, maxi - mini)
        else
            for input in corners(transformed)
                output = unchecked_apply_model(model, input)
                bb = update_boundingbox(bb, output)
            end
        end
        return bb
    else
        return transformed
    end
end

promote_geom(::Type{<:VT}, x::VT) where {VT} = x
promote_geom(::Type{<:VT}, x::AbstractArray{<: VT}) where {VT} = x
promote_geom(::Type{<:VecTypes{N, T}}, x::Rect{N, T}) where {N, T} = x

promote_geom(output_type::Type{<:VecTypes}, x::VecTypes) = to_ndim(output_type, x, 0)
promote_geom(output_type::Type{<:VecTypes}, x::AbstractArray) = promote_geom.(output_type, x)
function promote_geom(output_type::Type{<:VecTypes}, x::T) where {T <: Rect}
    return T(promote_geom(output_type, minimum(x)), promote_geom(output_type, widths(x)))
end


"""
    apply_transform(f, data, space)
Apply the data transform func to the data if the space matches one
of the the transformation spaces (currently only :data is transformed)
"""
apply_transform(f, data, space) = to_value(space) === :data ? apply_transform(f, data) : data
function apply_transform(f::Observable, data::Observable, space::Observable)
    return lift((f, d, s)-> apply_transform(f, d, s), f, data, space)
end

"""
    apply_transform(f, data)
Apply the data transform func to the data
"""
apply_transform(f::typeof(identity), x) = x
# these are all ambiguity fixes
apply_transform(f::typeof(identity), x::AbstractArray) = x
apply_transform(f::typeof(identity), x::VecTypes) = x
apply_transform(f::typeof(identity), x::Number) = x
apply_transform(f::typeof(identity), x::ClosedInterval) = x

apply_transform(f::NTuple{2, typeof(identity)}, x) = x
apply_transform(f::NTuple{2, typeof(identity)}, x::AbstractArray) = x
apply_transform(f::NTuple{2, typeof(identity)}, x::VecTypes) = x
apply_transform(f::NTuple{2, typeof(identity)}, x::Number) = x
apply_transform(f::NTuple{2, typeof(identity)}, x::ClosedInterval) = x

apply_transform(f::NTuple{3, typeof(identity)}, x) = x
apply_transform(f::NTuple{3, typeof(identity)}, x::AbstractArray) = x
apply_transform(f::NTuple{3, typeof(identity)}, x::VecTypes) = x
apply_transform(f::NTuple{3, typeof(identity)}, x::Number) = x
apply_transform(f::NTuple{3, typeof(identity)}, x::ClosedInterval) = x

struct PointTrans{N, F}
    f::F
    function PointTrans{N}(f::F) where {N, F}
        if !hasmethod(f, Tuple{Point{N}})
            error("PointTrans with parameter N = $N must be applicable to an argument of type Point{$N}.")
        end
        new{N, F}(f)
    end
end

# PointTrans{N}(func::F) where {N, F} = PointTrans{N, F}(func)
Base.broadcastable(x::PointTrans) = (x,)

function apply_transform(f::PointTrans{N}, point::Point{N}) where N
    return f.f(point)
end

function apply_transform(f::PointTrans{N1}, point::Point{N2, T}) where {N1, N2, T}
    p_dim = to_ndim(Point{N1, T}, point, 0.0)
    p_trans = f.f(p_dim)
    if N1 < N2
        p_large = ntuple(i-> i <= N1 ? p_trans[i] : point[i], N2)
        return Point{N2, T}(p_large)
    else
        return to_ndim(Point{N2, T}, p_trans, 0.0)
    end
end

function apply_transform(f, data::AbstractArray)
    map(point -> apply_transform(f, point), data)
end

function apply_transform(f::Tuple{Any, Any}, point::VecTypes{2, T}) where T
    p1, p2 = point
    try
        p1 = f[1](p1)
    catch err
        @warn err
    end
    try
        p2 = f[2](p2)
    catch err
        @warn err
    end
    Point2{T}(p1, p2)
end
# ambiguity fix
apply_transform(f::NTuple{2, typeof(identity)}, point::VecTypes{2}) = point


function apply_transform(f::Tuple{Any, Any}, point::VecTypes{3})
    apply_transform((f..., identity), point)
end
# ambiguity fix
apply_transform(f::NTuple{2, typeof(identity)}, point::VecTypes{3}) = point

function apply_transform(f::Tuple{Any, Any, Any}, point::VecTypes{3, T}) where T
    p1, p2, p3 = point
    try
        p1 = f[1](p1)
    catch err
        @warn err
    end
    try
        p2 = f[2](p2)
    catch err
        @warn err
    end
    try
        p3 = f[3](p3)
    catch err
        @warn err
    end
    Point3{T}(p1, p2, p3)
end
# ambiguity fix
apply_transform(f::NTuple{3, typeof(identity)}, point::VecTypes{3}) = point


apply_transform(f, number::Number) = f(number)

function apply_transform(f::Observable, data::Observable)
    return lift((f, d)-> apply_transform(f, d), f, data)
end

apply_transform(f, itr::Pair) = apply_transform(f, itr[1]) => apply_transform(f, itr[2])
function apply_transform(f, itr::ClosedInterval)
    mini, maxi = extrema(itr)
    return apply_transform(f, mini) .. apply_transform(f, maxi)
end

function apply_transform(f, r::Rect)
    mi = minimum(r)
    ma = maximum(r)
    mi_t = apply_transform(f, mi)
    ma_t = apply_transform(f, ma)
    Rect(Vec(mi_t), Vec(ma_t .- mi_t))
end
function apply_transform(f::PointTrans, r::Rect)
    mi = minimum(r)
    ma = maximum(r)
    mi_t = apply_transform(f, Point(mi))
    ma_t = apply_transform(f, Point(ma))
    Rect(Vec(mi_t), Vec(ma_t .- mi_t))
end

# ambiguity fix
apply_transform(f::typeof(identity), r::Rect) = r
apply_transform(f::NTuple{2, typeof(identity)}, r::Rect) = r
apply_transform(f::NTuple{3, typeof(identity)}, r::Rect) = r

const pseudolog10 = ReversibleScale(
    x -> sign(x) * log10(abs(x) + 1),
    x -> sign(x) * (exp10(abs(x)) - 1);
    limits=(0f0, 3f0),
    name=:pseudolog10
)

Symlog10(hi) = Symlog10(-hi, hi)
function Symlog10(lo, hi)
    forward(x) = if x > 0
        x <= hi ? x / hi * log10(hi) : log10(x)
    elseif x < 0
        x >= lo ? x / abs(lo) * log10(abs(lo)) : -log10(abs(x))
    else
        x
    end
    inverse(x) = if x > 0
        l = log10(hi)
        x <= l ? x / l * hi : exp10(x)
    elseif x < 0
        l = -log10(abs(lo))
        x >= l ? x / l * abs(lo) : -exp10(abs(x))
    else
        x
    end
    return ReversibleScale(forward, inverse; limits=(0.0f0, 3.0f0), name=:Symlog10)
end

function inverse_transform(f)
    f⁻¹ = InverseFunctions.inverse(f)
    return f⁻¹ isa InverseFunctions.NoInverse ? nothing : f⁻¹  # nothing is for backwards compatibility
end
inverse_transform(F::Tuple) = map(inverse_transform, F)
inverse_transform(s::ReversibleScale) = s.inverse

function is_identity_transform(t)
    return t === identity || t isa Tuple && all(x-> x === identity, t)
end


################################################################################
### Polar Transformation
################################################################################

"""
    Polar(theta_as_x = true, clip_r = true, theta_0::Float64 = 0.0, direction::Int = +1, r0::Float64 = 0)

This struct defines a general polar-to-cartesian transformation, i.e.

```math
(r, θ) -> ((r - r₀) ⋅ \\cos(direction ⋅ (θ + θ₀)), (r - r₀) ⋅ \\sin(direction \\cdot (θ + θ₀)))
```

where θ is assumed to be in radians.

Controls:
- `theta_as_x = true` controls the order of incoming arguments. If true, a `Point2`
is interpreted as `(θ, r)`, otherwise `(r, θ)`.
- `clip_r = true` controls whether negative radii are clipped. If true, `r < 0`
produces `NaN`, otherwise they simply enter in the formula above as is. Note that
the inversion only returns `r ≥ 0`
- `theta_0 = 0` offsets angles by the specified amount.
- `direction = +1` inverts the direction of θ.
- `r0 = 0` offsets radii by the specified amount. Not that this will affect the
shape of transformed objects.
"""
struct Polar
    theta_as_x::Bool
    clip_r::Bool
    theta_0::Float64
    direction::Int
    r0::Float64

    function Polar(theta_0::Real = 0.0, direction::Int = +1, r0::Real = 0, theta_as_x::Bool = true, clip_r::Bool = true)
        return new(theta_as_x, clip_r, theta_0, direction, r0)
    end
end

Base.broadcastable(x::Polar) = (x,)

function apply_transform(trans::Polar, point::VecTypes{2, T}) where T <: Real
    if trans.theta_as_x
        θ, r = point
    else
        r, θ = point
    end
    r = r - trans.r0
    if trans.clip_r && (r < 0.0)
        return Point2{T}(NaN)
    end
    θ = trans.direction * (θ + trans.theta_0)
    y, x = r .* sincos(θ)
    return Point2{T}(x, y)
end

# Point2 may get expanded to Point3. In that case we leave z untransformed
function apply_transform(f::Polar, point::VecTypes{N2, T}) where {N2, T}
    p_dim = to_ndim(Point2{T}, point, 0.0)
    p_trans = apply_transform(f, p_dim)
    if 2 < N2
        p_large = ntuple(i-> i <= 2 ? p_trans[i] : point[i], N2)
        return Point{N2, T}(p_large)
    else
        return to_ndim(Point{N2, T}, p_trans, 0.0)
    end
end

# For bbox
function apply_transform(trans::Polar, bbox::Rect3d)
    if trans.theta_as_x
        θmin, rmin, zmin = minimum(bbox)
        θmax, rmax, zmax = maximum(bbox)
    else
        rmin, θmin, zmin = minimum(bbox)
        rmax, θmax, zmax = maximum(bbox)
    end
    bb2d = polaraxis_bbox((rmin, rmax), (θmin, θmax), trans.r0, trans.direction, trans.theta_0)
    o = minimum(bb2d); w = widths(bb2d)
    return Rect3d(to_ndim(Point3d, o, zmin), to_ndim(Vec3d, w, zmax - zmin))
end

function inverse_transform(trans::Polar)
    if trans.theta_as_x
        return Makie.PointTrans{2}() do point
            typeof(point)(
                mod(trans.direction * atan(point[2], point[1]) - trans.theta_0, 0..2pi),
                hypot(point[1], point[2]) + trans.r0
            )
        end
    else
        return Makie.PointTrans{2}() do point
            typeof(point)(
                hypot(point[1], point[2]) + trans.r0,
                mod(trans.direction * atan(point[2], point[1]) - trans.theta_0, 0..2pi)
            )
        end
    end
end


# this is a simplification which will only really work with non-rotated or
# scaled scene transformations, but for 2D scenes this should work well enough.
# and this way we can use the z-value as a means to shift the drawing order
# by translating e.g. the axis spines forward so they are not obscured halfway
# by heatmaps or images
# zvalue2d(x)::Float32 = Float32(Makie.translation(x)[][3] + zvalue2d(x.parent))
@inline zvalue2d(x)::Float32 = Float32(transformationmatrix(x)[][3, 4])
@inline zvalue2d(::Nothing)::Float32 = 0f0
