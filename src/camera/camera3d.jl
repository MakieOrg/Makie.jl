abstract type AbstractCamera3D <: AbstractCamera end

struct Camera3D <: AbstractCamera3D
    # User settings
    settings::Attributes
    controls::Attributes

    # Interactivity
    pulser::Observable{Float64}
    selected::Observable{Bool}
    # scroll_mod::Observable{Bool}

	# view matrix
    eyeposition::Observable{Vec3f}
    lookat::Observable{Vec3f}
    upvector::Observable{Vec3f}
	
	# perspective projection matrix
    fov::Observable{Float32}
    near::Observable{Float32}
    far::Observable{Float32}
end

"""
    Camera3D(scene[; attributes...])

Creates a 3d camera with a lot of controls.

The 3D camera is (or can be) unrestricted in terms of rotations and translations. Both `cam3d!(scene)` and `cam3d_cad!(scene)` create this camera type. Unlike the 2D camera, settings and controls are stored in the `cam.attributes` field rather than in the struct directly, but can still be passed as keyword arguments. The general camera settings include

- `fov = 45f0` sets the "neutral" field of view, i.e. the fov corresponding to no zoom. This is irrelevant if the camera uses an orthographic projection.
- `near = automatic` sets the value of the near clip. By default this will be chosen based on the scenes bounding box. The final value is in `cam.near`.
- `far = automatic` sets the value of the far clip. By default this will be chosen based on the scenes bounding box. The final value is in `cam.far`.
- `rotation_center = :lookat` sets the default center for camera rotations. Currently allows `:lookat` or `:eyeposition`.
- `projectiontype = Perspective` sets the type of the projection. Can be `Orthographic` or `Perspective`.
- `fixed_axis = false`: If true panning uses the (world/plot) z-axis instead of the camera up direction.
- `zoom_shift_lookat = true`: If true attempts to keep data under the cursor in view when zooming.
- `cad = false`: If true rotates the view around `lookat` when zooming off-center.

The camera view follows from the position of the camera `eyeposition`, the point which the camera focuses `lookat` and the up direction of the camera `upvector`. These can be accessed as `cam.eyeposition` etc and adjusted via `update_cam!(scene, cameracontrols(scene), eyeposition, lookat[, upvector = Vec3f(0, 0, 1)])`. They can also be passed as keyword arguments when the camera is constructed.

The camera can be controlled by keyboard and mouse. The keyboard has the following available attributes

- `up_key   = Keyboard.r` sets the key for translations towards the top of the screen.
- `down_key = Keyboard.f` sets the key for translations towards the bottom of the screen.
- `left_key  = Keyboard.a` sets the key for translations towards the left of the screen.
- `right_key = Keyboard.d` sets the key for translations towards the right of the screen.
- `forward_key  = Keyboard.w` sets the key for translations into the screen.
- `backward_key = Keyboard.s` sets the key for translations out of the screen.

- `zoom_in_key   = Keyboard.u` sets the key for zooming into the scene (enlarge, via fov).
- `zoom_out_key  = Keyboard.o` sets the key for zooming out of the scene (shrink, via fov).
- `stretch_view_key  = Keyboard.page_up` sets the key for moving `eyepostion` away from `lookat`.
- `contract_view_key = Keyboard.page_down` sets the key for moving `eyeposition` towards `lookat`.

- `pan_left_key  = Keyboard.j` sets the key for rotations around the screens vertical axis.
- `pan_right_key = Keyboard.l` sets the key for rotations around the screens vertical axis.
- `tilt_up_key   = Keyboard.i` sets the key for rotations around the screens horizontal axis.
- `tilt_down_key = Keyboard.k` sets the key for rotations around the screens horizontal axis.
- `roll_clockwise_key        = Keyboard.e` sets the key for rotations of the screen.
- `roll_counterclockwise_key = Keyboard.q` sets the key for rotations of the screen.

- `keyboard_rotationspeed = 1f0` sets the speed of keyboard based rotations.
- `keyboard_translationspeed = 0.5f0` sets the speed of keyboard based translations.
- `keyboard_zoomspeed = 1f0` sets the speed of keyboard based zooms.
- `update_rate = 1/30` sets the rate at which keyboard based camera updates are evaluated.

and mouse interactions are controlled by

- `translation_button = Mouse.right` sets the mouse button for drag-translations. (up/down/left/right)
- `scroll_mod = true` sets an additional modifier button for scroll-based zoom. (true being neutral)
- `rotation_button = Mouse.left` sets the mouse button for drag-rotations. (pan, tilt)

- `mouse_rotationspeed = 1f0` sets the speed of mouse rotations.
- `mouse_translationspeed = 0.5f0` sets the speed of mouse translations.
- `mouse_zoomspeed = 1f0` sets the speed of mouse zooming (mousewheel).
- `circular_rotation = (true, true, true)` enables circular rotations for (fixed x, fixed y, fixed z) rotation axis. (This means drawing a circle with your mouse around the center of the scene will result in a continuous rotation.)

There are also a few generally applicable controls:

- `fix_x_key = Keyboard.x` sets the key for fixing translations and rotations to the (world/plot) x-axis.
- `fix_y_key = Keyboard.y` sets the key for fixing translations and rotations to the (world/plot) y-axis.
- `fix_z_key = Keyboard.z` sets the key for fixing translations and rotations to the (world/plot) z-axis.
- `reset = Keyboard.home` sets the key for fully resetting the camera. This equivalent to setting `lookat = Vec3f(0)`, `upvector = Vec3f(0, 0, 1)`, `eyeposition = Vec3f(3)` and then calling `center!(scene)`.

You can also make adjustments to the camera position, rotation and zoom by calling relevant functions:

- `translate_cam!(scene, v)` will translate the camera by the given world/plot space vector `v`.
- `rotate_cam!(scene, angles)` will rotate the camera around its axes with the corresponding angles. The first angle will rotate around the cameras "right" that is the screens horizontal axis, the second around the up vector/vertical axis or `Vec3f(0, 0, +-1)` if `fixed_axis = true`, and the third will rotate around the view direction i.e. the axis out of the screen. The rotation respects the current `rotation_center` of the camera.
- `zoom!(scene, zoom_step)` will change the zoom level of the scene without translating or rotating the scene. `zoom_step` applies multiplicatively to `cam.zoom_mult` which is used as a multiplier to the fov (perspective projection) or width and height (orthographic projection).
"""
function Camera3D(scene::Scene; kwargs...)
    overwrites = Attributes(kwargs)

    controls = Attributes(
        # Keyboard controls
        # Translations
        up_key        = Keyboard.r,
        down_key      = Keyboard.f,
        left_key      = Keyboard.a,
        right_key     = Keyboard.d,
        forward_key   = Keyboard.w,
        backward_key  = Keyboard.s,
        # Zooms
        zoom_in_key   = Keyboard.u,
        zoom_out_key  = Keyboard.o,
        # Rotations
        pan_left_key  = Keyboard.j,
        pan_right_key = Keyboard.l,
        tilt_up_key   = Keyboard.i,
        tilt_down_key = Keyboard.k,
        roll_clockwise_key        = Keyboard.e,
        roll_counterclockwise_key = Keyboard.q,
        # Mouse controls
        translation_button = Mouse.right,
        rotation_button    = Mouse.left,
        scroll_mod         = true,
        # Shared controls
        fix_x_key = Keyboard.x,
        fix_y_key = Keyboard.y,
        fix_z_key = Keyboard.z,
        reset = Keyboard.home
    )

    replace!(controls, :Camera3D, scene, overwrites)

    settings = Attributes(
        keyboard_rotationspeed = 1f0,
        keyboard_translationspeed = 0.5f0,
        keyboard_zoomspeed = 1f0,

        mouse_rotationspeed = 1f0,
        mouse_translationspeed = 1f0,
        mouse_zoomspeed = 1f0,
        
        enable_translation = true,
        enable_rotation = true,
        enable_zoom = true,
        
        projectiontype = Makie.Perspective,
        circular_rotation = (true, true, true),
        rotation_center = :lookat,
        update_rate = 1/30,
        zoom_shift_lookat = true,
        fixed_axis = true,
        cad = false
    )

    replace!(settings, :Camera3D, scene, overwrites)

    cam = Camera3D(
        settings, controls, 

        # Internals - controls
        Observable(-1.0),
        Observable(true),

        # Semi-Internal - view matrix
        get(overwrites, :eyeposition, Observable(Vec3f(3, 3, 3))),
        get(overwrites, :lookat,      Observable(Vec3f(0, 0, 0))),
        get(overwrites, :upvector,    Observable(Vec3f(0, 0, 1))),

        # Semi-Internal - projection matrix
        get(overwrites, :fov, Observable(45.0)),
        get(overwrites, :near, Observable(0.1)),
        get(overwrites, :far, Observable(10.0)),
    )

    disconnect!(camera(scene))

    # Keyboard controls
    # ticks every so often to get consistent position updates.
    on(cam.pulser) do prev_time
        current_time = time()
        active = on_pulse(scene, cam, current_time - prev_time)
        @async if active && cam.selected[]
            sleep(settings.update_rate[])
            cam.pulser[] = current_time
        else
            cam.pulser.val = -1.0
        end
    end

    keynames = (
        :up_key, :down_key, :left_key, :right_key, :forward_key, :backward_key,
        :zoom_in_key, :zoom_out_key,
        :pan_left_key, :pan_right_key, :tilt_up_key, :tilt_down_key,
        :roll_clockwise_key, :roll_counterclockwise_key
    )

    # Start ticking if relevant keys are pressed
    on(camera(scene), events(scene).keyboardbutton) do event
        if event.action in (Keyboard.press, Keyboard.repeat) && cam.pulser[] == -1.0 &&
            cam.selected[] && any(key -> ispressed(scene, controls[key][]), keynames)

            cam.pulser[] = time()
            return Consume(true)
        end
        return Consume(false)
    end

    # de/select plot on click outside/inside
    # also deselect other cameras
    deselect_all_cameras!(root(scene))
    on(camera(scene), events(scene).mousebutton, priority = 100) do event
        if event.action == Mouse.press
            cam.selected[] = is_mouseinside(scene)
        end
        return Consume(false)
    end

    # Mouse controls
    add_translation!(scene, cam)
    add_rotation!(scene, cam)

    # add camera controls to scene
    cameracontrols!(scene, cam)

    # Trigger updates on scene resize and settings change
    on(camera(scene), cam.fov) do _
        if settings.projectiontype[] == Makie.Perspective
            update_cam!(scene, cam)
        end
    end
    on(camera(scene), scene.px_area, cam.near, cam.far, settings.projectiontype) do _, _, _, _
        update_cam!(scene, cam)
    end

    # reset
    on(camera(scene), events(scene).keyboardbutton) do event
        if cam.selected[] && event.key == controls[:reset][] && event.action == Keyboard.release
            # center keeps the rotation of the camera so we reset that here
            # might make sense to keep user set lookat, upvector, eyeposition
            # around somewhere for this?
            center!(scene)
            return Consume(true)
        end
        return Consume(false)
    end
    update_cam!(scene, cam)
    cam
