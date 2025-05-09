abstract type AbstractLight end

# GLMakie interface

# These need to match up with light shaders to differentiate light types
module LightType
    const UNDEFINED        = 0
    # const Ambient          = 1
    const PointLight       = 2
    const DirectionalLight = 3
    const SpotLight        = 4
    const RectLight        = 5
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
    color::RGBf
    position::Vec3f
    attenuation::Vec2f
end

# no attenuation
function PointLight(color::Colorant, position::VecTypes{3})
    return PointLight(color, position, Vec2f(0))
end
# automatic attenuation
function PointLight(color::Colorant, position::VecTypes{3}, range::Real)
    return PointLight(color, position, default_attenuation(range))
end

light_type(::PointLight) = LightType.PointLight
light_color(l::PointLight) = l.color

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
    color::RGBf
    direction::Vec3f

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
light_color(l::DirectionalLight) = l.color


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
    color::RGBf
    position::Vec3f
    direction::Vec3f
    angles::Vec2f
end

light_type(::SpotLight) = LightType.SpotLight
light_color(l::SpotLight) = l.color


"""
    EnvironmentLight(intensity, image)

An environment light that uses a spherical environment map to provide lighting.
See: https://en.wikipedia.org/wiki/Reflection_mapping

Availability:
- RPRMakie
"""
struct EnvironmentLight <: AbstractLight
    intensity::Float32
    image::Matrix{RGBf}
end

"""
    RectLight(color, r::Rect2[, direction = -normal])
    RectLight(color, center::Point3f, b1::Vec3f, b2::Vec3f[, direction = -normal])

Creates a RectLight with a given color. The first constructor derives the light
from a `Rect2` extending in x and y directions. The second specifies the `center`
of the rect (or more accurately parallelogram) with `b1` and `b2` specifying the
width and height vectors (including scale).

Note that RectLight implements `translate!`, `rotate!` and `scale!` to simplify
adjusting the light.

Availability:
- GLMakie with `Shading = MultiLightShading`
"""
struct RectLight <: AbstractLight
    color::RGBf
    position::Point3f
    u1::Vec3f
    u2::Vec3f
    direction::Vec3f
end

RectLight(color, pos, u1, u2) = RectLight(color, pos, u1, u2, -normalize(cross(u1, u2)))
function RectLight(color, r::Rect2)
    mini = minimum(r); ws = widths(r)
    position = to_ndim(Point3f, mini + 0.5 * ws, 0)
    u1 = Vec3f(ws[1], 0, 0)
    u2 = Vec3f(0, ws[2], 0)
    return RectLight(color, position, u1, u2, normalize(Vec3f(0,0,-1)))
end

# Implement Transformable interface (more or less) to simplify working with
# RectLights

# function translate!(::Type{T}, l::RectLight, v) where T
#     offset = to_ndim(Vec3f, Float32.(v), 0)
#     if T === Accum
#         l.position[] = l.position[] + offset
#     elseif T === Absolute
#         l.position[] = offset
#     else
#         error("Unknown translation type: $T")
#     end
# end
# translate!(l::RectLight, v) = translate!(Absolute, l, v)

# function rotate!(l::RectLight, q...)
#     rot = convert_attribute(q, key"rotation"())
#     l.u1[] = rot * l.u1[]
#     l.u2[] = rot * l.u2[]
#     l.direction[] = rot * l.direction[]
# end

# function scale!(::Type{T}, l::RectLight, s) where T
#     scale = to_ndim(Vec2f, Float32.(s), 0)
#     if T === Accum
#         l.u1[] = scale[1] * l.u1[]
#         l.u2[] = scale[2] * l.u2[]
#     elseif T === Absolute
#         l.u1[] = scale[1] * normalize(l.u1[])
#         l.u2[] = scale[2] * normalize(l.u2[])
#     else
#         error("Unknown translation type: $T")
#     end
# end
# scale!(l::RectLight, x::Real, y::Real) = scale!(Accum, l, Vec2f(x, y))
# scale!(l::RectLight, xy::VecTypes) = scale!(Accum, l, xy)


light_type(::RectLight) = LightType.RectLight
light_color(l::RectLight) = l.color

################################################################################

