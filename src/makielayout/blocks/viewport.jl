# Forwarded from Camera pr

struct Ray
    origin::Point3f
    direction::Vec3f
end


################################################################################

################################################################################
### Texture generation
################################################################################


function generate_navball_texture(;
        top_color = Makie.wong_colors(1)[1],
        bottom_color = Makie.wong_colors(1)[2],
        majortick_linewidth = 8, minortick_linewidth = 2,
        minorticklength = 0.01, majorticklength = 0.02,
        ticklabelpad = 0.005,
        resolution = (1800, 900),
        fontsize = 30,
        linecolor = :black,
        filename = Makie.assetpath("navball_texture.png")
    )

    # Scaling due to shrinking circumference
    scaling(z) = min(1e6, 1.0 / cos(z * pi/2))

    parent = Scene(resolution = resolution, backgroundcolor = top_color, clear = true)
    Scene(parent, px_area = Observable(Rect2i(0, 450, 1800, 450)), backgroundcolor = bottom_color, clear = true)
    scene = Scene(parent, backgroundcolor = :transparent, clear = false)

    # main north-south lines
    zs = range(-1, 1, length = 301)
    for x in (-1.0, -0.5, 0.0, 0.5, 1.0)
        lines!(
            scene, fill(x, length(zs)), zs, linewidth = majortick_linewidth * scaling.(zs), 
            #fxaa = fxaa, 
            color = linecolor
        )
    end

    # equator
    lines!(scene, [-1.1, 1.1], [0.0, 0.0], linewidth = majortick_linewidth, color = linecolor)

    # Minor lines
    zs = range(-1, 1, length = 301)
    for x in (-0.75, -0.25, 0.25, 0.75)
        lines!(
            scene, fill(x, length(zs)), zs, linewidth = minortick_linewidth * scaling.(zs), 
            color = linecolor
        )
    end
    for z in (-0.5, 0.5)
        lines!(scene, [-1, 1], [z, z], linewidth = minortick_linewidth, color = linecolor)
    end

    # Major Ticks
    zs = range(-1, 1, length=19)[2:end-1]
    xs = (-1.0, -0.5, 0.0, 0.5, 1.0)
    ps = [Point2f(x+dx*scaling(z), z) for z in zs for x in xs for dx in (-majorticklength, majorticklength)]
    linesegments!(scene, ps, color = linecolor, linewidth = minortick_linewidth)

    zs = vcat(range(-1, 0, length=10)[3:end-1], range(0, 1, length=10)[2:end-2])
    xs = (-1.0, -0.5, 0.0, 0.5, 1.0)
    ps = [Point2f(x - (majorticklength + ticklabelpad) * scaling(z), z) for z in zs for x in xs]
    text!(
        scene, ps,
        text = [string(z) for z in vcat(-70:10:-10, 10:10:70) for x in xs],
        color = :white, fontsize = fontsize .* Vec2f.(scaling.(last.(ps)), 1),
        strokecolor = :black, strokewidth = 2,
        align = (:left, :center),
    )

    zs = vcat(range(-1, 0, length=10)[3:end-1], range(0, 1, length=10)[2:end-2])
    xs = (-1.0, -0.5, 0.0, 0.5, 1.0)
    ps = [Point2f(x - (majorticklength + ticklabelpad) * scaling(z), z) for z in zs for x in xs]
    text!(
        scene, ps,
        text = [string(z) for z in vcat(-70:10:-10, 10:10:70) for x in xs],
        color = :white, fontsize = fontsize .* Vec2f.(scaling.(last.(ps)), 1),
        strokecolor = :black, strokewidth = 2,
        align = (:right, :center)
    )

    zs = range(-1, 1, length=19)[[2, 18]]
    xs = (-0.75, -0.25, 0.25, 0.75)
    ps = [Point2f(x, z) for z in zs for x in xs]
    text!(
        scene, ps,
        text = [string(z) for z in (-80, 80) for x in xs],
        color = :white, fontsize = fontsize .* Vec2f.(scaling.(last.(ps)), 1),
        strokecolor = :black, strokewidth = 2,
        align = (:center, :center)
    )
    
    # Minor Ticks
    zs = range(-1, 1, length=37)[2:2:end-1]
    xs = (-1.0, -0.5, 0.0, 0.5, 1.0)
    ps = [Point2f(x+dx*scaling(z), z) for z in zs for x in xs for dx in (-minorticklength, minorticklength)]
    linesegments!(
        scene, ps, color = linecolor, linewidth = minortick_linewidth#, fxaa = fxaa
    )

    # Labels
    horizontal_labels = ("-X", "225", "-Y", "315", "X", "45", "Y", "135", "-X")
    text!(
        scene, 
        [Point2f(x, 0) for x in range(-1, 1, length = 9)],
        text = [str for str in horizontal_labels],
        color = :white, fontsize = fontsize,
        align = (:center, :center),
        strokecolor = :black, strokewidth = 2
    )
    text!(
        scene, 
        [Point2f(x, z) for x in range(-1, 1, length = 9) for z in (-0.5, 0.5)],
        text = [str for str in horizontal_labels for z in 1:2],
        color = :white, fontsize = fontsize * Vec2f(scaling(0.5), 1),
        align = (:center, :center),
        strokecolor = :black, strokewidth = 2,
    )

    # Frame
    linesegments!(
        scene, [-1, 1, -1, 1], [1, 1, -1, -1], 
        color = linecolor, linewidth = 2*majortick_linewidth#, fxaa = fxaa
    )

    Makie.save(filename, parent)

    return parent
