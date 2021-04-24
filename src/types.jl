const RGBAf0 = RGBA{Float32}
# Solution 1: strictly type fields
const TorVector{T} = Union{Vector{T}, T}

@enum Space Pixel Data

mutable struct Camera
    pixel_space::Observable{Mat4f0}
    view::Observable{Mat4f0}
    projection::Observable{Mat4f0}
    projectionview::Observable{Mat4f0}
    resolution::Observable{Vec2f0}
    eyeposition::Observable{Vec3f0}
    steering_nodes::Vector{Any}
end

function Camera()
    Camera(
        Observable(Mat4f0(I)),
        Observable(Mat4f0(I)),
        Observable(Mat4f0(I)),
        Observable(Mat4f0(I)),
        Observable(Vec2f0(0)),
        Observable(Vec3f0(1)),
        []
    )
end

function connect!(camera::Camera, pixel_area::Observable{FRect2D})
    on(pixel_area) do window_size
        nearclip = -10_000f0
        farclip = 10_000f0
        w, h = Float32.(widths(window_size))
        camera.pixel_space[] = orthographicprojection(0f0, w, 0f0, h, nearclip, farclip)
        camera.resolution[] = Vec2f0(w, h)
    end
end

struct Transformation
    parent::Base.RefValue{Any}
    translation::Observable{Vec3f0}
    scale::Observable{Vec3f0}
    rotation::Observable{Quaternionf0}
    model::Observable{Mat4f0}
    # data conversion node, for e.g. log / log10 etc
    transform_func::Observable{Any}
    function Transformation(translation, scale, rotation, model, transform_func)
        return new(
            Base.RefValue{Any}(),
            translation, scale, rotation, model, transform_func
        )
    end
end

function transformationmatrix(translation, scale)
    T = eltype(translation)
    T0, T1 = zero(T), one(T)
    Mat{4}(
        scale[1],T0,  T0,  T0,
        T0,  scale[2],T0,  T0,
        T0,  T0,  scale[3],T0,
        translation[1],translation[2],translation[3], T1
    )
end
function transformationmatrix(translation, scale, rotation::Quaternion)
    trans_scale = transformationmatrix(translation, scale)
    return trans_scale * Mat4f0(rotation)
end

function Transformation(transform_func=identity;
                        translation=Observable(Vec3f0(0)),
                        scale=Observable(Vec3f0(1)),
                        rotation=Observable(Quaternionf0(0, 0, 0, 1)))
    model = map(transformationmatrix, translation, scale, rotation)
    return Transformation(
        translation,
        scale,
        rotation,
        model,
        Observable{Any}(transform_func)
    )
end