end

# These imitate the old camera
cam3d!(scene; zoom_shift_lookat = true, fixed_axis = true, kwargs...) =
    Camera3D(scene, zoom_shift_lookat = zoom_shift_lookat, fixed_axis = fixed_axis; kwargs...)

cam3d_cad!(scene; cad = true, zoom_shift_lookat = false, fixed_axis = false, kwargs...) =
    Camera3D(scene, cad = cad, zoom_shift_lookat = zoom_shift_lookat, fixed_axis = fixed_axis; kwargs...)

function deselect_all_cameras!(scene)
    cam = cameracontrols(scene)
    cam isa AbstractCamera3D && (cam.selected[] = false)
    for child in scene.children
        deselect_all_cameras!(child)
    end
    nothing
end


################################################################################
### Interactivity init
################################################################################



function on_pulse(scene, cam::Camera3D, timestep)
    @extractvalue cam.controls (
        right_key, left_key, up_key, down_key, backward_key, forward_key,
        tilt_up_key, tilt_down_key, pan_left_key, pan_right_key, roll_counterclockwise_key, roll_clockwise_key,
        zoom_out_key, zoom_in_key
    )
    @extractvalue cam.settings (
        keyboard_translationspeed, keyboard_rotationspeed, keyboard_zoomspeed, projectiontype
    )

    # translation
    right       = ispressed(scene, right_key)
    left        = ispressed(scene, left_key)
    up          = ispressed(scene, up_key)
    down        = ispressed(scene, down_key)
    backward    = ispressed(scene, backward_key)
    forward     = ispressed(scene, forward_key)
    translating = right || left || up || down || backward || forward

    if translating
        # translation in camera space x/y/z direction
        if projectiontype == Perspective
            viewnorm = norm(cam.lookat[] - cam.eyeposition[])
            xynorm = 2 * viewnorm * tand(0.5 * cam.fov[])
            translation = keyboard_translationspeed * timestep * Vec3f(
                xynorm * (right - left), 
                xynorm * (up - down), 
                viewnorm * (backward - forward)
            )
        else
            # translation in camera space x/y/z direction
            viewnorm = norm(cam.eyeposition[] - cam.lookat[])
            translation = 2 * viewnorm * keyboard_translationspeed * timestep * Vec3f(
                right - left, up - down, backward - forward
            )
        end
        _translate_cam!(scene, cam, translation)
    end

    # rotation
    up               = ispressed(scene, tilt_up_key)
    down             = ispressed(scene, tilt_down_key)
    left             = ispressed(scene, pan_left_key)
    right            = ispressed(scene, pan_right_key)
    counterclockwise = ispressed(scene, roll_counterclockwise_key)
    clockwise        = ispressed(scene, roll_clockwise_key)
    rotating = up || down || left || right || counterclockwise || clockwise

    if rotating
        # rotations around camera space x/y/z axes
        angles = keyboard_rotationspeed * timestep *
            Vec3f(up - down, left - right, counterclockwise - clockwise)

        _rotate_cam!(scene, cam, angles)
    end

    # zoom
    zoom_out = ispressed(scene, zoom_out_key)
    zoom_in  = ispressed(scene, zoom_in_key)
    zooming = zoom_out || zoom_in

    if zooming
        zoom_step = (1f0 + keyboard_zoomspeed * timestep) ^ (zoom_out - zoom_in)
        _zoom!(scene, cam, zoom_step, false)
    end

    # if any are active, update matrices, else stop clock
    if translating || rotating || zooming
        update_cam!(scene, cam)
        return true
    else
        return false
    end
