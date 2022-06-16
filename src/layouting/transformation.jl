Base.parent(t::Transformation) = isassigned(t.parent) ? t.parent[] : nothing

function Transformation(transform_func=identity;
                        scale=Vec3f(1),
                        translation=Vec3f(0),
                        rotation=Quaternionf(0, 0, 0, 1))

    scale_o = convert(Observable{Vec3f}, scale)
    translation_o = convert(Observable{Vec3f}, translation)
    rotation_o = convert(Observable{Quaternionf}, rotation)
    model = map(transformationmatrix, translation_o, scale_o, rotation_o)
    return Transformation(
        translation_o,
        scale_o,
        rotation_o,
        model,
        convert(Observable{Any}, transform_func)
    )
end

function Transformation(transformable::Transformable;
                        scale=Vec3f(1),
                        translation=Vec3f(0),
                        rotation=Quaternionf(0, 0, 0, 1))

    scale_o = convert(Observable{Vec3f}, scale)
    translation_o = convert(Observable{Vec3f}, translation)
    rotation_o = convert(Observable{Quaternionf}, rotation)
    parent_transform = transformation(transformable)

    pmodel = parent_transform.model
    model = map(translation_o, scale_o, rotation_o, pmodel) do t, s, r, p
        return p * transformationmatrix(t, s, r)
    end

    trans = Transformation(
        translation_o,
        scale_o,
        rotation_o,
        model,
        copy(parent_transform.transform_func)
    )

    trans.parent[] = parent_transform
    return trans
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
        scene::Transformable;
        translation = Vec3f(0),
        scale = Vec3f(1),
        rotation = 0.0,
    )
    translate!(scene, to_value(translation))
    scale!(scene, to_value(scale))
    rotate!(scene, to_value(rotation))
end

function transform!(
        scene::Transformable, attributes::Union{Attributes, AbstractDict}
    )
    transform!(scene; attributes...)
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

rotation(scene::Transformable) = transformation(scene).rotation

function rotate!(::Type{T}, scene::Transformable, q) where T
    rot = convert_attribute(q, key"rotation"())
    if T === Accum
        rot1 = rotation(scene)[]
        rotation(scene)[] = rot1 * rot
    elseif T == Absolute
        rotation(scene)[] = rot
    else
        error("Unknown transformation: $T")
    end
end

"""
    rotate!(Accum, scene::Transformable, axis_rot...)

Apply a relative rotation to the Scene, by multiplying by the current rotation.
"""
rotate!(::Type{T}, scene::Transformable, axis_rot...) where T = rotate!(T, scene, axis_rot)

"""
    rotate!(t::Transformable, axis_rot::Quaternion)
    rotate!(t::Transformable, axis_rot::AbstractFloat)
    rotate!(t::Transformable, axis_rot...)

Apply an absolute rotation to the Scene. Rotations are all internally converted to `Quaternion`s.
"""
rotate!(scene::Transformable, axis_rot...) = rotate!(Absolute, scene, axis_rot)
rotate!(scene::Transformable, axis_rot::Quaternion) = rotate!(Absolute, scene, axis_rot)
rotate!(scene::Transformable, axis_rot::AbstractFloat) = rotate!(Absolute, scene, axis_rot)

translation(scene::Transformable) = transformation(scene).translation

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

function translate!(::Type{T}, scene::Transformable, t) where T
    offset = to_ndim(Vec3f, Float32.(t), 0)
    if T === Accum
        translation(scene)[] = translation(scene)[] .+ offset
    elseif T === Absolute
        translation(scene)[] = offset
    else
        error("Unknown translation type: $T")
    end
end
"""
    translate!(scene::Transformable, xyz::VecTypes)
    translate!(scene::Transformable, xyz...)

Apply an absolute translation to the Scene, translating it to `x, y, z`.
"""
translate!(scene::Transformable, xyz::VecTypes) = translate!(Absolute, scene, xyz)
translate!(scene::Transformable, xyz...) = translate!(Absolute, scene, xyz)

"""
    translate!(Accum, scene::Transformable, xyz...)

Translate the scene relative to its current position.
"""
translate!(::Type{T}, scene::Transformable, xyz...) where T = translate!(T, scene, xyz)

function transform!(scene::Transformable, x::Tuple{Symbol, <: Number})
    plane, dimval = string(x[1]), Float32(x[2])
    if length(plane) != 2 || (!all(x-> x in ('x', 'y', 'z'), plane))
        error("plane needs to define a 2D plane in xyz. It should only contain 2 symbols out of (:x, :y, :z). Found: $plane")
    end
    if all(x-> x in ('x', 'y'), plane) # xy plane
        translate!(scene, 0, 0, dimval)
    elseif all(x-> x in ('x', 'z'), plane) # xz plane
        rotate!(scene, Vec3f(1, 0, 0), 0.5pi)
        translate!(scene, 0, dimval, 0)
    else #yz plane
        r1 = qrotation(Vec3f(0, 1, 0), 0.5pi)
        r2 = qrotation(Vec3f(1, 0, 0), 0.5pi)
        rotate!(scene,  r2 * r1)
        translate!(scene, dimval, 0, 0)
    end
    scene
end

transformationmatrix(x) = transformation(x).model

