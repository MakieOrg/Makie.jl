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

# Each light should implement
light_type(::AbstractLight) = LightType.UNDEFINED
light_color(::AbstractLight) = RGBf(0, 0, 0)
# Other attributes need to be handled explicitly in backends


"""
    AmbientLight(color) <: AbstractLight

A simple ambient light that uniformly lights every object based on its light color.

Availability:
- All backends with `shading != :none`
"""
struct AmbientLight <: AbstractLight
    color::Observable{RGBf}
end

light_type(::AmbientLight) = LightType.Ambient
light_color(l::AmbientLight) = l.color[]


"""
    PointLight(color, position[, attenuation = Vec2f(0)])
    PointLight(color, position, range::Real)

A point-like light source placed at the given `position` with the given light
`color`.

Optionally an attenuation parameter can be used to reduce the brightness of the
light source with distance. The reduction is given by
`1 / (1 + attenuation[1] * distance + attenuation[2] * distance^2)`.
Alternatively you can pass a light `range` to generate matching default
attenuation parameters.

Availability:
- Without attenuation: All backends with `shading != :none`
- With attenuation: GLMakie with `shading = :verbose`
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

Availability:
- GLMakie with `shading = :verbose`
- RPRMakie
"""
struct DirectionalLight <: AbstractLight
    color::Observable{RGBf}
    direction::Observable{Vec3f}
end

light_type(::DirectionalLight) = LightType.DirectionalLight
light_color(l::DirectionalLight) = l.color[]


"""
    SpotLight(color, position, direction, angles)

Creates a spot light which illuminates objects in a light cone starting at
`position` pointing in `direction`. The opening angle is defined by an inner
and outer angle given in `angles`, between which the light intensity drops off.

Availability:
- GLMakie with `shading = :verbose`
- RPRMakie
"""
struct SpotLight <: AbstractLight
    color::Observable{RGBf}
    position::Observable{Vec3f}
    direction::Observable{Vec3f}
    angles::Observable{Vec2f}
end

light_type(::SpotLight) = LightType.SpotLight
light_color(l::SpotLight) = l.color[]


"""
    EnvironmentLight(intensity, image)

An environment light that uses a spherical environment map to provide lighting.
See: https://en.wikipedia.org/wiki/Reflection_mapping

Availability:
- RPRMakie
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