end


function add_translation!(scene, cam::Camera3D)
    @extract cam.controls (translation_button, scroll_mod)
    @extract cam.settings (mouse_translationspeed, mouse_zoomspeed, cad, projectiontype)

    last_mousepos = RefValue(Vec2f(0, 0))
    dragging = RefValue(false)

    function compute_diff(delta)
        if projectiontype[] == Perspective
          # TODO wrong scaling? :(
            ynorm = 2 * norm(cam.lookat[] - cam.eyeposition[]) * tand(0.5 * cam.fov[])
            return ynorm / widths(scene.px_area[])[2] * delta
        else
            viewnorm = norm(cam.eyeposition[] - cam.lookat[])
            return 2 * viewnorm / widths(scene.px_area[])[2] * delta
        end
    end

    # drag start/stop
    on(camera(scene), scene.events.mousebutton) do event
        if ispressed(scene, translation_button[])
            if event.action == Mouse.press && is_mouseinside(scene) && !dragging[]
                last_mousepos[] = mouseposition_px(scene)
                dragging[] = true
                return Consume(true)
            end
        elseif event.action == Mouse.release && dragging[]
            mousepos = mouseposition_px(scene)
            diff = compute_diff(last_mousepos[] .- mousepos)
            last_mousepos[] = mousepos
            dragging[] = false
            translate_cam!(scene, cam, mouse_translationspeed[] .* Vec3f(diff[1], diff[2], 0f0))
            return Consume(true)
        end
        return Consume(false)
    end

    # in drag
    on(camera(scene), scene.events.mouseposition) do mp
        if dragging[] && ispressed(scene, translation_button[])
            mousepos = screen_relative(scene, mp)
            diff = compute_diff(last_mousepos[] .- mousepos)
            last_mousepos[] = mousepos
            translate_cam!(scene, cam, mouse_translationspeed[] * Vec3f(diff[1], diff[2], 0f0))
            return Consume(true)
        end
        return Consume(false)
    end

    on(camera(scene), scene.events.scroll) do scroll
        if is_mouseinside(scene) && ispressed(scene, scroll_mod[])
            zoom_step = (1f0 + 0.1f0 * mouse_zoomspeed[]) ^ -scroll[2]
            zoom!(scene, cam, zoom_step, cad[])
            return Consume(true)
        end
        return Consume(false)
    end
