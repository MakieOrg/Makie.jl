################################################################################
### Block Setup
################################################################################


# Simplified/Modified from Camera3D to make sure updates work correctly
struct CameraWidgetCamera <: AbstractCamera
    phi::Observable{Float32}
    theta::Observable{Float32}
    attributes::Attributes
end


# Create floating Controller
"""
    CameraWidget(axis[; kwargs...])

Creates a camera widget free from the layout.
"""
function CameraWidget(axis::Union{LScene, Axis3}; kwargs...)
    CameraWidget(root(axis.scene); axis = axis, float = true, kwargs...)
end

# Create grid-based Controller
"""
    CameraWidget(gp, axis[; kwargs...])

Creates a camera widget free at a give layout position `gp`. E.g. `CameraWidget(fig[1, 2], lscene)`.
"""
function CameraWidget(x::Union{GridPosition, GridSubposition}, axis::Union{LScene, Axis3}; kwargs...)
    CameraWidget(x; axis = axis, float = false, kwargs...)
end


function initialize_block!(controller::CameraWidget; axis::Union{LScene, Axis3}, float::Bool)
    blockscene = controller.blockscene

    # Create Scene for Widget (possibly detached from gridlayout)
    if float
        align = map(blockscene, controller.halign, controller.valign) do halign, valign
            return Vec2f(halign2num(halign), valign2num(valign))
        end

        scene_region = map(blockscene,
            axis.layoutobservables.computedbbox, controller.float_size, align
        ) do parent_bb, size, align
            mini = minimum(parent_bb); ws = widths(parent_bb)
            anchor = mini .+ align .* ws
            size = minimum(size) # the scene should end up square
            origin = anchor .- align * size
            return round_to_IRect2D(Rect2(origin, Vec2f(size)))
        end
    else
        align = Observable(Vec2f(0, 0))
        scene_region = map(blockscene, controller.layoutobservables.computedbbox) do bb
            mini = minimum(bb); ws = widths(bb)
            center = mini + 0.5 * ws
            w = min(ws[1], ws[2])
            return round_to_IRect2D(Rect2(center .- 0.5 * w, Vec2(w)))
        end
    end

    scene = Scene(blockscene, viewport = scene_region) # clear = false

    # Handle textures
    # scene size threshholds for texture swaps
    selected_texture = RefValue(:none)

    texture = let
        w, h = widths(scene_region[])
        tex = if h < controller.low_mid_threshold[]
            selected_texture[] = :low
            controller.texture_low[]
        elseif h < controller.mid_high_threshold[]
            selected_texture[] = :mid
            controller.texture_mid[]
        else
            selected_texture[] = :high
            tex = controller.texture_high[]
        end
        Observable(tex)
    end

    on(scene_region) do bb
        w, h = widths(bb)
        if (h <= controller.low_mid_threshold[]) && (selected_texture[] != :low)
            selected_texture[] = :low
            texture[] = controller.texture_low[]
        elseif (controller.low_mid_threshold[] < h <= controller.mid_high_threshold[]) && (selected_texture[] != :mid)
            selected_texture[] = :mid
            texture[] = controller.texture_mid[]
        elseif (controller.mid_high_threshold[] < h) && (selected_texture[] != :high)
            selected_texture[] = :high
            texture[] = controller.texture_high[]
        end
    end

    # Generate sphere mesh
    m = uv_normal_mesh(Tesselation(Sphere(Point3f(0), 1f0), 50))
    mp = mesh!(
        scene, m, color = ShaderAbstractions.Sampler(texture, anisotropic = 16f0),
        transparency = false, fxaa=!false
    )
    rotate!(mp, Vec3f(0, 0, 1), pi)

    # Variables for selection ranges/steps
    step_index = Observable(3)
    step = map((r, i) -> 2pi / r[i], controller.step_choices, step_index)

    # Generate camera controls + linking
    cam = CameraWidgetCamera(
        scene, axis, step = step, fov = controller.fov,
        projectiontype = controller.projectiontype,
        rotationspeed = controller.rotationspeed,
        click_timeout = controller.click_timeout
    )

    # Angle step burnout text
    timeout = Observable(-0.05)
    on(timeout) do remaining
        @async if remaining >= 0.0
            sleep(0.05)
            timeout[] -= 0.05
        end
    end

    text!(
        scene,
        Point2f(0.9), space = :clip, align = (:right, :top),
        text = map((r, i) -> "$(360/r[i])°", controller.step_choices, step_index),
        fontsize = controller.angle_indicator_fontsize,
        color = map((c, a) -> (c, a), controller.angle_indicator_fontcolor, timeout),
        strokewidth = controller.angle_indicator_strokesize,
        strokecolor = map(a -> (:white, a), timeout),
        visible = map(remaining -> remaining > 0, timeout)
    )

    # sphere background
    bg = scatter!(
        scene, Point2f(0), space = :clip,
        marker = Circle, markersize = 1.75, markerspace = :clip,
        color = controller.backgroundcolor, fxaa = true,
    )
    translate!(bg, 0, 0, 1)

    # Create outline for hovered region
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
        color = controller.direction_indicator_color,
        linewidth = controller.direction_indicator_linewidth,
        visible = false, fxaa = true#, depth_shift = -0.001
    )

    # Update angular step
    on(scene, events(scene).scroll, priority = 100) do e
        if is_mouseinside(scene)
            idx = trunc(Int, step_index[] - sign(e[2]))
            if 0 < idx <= length(controller.step_choices[]) && (idx != step_index[])
                step_index[] = idx
                if timeout.val < 0.0
                    timeout[] = controller.angle_indicator_timeout[]
                else
                    timeout.val = controller.angle_indicator_timeout[]
                end
                if is_mouseinside(scene)
                    phi, theta = _hovered_angles(scene, cam, step[])
                    if !isnan(phi)
                        phi_theta[] = (phi, theta)
                    end
                end
            end
            return Consume(true)
        end
        return Consume(false)
    end


    # Translation of floating widget
    in_drag = RefValue(false)
    drag_offset = RefValue(Vec2f(0))
    on(scene, events(scene).mousebutton, priority = 101) do e
        if float && is_mouseinside(scene) && e.button == Mouse.right
            if e.action == Mouse.press
                drag_offset[] = origin(scene.viewport[]) .- events(scene).mouseposition[]
                in_drag[] = true
            else
                in_drag[] = false
            end
            return Consume(true)
        end
    end

    # Update angles for selectable region
    on(scene, events(scene).mouseposition, priority = 101) do mp
        if is_mouseinside(controller.blockscene) && float && in_drag[]
            size = controller.float_size[]
            bb = axis.layoutobservables.computedbbox[]
            xy = origin(bb); wh = widths(bb)
            align[] = (mp .+ drag_offset[] .- xy) ./ (wh .- size)
        elseif is_mouseinside(scene)
            phi, theta = _hovered_angles(scene, cam, step[])
            if !isnan(phi)
                phi_theta[] = (phi, theta)
                lp.visible[] = true
            else
                lp.visible[] = false
            end
        else
            lp.visible[] = false
        end
        return Consume(false)
    end

    on(scene, scene.camera.projectionview, priority = 100) do _
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


