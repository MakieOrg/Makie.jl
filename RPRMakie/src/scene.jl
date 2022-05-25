using LinearAlgebra

function update_rpr_camera!(oldvals, camera, cam_controls, cam)
    # Create camera
    c = cam_controls
    l, u, p, fov = c.lookat[], c.upvector[], c.eyeposition[], c.fov[]
    far, near, res = c.far[], c.near[], cam.resolution[]
    new_vals = (; l, u, p, fov, far, near, res)
    new_vals == oldvals && return oldvals
    wd = norm(l - p)
    RPR.rprCameraSetSensorSize(camera, res...)
    RPR.rprCameraSetFocusDistance(camera, wd)
    lookat!(camera, p, l, u)
    RPR.rprCameraSetFarPlane(camera, far)
    RPR.rprCameraSetNearPlane(camera, near)
    h = norm(res)
    RPR.rprCameraSetFocalLength(camera, (30*h)/fov)
    # RPR_CAMERA_FSTOP
    # RPR_CAMERA_MODE
    return new_vals
end

function to_rpr_object(context, matsys, scene, plot)
    @warn("Not supported $(typeof(plot))")
    return nothing
end

function insert_plots!(context, matsys, scene, mscene::Makie.Scene, @nospecialize(plot::PlotObject))
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

function to_rpr_light(context::RPR.Context, light::Makie.AmbientLight)
    env_img = fill(light.color[], 1, 1)
    img = RPR.Image(context, env_img)
    env_light = RPR.EnvironmentLight(context)
    set!(env_light, img)
    return env_light
end

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

function to_rpr_scene(context::RPR.Context, matsys, mscene::Makie.Scene)
    scene = RPR.Scene(context)
    set!(context, scene)
    # Only set background image if it isn't set by env light, since
    # background image takes precedence
    if !any(x-> x isa Makie.EnvironmentLight, mscene.lights)
        env_img = fill(to_color(mscene.backgroundcolor[]), 1, 1)
        img = RPR.Image(context, env_img)
        RPR.rprSceneSetBackgroundImage(scene, img)
    end
    for light in mscene.lights
        rpr_light = to_rpr_light(context, light)
        push!(scene, rpr_light)
    end

    for plot in mscene.plots
        insert_plots!(context, matsys, scene, mscene, plot)
    end
    return scene
end

function replace_scene_rpr!(scene::Makie.Scene, screen=RPRScreen(scene); refresh=Observable(nothing))
    context = screen.context
    matsys = screen.matsys
    screen.scene = scene
    rpr_scene = to_rpr_scene(context, matsys, scene)
    screen.rpr_scene = rpr_scene

    cam_controls = Makie.cameracontrols(scene)
    cam = Makie.camera(scene)
    camera = RPR.Camera(context)
    set!(rpr_scene, camera)
    # hide Makie scene
    # scene.visible[] = false
    foreach(p -> p.visible = false, scene.plots)
    sub = campixel(scene)
    fb_size = size(scene)
    im = image!(sub, rand(RGBAf, fb_size))

    # translate!(im, 0, 0, 1000)

    clear = true
    onany(refresh, cam.projectionview) do _, _
        clear = true
        return
    end

    RPR.rprContextSetParameterByKey1u(context, RPR.RPR_CONTEXT_ITERATIONS, 1)
    cam_values = (;)
    task = @async while isopen(scene)
        cam_values = update_rpr_camera!(cam_values, camera, cam_controls, cam)
        framebuffer2 = render(screen; clear=clear, iterations=1)
        if clear
            clear = false
        end
        data = RPR.get_data(framebuffer2)
        im[1] = reverse(reshape(data, screen.fb_size); dims=2)
        sleep(1/10)
    end
    return context, task, rpr_scene
end

struct RPRBackend <: Makie.AbstractBackend end

mutable struct RPRScreen <: Makie.AbstractScreen
    context::RPR.Context
    matsys::RPR.MaterialSystem
    framebuffer1::RPR.FrameBuffer
    framebuffer2::RPR.FrameBuffer
    fb_size::Tuple{Int, Int}
    scene::Union{Nothing, Scene}
    setup_scene::Bool
    rpr_scene::Union{Nothing, RPR.Scene}
    iterations::Int
    cleared::Bool
