abstract type AbstractLight end

# GLMakie interface

# These need to match up with light shaders to differentiate light types
module LightType
    const UNDEFINED        = 0
    const Ambient          = 1
    const PointLight       = 2
    const DirectionalLight = 3
    const SpotLight        = 4
end

# always implement
light_type(::AbstractLight) = LightType.UNDEFINED

# TODO: rethink these
# implement as needed (keep types)
light_color(::AbstractLight) = RGBf(0, 0, 0)
light_position(::AbstractLight) = Vec3f(0)
light_direction(::AbstractLight) = Vec3f(0)
light_parameters(::AbstractLight) = Vec3f(0) # extra data passthrough


"""
    AmbientLight(color) <: AbstractLight

A simple ambient light that uniformly lights every object based on its light color.
"""
struct AmbientLight <: AbstractLight
    color::Observable{RGBf}
end

light_type(::AmbientLight) = LightType.Ambient
light_color(l::AmbientLight) = l.color[]


"""
    PointLight(color, position)

A point-like light source placed at the given `position` with the given light
`color`.
"""
struct PointLight <: AbstractLight
    color::Observable{RGBf}
    position::Observable{Vec3f}
    attenuation::Observable{Vec2f}
end

# no attenuation
function PointLight(color::Union{Colorant, Observable{<: Colorant}}, position::Union{VecTypes{3}, Observable{<: VecTypes{3}}})
    return PointLight(color, position, Vec2f(0))
end
# automatic attenuation
function PointLight(color::Union{Colorant, Observable{<: Colorant}}, position::Union{VecTypes{3}, Observable{<: VecTypes{3}}}, range::Real)
    return PointLight(color, position, default_attenuation(range))
end

@deprecate PointLight(position::Union{VecTypes{3}, Observable{<: VecTypes{3}}}, color::Union{Colorant, Observable{<: Colorant}}) PointLight(color, position)

light_type(::PointLight) = LightType.PointLight
light_color(l::PointLight) = l.color[]
light_position(l::PointLight) = l.position[]
light_parameters(l::PointLight) = to_ndim(Vec3f, l.attenuation[], 0)

# fit of values used on learnopengl/ogre3d
function default_attenuation(range::Real)
    return Vec2f(
        4.690507869767646 * range ^ -1.009712247799057,
        82.4447791934059 * range ^ -2.0192061630628966
    )
end


"""
    DirectionalLight(color, direction)

A light type which simulates a distant light source with parallel light rays
going in the given `direction`.
"""
struct DirectionalLight <: AbstractLight
    color::Observable{RGBf}
    direction::Observable{Vec3f}
end

light_type(::DirectionalLight) = LightType.DirectionalLight
light_color(l::DirectionalLight) = l.color[]
light_direction(l::DirectionalLight) = l.direction[]


"""
    SpotLight(color, position, direction, angles)

Creates a spot light which illuminates objects in a light cone starting at
`position` pointing in `direction`. The opening angle is defined by an inner
and outer angle in `angles` between which the light intensity drops off.
"""
struct SpotLight <: AbstractLight
    color::Observable{RGBf}
    position::Observable{Vec3f}
    direction::Observable{Vec3f}
    angles::Observable{Vec2f}
end

light_type(::SpotLight) = LightType.SpotLight
light_color(l::SpotLight) = l.color[]
light_position(l::SpotLight) = l.position[]
light_direction(l::SpotLight) = l.direction[]
light_parameters(l::SpotLight) = l.angles[]


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
    return lights[indices[1]]
end