# The API isn't that well documented - but here are some useful links:
# This describes the Maya plugin for RPR.  It's not the same as the RPR SDK, but it's a good start.
# Some of the settings don't exist in the RPR SDK, but most do.
# https://radeon-pro.github.io/RadeonProRenderDocs/en/plugins/maya/lights.html


# First, define methods to convert Makie lights into RPR lights.

########################################
#             Point light              #
########################################

function to_rpr_light(context::RPR.Context, light::Makie.PointLight)
    pointlight = RPR.PointLight(context)
    map(light.position) do pos
        transform!(pointlight, Makie.translationmatrix(pos))
    end
    map(light.radiance) do r
        setradiantpower!(pointlight, red(r), green(r), blue(r))
    end
    return pointlight
end

########################################
#            Ambient light             #
########################################

function to_rpr_light(context::RPR.Context, light::Makie.AmbientLight)
    env_img = fill(light.color[], 1, 1)
    img = RPR.Image(context, env_img)
    env_light = RPR.EnvironmentLight(context)
    set!(env_light, img)
    return env_light
end

########################################
#          Environment light           #
########################################

function to_rpr_light(context::RPR.Context, light::Makie.EnvironmentLight)
    env_light = RPR.EnvironmentLight(context)
    last_img = RPR.Image(context, light.image[])
    set!(env_light, last_img)
    setintensityscale!(env_light, light.intensity[])
    on(light.intensity) do i
        setintensityscale!(env_light, i)
    end
    on(light.image) do img
        new_img = RPR.Image(context, img)
        set!(env_light, new_img)
        RPR.release(last_img)
        last_img = new_img
    end
    return env_light
end


# now, define our own light structs to mimic RPR's options

############################################################
#                        Disk light                        #
############################################################

# TODO: 

# """
#     DiskLight(; angle, inner_angle, radius, radiant_power, position, lookat)

# Creates a disk light with the given parameters. The disk light is a cone of light

# !!! warning
#     This light only works with RPRMakie!  Please don't attempt to use this light with any other backend.

# # Fields
# $(Makie.DocStringExtensions.FIELDS)
# """
# struct DiskLight <: Makie.AbstractLight
#     "The transformation of the light; encodes position and rotation information.  You can manipulate this, but please don't change `scale` unless it's changed with the Scene."
#     transformation::Makie.Transformation
#     "The angle of the disk light.  Ranges from 0 to 179 degrees."
#     angle::Observable{Float32}
#     "The inner angle of the disk light.  Ranges from 0 to 179 degrees."
#     inner_angle::Observable{Float32}
#     "The radius of the disk light.  Ranges from 0 to 1.  Controls the softness of the disk."
#     radius::Observable{Float32}
#     "The radiant power of the light.  This is a color, and the color is multiplied by the intensity of the light.  Intensity values are approximately comparable to watts."
#     radiant_power::Observable{RGBf}
# end

# function DiskLight(; angle = 20, inner_angle = 20, radius = 0.4, radiant_power = RGBf(1, 1, 1), position = Point3f(0, 0, 1), lookat = Point3f(0, 0, 0))
#     return new(
#         Transformation(
#             identity; 
#             translation = to_ndim(Point3f, position, 0), 
#             scale = Vec3f(1), 
#             rotation = Makie.rotation_between(to_value(to_ndim(Point3f, position, 0)), to_value(to_ndim(Point3f, lookat, 0))),
#         ),
#         convert(Observable, Float32(angle)),
#         convert(Observable, Float32(inner_angle)),
#         convert(Observable, Float32(radius)),
#         convert(Observable, RGBf(radiant_power)),
#     )
# end

# # monkey patch for now, will be upstreamed to RPR
# function RPR.setradiantpower!(light::RPR.DiskLight, r::Number, g::Number, b::Number)
#     return RPR.rprDiskLightSetRadiantPower3f(light.pointer, rpr_float(r), rpr_float(g), rpr_float(b))
# end

# function RPRMakie.to_rpr_light(context::RPR.Context, light::DiskLight)

#     disk_light = RPR.DiskLight(context)

#     on(light.radiant_power) do radiant_power
#         RPR.setradiantpower!(disk_light, red(radiant_power), green(radiant_power), blue(radiant_power))
#     end
#     on(light.angle) do angle
#         RPR.rprDiskLightSetAngle(disk_light.pointer, angle)
#     end
#     on(light.inner_angle) do inner_angle
#         RPR.rprDiskLightSetInnerAngle(disk_light.pointer, inner_angle)
#     end
#     on(light.radius) do radius
#         RPR.rprDiskLightSetRadius(disk_light.pointer, radius)
#     end
    
#     on(light.transformation.model) do model
#         RPR.transform!(disk_light, model)
#     end

#     notify(light.radiant_power); notify(light.angle); notify(light.inner_angle); notify(light.radius); notify(light.transformation.model)