end

function RPRScreen(scene::Scene; kw...)
    fb_size = size(scene)
    screen = RPRScreen(fb_size; kw...)
    screen.scene = scene
    return screen
end

function RPRScreen(fb_size::NTuple{2,<:Integer};
                   iterations=NUM_ITERATIONS[],
                   resource=RENDER_RESOURCE[],
                   plugin=RENDER_PLUGIN[], max_recursion=10)
    context = RPR.Context(; resource=resource, plugin=plugin)
    matsys = RPR.MaterialSystem(context, 0)
    set_standard_tonemapping!(context)
    set!(context, RPR.RPR_CONTEXT_MAX_RECURSION, UInt(max_recursion))
    framebuffer1 = RPR.FrameBuffer(context, RGBA, fb_size)
    framebuffer2 = RPR.FrameBuffer(context, RGBA, fb_size)
    set!(context, RPR.RPR_AOV_COLOR, framebuffer1)
    return RPRScreen(context, matsys, framebuffer1, framebuffer2, fb_size, nothing, false, nothing,
                     iterations, false)
end

function render(screen; clear=true, iterations=screen.iterations)
    context = screen.context
    fb_size = screen.fb_size
    framebuffer1 = screen.framebuffer1
    framebuffer2 = screen.framebuffer2
    scene = screen.scene
    if fb_size != size(scene)
        fb_size = size(scene)
        RPR.release(framebuffer1)
        RPR.release(framebuffer2)
        framebuffer1 = RPR.FrameBuffer(context, RGBA, fb_size)
        framebuffer2 = RPR.FrameBuffer(context, RGBA, fb_size)
        set!(context, RPR.RPR_AOV_COLOR, framebuffer1)
        screen.fb_size = fb_size
        screen.framebuffer1 = framebuffer1
        screen.framebuffer2 = framebuffer2
    end
    clear && clear!(framebuffer1)
    RPR.rprContextSetParameterByKey1u(context, RPR.RPR_CONTEXT_ITERATIONS, iterations)
    RPR.render(context)
    RPR.rprContextResolveFrameBuffer(context, framebuffer1, framebuffer2, false)
    return framebuffer2
end

function Makie.colorbuffer(screen::RPRScreen)
    if !screen.setup_scene
        Makie.backend_display(screen, screen.scene)
    end
    data_1d = RPR.get_data(render(screen))
    r = reverse(reshape(data_1d, screen.fb_size), dims=2)
    img = rotl90(r)
    return map(img) do color
        RGB{Colors.N0f8}(mapc(x-> clamp(x, 0, 1), color))
    end
end

function Makie.backend_display(::RPRBackend, scene::Scene; kw...)
    screen = RPRScreen(scene)
    Makie.backend_display(screen, scene)
    return screen
end

function Makie.backend_display(screen::RPRScreen, scene::Scene)
    screen.scene = scene
    rpr_scene = to_rpr_scene(screen.context, screen.matsys, scene)
    screen.rpr_scene = rpr_scene
    cam_controls = cameracontrols(scene)
    cam = camera(scene)
    rpr_camera = RPR.Camera(screen.context)
    set!(rpr_scene, rpr_camera)
    update_rpr_camera!((;), rpr_camera, cam_controls, cam)
    screen.setup_scene = true
    return screen
end

function Base.insert!(screen::RPRScreen, scene::Scene, plot::AbstractPlot)
    context = screen.context
    matsys = screen.matsys
    rpr_scene = screen.rpr_scene
    insert_plots!(context, matsys, rpr_scene, scene, plot)
    return screen
end

function Makie.backend_show(b::RPRBackend, io::IO, ::MIME"image/png", scene::Scene)
    screen = Makie.backend_display(b, scene)
    img = Makie.colorbuffer(screen)
    FileIO.save(FileIO.Stream{FileIO.format"PNG"}(Makie.raw_io(io)), img)
    return screen
end

function Base.show(io::IO, ::MIME"image/png", screen::RPRScreen)
    img = Makie.colorbuffer(screen)
    FileIO.save(FileIO.Stream{FileIO.format"PNG"}(Makie.raw_io(io)), img)
    return screen
end
