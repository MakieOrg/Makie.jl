
function Transformation(transform_func=identity)
    flip = Node((false, false, false))
    scale = Node(Vec3f0(1))
    scale = lift(flip, scale) do f, s
        map((f, s)-> f ? -s : s, Vec(f), s)
    end
    translation, rotation, align = (
        Node(Vec3f0(0)),
        Node(Quaternionf0(0, 0, 0, 1)),
        Node(Vec2f0(0))
    )
    trans = nothing
    model = map_once(scale, translation, rotation, align, flip) do s, o, q, a, flip
        parent = if trans !== nothing && isassigned(trans.parent)
            boundingbox(trans.parent[])
        else
            nothing
        end
        transformationmatrix(o, s, q, a, flip, parent)
    end
    return Transformation(
        translation,
        scale,
        rotation,
        model,
        flip,
        align,
        Node{Any}(transform_func)
    )
end

function Transformation(scene::SceneLike)
    flip = Node((false, false, false))
    scale = Node(Vec3f0(1))
    translation, rotation, align = (
        Node(Vec3f0(0)),
        Node(Quaternionf0(0, 0, 0, 1)),
        Node(Vec2f0(0))
    )
    pmodel = transformationmatrix(scene)
    trans = nothing
    model = map_once(scale, translation, rotation, align, pmodel, flip) do s, o, q, a, p, f
        bb = if trans !== nothing && isassigned(trans.parent)
            boundingbox(trans.parent[])
        else
            nothing
        end
        return p * transformationmatrix(o, s, q, align, f, bb)
    end

    ptrans = transformation(scene)
    trans = Transformation(
        translation,
        scale,
        rotation,
        model,
        flip,
        align,
        copy(ptrans.transform_func)
    )
    return trans
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
        scene::SceneLike;
        translation = Vec3f0(0),
        scale = Vec3f0(1),
        rotation = 0.0,
    )
    translate!(scene, translation)
    scale!(scene, scale)
    rotate!(scene, rotation)
end



transformation(t::Scene) = t.transformation
transformation(t::AbstractPlot) = t.transformation
transformation(t::Transformation) = t

scale(t::Transformable) = transformation(t).scale

scale!(t::Transformable, s) = (scale(t)[] = to_ndim(Vec3f0, Float32.(s), 1))

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
    rotate!(scene::Transformable, axis_rot::Quaternion)
    rotate!(scene::Transformable, axis_rot::AbstractFloat)
    rotate!(scene::Transformable, axis_rot...)

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
    offset = to_ndim(Vec3f0, Float32.(t), 0)
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
        rotate!(scene, Vec3f0(1, 0, 0), 0.5pi)
        translate!(scene, 0, dimval, 0)
    else #yz plane
        r1 = qrotation(Vec3f0(0, 1, 0), 0.5pi)
        r2 = qrotation(Vec3f0(1, 0, 0), 0.5pi)
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
apply_transform(f::typeof(identity), position::Number) = position
apply_transform(f::typeof(identity), positions::AbstractArray) = positions
apply_transform(f::typeof(identity), positions::AbstractVector) = positions
apply_transform(f::typeof(identity), position::VecTypes) = position

struct PointTrans{N, F}
    f::F
end

PointTrans{N}(func::F) where {N, F} = PointTrans{N, F}(func)
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
    return map(point-> apply_transform(f, point), data)
end

function apply_transform(f::NTuple{N, Any}, point::VecTypes{N}) where {N, T}
    return Point{N, Float32}(ntuple(i-> apply_transform(f[i], point[i]), N))
end

apply_transform(f, number::Number) = f(number)

function apply_transform(f::Union{typeof(log), typeof(log10), typeof(log2)}, number::Number)
    if number <= 0.0
        return 0.0
    else
        return f(number)
    end
end

function apply_transform(f::Observable, data::Observable)
    return lift((f, d)-> apply_transform(f, d), f, data)
end

apply_transform(f, itr::Pair) = apply_transform(f, itr[1]) => apply_transform(f, itr[2])
function apply_transform(f, itr::ClosedInterval)
    mini, maxi = extrema(itr)
    return apply_transform(f, mini) .. apply_transform(f, maxi)
end