function add_light_computation!(graph, lights)
    # TODO: Can we tear apart the old system and change each light to contain
    # no Observables?

    idx = findfirst(light -> light isa AmbientLight, lights)
    ambient_color = isnothing(idx) ? RGBf(0,0,0) : lights[idx].color

    filtered_lights = filter(light -> !isa(light, AmbientLight), lights)
    if length(lights) - length(filtered_lights) > 1
        @error("Only one AmbientLights is allowed. Skipping AmbientLights beyond the first.")
    end

    # TODO: defaults
    add_input!(graph, :ambient_color, ambient_color)
    add_input!(graph, :lights, convert(Vector{AbstractLight}, filtered_lights))

    register_computation!(
        fast_light_computation, graph,
        [:lights, :eye_to_world], # camera view matrix, not space adjusted plot matrix (right?)
        [:dirlight_color, :dirlight_direction, :dirlight_cam_relative, :dirlight_final_direction]
    )

    register_computation!(graph, [:lights], [:lighting_mode]) do (lights,), changed, cached
        is_fast = (length(lights) == 0) || (lights[1] isa DirectionalLight)
        return (ifelse(is_fast, FastShading, MultiLightShading), )
    end
end

function fast_light_computation(inputs, changed, cached)
    lights, iview = inputs
    idx = findfirst(light -> light isa DirectionalLight, lights)

    if idx === nothing && cached === nothing
        return (RGBf(0,0,0), Vec3f(0), true, Vec3f(0))
    else
        light = lights[idx]::DirectionalLight
        color = light.color
        dir = light.direction
        cam_relative = light.camera_relative
        final_dir = cam_relative ? iview[Vec(1,2,3), Vec(1,2,3)] * dir : dir
        return (color, Vec3f(dir), cam_relative, Vec3f(final_dir))
    end

    return nothing
end

# These return the number of parameter slots they used
push_parameters!(parameters, light::AbstractLight, iview) = push_parameters!(parameters, light)

function push_parameters!(parameters, light::PointLight)
    push!(parameters, light.position..., light.attenuation...)
end

function push_parameters!(parameters, light::DirectionalLight, iview)
    dir = light.direction
    if light.camera_relative
        dir = iview[Vec(1,2,3), Vec(1,2,3)] * dir
    end
    push!(parameters, normalize(dir)...)
end

function push_parameters!(parameters, light::SpotLight)
    push!(parameters, light.position..., normalize(light.direction)..., cos.(light.angles)...)
end

function push_parameters!(parameters, light::RectLight)
    push!(parameters, light.position..., light.u1..., light.u2..., normalize(light.direction)...)
end

light_parameter_count(::PointLight) = 5
light_parameter_count(::DirectionalLight) = 3
light_parameter_count(::SpotLight) = 8
light_parameter_count(::RectLight) = 12

function register_multi_light_computation(scene, MAX_LIGHTS, MAX_PARAMS)
    # TODO: Maybe be smarter with view and DirectionalLight?
    # I.e. only apply and update them, not all lights?
    # Though the array will need to be pushed to the gpu as long as any are present anyway...
    register_computation!(
            scene.compute, [:lights, :eye_to_world], [:N_lights, :light_types, :light_colors, :light_parameters]
        ) do (lights, iview), changed, cached

        n_lights = 0
        n_params = 0
        for light in lights
            n = light_parameter_count(light)
            if n_lights + 1 > MAX_LIGHTS
                @warn "Exceeded the maximum number of lights ($(n_lights + 1) > $MAX_LIGHTS). Skipping lights beyond number $n_lights."
                break
            elseif n_params + n > MAX_PARAMS
                @warn "Exceeded the maximum number of light parameters ($(n_params + n) > $MAX_PARAMS). Skipping lights beyond number $n_lights."
                break
            end
            n_lights += 1
            n_params += n
        end

        usable_lights = view(lights, 1:n_lights)
        types = light_type.(usable_lights)
        colors = light_color.(usable_lights)
        parameters = Float32[]
        foreach(light -> push_parameters!(parameters, light, iview), usable_lights)

        return (n_lights, types, colors, parameters)
    end
end


################################################################################


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
        @warn "`shading = $prev` is not valid. Use `Makie.automatic`, `NoShading`, `FastShading` or `MultiLightShading`. Defaulting to `$shading`."
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
                plot.attributes[:shading] = MultiLightShading
                return
            end
            if ambient_count > 1 || dir_light_count > 1
                plot.attributes[:shading] = MultiLightShading
                return
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