end


function add_rotation!(scene, cam::Camera3D)
    @extract cam.controls (rotation_button, )
    @extract cam.settings (mouse_rotationspeed, )

    last_mousepos = RefValue(Vec2f(0, 0))
    dragging = RefValue(false)
    e = events(scene)

    # drag start/stop
    on(camera(scene), e.mousebutton) do event
        if ispressed(scene, rotation_button[])
            if event.action == Mouse.press && is_mouseinside(scene) && !dragging[]
                last_mousepos[] = mouseposition_px(scene)
                dragging[] = true
                return Consume(true)
            end
        elseif event.action == Mouse.release && dragging[]
            mousepos = mouseposition_px(scene)
            dragging[] = false
            rot_scaling = mouse_rotationspeed[] * (e.window_dpi[] * 0.005)
            mp = (last_mousepos[] .- mousepos) .* 0.01f0 .* rot_scaling
            last_mousepos[] = mousepos
            rotate_cam!(scene, cam, Vec3f(-mp[2], mp[1], 0f0), true)
            return Consume(true)
        end
        return Consume(false)
    end

    # in drag
    on(camera(scene), e.mouseposition) do mp
        if dragging[] && ispressed(scene, rotation_button[])
            mousepos = screen_relative(scene, mp)
            rot_scaling = mouse_rotationspeed[] * (e.window_dpi[] * 0.005)
            mp = (last_mousepos[] .- mousepos) * 0.01f0 * rot_scaling
            last_mousepos[] = mousepos
            rotate_cam!(scene, cam, Vec3f(-mp[2], mp[1], 0f0), true)
            return Consume(true)
        end
        return Consume(false)
    end
