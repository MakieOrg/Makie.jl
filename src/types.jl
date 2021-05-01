const RGBAf0 = RGBA{Float32}
# Solution 1: strictly type fields
const TorVector{T} = Union{Vector{T},T}

@enum Space Pixel Data

mutable struct Camera
    pixel_space::Observable{Mat4f}
    view::Observable{Mat4f}
    projection::Observable{Mat4f}
    projectionview::Observable{Mat4f}
    screen_area::Observable{Rect2D{Int}}
    eyeposition::Observable{Vec3f}
    steering_nodes::Vector{Any}
end

function Mat4f(x::UniformScaling)
    return Mat4f((
        1f0, 0f0, 0f0, 0f0,
        0f0, 1f0, 0f0, 0f0,
        0f0, 0f0, 1f0, 0f0,
        0f0, 0f0, 0f0, 1f0,
        ))
end


function Camera()
    Camera(
        Observable(Mat4f(I)),
        Observable(Mat4f(I)),
        Observable(Mat4f(I)),
        Observable(Mat4f(I)),
        Observable(Rect2D(0, 0, 0, 0)),
        Observable(Vec3f(1)),
        [],
    )
end

GeometryBasics.widths(x::Camera) = widths(x.screen_area[])

function connect!(camera::Camera, screen_area::Observable{Rect2D{Int}})
    on(screen_area) do window_size
        nearclip = -10_000.0f0
        farclip = 10_000.0f0
        w, h = Float32.(widths(window_size))
        camera.pixel_space[] = orthographicprojection(0.0f0, w, 0.0f0, h, nearclip, farclip)
        camera.screen_area[] = screen_area
    end
end

struct Transformation
    parent::Base.RefValue{Any}
    translation::Observable{Vec3f}
    scale::Observable{Vec3f}
    rotation::Observable{Quaternionf0}
    model::Observable{Mat4f}
    # data conversion node, for e.g. log / log10 etc
    transform_func::Observable{Any}
    function Transformation(translation, scale, rotation, model, transform_func)
        return new(
            Base.RefValue{Any}(),
            translation,
            scale,
            rotation,
            model,
            transform_func,
        )
    end
end

function transformationmatrix(translation, scale)
    T = eltype(translation)
    T0, T1 = zero(T), one(T)
    return Mat4{T}((
        T(scale[1]), T0, T0, T0,
        T0,T(scale[2]), T0, T0,
        T0, T0, T(scale[3]), T0,
        translation[1], translation[2], translation[3], T1
    ))
end

function transformationmatrix(translation, scale, rotation::Quaternion)
    trans_scale = transformationmatrix(translation, scale)
    return trans_scale * Mat4f(rotation)
end

function Transformation(
    transform_func = identity;
    translation = Observable(Vec3f(0)),
    scale = Observable(Vec3f(1)),
    rotation = Observable(Quaternionf0(0, 0, 0, 1)),
)
    model = map(transformationmatrix, translation, scale, rotation)
    return Transformation(
        translation,
        scale,
        rotation,
        model,
        Observable{Any}(transform_func),
    )
end
