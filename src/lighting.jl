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
- All backends with `shading = FastShading` or `MultiLightShading`
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
attenuation parameters. Note that you may need to set the light intensity, i.e.
the light color to values greater than 1 to get satisfying results.

Availability:
- GLMakie with `shading = MultiLightShading`
- RPRMakie
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
    DirectionalLight(color, direction[, camera_relative = false])

A light type which simulates a distant light source with parallel light rays
going in the given `direction`.

Availability:
- All backends with `shading = FastShading` or `MultiLightShading`
"""
struct DirectionalLight <: AbstractLight
    color::Observable{RGBf}
    direction::Observable{Vec3f}

    # Usually a light source is placed in world space, i.e. unrelated to the
    # camera. As a default however, we want to make sure that an object is
    # always reasonably lit, which requires the light source to move with the
    # camera. To keep this in sync in WGLMakie, the calculation needs to happen
    # in javascript. This flag notives WGLMakie and other backends that this
    # calculation needs to happen.
    camera_relative::Bool

    DirectionalLight(col, dir, rel = false) = new(col, dir, rel)
end
light_type(::DirectionalLight) = LightType.DirectionalLight
light_color(l::DirectionalLight) = l.color[]


"""
    SpotLight(color, position, direction, angles)

Creates a spot light which illuminates objects in a light cone starting at
`position` pointing in `direction`. The opening angle is defined by an inner
and outer angle given in `angles`, between which the light intensity drops off.

Availability:
- GLMakie with `shading = MultiLightShading`
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

function default_shading!(plot, lights::Vector{<: AbstractLight})
    # if the plot does not have :shading we assume the plot doesn't support it
    haskey(plot.attributes, :shading) || return

    # Bad type
    shading = to_value(plot.attributes[:shading])
    if !(shading isa MakieCore.ShadingAlgorithm || shading === automatic)
        prev = shading
        if (shading isa Bool) && (shading == false)
            shading = NoShading
        else
            shading = automatic
        end
        @warn "`shading = $prev` is not valid. Use `automatic`, `NoShading`, `FastShading` or `MultiLightShading`. Defaulting to `$shading`."
    end

    # automatic conversion
    if shading === automatic
        ambient_count = 0
        dir_light_count = 0

        for light in lights
            if light isa AmbientLight
                ambient_count += 1
            elseif light isa DirectionalLight
                dir_light_count += 1
            elseif light isa EnvironmentLight
                continue
            else
                shading = MultiLightShading
                break
            end
            if ambient_count > 1 || dir_light_count > 1
                shading = MultiLightShading
                break
            end
        end

        if dir_light_count + ambient_count == 0
            shading = NoShading
        else
            shading = FastShading
        end
    end

    plot.attributes[:shading] = shading

    return
end