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
    far = wd * 10
    near = wd * 0.001
    RPR.rprCameraSetFarPlane(camera, far)
    RPR.rprCameraSetNearPlane(camera, near)
    focal_length = res[2] / (2 * tand(fov / 2)) # fov is vertical
    RPR.rprCameraSetFocalLength(camera, focal_length)
    # RPR_CAMERA_FSTOP
    # RPR_CAMERA_MODE
    return new_vals
end

function to_rpr_object(context, matsys, scene, plot)
    @warn("Not supported $(typeof(plot))")
    return nothing
end

function insert_plots!(context, matsys, scene, mscene::Makie.Scene, @nospecialize(plot::Plot))
    return if isempty(plot.plots) # if no plots inserted, this truly is an atomic
        object = to_rpr_object(context, matsys, mscene, plot)
        if !isnothing(object)
            if object isa AbstractVector
                foreach(x -> push!(scene, x), object)
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

to_rpr_light(ctx, rpr_scene, light, scene) = to_rpr_light(ctx, rpr_scene, light)

# TODO attenuation
function to_rpr_light(context::RPR.Context, matsys, light::Makie.PointLight)
    pointlight = RPR.PointLight(context)
    transform!(pointlight, Makie.translationmatrix(light.position))
    c = light.color
    setradiantpower!(pointlight, red(c), green(c), blue(c))
    return pointlight
end

# TODO: Move to RadeonProRender.jl
function RPR.RPR.rprContextCreateSpotLight(context)
    out_light = Ref{RPR.rpr_light}()
    RPR.RPR.rprContextCreateSpotLight(context, out_light)
    return out_light[]
end

function to_rpr_light(context::RPR.Context, rpr_scene, light::Makie.DirectionalLight, scene)
    directionallight = RPR.DirectionalLight(context)
    dir = light.direction
    if light.camera_relative
        T = inv(scene.camera.view[][Vec(1, 2, 3), Vec(1, 2, 3)])
        dir = normalize(T * dir)
    else
        dir = normalize(dir)
    end
    quart = Makie.rotation_between(Vec3f(dir), Vec3f(0, 0, -1))
    transform!(directionallight, Makie.rotationmatrix4(quart))
    c = light.color
    setradiantpower!(directionallight, red(c), green(c), blue(c))
    return directionallight
end

function to_rpr_light(context::RPR.Context, rpr_scene, light::Makie.RectLight)
    mesh = lift(light.position, light.u1, light.u2) do center, u1, u2
        pos = center - 0.5u1 - 0.5u2
        points = Point3f[pos, pos + u1, pos + u1 + u2, pos + u2]
        faces = [GLTriangleFace(1, 2, 3), GLTriangleFace(1, 3, 4)]
        return GeometryBasics.Mesh(points, faces)
    end
    rpr_mesh = RPR.Shape(context, mesh[])
    env_img = fill(light.color[], 1, 1)
    img = RPR.Image(context, env_img)
    env_light = RPR.EnvironmentLight(context)
    set!(env_light, img)
    setintensityscale!(env_light, 0.1)
    # TODO, this doesn't seem to properly create a rectangular portal -.-
    setportal!(rpr_scene, env_light, rpr_mesh)
    return env_light
end

function to_rpr_light(context::RPR.Context, rpr_scene, light::Makie.SpotLight)
    spotlight = RPR.SpotLight(context)
    map(light.position, light.direction) do pos, dir
        quart = Makie.rotation_between(dir, Vec3f(0, 0, -1))
        transform!(spotlight, Makie.translationmatrix(pos) * Makie.rotationmatrix4(quart))
    end
    map(light.color) do c
        setradiantpower!(spotlight, red(c), green(c), blue(c))
    end
    map(light.angles) do (inner, outer)
        RadeonProRender.RPR.rprSpotLightSetConeShape(spotlight, inner, outer)
    end
    return spotlight
end

function to_rpr_light(context::RPR.Context, rpr_scene, color::Colorant)
    env_img = fill(color, 1, 1)
    img = RPR.Image(context, env_img)
    env_light = RPR.EnvironmentLight(context)
    set!(env_light, img)
    return env_light
end