end


################################################################################
### Camera transformations
################################################################################


# Simplified methods
function translate_cam!(scene, cam::Camera3D, t::VecTypes)
    _translate_cam!(scene, cam, t)
    update_cam!(scene, cam)
    nothing
end

function rotate_cam!(scene, cam::Camera3D, angles::VecTypes, from_mouse=false)
    _rotate_cam!(scene, cam, angles, from_mouse)
    update_cam!(scene, cam)
    nothing
end

"""
    zoom!(scene, zoom_step)

Zooms the camera in or out based on the multiplier `zoom_step`. A `zoom_step`
of 1.0 is neutral, larger zooms out and lower zooms in.

Note that this method only applies to Camera3D.
"""
zoom!(scene, zoom_step) = zoom!(scene, cameracontrols(scene), zoom_step, false)
function zoom!(scene, cam, zoom_step, cad = false)
    _zoom!(scene, cam, zoom_step, cad)
    update_cam!(scene, cam)
    nothing
end


function _translate_cam!(scene, cam::Camera3D, t)
    cam.settings.enable_translation[] || return

    @extractvalue cam.controls (fix_x_key, fix_y_key, fix_z_key)

    # This uses a camera based coordinate system where
    # x expands right, y expands up and z expands towards the screen
    lookat = cam.lookat[]
    eyepos = cam.eyeposition[]
    up = normalize(cam.upvector[])
    u_z = normalize(eyepos - lookat)
    u_x = normalize(cross(up, u_z))
    u_y = normalize(cross(u_z, u_x))

    trans = u_x * t[1] + u_y * t[2] + u_z * t[3]

    # apply world space restrictions
    fix_x = ispressed(scene, fix_x_key)::Bool
    fix_y = ispressed(scene, fix_y_key)::Bool
    fix_z = ispressed(scene, fix_z_key)::Bool
    if fix_x || fix_y || fix_z
        trans = Vec3f(fix_x, fix_y, fix_z) .* trans
    end

    cam.eyeposition[] = eyepos + trans
    cam.lookat[] = lookat + trans
    return