end

################################################################################
### Camera setup
################################################################################


# Simplified/Modified from Camera3D to make sure updates work correctly
struct ViewportControllerCamera <: AbstractCamera
    phi::Observable{Float32}
    theta::Observable{Float32}
    attributes::Attributes
end

function ViewportControllerCamera(scene::Scene, axis; kwargs...)
    kwdict = Dict(kwargs)
    attr = Attributes(
        fov = 45.0,
        projectiontype = Makie.Perspective,
        rotationspeed = 1.0,
        click_timeout = 0.3,
        selected = false,
        step = get(kwdict, :step, 2pi/16)
    )
    # merge!(attr, Attributes(kwargs)) # doesn't replace?

    if axis isa Axis3
        cam = ViewportControllerCamera(
            Observable{Float32}(axis.azimuth[]), 
            Observable{Float32}(axis.elevation[]),
            attr
        )
    else
        cam = ViewportControllerCamera(
            Observable{Float32}(pi/4), 
            Observable{Float32}(0.61547977f0),
            attr
        )
    end

    disconnect!(camera(scene))

    # de/select plot on click outside/inside
    # also deselect other cameras
    deselect_all_cameras!(root(scene))
    on(camera(scene), events(scene).mousebutton, priority = 100) do event
        if event.action == Mouse.press
            attr.selected[] = is_mouseinside(scene)
        end
        return Consume(false)
    end

    # Mouse controls
    add_rotation!(scene, cam, axis)

    # add camera controls to scene
    cameracontrols!(scene, cam)

    # Trigger updates on scene resize and settings change
    # scene.px_area, 
    on(camera(scene), scene.px_area, attr[:fov], attr[:projectiontype]) do _, _, _
        update_cam!(scene, cam)
    end

    notify(attr.fov)

    connect_camera!(axis, scene)

    cam
end
deselect_camera!(cam::ViewportControllerCamera) = cam.attributes.selected[] = false

function _hovered_angles(scene, cam, step)
    mp = events(scene).mouseposition[]
    selections = Makie.pick(scene, Rect2i(mp .- 2, Vec2(5)))
    if any(pidx -> pidx[1] isa Mesh, selections)
        ray = ray_at_cursor(scene, cam)
        # ray = p + tv, Sphere: x² + y² + z² = r²
        # Solve resulting quadratic equation
        a = dot(ray.direction, ray.direction)
        b = 2 * dot(ray.origin, ray.direction)
        c = dot(ray.origin, ray.origin) - 1 # radius 1
        # goes below 0 only because rect pick may trigger outside sphere
        t2 = (-b - sqrt(max(0, b*b - 4*a*c))) / (2*a) 
        p = ray.origin + t2 * ray.direction

        # to spherical
        theta = asin(p[3]) 
        if abs(p[3]) > 0.999
            phi = 0.0
        else
            p = p[Vec(1,2)]
            p = p / norm(p)
            phi = mod(2pi + atan(p[2], p[1]), 2pi)
        end

        # snapping
        phi   = step * round(phi / step)
        theta = step * round(theta / step)
        return phi, theta
    else
        return NaN, NaN
    end
end