transform_func(x) = transform_func_obs(x)[]
transform_func_obs(x) = transformation(x).transform_func

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

function apply_transform(f::PointTrans{N}, point::VecTypes{N}) where N
    return f.f(point)
end

function apply_transform(f::PointTrans{N1}, point::VecTypes{N2}) where {N1, N2}
    p_dim = to_ndim(Point{N1, Float32}, point, 0.0)
    p_trans = f.f(p_dim)
    if N1 < N2
        p_large = ntuple(i-> i <= N1 ? p_trans[i] : point[i], N2)
        return Point{N2, Float32}(p_large)
    else
        return to_ndim(Point{N2, Float32}, p_trans, 0.0)
    end
end

# The following methods are based on logic from the PROJ library,
# which essentially try to find the true bounding box of the given
# rectangle after transformation, by sampling from a regular grid
# bounded by the rectangle in input space.

"""
    Makie._DEFAULT_RECT_TRANSFORM_DENSITY = Ref{Int}(21)

This controls the density of the grid within the default implementation of
`apply_transform(f::PointTrans{2}, rect::Rect{2, T})`.  Set it by:
```julia
Makie._DEFAULT_RECT_TRANSFORM_DENSITY[] = new_transform_density::Int
```
"""
const _DEFAULT_RECT_TRANSFORM_DENSITY = Ref{Int}(21)

function apply_transform(f::PointTrans{2}, rect::Rect{2, T}) where T
    N = _DEFAULT_RECT_TRANSFORM_DENSITY[]
    umins = fill(T(Inf),  2)
    umaxs = fill(T(-Inf), 2)
    xmins = minimum(rect)
    xmaxs = maximum(rect)
    for x in range(xmins[1], xmaxs[2]; length = N)
        for y in range(xmins[2], xmaxs[2]; length = N)
            u = Makie.apply_transform(f, Point(x, y))
            for i in 1:2
                umins[i] = min(umins[i], u[i])
                umaxs[i] = max(umaxs[i], u[i])
            end
        end
    end

    return Rect(Vec2(umins), Vec2(umaxs .- umins))
end

function apply_transform(f::PointTrans{3}, rect::Rect{3, T}) where T
    N = _DEFAULT_RECT_TRANSFORM_DENSITY[]
    umins = fill(T(Inf),  3)
    umaxs = fill(T(-Inf), 3)
    xmins = minimum(rect)
    xmaxs = maximum(rect)
    for x in range(xmins[1], xmaxs[2]; length = N)
        for y in range(xmins[2], xmaxs[2]; length = N)
            for z in range(xmins[3], xmaxs[3]; length = N)
                u = Makie.apply_transform(f, Point(x, y, z))
                for i in 1:3
                    umins[i] = min(umins[i], u[i])
                    umaxs[i] = max(umaxs[i], u[i])
                end
            end
        end
    end

    return Rect(Vec3(umins), Vec3(umaxs .- umins))
end


function apply_transform(f, data::AbstractArray)
    map(point-> apply_transform(f, point), data)
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


pseudolog10(x) = sign(x) * log10(abs(x) + 1)
inv_pseudolog10(x) = sign(x) * (exp10(abs(x)) - 1)

struct Symlog10
    low::Float64
    high::Float64
    function Symlog10(low, high)
        if !(low < 0 && high > 0)
            error("Low bound needs to be smaller than 0 and high bound larger than 0. You gave $low, $high.")
        end
        new(Float64(low), Float64(high))
    end
end

Symlog10(x) = Symlog10(-x, x)

function (s::Symlog10)(x)
    if x > 0
        x <= s.high ? x / s.high * log10(s.high) : log10(x)
    elseif x < 0
        x >= s.low ? x / abs(s.low) * log10(abs(s.low)) : sign(x) * log10(abs(x))
    else
        x
    end
end

function inv_symlog10(x, low, high)
    if x > 0
        l = log10(high)
        x <= l ? x / l * high : exp10(x)
    elseif x < 0
        l = sign(x) * log10(abs(low))
        x >= l ? x / l * abs(low) : sign(x) * exp10(abs(x))
    else
        x
    end
end

inverse_transform(::typeof(identity)) = identity
inverse_transform(::typeof(log10)) = exp10
inverse_transform(::typeof(log)) = exp
inverse_transform(::typeof(log2)) = exp2
inverse_transform(::typeof(sqrt)) = x -> x ^ 2
inverse_transform(::typeof(pseudolog10)) = inv_pseudolog10
inverse_transform(F::Tuple) = map(inverse_transform, F)
inverse_transform(::typeof(logit)) = logistic
inverse_transform(s::Symlog10) = x -> inv_symlog10(x, s.low, s.high)
inverse_transform(s) = nothing

function is_identity_transform(t)
    return t === identity || t isa Tuple && all(x-> x === identity, t)
end


# this is a simplification which will only really work with non-rotated or
# scaled scene transformations, but for 2D scenes this should work well enough.
# and this way we can use the z-value as a means to shift the drawing order
# by translating e.g. the axis spines forward so they are not obscured halfway
# by heatmaps or images
zvalue2d(x)::Float32 = Makie.translation(x)[][3] + zvalue2d(x.parent)
zvalue2d(::Nothing)::Float32 = 0f0
