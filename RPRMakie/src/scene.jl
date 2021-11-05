using LinearAlgebra

function to_rpr_camera(context::RPR.Context, cam_controls, cam)
    # Create camera
    camera = RPR.Camera(context)

    map(cam_controls.eyeposition) do position
        l, u = cam_controls.lookat[], cam_controls.upvector[]
        RPR.rprCameraSetFocusDistance(camera, norm(l - position))
        lookat!(camera, position, l, u)
        return
    end

    map(cam_controls.far) do far
        RPR.rprCameraSetFarPlane(camera, far)
        return
    end

    map(cam_controls.near) do near
        RPR.rprCameraSetNearPlane(camera, near)
        return
    end

    map(cam_controls.fov, cam.resolution) do fov, res
        l, p = cam_controls.lookat[], cam_controls.eyeposition[]
        wd = norm(l-p)
        h = 2norm(res)
        return RPR.rprCameraSetFocalLength(camera, (h*wd)/0.5fov)
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
    cam_controls = Makie.cameracontrols(mscene)
    cam = Makie.camera(mscene)
    camera = to_rpr_camera(context, cam_controls, cam)
    set!(scene, camera)

    env_light = RPR.EnvironmentLight(context)
    # image_path = RPR.assetpath("studio032.exr")
    env_img = fill(to_color(mscene.backgroundcolor[]), 1, 1)
    # img = RPR.Image(context, image_path)
    img = RPR.Image(context, env_img)
    set!(env_light, img)
    setintensityscale!(env_light, 0.8)
    push!(scene, env_light)

    light = RPR.PointLight(context)
    transform!(light, Makie.translationmatrix(Vec3f0(2, -10, 10)))
    RPR.setradiantpower!(light, 100, 100, 100)
    push!(scene, light)

    for plot in mscene.plots
        insert_plots!(context, matsys, scene, mscene, plot)
    end
    return scene, camera
end

function replace_scene_rpr!(scene,
        context=RPR.Context(resource=RPR.RPR_CREATION_FLAGS_ENABLE_GPU0),
        matsys = RPR.MaterialSystem(context, 0);
        refresh=Observable(nothing),
        iterations=1)
    set_standard_tonemapping!(context)
    set!(context, RPR.RPR_CONTEXT_MAX_RECURSION, UInt(10))
    rpr_scene, rpr_camera = RPRMakie.to_rpr_scene(context, matsys, scene)
    # hide Makie scene
    scene.visible[] = false
    foreach(p-> p.visible = false, scene.plots)
    sub = campixel(scene)
    fb_size = size(scene)
    im = image!(sub, zeros(RGBAf, fb_size))
    translate!(im, 0, 0, 10000)
    framebuffer1 = RPR.FrameBuffer(context, RGBA, fb_size)
    framebuffer2 = RPR.FrameBuffer(context, RGBA, fb_size)
    RPR.rprCameraSetSensorSize(rpr_camera, fb_size...)
    onany(camera(scene).projection, refresh) do proj, refresh
        clear!(framebuffer1)
    end
    set!(context, RPR.RPR_AOV_COLOR, framebuffer1)
    RPR.rprContextSetParameterByKey1u(context, RPR.RPR_CONTEXT_ITERATIONS, iterations)
    task = @async while isopen(scene)
        if fb_size != size(scene)
            @info("resizing scene")
            fb_size = size(scene)
            RPR.release(framebuffer1)
            RPR.release(framebuffer2)
            framebuffer1 = RPR.FrameBuffer(context, RGBA, fb_size)
            framebuffer2 = RPR.FrameBuffer(context, RGBA, fb_size)
            set!(context, RPR.RPR_AOV_COLOR, framebuffer1)
            RPR.rprCameraSetSensorSize(rpr_camera, fb_size...)
        end
        RPR.render(context)
        RPR.rprContextResolveFrameBuffer(context, framebuffer1, framebuffer2, false)
        data = RPR.get_data(framebuffer2)
        im[1] = reverse(reshape(data, fb_size), dims=2)
        sleep(0.01)
    end
    return context, task, rpr_scene
end