function add_rotation!(scene, cam::ViewportControllerCamera, axis)
    @extract cam.attributes (rotationspeed, click_timeout, step)
    drag_state = RefValue((false, Vec2f(0), time()))
    e = events(scene)

    # drag start/stop
    on(camera(scene), e.mousebutton) do event
        if event.button == Mouse.left
            active, last_mousepos, last_time = drag_state[]
            if event.action == Mouse.press && is_mouseinside(scene) # && !active
                drag_state[] = (true, mouseposition_px(scene), time())
                return Consume(true)
            elseif event.action == Mouse.release && active
                dt = time() - last_time
                if dt < click_timeout[]
                    # do click stuff
                    phi, theta = _hovered_angles(scene, cam, step[])
                    if !isnan(phi)
                        update_cam!(scene, cam, phi, theta)
                        update_camera!(axis, cam.phi[], cam.theta[])
                    end
                else
                    # do drag stuff
                    mousepos = mouseposition_px(scene)
                    rot_scaling = rotationspeed[] * (e.window_dpi[] * 0.005)
                    mp = (last_mousepos .- mousepos) .* 0.01f0 .* rot_scaling
                    rotate_cam!(scene, cam, mp[1], mp[2], axis)
                end
                drag_state[] = (false, Vec2f(0), time())
                println()

                return Consume(true)
            end
        end

        return Consume(false)
    end

    # in drag
    on(camera(scene), e.mouseposition) do mp
        active, last_mousepos, last_time = drag_state[]
        if active && ispressed(scene, Mouse.left)
            mousepos = screen_relative(scene, mp)
            rot_scaling = rotationspeed[] * (e.window_dpi[] * 0.005)
            mp = (last_mousepos .- mousepos) * 0.01f0 * rot_scaling
            rotate_cam!(scene, cam, mp[1], mp[2], axis)
            drag_state[] = (active, mousepos, last_time)
            println()
            return Consume(true)
        end

        return Consume(false)
    end
end

function rotate_cam!(scene, cam::ViewportControllerCamera, dphi::Real, dtheta::Real, axis)
    @info dphi, dtheta
    cam.theta[] = mod(cam.theta[] + dtheta, 2pi)
    reverse = ifelse(pi/2 <= cam.theta[] <= 3pi/2, -1, 1)
    cam.phi[] = mod(cam.phi[] + reverse * dphi, 2pi)

    update_cam!(scene, cam)    
    update_camera!(axis, cam.phi[], cam.theta[])

    return
end

# Update camera matrices
function update_cam!(scene::Scene, cam::ViewportControllerCamera, phi::Real, theta::Real)
    dphi = mod(2pi + cam.phi[] - phi, 2pi)
    print(dphi, " -> ")
    dphi = ifelse(dphi > pi, dphi - 2pi, dphi)
    println(dphi)
    if !(-1.1pi/2 <= dphi <= 1.1pi/2)
        cam.phi[]   = mod(phi + pi, 2pi)
        cam.theta[] = mod(pi - theta, 2pi)
    else
        cam.phi[] = phi
        cam.theta[] = theta
    end
    return update_cam!(scene, cam)
end

function update_cam!(scene::Scene, cam::ViewportControllerCamera)
    # @extractvalue cam (lookat, eyeposition, upvector)
    fov = cam.attributes.fov[]

    phi = cam.phi[]; theta = cam.theta[]
    @info "update mat: $phi, $theta"
    eyeposition = spherical_to_cartesian(phi, theta, 3f0)
    lookat = Vec3f(0)
    upvector = spherical_to_cartesian(phi, theta + pi/2)

    view = Makie.lookat(eyeposition, lookat, upvector)

    aspect = Float32((/)(widths(scene.px_area[])...))
    if cam.attributes.projectiontype[] == Makie.Perspective
        view_norm = norm(eyeposition - lookat)
        proj = Makie.perspectiveprojection(Float32(fov), aspect, view_norm * 0.1f0, view_norm * 2f0)
    else
        h = norm(eyeposition - lookat); w = h * aspect
        proj = Makie.orthographicprojection(-w, w, -h, h, h * 0.1f0, h * 2f0)
    end

    Makie.set_proj_view!(camera(scene), proj, view)
    scene.camera.eyeposition[] = eyeposition

    return
end

