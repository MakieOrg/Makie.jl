
function Transformation()
    flip = node(:flip, (false, false, false))
    scale = node(:scale, Vec3f0(1))
    scale = map(flip, scale) do f, s
        map((f, s)-> f ? -s : s, Vec(f), s)
    end
    translation, rotation, align = (
        node(:translation, Vec3f0(0)),
        node(:rotation, Quaternionf0(0, 0, 0, 1)),
        node(:align, Vec2f0(0))
    )
    model = map_once(scale, translation, rotation, align) do s, o, q, a
        transformationmatrix(o, s, q)
    end
    Transformation(
        translation,
        scale,
        rotation,
        model,
        flip,
        align,
        signal_convert(Node{Any}, identity)
    )
end

function Transformation(scene::SceneLike)
    flip = node(:flip, (false, false, false))
    scale = node(:scale, Vec3f0(1))
    scale = map(flip, scale) do f, s
        map((f, s)-> f ? -s : s, Vec(f), s)
    end
    translation, rotation, align = (
        node(:translation, Vec3f0(0)),
        node(:rotation, Quaternionf0(0, 0, 0, 1)),
        node(:align, Vec2f0(0))
    )
    pmodel = modelmatrix(scene)
    model = map_once(scale, translation, rotation, align, pmodel) do s, o, q, a, p
        p * transformationmatrix(o, s, q)
    end
    Transformation(
        translation,
        scale,
        rotation,
        model,
        flip,
        align,
        signal_convert(Node{Any}, identity)
    )
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
scale!(t::Transformable, xyz...) = scale!(t, xyz)

rotation(scene::Transformable) = transformation(scene).rotation
function rotate!(::Type{T}, scene::Transformable, q) where T
    rot = convert_attribute(q, key"rotation"())
    if T === Accum
        rot1 = rotation(scene)[]
        rotation(scene)[] = qmul(rot1, rot)
    elseif T == Absolute
        rotation(scene)[] = rot
    else
        error("Unknown transformation: $T")
    end
end

rotate!(::Type{T}, scene::Transformable, axis_rot...) where T = rotate!(T, scene, axis_rot)
rotate!(scene::Transformable, axis_rot...) = rotate!(Absolute, scene, axis_rot)
rotate!(scene::Transformable, axis_rot::Quaternion) = rotate!(Absolute, scene, axis_rot)
rotate!(scene::Transformable, axis_rot::AbstractFloat) = rotate!(Absolute, scene, axis_rot)

translation(scene::Transformable) = transformation(scene).translation

struct Accum end; struct Absolute end

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
translate!(scene::Transformable, xyz::VecTypes) = translate!(Absolute, scene, xyz)
translate!(scene::Transformable, xyz...) = translate!(Absolute, scene, xyz)
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
        q1 = qrotation(Vec3f0(1, 0, 0), -0.5pi)
        q2 = qrotation(Vec3f0(0, 0, 1), 0.5pi)
        rotate!(scene, q2 * q1)
        translate!(scene, dimval, 0, 0)
    end
    scene
end

modelmatrix(x) = transformation(x).model
