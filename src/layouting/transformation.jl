Base.parent(t::Transformation) = isassigned(t.parent) ? t.parent[] : nothing

function Observables.connect!(parent::Transformation, child::Transformation; connect_func=true)
    tfuncs = []
    obsfunc = on(parent.model; update=true) do m
        return child.parent_model[] = m
    end
    push!(tfuncs, obsfunc)
    if connect_func
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
        translation = Vec3f(0),
        scale = Vec3f(1),
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

scale(t::Transformable) = transformation(t).scale

scale!(t::Transformable, s) = (scale(t)[] = to_ndim(Vec3f, Float32.(s), 1))

"""
    scale!(t::Transformable, x, y)
    scale!(t::Transformable, x, y, z)
    scale!(t::Transformable, xyz)
    scale!(t::Transformable, xyz...)

Scale the given `Transformable` (a Scene or Plot) to the given arguments.
Can take `x, y` or `x, y, z`.
This is an absolute scaling, and there is no option to perform relative scaling.
"""
scale!(t::Transformable, xyz...) = scale!(t, xyz)

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
    rotate!(t::Transformable, axis_rot::AbstractFloat)
    rotate!(t::Transformable, axis_rot...)

Apply an absolute rotation to the transformable. Rotations are all internally converted to `Quaternion`s.
"""
rotate!(t::Transformable, axis_rot...) = rotate!(Absolute, t, axis_rot)
rotate!(t::Transformable, axis_rot::Quaternion) = rotate!(Absolute, t, axis_rot)
rotate!(t::Transformable, axis_rot::AbstractFloat) = rotate!(Absolute, t, axis_rot)

translation(t::Transformable) = transformation(t).translation

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

function translate!(::Type{T}, t::Transformable, trans) where T
    offset = to_ndim(Vec3f, Float32.(trans), 0)
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

function transform!(t::Transformable, x::Tuple{Symbol, <: Number})
    plane, dimval = string(x[1]), Float32(x[2])
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

transformationmatrix(x) = transformation(x).model
transformation(x::Attributes) = x.transformation[]
transform_func(x) = transform_func_obs(x)[]
transform_func_obs(x) = transformation(x).transform_func

"""
    apply_transform_and_model(plot, pos, output_type = Point3f)
    apply_transform_and_model(model, transfrom_func, pos, output_type = Point3f)


Applies the transform function and model matrix (i.e. transformations from
`translate!`, `rotate!` and `scale!`) to the given input
"""
function apply_transform_and_model(plot::AbstractPlot, pos, output_type = Point3f)
    return apply_transform_and_model(
        plot.model[], transform_func(plot), pos,
        to_value(get(plot, :space, :data)),
        output_type
    )
end
function apply_transform_and_model(model::Mat4f, f, pos::VecTypes, space = :data, output_type = Point3f)
    transformed = apply_transform(f, pos, space)
    p4d = to_ndim(Point4f, to_ndim(Point3f, transformed, 0), 1)
    p4d = model * p4d
    p4d = p4d ./ p4d[4]
    return to_ndim(output_type, p4d, NaN)
end
function apply_transform_and_model(model::Mat4f, f, positions::Vector, space = :data, output_type = Point3f)
    return map(positions) do pos
        apply_transform_and_model(model, f, pos, space, output_type)
    end
end

"""
    apply_transform(f, data, space)
Apply the data transform func to the data if the space matches one
of the the transformation spaces (currently only :data is transformed)
"""
apply_transform(f, data, space) = space === :data ? apply_transform(f, data) : data
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

function apply_transform(f::PointTrans{N1}, point::Point{N2}) where {N1, N2}
    p_dim = to_ndim(Point{N1, Float32}, point, 0.0)
    p_trans = f.f(p_dim)
    if N1 < N2
        p_large = ntuple(i-> i <= N1 ? p_trans[i] : point[i], N2)
        return Point{N2, Float32}(p_large)
    else
        return to_ndim(Point{N2, Float32}, p_trans, 0.0)
    end
end

function apply_transform(f, data::AbstractArray)
    map(point -> apply_transform(f, point), data)
end

function apply_transform(f::Tuple{Any, Any}, point::VecTypes{2})
    Point2{Float32}(
        f[1](point[1]),
        f[2](point[2]),
    )
end
# ambiguity fix
apply_transform(f::NTuple{2, typeof(identity)}, point::VecTypes{2}) = point


function apply_transform(f::Tuple{Any, Any}, point::VecTypes{3})
    apply_transform((f..., identity), point)
end
# ambiguity fix
apply_transform(f::NTuple{2, typeof(identity)}, point::VecTypes{3}) = point

function apply_transform(f::Tuple{Any, Any, Any}, point::VecTypes{3})
    Point3{Float32}(
        f[1](point[1]),
        f[2](point[2]),
        f[3](point[3]),
    )
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

inverse_transform(::typeof(identity)) = identity
inverse_transform(::typeof(log10)) = exp10
inverse_transform(::typeof(log2)) = exp2
inverse_transform(::typeof(log)) = exp
inverse_transform(::typeof(sqrt)) = x -> x ^ 2
inverse_transform(F::Tuple) = map(inverse_transform, F)
inverse_transform(::typeof(logit)) = logistic
inverse_transform(s::ReversibleScale) = s.inverse
inverse_transform(::Any) = nothing

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
- `theta_as_x = true` controls the order of incoming arguments. If true, a `Point2f`
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
    p_dim = to_ndim(Point2f, point, 0.0)
    p_trans = apply_transform(f, p_dim)
    if 2 < N2
        p_large = ntuple(i-> i <= 2 ? p_trans[i] : point[i], N2)
        return Point{N2, Float32}(p_large)
    else
        return to_ndim(Point{N2, Float32}, p_trans, 0.0)
    end
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
zvalue2d(x)::Float32 = Makie.translation(x)[][3] + zvalue2d(x.parent)
zvalue2d(::Nothing)::Float32 = 0f0