# update controller based on axis
function connect_camera!(ax::Axis3, scene::Scene)
    cam = cameracontrols(scene)
    onany(ax.elevation, ax.azimuth) do theta, phi
        update_cam!(scene, cam, phi, theta)
        return
    end
    notify(ax.elevation)
    return
end

function connect_camera!(lscene::LScene, scene::Scene)
    cam = cameracontrols(lscene.scene)
    onany(camera(lscene.scene).view) do _
        @extractvalue cam (lookat, eyeposition, upvector)

        dir = normalize(eyeposition - lookat)
        theta = asin(dir[3]) 
        theta = mod(2pi + ifelse(upvector[3] > 0, theta, pi - theta), 2pi)
        if abs(dir[3]) > 0.9
            right = cross(upvector, dir)
            p = right[Vec(1,2)]
            p = p / norm(p)
            phi = mod(3pi/2 + atan(p[2], p[1]), 2pi)
        else
            p = dir[Vec(1,2)]
            p = p / norm(p)
            phi = mod(2pi + atan(p[2], p[1]) + ifelse(pi/2 <= theta <= 3pi/2, pi, 0), 2pi)
        end
        @info "from other: $phi, $theta"
        update_cam!(scene, scene.camera_controls, phi, theta)
        return
    end
    notify(camera(lscene.scene).view)
    return
end

# Update axis based on controller 
function update_camera!(ax::Axis3, phi, theta)
    ax.azimuth[] = phi
    ax.elevation[] = theta
    return
end

function update_camera!(lscene::LScene, phi, theta)
    cam = cameracontrols(lscene.scene)
    dir = spherical_to_cartesian(phi, theta)
    viewdir = cam.eyeposition[] - cam.lookat[]
    upvector = spherical_to_cartesian(phi, theta + pi/2)
    eyepos = cam.lookat[] + norm(viewdir) * dir
    update_cam!(lscene.scene, cam, eyepos, cam.lookat[], upvector)
    return
end

function spherical_to_cartesian(phi, theta, radius = 1f0)
    return radius * Vec3f(cos(theta) * cos(phi), cos(theta) * sin(phi), sin(theta))
end

function cartesian_to_spherical(v::Vec3f)

end

################################################################################


function ray_at_cursor(scene::Scene, cam::ViewportControllerCamera)
    phi = cam.phi[]; theta = cam.theta[]
    viewdir = - Vec3f(cos(theta) * cos(phi), cos(theta) * sin(phi), sin(theta))
    eyepos = - 3f0 * viewdir
    theta += pi/2
    up = Vec3f(cos(theta) * cos(phi), cos(theta) * sin(phi), sin(theta))

    u_z = normalize(viewdir)
    u_x = normalize(cross(u_z, up))
    u_y = normalize(cross(u_x, u_z))
    
    px_width, px_height = widths(scene.px_area[])
    aspect = px_width / px_height
    rel_pos = 2 .* mouseposition_px(scene) ./ (px_width, px_height) .- 1

    if cam.attributes.projectiontype[] === Perspective
        dir = (rel_pos[1] * aspect * u_x + rel_pos[2] * u_y) * 
                tand(0.5 * cam.attributes.fov[]) + u_z
        return Ray(eyepos, normalize(dir))
    else
        # Orthographic has consistent direction, but not starting point
        origin = norm(viewdir) * (rel_pos[1] * aspect * u_x + rel_pos[2] * u_y)
        return Ray(origin, normalize(viewdir))
    end
end



################################################################################
### Create Block
################################################################################


# Create Controller
Viewport3DController(x, axis::Union{LScene, Axis3}; kwargs...) = Viewport3DController(x; axis = axis, kwargs...)