#     return disk_light
# end
    

############################################################
#                        Spot light                        #
###########################################################

"""
    SpotLight(; outer_angle, inner_angle, radiant_power, position, rotation)

Creates a spot light with the given parameters.  
This is essentially an idealized theatre spotlight, with all that entails.

!!! warning
    This light only works with RPRMakie!  Please don't attempt to use this light with any other backend.

# Fields
$(Makie.DocStringExtensions.FIELDS)
"""
struct SpotLight <: Makie.AbstractLight
    "The transformation of the light; encodes position and rotation information.  You can manipulate this, but please don't change `scale` unless it's changed with the Scene."
    transformation::Makie.Transformation
    "The outer angle of the spotlight, in radians.  This defines the spread of the outer edge of the beam.  Ranges from 0 to π."
    outer_angle::Observable{Float32}
    "The inner angle of the spotlight, in radians.  This defines the softness of the beam, i.e., the scaling of the intensity of the light as a function of its distance from the center of the beam.  Ranges from 0 to `outer_angle`."
    inner_angle::Observable{Float32}
    "The radiant power of the light.  This is a color, and the color is multiplied by the intensity of the light.  Intensity values are approximately comparable to watts."
    radiant_power::Observable{RGBf}
end

function SpotLight(; outer_angle = π/4, inner_angle = π/4, radius = 0.4, radiant_power = RGBf(1, 1, 1), position = Point3f(0, 0, 1), rotation = Makie.to_rotation(0))
    return SpotLight(
        Makie.Transformation(identity; translation = position, scale = Vec3f(1), rotation = convert(Observable{Quaternionf}, lift(to_rotation, rotation))),
        convert(Observable, Float32(outer_angle)),
        convert(Observable, Float32(inner_angle)),
        convert(Observable, RGBf(radiant_power)),
    )
end

function RPRMakie.to_rpr_light(context::RPR.Context, light::SpotLight)

    spot_light = RPR.SpotLight(context)

    on(light.radiant_power) do radiant_power
        RPR.setradiantpower!(spot_light, red(radiant_power), green(radiant_power), blue(radiant_power))
    end
    onany(light.outer_angle, light.inner_angle) do outer_angle, inner_angle
        RPR.rprSpotLightSetConeShape(spot_light.pointer, inner_angle, outer_angle)
    end
    on(light.transformation.model) do model
        RPR.transform!(spot_light, model)
    end

    notify(light.radiant_power); notify(light.outer_angle); notify(light.inner_angle); notify(light.transformation.model)

    return spot_light
end
    
############################################################
#                    Directional light                     #
############################################################

# This is probably the most useful light.

"""
    DirectionalLight(; shadow_softness_angle, radiant_power, rotation)

A directional light has no apparent source, but rather appears to come from a very far distance.  
It is essentially a parallel beam of light, coming from a certain direction.

!!! warning
    This light only works with RPRMakie!  Please don't attempt to use this light with any other backend.

# Fields
$(Makie.DocStringExtensions.FIELDS)
"""
struct DirectionalLight <: Makie.AbstractLight
    "The direction from which the light arrives, presumably relative to the upvector."
    rotation::Observable{Quaternionf}
    "Coefficient value within the range of [0;1]. 0.0 means sharp shadows.  This is, essentially, the inverse of the size of the 'source' of the directional light."
    shadow_softness_angle::Observable{Float32}
    "The radiant power of the light, measured in watt analogues."
    radiant_power::Observable{RGBf}
end

function DirectionalLight(; shadow_softness_angle = 0.25, radiant_power = RGBf(1, 1, 1), position = Point3f(0, 0, 1), rotation = Makie.to_rotation(0))
    return DirectionalLight(
        convert(Observable, rotation isa Observable ? lift(to_rotation, rotation) : to_rotation(rotation)),
        convert(Observable, Float32(shadow_softness_angle)),
        convert(Observable, RGBf(radiant_power)),
    )
end

function RPRMakie.to_rpr_light(context::RPR.Context, light::DirectionalLight)

    directional_light = RPR.DirectionalLight(context)

    on(light.radiant_power) do radiant_power
        RPR.setradiantpower!(directional_light, red(radiant_power), green(radiant_power), blue(radiant_power))
    end
    onany(light.shadow_softness_angle) do shadow_softness_angle
        RPR.rprDirectionalLightSetShadowSoftnessAngle(directional_light.pointer, shadow_softness_angle)
    end
    on(light.rotation) do rotation
        RPR.transform!(directional_light, Makie.transformationmatrix(Vec3f(0), Vec3f(1), to_rotation(rotation)))
    end

    notify(light.rotation); notify(light.radiant_power); notify(light.shadow_softness_angle); 

    return directional_light
end

# Note that SkyLight is deprecated, so we don't use that.