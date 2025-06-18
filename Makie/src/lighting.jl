abstract type AbstractLight end

# GLMakie interface

# These need to match up with light shaders to differentiate light types
module LightType
    const UNDEFINED = 0
    # const Ambient          = 1
    const PointLight = 2
    const DirectionalLight = 3
    const SpotLight = 4
    const RectLight = 5
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
        4.690507869767646 * range^-1.009712247799057,
        82.4447791934059 * range^-2.0192061630628966
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
    return RectLight(color, position, u1, u2, normalize(Vec3f(0, 0, -1)))
end

# Implement Transformable interface (more or less) to simplify working with
# RectLights

function translate(::Type{T}, l::RectLight, v) where {T}
    offset = to_ndim(Vec3f, Float32.(v), 0)
    pos = l.position
    if T === Accum
        pos += offset
    elseif T === Absolute
        pos = offset
    else
        error("Unknown translation type: $T")
    end
    return RectLight(l.color, pos, l.u1, l.u2, l.direction)
end
translate(l::RectLight, v) = translate(Absolute, l, v)

function rotate(l::RectLight, q...)
    rot = convert_attribute(q, key"rotation"())
    u1 = rot * l.u1
    u2 = rot * l.u2
    direction = rot * l.direction
    return RectLight(l.color, l.position, u1, u2, direction)
end

function scale(::Type{T}, l::RectLight, s) where {T}
    scale = to_ndim(Vec2f, Float32.(s), 0)
    u1 = l.u1; u2 = l.u2
    if T === Accum
        u1 = scale[1] * u1
        u2 = scale[2] * u2
    elseif T === Absolute
        u1 = scale[1] * normalize(u1)
        u2 = scale[2] * normalize(u2)
    else
        error("Unknown translation type: $T")
    end
    return RectLight(l.color, l.position, u1, u2, l.direction)
end
scale(l::RectLight, x::Real, y::Real) = scale(Accum, l, Vec2f(x, y))
scale(l::RectLight, xy::VecTypes) = scale(Accum, l, xy)


light_type(::RectLight) = LightType.RectLight
light_color(l::RectLight) = l.color

################################################################################

function add_light_computation!(graph, scene, lights)
    idx = findfirst(light -> light isa AmbientLight, lights)
    ambient_color = isnothing(idx) ? RGBf(0, 0, 0) : lights[idx].color

    filtered_lights = filter(light -> !isa(light, AmbientLight), lights)
    if length(lights) - length(filtered_lights) > 1
        @error("Only one AmbientLights is allowed. Skipping AmbientLights beyond the first.")
    end

    add_input!((k, c) -> RGBf(to_color(c)), graph, :ambient_color, ambient_color)
    add_input!(graph, :lights, convert(Vector{AbstractLight}, filtered_lights))
    add_input!(graph, :shading, get(scene.theme, :shading, automatic))
    graph[:shading].value = RefValue{Any}(nothing) # allow shading to switch between automatic and ShadingAlgorithm

    map!(graph, :lights, [:dirlight_color, :dirlight_direction, :dirlight_cam_relative]) do lights
        local idx
        idx = findfirst(light -> light isa DirectionalLight, lights)
        if idx === nothing
            return (RGBf(0, 0, 0), Vec3f(0), true)
        else
            light = lights[idx]::DirectionalLight
            color = light.color
            dir = normalize(Vec3f(light.direction))
            cam_relative = light.camera_relative
            return (color, dir, cam_relative)
        end
    end

    # Split this to avoid updating WGLMakie
    # camera view matrix, not space adjusted plot matrix (right?)
    map!(graph, [:dirlight_direction, :dirlight_cam_relative, :eye_to_world], :dirlight_final_direction) do dir, cam_relative, iview
        final_dir = cam_relative ? Vec3f(iview[Vec(1, 2, 3), Vec(1, 2, 3)] * dir) : dir
        return final_dir
    end

    return
end

# shading is a compile time variable for robjs, but it is allowed to change
# when the robj is recompiled (e.g. screen reopened) so we make it dynamic
# here. It should not be used outside of renderobject construction
function get_shading_mode(scene)
    graph = scene.compute
    if !haskey(graph, :lighting_mode)
        register_computation!(graph, Symbol[:shading, :lights], [:lighting_mode]) do (shading, _lights), changed, cached
            mode = if shading === automatic
                lights = filter(l -> !isa(l, EnvironmentLight), _lights)
                is_fast = length(lights) == 0 || (length(lights) == 1 && lights[1] isa DirectionalLight)
                ifelse(is_fast, FastShading, MultiLightShading)
            else
                shading
            end::Makie.ShadingAlgorithm
            return (mode,)
        end
    end
    return graph[:lighting_mode][]
end

# These return the number of parameter slots they used
push_parameters!(parameters, light::AbstractLight, iview) = push_parameters!(parameters, light)

function push_parameters!(parameters, light::PointLight)
    return push!(parameters, light.position..., light.attenuation...)
end

function push_parameters!(parameters, light::DirectionalLight, iview)
    dir = light.direction
    if light.camera_relative
        dir = iview[Vec(1, 2, 3), Vec(1, 2, 3)] * dir
    end
    return push!(parameters, normalize(dir)...)
