function to_rpr_camera(context::RPR.Context, cam)
    # Create camera
    camera = RPR.Camera(context)

    map(cam.eyeposition) do position
        l, u = cam.lookat[], cam.upvector[]
        return lookat!(camera, position, l, u)
    end

    map(cam.fov) do fov
        return RPR.rprCameraSetFocalLength(camera, fov/2)
    end
    # TODO:
    # RPR_CAMERA_FSTOP
    # RPR_CAMERA_FOCAL_LENGTH
    # RPR_CAMERA_SENSOR_SIZE
    # RPR_CAMERA_MODE
    # RPR_CAMERA_FOCUS_DISTANCE
    return camera
end

function to_rpr_object(context, matsys, scene, plot)
    @warn("Not supported $(typeof(plot))")
    return nothing
end

function insert_plots!(context, matsys, scene, mscene::Makie.Scene, @nospecialize(plot::Combined))
    if isempty(plot.plots) # if no plots inserted, this truly is an atomic
        object = to_rpr_object(context, matsys, mscene, plot)
        if !isnothing(object)
            if object isa AbstractVector
                foreach(x-> push!(scene, x), object)
            else
                push!(scene, object)
            end
        end
    else
        for plot in plot.plots
            insert_plots!(context, matsys, scene, mscene, plot)
        end
    end
end

function to_rpr_scene(context::RPR.Context, mscene::Makie.Scene)
    scene = RPR.Scene(context)
    set!(context, scene)
    cam = Makie.cameracontrols(mscene)
    camera = to_rpr_camera(context, cam)
    set!(scene, camera)

    env_light = RPR.EnvironmentLight(context)
    image_path = RPR.assetpath("studio026.exr")
    img = RPR.Image(context, image_path)
    set!(env_light, img)
    setintensityscale!(env_light, 0.5)
    push!(scene, env_light)

    light = RPR.PointLight(context)
    transform!(light, Makie.translationmatrix(cam.eyeposition[]))
    RPR.setradiantpower!(light, 500, 500, 500)
    push!(scene, light)

    matsys = RPR.MaterialSystem(context, 0)

    for plot in mscene.plots
        insert_plots!(context, matsys, scene, mscene, plot)
    end
    return scene
end
