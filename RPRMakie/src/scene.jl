function to_rpr_camera(context::RPR.Context, cam)
    # Create camera
    camera = RPR.Camera(context)

    map(cam.eyeposition) do position
        l, u = cam.lookat[], cam.upvector[]
        return lookat!(camera, position, l, u)
    end

    map(cam.fov) do fov
        @show fov
        return RPR.rprCameraSetFocalLength(camera, abs(15/tan(fov/2)))
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

function to_rpr_scene(context::RPR.Context, matsys, mscene::Makie.Scene)
    scene = RPR.Scene(context)
    set!(context, scene)
    cam = Makie.cameracontrols(mscene)
    camera = to_rpr_camera(context, cam)
    set!(scene, camera)

    env_light = RPR.EnvironmentLight(context)
    image_path = RPR.assetpath("studio032.exr")
    img = RPR.Image(context, image_path)
    set!(env_light, img)
    setintensityscale!(env_light, 0.5)
    push!(scene, env_light)

    light = RPR.PointLight(context)
    transform!(light, Makie.translationmatrix(Vec3f0(0, 50, 120)))
    RPR.setradiantpower!(light, 100000, 100000, 100000)
    push!(scene, light)



    for plot in mscene.plots
        insert_plots!(context, matsys, scene, mscene, plot)
    end
    return scene
end

function replace_scene_rpr!(scene,
        context=RPR.Context(resource=RPR.RPR_CREATION_FLAGS_ENABLE_GPU0),
        matsys = RPR.MaterialSystem(context, 0); refresh=Observable(nothing))
    set_standard_tonemapping!(context)
    RPRMakie.to_rpr_scene(context, matsys, scene)
    # hide Makie scene
    scene.visible = false
    # foreach(p-> delete!(scene, p), copy(scene.plots))
    sub = campixel(scene)
    fb_size = size(scene)
    im = image!(sub, zeros(RGBAf0, fb_size), raw=true)
    framebuffer = RPR.FrameBuffer(context, RGBA, fb_size)
    framebuffer2 = RPR.FrameBuffer(context, RGBA, fb_size)
    set!(context, RPR.RPR_AOV_COLOR, framebuffer)
    onany(camera(scene).projection, refresh) do proj, refresh
        clear!(framebuffer)
    end
    RPR.rprContextSetParameterByKey1u(context, RPR.RPR_CONTEXT_ITERATIONS, 1)
    task = @async while isopen(scene)
        RPR.render(context)
        RPR.rprContextResolveFrameBuffer(context, framebuffer, framebuffer2, false)
        data = RPR.get_data(framebuffer2)
        im[1] = reverse(reshape(data, fb_size), dims=2)
        sleep(0.01)
    end
    return context, task
end