end

function push_parameters!(parameters, light::SpotLight)
    return push!(parameters, light.position..., normalize(light.direction)..., cos.(light.angles)...)
end

function push_parameters!(parameters, light::RectLight)
    return push!(parameters, light.position..., light.u1..., light.u2..., normalize(light.direction)...)
end

light_parameter_count(::PointLight) = 5
light_parameter_count(::DirectionalLight) = 3
light_parameter_count(::SpotLight) = 8
light_parameter_count(::RectLight) = 12

function register_multi_light_computation(scene, MAX_LIGHTS, MAX_PARAMS)
    # TODO: Maybe be smarter with view and DirectionalLight?
    # I.e. only apply and update them, not all lights?
    # Though the array will need to be pushed to the gpu as long as any are present anyway...
    return register_computation!(
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
        types = Int32.(light_type.(usable_lights))
        colors = RGBf.(light_color.(usable_lights))
        parameters = Float32[]
        foreach(light -> push_parameters!(parameters, light, iview), usable_lights)

        return (n_lights, types, colors, parameters)
    end
end


################################################################################
# User Interface

"""
    set_shading_algorithm!(scenelike, mode::ShadingAlgorithm)

Sets the shading algorithm of the scene. This is only valid before displaying these scene.
"""
set_shading_algorithm!(scene, mode) = set_shading_algorithm!(get_scene(scene).compute, mode)
function set_shading_algorithm!(graph::ComputeGraph, mode::Union{Automatic, Makie.ShadingAlgorithm})
    if haskey(graph, :lighting_mode)
        error("Shading mode has already been set.")
    else
        graph.shading = mode
    end
    return
end

"""
    set_ambient_light!(scenelike, color)

Sets the color of the ambient light in the scene.
"""
set_ambient_light!(scene, color) = set_ambient_light!(get_scene(scene).compute, color)
function set_ambient_light!(graph::ComputeGraph, color)
    update!(graph, ambient_color = to_color(color))
    return
end

"""
    set_directional_light!(scenelike; [color, direction, camera_relative])

Adjusts the directional light of the scene, assuming it is using `FastShading`.
Not to be used with `MultiLightShading`.
"""
set_directional_light!(scene; kwargs...) = set_directional_light!(get_scene(scene).compute; kwargs...)
function set_directional_light!(graph::ComputeGraph; kwargs...)
    lights = graph[:lights][]
    if graph[:shading][] == MultiLightShading || length(lights) != 1 || !isa(first(lights), DirectionalLight)
        error("Cannot set directional light - Scene not in FastShading mode.")
    end
    light = lights[1]
    data = map(name -> get(kwargs, name, getfield(light, name)), (:color, :direction, :camera_relative))
    update!(graph, lights = [DirectionalLight(data...)])
    return
end

"""
    set_light!(scenelike, i; fields...)

Adjusts one or multiple fields of light number `i`. (The ambient light is not
included in the lights list.)
"""
set_light!(scene, idx; kwargs...) = set_light!(get_scene(scene).compute, idx; kwargs...)
function set_light!(graph::ComputeGraph, idx; kwargs...)
    lights = graph[:lights][]
    light = lights[idx]
    T = typeof(light)
    data = map(name -> get(kwargs, name, getfield(light, name)), fieldnames(T))
    lights[idx] = T(data...)
    update!(graph, lights = lights)
    return
end

"""
    set_light!(scenelike, i, light)

Replaces light `i` with the given `light`. (The ambient light is not included in
the lights list.)
"""
set_light!(scene, idx, light::AbstractLight) = set_light!(get_scene(scene).compute, idx, light)
function set_light!(graph::ComputeGraph, idx, light::AbstractLight)
    lights = graph[:lights][]
    lights[idx] = light
    update!(graph, lights = lights)
    return
end

"""
    get_lights(scenelike)

Returns the current lights vector of the scene. The ambient light is not included
in here.
"""
get_lights(scene) = get_lights(get_scene(scene).compute)
get_lights(graph::ComputeGraph) = graph[:lights][]

"""
    set_lights!(scene, lights)

Replaces the lights vector with a new vector of `lights`. The new lights should
not include `AmbientLight`.
"""
set_lights!(scene, lights) = set_lights!(get_scene(scene).compute, lights)
function set_lights!(graph::ComputeGraph, lights)
    if any(l -> l isa AmbientLight, lights)
        error("The ambient light should be unique and controlled by `set_ambient_light!()`")
    end
    update!(graph, lights = lights)
    return
end

"""
    push_light!(scene, light)

Adds a new light to the active lights. The light should not be an AmbientLight.
"""
push_light!(scene, light) = push_light!(get_scene(scene).compute, light)
function push_light!(graph::ComputeGraph, light::AbstractLight)
    lights = graph[:lights][]
    push!(lights, light)
    update!(graph, lights = lights)
    return
end
function push_light!(graph::ComputeGraph, light::AmbientLight)
    error("The ambient light should be unique and controlled by `set_ambient_light!()`")
end