end


function _rotate_cam!(scene, cam::Camera3D, angles::VecTypes, from_mouse=false)
    cam.settings.enable_rotation[] || return

    @extractvalue cam.controls (fix_x_key, fix_y_key, fix_z_key)
    @extractvalue cam.settings (fixed_axis, circular_rotation, rotation_center)

    # This applies rotations around the x/y/z axis of the camera coordinate system
    # x expands right, y expands up and z expands towards the screen
    lookat = cam.lookat[]
    eyepos = cam.eyeposition[]
    up = cam.upvector[]         # +y
    viewdir = lookat - eyepos   # -z
    right = cross(viewdir, up)  # +x

    x_axis = right
    y_axis = fixed_axis ? Vec3f(0, 0, ifelse(up[3] < 0, -1, 1)) : up
    z_axis = -viewdir

    fix_x = ispressed(scene, fix_x_key)::Bool
    fix_y = ispressed(scene, fix_y_key)::Bool
    fix_z = ispressed(scene, fix_z_key)::Bool
    cx, cy, cz = circular_rotation

    rotation = Quaternionf(0, 0, 0, 1)
    if !xor(fix_x, fix_y, fix_z)
        # if there are more or less than one restriction apply all rotations
        rotation *= qrotation(x_axis, angles[1])
        rotation *= qrotation(y_axis, angles[2])
        rotation *= qrotation(z_axis, angles[3])
    else
        # apply world space restrictions
        if from_mouse && ((fix_x && cx) || (fix_y && cy) || (fix_z && cz))
            # recontextualize the (dy, dx, 0) from mouse rotations so that
            # drawing circles creates continuous rotations around the fixed axis
            mp = mouseposition_px(scene)
            past_half = 0.5f0 .* widths(scene.px_area[]) .> mp
            flip = 2f0 * past_half .- 1f0
            angle = flip[1] * angles[1] + flip[2] * angles[2]
            angles = Vec3f(-angle, -angle, angle)
            # only one fix is true so this only rotates around one axis
            rotation *= qrotation(
                Vec3f(fix_x, fix_y, fix_z) .* Vec3f(sign(right[1]), viewdir[2], sign(up[3])),
                dot(Vec3f(fix_x, fix_y, fix_z), angles)
            )
        else
            # restrict total quaternion rotation to one axis
            rotation *= qrotation(x_axis, angles[1])
            rotation *= qrotation(y_axis, angles[2])
            rotation *= qrotation(z_axis, angles[3])
            # the first three components are related to rotations around the x/y/z-axis
            rotation = Quaternionf(rotation.data .* (fix_x, fix_y, fix_z, 1))
        end
    end

    cam.upvector[] = rotation * up
    viewdir = rotation * viewdir

    # TODO maybe generalize this to arbitrary center?
    # calculate positions from rotated vectors
    if rotation_center === :lookat
        cam.eyeposition[] = lookat - viewdir
    else
        cam.lookat[] = eyepos + viewdir
    end

    return
end