function to_rpr_light(context::RPR.Context, rpr_scene, light::Makie.EnvironmentLight)
    env_light = RPR.EnvironmentLight(context)
    last_img = RPR.Image(context, light.image')
    set!(env_light, last_img)
    setintensityscale!(env_light, light.intensity[])
    # exchange y and z axis to align Makie's and RPR's representations
    flipmat = Makie.Mat4f(
        1, 0, 0, 0,
        0, 0, 1, 0,
        0, 1, 0, 0,
        0, 0, 0, 1,
    )
    transform!(env_light, flipmat)
    # on(light.intensity) do i
    #     setintensityscale!(env_light, i)
    # end
    # on(light.image) do img
    #     new_img = RPR.Image(context, img)
    #     set!(env_light, new_img)
    #     RPR.release(last_img)
    #     last_img = new_img
    # end
    return env_light
end

function to_rpr_scene(context::RPR.Context, matsys, mscene::Makie.Scene)
    scene = RPR.Scene(context)
    set!(context, scene)
    # Only set background image if it isn't set by env light, since
    # background image takes precedence
    lights = mscene.compute.lights[]
    if !any(x -> x isa Makie.EnvironmentLight, lights)
        env_img = fill(to_color(mscene.backgroundcolor[]), 1, 1)
        img = RPR.Image(context, env_img)
        RPR.rprSceneSetBackgroundImage(scene, img)
    end
    for light in lights
        @show typeof(light)
        rpr_light = to_rpr_light(context, scene, light, mscene)
        push!(scene, rpr_light)
    end
    push!(scene, to_rpr_light(context, scene, mscene.compute.ambient_color[]))


    for plot in mscene.plots
        insert_plots!(context, matsys, scene, mscene, plot)
    end
    return scene
end

function replace_scene_rpr!(scene::Makie.Scene, screen = Screen(scene); refresh = Observable(nothing))
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

    clear = Threads.Atomic{Bool}(true)
    onany(refresh, cam.projectionview) do _, _
        clear[] = true
        return
    end

    RPR.rprContextSetParameterByKey1u(context, RPR.RPR_CONTEXT_ITERATIONS, 1)
    cam_values = (;)

    task = @async while isopen(scene)
        t = time()
        cam_values = update_rpr_camera!(cam_values, camera, cam_controls, cam)
        framebuffer2 = render(screen; clear = clear[], iterations = 1)
        if clear[]
            clear[] = false
        end
        data = RPR.get_data(framebuffer2)
        im[1] = reverse(reshape(data, screen.fb_size); dims = 2)
        tframe = time() - t
        to_sleep = (1 / 10) - tframe
        if to_sleep < 0.0
            yield()
        else
            sleep(to_sleep)
        end
    end
    return context, task, rpr_scene
end


"""
    Screen(args...; screen_config...)

# Arguments one can pass via `screen_config`:

$(Base.doc(ScreenConfig))

# Constructors:

$(Base.doc(MakieScreen))
"""
mutable struct Screen <: Makie.MakieScreen
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

Base.size(screen::Screen) = screen.fb_size

function Base.show(io::IO, ::MIME"image/png", screen::Screen)
    img = colorbuffer(screen)
    return FileIO.save(FileIO.Stream{FileIO.format"PNG"}(Makie.raw_io(io)), img)
end

function Makie.apply_screen_config!(screen::Screen, config::ScreenConfig)
    context = RPR.Context(; resource = config.resource, plugin = config.plugin)
    screen.context = context
    screen.matsys = RPR.MaterialSystem(context, 0)
    set_standard_tonemapping!(context)
    set!(context, RPR.RPR_CONTEXT_MAX_RECURSION, UInt(config.max_recursion))
    screen.iterations = config.iterations
    return screen
end

function Screen(fb_size::NTuple{2, <:Integer}; screen_config...)
    config = Makie.merge_screen_config(ScreenConfig, Dict{Symbol, Any}(screen_config))
    return Screen(fb_size, config)
end

function Screen(scene::Scene; screen_config...)
    config = Makie.merge_screen_config(ScreenConfig, Dict{Symbol, Any}(screen_config))
    return Screen(scene, config)
end

function Screen(scene::Scene, config::ScreenConfig)
    screen = Screen(size(scene), config)
    screen.scene = scene
    return screen
end

Screen(scene::Scene, config::ScreenConfig, ::IO, ::MIME) = Screen(scene, config)
Screen(scene::Scene, config::ScreenConfig, ::Makie.ImageStorageFormat) = Screen(scene, config)

function Screen(fb_size::NTuple{2, <:Integer}, config::ScreenConfig)
    context = RPR.Context(; resource = config.resource, plugin = config.plugin)
    matsys = RPR.MaterialSystem(context, 0)
    set_standard_tonemapping!(context)
    set!(context, RPR.RPR_CONTEXT_MAX_RECURSION, UInt(config.max_recursion))
    framebuffer1 = RPR.FrameBuffer(context, RGBA, fb_size)
    framebuffer2 = RPR.FrameBuffer(context, RGBA, fb_size)
    set!(context, RPR.RPR_AOV_COLOR, framebuffer1)
    return Screen(
        context, matsys, framebuffer1, framebuffer2, fb_size,
        nothing, false, nothing,
        config.iterations, false
    )
end

function render(screen; clear = true, iterations = screen.iterations)
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

function Makie.colorbuffer(screen::Screen)
    if !screen.setup_scene
        display(screen, screen.scene)
    end
    data_1d = RPR.get_data(render(screen))
    r = reverse(reshape(data_1d, screen.fb_size), dims = 2)
    img = rotl90(r)
    return map(img) do color
        RGB{Colors.N0f8}(mapc(x -> clamp(x, 0, 1), color))
    end
end

function Base.display(screen::Screen, scene::Scene; display_kw...)
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

function Base.insert!(screen::Screen, scene::Scene, plot::AbstractPlot)
    context = screen.context
    matsys = screen.matsys
    rpr_scene = screen.rpr_scene
    insert_plots!(context, matsys, rpr_scene, scene, plot)
    return screen
end

Makie.backend_showable(::Type{Screen}, ::Union{MIME"image/jpeg", MIME"image/png"}) = true
