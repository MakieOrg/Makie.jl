abstract type AbstractLight end

# TODO: probably need some kind of resize tracking?
# struct LightVector
#     lights::Vector{AbstractLight}
#     array_changed::Observable{Nothing}
# end

# for f in (push!, append!, setindex!, ...)
#     @eval function Base.($f)(lv::LightVector, args...; kwargs...)
#         output = ($f)(lv.lights, args...; kwargs...)
#         notify(lv.array_changed)
#         return output
#     end
# end


"""
    AmbientLight(color) <: AbstractLight

A simple ambient light that uniformly lights every object based on its light color.
"""
struct AmbientLight <: AbstractLight
    color::Observable{RGBf}
end

"""
    PointLight(position, color)

A point-like light source placed at the given `position` with the given light
`color`. This takes the direction of the light and the surface normals of the
object into account.
"""
struct PointLight <: AbstractLight
    position::Observable{Vec3f}
    radiance::Observable{RGBf} # TODO rename?
end

"""
    EnvironmentLight(intensity, image)

An environment Light, that uses a spherical environment map to provide lighting.
See: https://en.wikipedia.org/wiki/Reflection_mapping
"""
struct EnvironmentLight <: AbstractLight
    intensity::Observable{Float32}
    image::Observable{Matrix{RGBf}}
end


function get_one_light(lights, Typ)
    indices = findall(x-> x isa Typ, lights)
    isempty(indices) && return nothing
    if length(indices) > 1
        @warn("Only one light supported by backend right now. Using only first light")
    end
    return lights[indices[1]]
end

module LightType
    const UNDEFINED        = 0
    const Ambient          = 1
    const PointLight       = 2
    const DirectionalLight = 3
    const SpotLight        = 4
end

"""
    GenericGLLight

Conversion target for lights in GLMakie.
"""
struct GenericGLLight <: AbstractLight
    type::Int32
    color::RGBf  # include intensity
    position::Point3f # world space
    direction::Vec3f   # world space

    # intensity reduction following
    # f = 1 / (c + l * d + q * d * d) (constant, linear, quadratic, distance)
    # where (c, l, q) = attenuation_parameters
    attentuation_parameters::Vec3f
end

function GenericGLLight(;
        type = LightType.UNDEFINED, color = RGBf(1, 1, 1), position = Point3f(0),
        direction = Vec3f(0), attenuation_parameters = Vec3f(1, 0, 0)
    )
    GenericGLLight(type, color, position, direction, attenuation_parameters)
end

function GenericGLLight(light::AmbientLight)
    return GenericGLLight(type = LightType.Ambient, color = light.color[])
end

function GenericGLLight(light::PointLight)
    return GenericGLLight(type = LightType.PointLight, color = light.radiance[], position = light.position[])
end