function _zoom!(scene, cam::Camera3D, zoom_step, cad = false)
    cam.settings.enable_zoom[] || return

    lookat = cam.lookat[]
    eyepos = cam.eyeposition[]
    viewdir = lookat - eyepos   # -z
    
    if cad
        # Rotate view based on offset from center
        u_z = normalize(viewdir)
        u_x = normalize(cross(u_z, cam.upvector[]))
        u_y = normalize(cross(u_x, u_z))

        rel_pos = 2f0 * mouseposition_px(scene) ./ widths(scene.px_area[]) .- 1f0
        shift = rel_pos[1] * u_x + rel_pos[2] * u_y
        shift *= 0.1 * sign(1 - zoom_step) * norm(viewdir)

        cam.eyeposition[] = lookat - zoom_step * viewdir + shift
    elseif cam.settings.projectiontype[] == Makie.Orthographic && cam.settings.zoom_shift_lookat[]
        # keep data under cursor
        u_z = normalize(viewdir)
        u_x = normalize(cross(u_z, cam.upvector[]))
        u_y = normalize(cross(u_x, u_z))
            
        ws = widths(scene.px_area[])
        rel_pos = (2.0 .* mouseposition_px(scene) .- ws) ./ ws[2]
        shift = (1 - zoom_step) * norm(viewdir) * (rel_pos[1] * u_x + rel_pos[2] * u_y)

        cam.lookat[]      = lookat + shift
        cam.eyeposition[] = lookat - zoom_step * viewdir + shift
    else
        # just zoom in/out
        cam.eyeposition[] = lookat - zoom_step * viewdir
    end

    return
end


################################################################################
### update_cam! methods
################################################################################


# Update camera matrices
function update_cam!(scene::Scene, cam::Camera3D)
    @extractvalue cam (lookat, eyeposition, upvector, near, far, fov)

    view = Makie.lookat(eyeposition, lookat, upvector)

    aspect = Float32((/)(widths(scene.px_area[])...))
    if cam.settings.projectiontype[] == Makie.Perspective
        view_norm = norm(eyeposition - lookat)
        proj = perspectiveprojection(fov, aspect, view_norm * near, view_norm * far)
    else
        h = norm(eyeposition - lookat); w = h * aspect
        proj = orthographicprojection(-w, w, -h, h, h * near, h * far)
    end

    set_proj_view!(camera(scene), proj, view)

    scene.camera.eyeposition[] = cam.eyeposition[]
end


# Update camera position via bbox
function update_cam!(scene::Scene, cam::Camera3D, area3d::Rect)
    bb = Rect3f(area3d)
    width = widths(bb)
    center = maximum(bb) - 0.5 * width

    old_dir = normalize(cam.eyeposition[] .- cam.lookat[])
    if cam.settings.projectiontype[] == Makie.Perspective
        dist = 0.5 * norm(width) * (1.0 + 0.6 / tand(0.5 * cam.fov[]))
    else
        dist = 0.6 * norm(width)
    end

    cam.lookat[]      =  center
    cam.eyeposition[] = cam.lookat[] .+ dist * old_dir
    cam.upvector[]    = Vec3f(0, 0, 1) # Should we reset this?

    update_cam!(scene, cam)

    return
end

# Update camera position via camera Position & Orientation
function update_cam!(scene::Scene, camera::Camera3D, eyeposition, lookat, up = camera.upvector[])
    camera.lookat[]      = Vec3f(lookat)
    camera.eyeposition[] = Vec3f(eyeposition)
    camera.upvector[]    = Vec3f(up)
    update_cam!(scene, camera)
    return
end


function show_cam(scene)
    cam = cameracontrols(scene)
    println("cam=cameracontrols(scene)")
    println("cam.eyeposition[] = ", round.(cam.eyeposition[], digits=2))
    println("cam.lookat[] = ", round.(cam.lookat[], digits=2))
    println("cam.upvector[] = ", round.(cam.upvector[], digits=2))
    println("cam.fov[] = ", round.(cam.fov[], digits=2))
    return
end