################################################################################
### Camera setup
################################################################################


function CameraWidgetCamera(scene::Scene, axis; kwargs...)
    kwdict = Dict(kwargs)
    attr = Attributes(
        fov = get(kwdict, :fov, 45.0),
        projectiontype = get(kwdict, :projectiontype, Makie.Perspective),
        rotationspeed = get(kwdict, :rotationspeed, 1.0),
        click_timeout = get(kwdict, :click_timeout, 0.3),
        step = get(kwdict, :step, 2pi/16),
        selected = false,
    )

    # This will be updated in connect_camera!
    if axis isa Axis3
        # Without this Axis3 ends up at a weird orientation...
        cam = CameraWidgetCamera(
            Observable{Float32}(axis.azimuth[]),
            Observable{Float32}(axis.elevation[]),
            attr
        )
    elseif axis isa LScene
        cam = CameraWidgetCamera(
            Observable{Float32}(0f0),
            Observable{Float32}(0f0),
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
    # scene.viewport,
    on(camera(scene), scene.viewport, attr[:fov], attr[:projectiontype]) do _, _, _
        update_cam!(scene, cam)
    end

    notify(attr.fov)

    connect_camera!(axis, scene)

    cam
end
deselect_camera!(cam::CameraWidgetCamera) = cam.attributes.selected[] = false

function Ray(scene::Scene, cam::CameraWidgetCamera, xy::VecTypes{2})
    phi = cam.phi[]; theta = cam.theta[]
    viewdir = - Vec3f(cos(theta) * cos(phi), cos(theta) * sin(phi), sin(theta))
    eyepos = - 3f0 * viewdir
    theta += pi/2
    up = Vec3f(cos(theta) * cos(phi), cos(theta) * sin(phi), sin(theta))

    u_z = normalize(viewdir)
    u_x = normalize(cross(u_z, up))
    u_y = normalize(cross(u_x, u_z))

    px_width, px_height = widths(scene.viewport[])
    aspect = px_width / px_height
    rel_pos = 2 .* xy ./ (px_width, px_height) .- 1

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

function _hovered_angles(scene, cam, step)
    # Pick in a small region to allow picking past lines on the sphere
    mp = events(scene).mouseposition[]
    mini = max.(minimum(scene.viewport[]) .+ 1, mp .- 2)
    maxi = min.(maximum(scene.viewport[]), mp .+ 2)
    selections = Makie.pick(scene, Rect2i(mini, maxi-mini))
    isempty(selections) && return NaN, NaN

    if any(pidx -> pidx[1] isa Mesh, selections)
        ray = Ray(scene, cam, mouseposition_px(scene))
        # ray = p + tv, Sphere: x² + y² + z² = r²
        # Solve resulting quadratic equation
        a = dot(ray.direction, ray.direction)
        b = 2 * dot(ray.origin, ray.direction)
        c = dot(ray.origin, ray.origin) - 1 # radius 1
        # goes below 0 only because rect pick may trigger outside sphere
        t2 = (-b - sqrt(max(0, b*b - 4*a*c))) / (2*a)
        p = ray.origin + t2 * ray.direction

        # to spherical
        theta = asin(clamp(p[3], -1.0, 1.0))
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

function add_rotation!(scene, cam::CameraWidgetCamera, axis)
    @extract cam.attributes (rotationspeed, click_timeout, step)
    drag_state = RefValue((false, Vec2f(0), time()))
    e = events(scene)

    # drag start/stop
    on(camera(scene), e.mousebutton, priority = 100) do event
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

                return Consume(true)
            end
        end

        return Consume(false)
    end

    # in drag
    on(camera(scene), e.mouseposition, priority = 100) do mp
        active, last_mousepos, last_time = drag_state[]
        if active && ispressed(scene, Mouse.left)
            mousepos = screen_relative(scene, mp)
            rot_scaling = rotationspeed[] * (e.window_dpi[] * 0.005)
            mp = (last_mousepos .- mousepos) * 0.01f0 * rot_scaling
            rotate_cam!(scene, cam, mp[1], mp[2], axis)
            drag_state[] = (active, mousepos, last_time)
            return Consume(true)
        end

        return Consume(false)
    end
end

function rotate_cam!(scene, cam::CameraWidgetCamera, dphi::Real, dtheta::Real, axis)
    cam.theta[] = mod(cam.theta[] + dtheta, 2pi)
    reverse = ifelse(pi/2 <= cam.theta[] <= 3pi/2, -1, 1)
    cam.phi[] = mod(cam.phi[] + reverse * dphi, 2pi)

    update_cam!(scene, cam)
    update_camera!(axis, cam.phi[], cam.theta[])

    return
end

# Update camera matrices
function update_cam!(scene::Scene, cam::CameraWidgetCamera, phi::Real, theta::Real)
    dphi = mod(2pi + cam.phi[] - phi, 2pi)
    dphi = ifelse(dphi > pi, dphi - 2pi, dphi)
    if !(-1.1pi/2 <= dphi <= 1.1pi/2)
        cam.phi[]   = mod(phi + pi, 2pi)
        cam.theta[] = mod(pi - theta, 2pi)
    else
        cam.phi[] = phi
        cam.theta[] = theta
    end
    return update_cam!(scene, cam)
end

function update_cam!(scene::Scene, cam::CameraWidgetCamera)
    # @extractvalue cam (lookat, eyeposition, upvector)
    fov = cam.attributes.fov[]

    phi = cam.phi[]; theta = cam.theta[]
    eyeposition = spherical_to_cartesian(phi, theta, 3f0)
    lookat = Vec3f(0)
    upvector = spherical_to_cartesian(phi, theta + pi/2)

    view = Makie.lookat(eyeposition, lookat, upvector)

    aspect = Float32((/)(widths(scene.viewport[])...))
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


################################################################################
### Texture generation
################################################################################


function generate_textures()
    for i in 1:3
        Makie.generate_ball_controller_texture(;
            majortick_step = (10, 15, 30)[i],
            minortick_step = (5, 5, 10)[i],
            merge_angle = (74, 74, 55)[i],
            majortick_linewidth = (6, 4, 3)[i],
            minortick_linewidth = 2.5 - 0.5i,
            minorticklength = (0.01, 0.01, 0.02)[i],
            majorticklength = (0.02, 0.02, 0.04)[i],
            ticklabelpad = (0.02, 0.02, 0.04)[i],
            ticklabel_strokewidth = (2, 2, 1.5)[i],
            resolution = (1600, 800) .>> (i-1),
            fontsize = (28, 22, 16)[i],
            hide_ring_labels = (false, false, true)[i],
            filename = Makie.assetpath("ball_controller_$(800 >> (i-1)).png")
        )
    end
end

function generate_ball_controller_texture(;
        top_color = RGBf(0.75, 0.9, 1),
        bottom_color = RGBf(0.65, 0.85, 0.5),
        majortick_step = 10, minortick_step = 5, merge_angle = 74,
        majortick_linewidth = 6, minortick_linewidth = 2,
        minorticklength = 0.01, majorticklength = 0.02,
        ticklabelpad = 0.02,
        ticklabelcolor = :white, ticklabeloutline = :black,
        ticklabel_strokewidth = 2,
        resolution = (1600, 800),
        fontsize = 28,
        linecolor = :black,
        hide_ring_labels = false,
        save = true,
        filename = Makie.assetpath("ball_controller_texture.png")
    )

    # Scaling due to shrinking circumference
    scaling(z) = min(1e6, 1.0 / cos(z * pi/2))

    parent = Scene(resolution = resolution, backgroundcolor = top_color, clear = true)
    Scene(
        parent,
        viewport = map(r -> Rect2i(0, 0, widths(r)[1], 0.5widths(r)[2]), parent.viewport),
        backgroundcolor = bottom_color, clear = true
    )
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

    # Minor north-south lines
    zs = range(-1, 1, length = 301)
    for x in (-0.75, -0.25, 0.25, 0.75)
        lines!(
            scene, fill(x, length(zs)), zs, linewidth = minortick_linewidth * scaling.(zs),
            color = linecolor
        )
    end

    # equator ring
    lines!(scene, [-1.1, 1.1], [0.0, 0.0], linewidth = majortick_linewidth, color = linecolor)
    # 45° rings
    for z in (-0.5, 0.5)
        lines!(scene, [-1, 1], [z, z], linewidth = minortick_linewidth, color = linecolor)
    end

    # Vertical ticks

    minor_tick_positions = vcat(reverse(0:-minortick_step:-81), (0:minortick_step:81))
    major_tick_positions = vcat(reverse(0:-majortick_step:-81), (0:majortick_step:81))

    # discard overlapping ticks
    for (trg, src) in zip(
            (minor_tick_positions, minor_tick_positions, major_tick_positions),
            (major_tick_positions, (-45, 0, 45), (-45, 0, 45))
        )

        filter!(trg) do trg_phi
            for src_phi in src
                if abs(trg_phi - src_phi) < 1
                    return false
                end
            end
            return true
        end
    end

    # Common
    xs = (-1.0, -0.5, 0.0, 0.5, 1.0)

    # Minor Ticks
    zs = minor_tick_positions ./ 90
    ps = [Point2f(x+dx*scaling(z), z) for z in zs for x in xs for dx in (-minorticklength, minorticklength)]
    linesegments!(
        scene, ps, color = linecolor, linewidth = minortick_linewidth#, fxaa = fxaa
    )

    # Major Ticks
    zs = major_tick_positions ./ 90
    ps = [Point2f(x+dx*scaling(z), z) for z in zs for x in xs for dx in (-majorticklength, majorticklength)]
    linesegments!(scene, ps, color = linecolor, linewidth = minortick_linewidth)

    # Separate labels
    ticks = filter(v -> abs(v) < merge_angle, major_tick_positions)
    zs = ticks ./ 90
    ps = [Point2f(x + (majorticklength + ticklabelpad) * scaling(z), z) for z in zs for x in xs]
    text!(
        scene, ps,
        text = [string(z) for z in ticks for x in xs],
        color = ticklabelcolor, fontsize = fontsize .* Vec2f.(scaling.(last.(ps)), 1),
        strokecolor = ticklabeloutline, strokewidth = ticklabel_strokewidth,
        align = (:left, :center),
    )

    ps = [Point2f(x - (majorticklength + ticklabelpad) * scaling(z), z) for z in zs for x in xs]
    text!(
        scene, ps,
        text = [string(z) for z in ticks for x in xs],
        color = ticklabelcolor, fontsize = fontsize .* Vec2f.(scaling.(last.(ps)), 1),
        strokecolor = ticklabeloutline, strokewidth = ticklabel_strokewidth,
        align = (:right, :center)
    )

    # Merged labels
    ticks = filter(v -> abs(v) > merge_angle, major_tick_positions)
    zs = ticks ./ 90
    xs = (-0.75, -0.25, 0.25, 0.75)
    ps = [Point2f(x, z) for z in zs for x in xs]
    text!(
        scene, ps,
        text = [string(z) for z in ticks for x in xs],
        color = ticklabelcolor, fontsize = fontsize .* Vec2f.(scaling.(last.(ps)), 1),
        strokecolor = ticklabeloutline, strokewidth = ticklabel_strokewidth,
        align = (:center, :center)
    )


    # Horizontal Labels
    horizontal_labels = ("-X", "225", "-Y", "315", "X", "45", "Y", "135", "-X")
    text!(
        scene,
        [Point2f(x, 0) for x in range(-1, 1, length = 9)],
        text = [str for str in horizontal_labels],
        color = ticklabelcolor, fontsize = fontsize,
        strokecolor = ticklabeloutline, strokewidth = ticklabel_strokewidth,
        align = (:center, :center),
    )
    if !hide_ring_labels
        text!(
            scene,
            [Point2f(x, z) for x in range(-1, 1, length = 9) for z in (-0.5, 0.5)],
            text = [str for str in horizontal_labels for z in 1:2],
            color = ticklabelcolor, fontsize = fontsize * Vec2f(scaling(0.5), 1),
            strokecolor = ticklabeloutline, strokewidth = ticklabel_strokewidth,
            align = (:center, :center),
        )
    end

    # Frame
    linesegments!(
        scene, [-1, 1, -1, 1], [1, 1, -1, -1],
        color = linecolor, linewidth = 2*majortick_linewidth#, fxaa = fxaa
    )

    save && Makie.save(filename, parent)

    return parent
end