function initialize_block!(controller::Viewport3DController; axis)
    blockscene = controller.blockscene

    scene_region = map(blockscene, controller.layoutobservables.computedbbox) do bb
        mini = minimum(bb); ws = widths(bb)
        center = mini + 0.5 * ws
        w = min(ws[1], ws[2])
        return round_to_IRect2D(Rect2(center .- 0.5 * w, Vec2(w)))
    end

    scene = Scene(
        blockscene, 
        px_area = scene_region, 
        # backgroundcolor = (:yellow, 0.3),
        clear = true
    )

    # m = Rhombicuboctahedron()
    texture = let
        # url = "https://raw.githubusercontent.com/linuxgurugamer/NavBallTextureChanger/master/GameData/NavBallTextureChanger/PluginData/Skins/Trekky0623_DIF.png"
        # path = Base.download(url)
        path = Makie.assetpath("navball_texture.png")
        img = FileIO.load(path)
        # rm(path)
        img
    end

    m = uv_normal_mesh(Tesselation(Sphere(Point3f(0), 1f0), 50))
    # @info length(coordinates(m))
    mp = mesh!(scene, m, color = texture, transparency = false, fxaa=!false)
    rotate!(mp, Vec3f(0, 0, 1), pi)

    step_choices = (4, 6, 8, 9, 10, 12, 16, 18, 24, 36, 72)
    step_index = Observable(3)
    step = map(i -> 2pi / step_choices[i], step_index)
    cam = ViewportControllerCamera(scene, axis, step = step)

    # info on step size
    timeout = Observable(-0.05)
    on(timeout) do remaining
        @info remaining
        @async if remaining >= 0.0
            sleep(0.05)
            timeout[] -= 0.05
        end
    end

    text!(
        scene, 
        Point2f(0.9), space = :clip, align = (:right, :top),
        text = map(i -> "$(360/step_choices[i])°", step_index),
        fontsize = 20, color = map(a -> (:black, a), timeout), 
        strokewidth = 2, strokecolor = map(a -> (:white, a), timeout), 
        visible = map(remaining -> remaining > 0, timeout)
    )

    # sphere background
    # bg = scatter!(
    #     scene, [Point2f(0) for _ in 1:3], space = :clip, 
    #     marker = Circle, markersize = [1.8, 1.77, 1.73], markerspace = :clip,
    #     color = [:black, :gray, :black], fxaa = true
    # )
    # translate!(bg, 0, 0, 1)
    bg = scatter!(
        scene, Point2f(0), space = :clip, 
        marker = Circle, markersize = 1.73, markerspace = :clip,
        color = :green, fxaa = true,
        glowcolor = :green, glowwidth = 5
    )
    translate!(bg, 0, 0, 1)

    # Mark selectable region
    phi_theta = Observable(Point2f(0, 0))
    region = map(phi_theta, step) do phi_theta, step
        r = 1.01
        if abs(phi_theta[2]) < pi/2 - 0.0001
            phi0 = phi_theta[1] - 0.5step
            phi1 = phi_theta[1] + 0.5step
            theta0 = phi_theta[2] - 0.5step
            theta1 = phi_theta[2] + 0.5step
            return vcat(
                spherical_to_cartesian.(range(phi0, phi1, length = 50), theta0, r),
                spherical_to_cartesian.(phi1, range(theta0, theta1, length = 50), r),
                spherical_to_cartesian.(range(phi1, phi0, length = 50), theta1, r),
                spherical_to_cartesian.(phi0, range(theta1, theta0, length = 50), r)
            )
        else
            return spherical_to_cartesian.(range(0, 2pi, length=100), phi_theta[2] - 0.5step, r)
        end
    end
    lp = lines!(
        scene, region, 
        color = :white, linewidth = 1, 
        # strokecolor = :black, strokewidth = 1,
        visible = false, fxaa = true#, depth_shift = -0.001
    )

    # Update angular step
    on(scene, events(scene).scroll) do e
        if is_mouseinside(scene)
            idx = trunc(Int, step_index[] - sign(e[2]))
            if 0 < idx <= length(step_choices) && (idx != step_index[])
                step_index[] = idx
                if timeout.val < 0.0
                    timeout[] = 3.0
                else
                    timeout.val = 3.0
                end
                if is_mouseinside(scene)
                    phi, theta = _hovered_angles(scene, cam, step[])
                    if !isnan(phi)
                        phi_theta[] = (phi, theta)
                    end
                end
            end
        end
    end

    # Update angles for selectable region
    on(scene, events(scene).mouseposition, priority = 1) do _
        if is_mouseinside(scene)
            phi, theta = _hovered_angles(scene, cam, step[])
            if !isnan(phi)
                phi_theta[] = (phi, theta)
                lp.visible[] = true
                return Consume(false)
            end
        end
        lp.visible[] = false
        return Consume(false)
    end

    on(scene, scene.camera.projectionview) do _
        if is_mouseinside(scene)
            phi, theta = _hovered_angles(scene, cam, step[])
            if !isnan(phi)
                phi_theta[] = (phi, theta)
                lp.visible[] = true
                return Consume(false)
            end
        end
        lp.visible[] = false
        return Consume(false)
    end

    return
end
