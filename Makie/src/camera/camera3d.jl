abstract type AbstractCamera3D <: AbstractCamera end

get_space(::AbstractCamera3D) = :data

struct Camera3D <: AbstractCamera3D
    # User settings
    settings::Attributes
    controls::Attributes

    # Interactivity
    selected::Observable{Bool}

    # view matrix
    eyeposition::Observable{Vec3d}
    lookat::Observable{Vec3d}
    upvector::Observable{Vec3d}

    # perspective projection matrix
    fov::Observable{Float64}
    near::Observable{Float64}
    far::Observable{Float64}
    bounding_sphere::Observable{Sphere{Float64}}
end

"""
    Camera3D(scene[; kwargs...])

Sets up a 3D camera with mouse and keyboard controls.

The behavior of the camera can be adjusted via keyword arguments or the fields
`settings` and `controls`.

## Settings

Settings include anything that isn't a mouse or keyboard button.

- `projectiontype = Perspective` sets the type of the projection. Can be `Orthographic` or `Perspective`.
- `rotation_center = :lookat` sets the default center for camera rotations. Currently allows `:lookat` or `:eyeposition`.
- `fixed_axis = true`: If true panning uses the (world/plot) z-axis instead of the camera up direction.
- `zoom_shift_lookat = true`: If true keeps the data under the cursor when zooming.
- `cad = false`: If true rotates the view around `lookat` when zooming off-center.
- `clipping_mode = :adaptive`: Controls how `near` and `far` get processed. Options:
    - `:static` passes `near` and `far` as is
    - `:adaptive` scales `near` by `norm(eyeposition - lookat)` and passes `far` as is
    - `:view_relative` scales `near` and `far` by `norm(eyeposition - lookat)`
    - `:bbox_relative` scales `near` and `far` to the scene bounding box as passed to the camera with `update_cam!(..., bbox)`. (More specifically `far = 1` is scaled to the furthest point of a bounding sphere and `near` is generally overwritten to be the closest point.)
- `center = true`: Controls whether the camera placement gets reset when calling `center!(scene)`, which is called when a new plot is added.

- `keyboard_rotationspeed = 1.0` sets the speed of keyboard based rotations.
- `keyboard_translationspeed = 0.5` sets the speed of keyboard based translations.
- `keyboard_zoomspeed = 1.0` sets the speed of keyboard based zooms.

- `mouse_rotationspeed = 1.0` sets the speed of mouse rotations.
- `mouse_translationspeed = 0.5` sets the speed of mouse translations.
- `mouse_zoomspeed = 1.0` sets the speed of mouse zooming (mousewheel).

- `circular_rotation = (false, false, false)` enables circular rotations for (fixed x, fixed y, fixed z) rotation axis. (This means drawing a circle with your mouse around the center of the scene will result in a continuous rotation.)

## Controls

Controls include any kind of hotkey setting.

- `up_key   = Keyboard.r` sets the key for translations towards the top of the screen.
- `down_key = Keyboard.f` sets the key for translations towards the bottom of the screen.
- `left_key  = Keyboard.a` sets the key for translations towards the left of the screen.
- `right_key = Keyboard.d` sets the key for translations towards the right of the screen.
- `forward_key  = Keyboard.w` sets the key for translations into the screen.
- `backward_key = Keyboard.s` sets the key for translations out of the screen.

- `zoom_in_key   = Keyboard.u` sets the key for zooming into the scene (translate eyeposition towards lookat).
- `zoom_out_key  = Keyboard.o` sets the key for zooming out of the scene (translate eyeposition away from lookat).
- `increase_fov_key = Keyboard.b` sets the key for increasing the fov.
- `decrease_fov_key = Keyboard.n` sets the key for decreasing the fov.

- `pan_left_key  = Keyboard.j` sets the key for rotations around the screens vertical axis.
- `pan_right_key = Keyboard.l` sets the key for rotations around the screens vertical axis.
- `tilt_up_key   = Keyboard.i` sets the key for rotations around the screens horizontal axis.
- `tilt_down_key = Keyboard.k` sets the key for rotations around the screens horizontal axis.
- `roll_clockwise_key        = Keyboard.e` sets the key for rotations of the screen.
- `roll_counterclockwise_key = Keyboard.q` sets the key for rotations of the screen.

- `fix_x_key = Keyboard.x` sets the key for fixing translations and rotations to the (world/plot) x-axis.
- `fix_y_key = Keyboard.y` sets the key for fixing translations and rotations to the (world/plot) y-axis.
- `fix_z_key = Keyboard.z` sets the key for fixing translations and rotations to the (world/plot) z-axis.
- `reset = Keyboard.left_control & Mouse.left` sets the key for resetting the camera. This equivalent to calling `center!(scene)`.
- `reposition_button = Keyboard.left_alt & Mouse.left` sets the key for focusing the camera on a plot object.

- `translation_button = Mouse.right` sets the mouse button for drag-translations. (up/down/left/right)
- `scroll_mod = true` sets an additional modifier button for scroll-based zoom. (true being neutral)
- `rotation_button = Mouse.left` sets the mouse button for drag-rotations. (pan, tilt)

## Other kwargs

Some keyword arguments are used to initialize fields. These include

- `eyeposition = Vec3d(3)`: The position of the camera.
- `lookat = Vec3d(0)`: The point the camera is focused on.
- `upvector = Vec3d(0, 0, 1)`: The world direction corresponding to the up direction of the screen.

- `fov = 45.0` is the field of view. This is irrelevant if the camera uses an orthographic projection.
- `near = automatic` sets the position of the near clip plane. Anything between the camera and the near clip plane is hidden. Must be greater 0. Usage depends on `clipping_mode`.
- `far = automatic` sets the position of the far clip plane. Anything further away than the far clip plane is hidden. Usage depends on `clipping_mode`. Defaults to `1` for `clipping_mode = :bbox_relative`, `2` for `:view_relative` or a value derived from limits for `:static`.

Note that updating these observables in an active camera requires a call to `update_cam(scene)`
for them to be applied. For updating `eyeposition`, `lookat` and/or upvector
`update_cam!(scene, eyeposition, lookat, upvector = Vec3d(0,0,1))` is preferred.

The camera position and orientation can also be adjusted via the functions

- `translate_cam!(scene, v)` will translate the camera by the given vector `v`.
- `rotate_cam!(scene, angles)` will rotate the camera around its axes with the corresponding angles. The first angle will rotate around the cameras "right" that is the screens horizontal axis, the second around the up vector/vertical axis or `Vec3d(0, 0, +-1)` if `fixed_axis = true`, and the third will rotate around the view direction i.e. the axis out of the screen. The rotation respects the current `rotation_center` of the camera.
- `zoom!(scene, zoom_step)` will change the zoom level of the scene without translating or rotating the scene. `zoom_step` applies multiplicatively to `cam.zoom_mult` which is used as a multiplier to the fov (perspective projection) or width and height (orthographic projection).
"""
function Camera3D(scene::Scene; kwargs...)
    overwrites = Attributes(kwargs)

    controls = Attributes(
        # Keyboard controls
        # Translations
        up_key = Keyboard.r,
        down_key = Keyboard.f,
        left_key = Keyboard.a,
        right_key = Keyboard.d,
        forward_key = Keyboard.w,
        backward_key = Keyboard.s,
        # Zooms
        zoom_in_key = Keyboard.u,
        zoom_out_key = Keyboard.o,
        increase_fov_key = Keyboard.b,
        decrease_fov_key = Keyboard.n,
        # Rotations
        pan_left_key = Keyboard.j,
        pan_right_key = Keyboard.l,
        tilt_up_key = Keyboard.i,
        tilt_down_key = Keyboard.k,
        roll_clockwise_key = Keyboard.e,
        roll_counterclockwise_key = Keyboard.q,
        # Mouse controls
        translation_button = Mouse.right,
        rotation_button = Mouse.left,
        scroll_mod = true,
        reposition_button = Keyboard.left_alt & Mouse.left,
        # Shared controls
        fix_x_key = Keyboard.x,
        fix_y_key = Keyboard.y,
        fix_z_key = Keyboard.z,
        reset = Keyboard.left_control & Mouse.left
    )

    replace!(controls, :Camera3D, scene, overwrites)

    settings = Attributes(
        keyboard_rotationspeed = 1.0,
        keyboard_translationspeed = 0.5,
        keyboard_zoomspeed = 1.0,

        mouse_rotationspeed = 1.0,
        mouse_translationspeed = 1.0,
        mouse_zoomspeed = 1.0,

        projectiontype = Makie.Perspective,
        circular_rotation = (false, false, false),
        rotation_center = :lookat,
        zoom_shift_lookat = true,
        fixed_axis = true,
        cad = false,
        center = true,
        clipping_mode = :adaptive # TODO: use bbox to adjust near/far automatically
    )

    replace!(settings, :Camera3D, scene, overwrites)

    if settings.clipping_mode[] === :view_relative
        far_default = 2.0
    elseif settings.clipping_mode[] === :bbox_relative
        far_default = 1.0
    else
        far_default = 100.0 # will be set when inserting a plot
    end

    cam = Camera3D(
        settings, controls,

        # Internals - controls
        Observable(true),

        # Semi-Internal - view matrix
        get(overwrites, :eyeposition, Observable(Vec3d(3, 3, 3))),
        get(overwrites, :lookat, Observable(Vec3d(0, 0, 0))),
        get(overwrites, :upvector, Observable(Vec3d(0, 0, 1))),

        # Semi-Internal - projection matrix
        get(overwrites, :fov, Observable(45.0)),
        get(overwrites, :near, Observable(0.1)),
        get(overwrites, :far, Observable(far_default)),
        Sphere(Point3d(0), 1.0)
    )

    disconnect!(camera(scene))

    # Keyboard controls
    # ticks every so often to get consistent position updates.
    on(camera(scene), events(scene).tick) do tick
        if cam.selected[]
            on_pulse(scene, cam, tick.delta_time)
        end
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
    add_mouse_controls!(scene, cam)

    # add camera controls to scene
    cameracontrols!(scene, cam)

    # Trigger updates on scene resize and settings change
    on(camera(scene), cam.fov) do _
        if settings.projectiontype[] == Makie.Perspective
            update_cam!(scene, cam)
        end
    end
    on(camera(scene), scene.viewport, cam.near, cam.far, settings.projectiontype) do _, _, _, _
        update_cam!(scene, cam)
    end

    # reset
    on(camera(scene), events(scene).keyboardbutton, events(scene).mousebutton, priority = 1) do ke, me
        if cam.selected[] && ispressed(scene, controls[:reset][]) &&
                (ke.action == Keyboard.press || me.action == Mouse.press)
            # center keeps the rotation of the camera so we reset that here
            # might make sense to keep user set lookat, upvector, eyeposition
            # around somewhere for this?
            old_center = cam.settings.center[]
            cam.settings.center[] = true
            center!(scene)
            cam.settings.center[] = old_center
            return Consume(true)
        end
        return Consume(false)
    end

    update_cam!(scene, cam)

    return cam
end

# These imitate the old camera
"""
    cam3d!(scene[; kwargs...])

Creates a `Camera3D` with `zoom_shift_lookat = true` and `fixed_axis = true`.
For more information, see [`Camera3D`](@ref)
"""
cam3d!(scene; zoom_shift_lookat = true, fixed_axis = true, kwargs...) =
    Camera3D(scene, zoom_shift_lookat = zoom_shift_lookat, fixed_axis = fixed_axis; kwargs...)

"""
    cam3d_cad!(scene[; kwargs...])

Creates a `Camera3D` with `cad = true`, `zoom_shift_lookat = false` and
`fixed_axis = false`. For more information, see [`Camera3D`](@ref)
"""
cam3d_cad!(scene; cad = true, zoom_shift_lookat = false, fixed_axis = false, kwargs...) =
    Camera3D(scene, cad = cad, zoom_shift_lookat = zoom_shift_lookat, fixed_axis = fixed_axis; kwargs...)

function deselect_all_cameras!(scene)
    cam = cameracontrols(scene)
    cam isa AbstractCamera3D && (cam.selected[] = false)
    for child in scene.children
        deselect_all_cameras!(child)
    end
    return nothing
end


################################################################################
### Interactivity init
################################################################################


function on_pulse(scene, cam::Camera3D, timestep)
    @extractvalue cam.controls (
        right_key, left_key, up_key, down_key, backward_key, forward_key,
        tilt_up_key, tilt_down_key, pan_left_key, pan_right_key, roll_counterclockwise_key, roll_clockwise_key,
        zoom_out_key, zoom_in_key, increase_fov_key, decrease_fov_key,
    )

    if !ispressed(
            scene, right_key | left_key | up_key | down_key | backward_key | forward_key |
                tilt_up_key | tilt_down_key | pan_left_key | pan_right_key | roll_counterclockwise_key |
                roll_clockwise_key | zoom_out_key | zoom_in_key | increase_fov_key | decrease_fov_key
        )

        return
    end

    @extractvalue cam.settings (
        keyboard_translationspeed, keyboard_rotationspeed, keyboard_zoomspeed, projectiontype,
    )

    # translation
    right = ispressed(scene, right_key)
    left = ispressed(scene, left_key)
    up = ispressed(scene, up_key)
    down = ispressed(scene, down_key)
    backward = ispressed(scene, backward_key)
    forward = ispressed(scene, forward_key)
    translating = right || left || up || down || backward || forward

    if translating
        # translation in camera space x/y/z direction
        if projectiontype == Perspective
            viewnorm = norm(cam.lookat[] - cam.eyeposition[])
            xynorm = 2 * viewnorm * tand(0.5 * cam.fov[])
            translation = keyboard_translationspeed * timestep * Vec3d(
                xynorm * (right - left),
                xynorm * (up - down),
                viewnorm * (backward - forward)
            )
        else
            # translation in camera space x/y/z direction
            viewnorm = norm(cam.eyeposition[] - cam.lookat[])
            translation = 2 * viewnorm * keyboard_translationspeed * timestep * Vec3d(
                right - left, up - down, backward - forward
            )
        end
        _translate_cam!(scene, cam, translation)
    end

    # rotation
    up = ispressed(scene, tilt_up_key)
    down = ispressed(scene, tilt_down_key)
    left = ispressed(scene, pan_left_key)
    right = ispressed(scene, pan_right_key)
    counterclockwise = ispressed(scene, roll_counterclockwise_key)
    clockwise = ispressed(scene, roll_clockwise_key)
    rotating = up || down || left || right || counterclockwise || clockwise

    if rotating
        # rotations around camera space x/y/z axes
        angles = keyboard_rotationspeed * timestep *
            Vec3d(up - down, left - right, counterclockwise - clockwise)

        _rotate_cam!(scene, cam, angles)
    end

    # zoom
    zoom_out = ispressed(scene, zoom_out_key)
    zoom_in = ispressed(scene, zoom_in_key)
    zooming = zoom_out || zoom_in

    if zooming
        zoom_step = (1.0 + keyboard_zoomspeed * timestep)^(zoom_out - zoom_in)
        _zoom!(scene, cam, zoom_step, false, false)
    end

    # fov
    fov_inc = ispressed(scene, increase_fov_key)
    fov_dec = ispressed(scene, decrease_fov_key)
    fov_adjustment = fov_inc || fov_dec

    if fov_adjustment
        step = (1 + keyboard_zoomspeed * timestep)^(fov_inc - fov_dec)
        cam.fov[] = clamp(cam.fov[] * step, 0.1, 179.0)
    end

    # if any are active, update matrices, else stop clock
    if translating || rotating || zooming || fov_adjustment
        update_cam!(scene, cam)
        return true
    else
        return false
    end
end


function add_mouse_controls!(scene, cam::Camera3D)
    @extract cam.controls (translation_button, rotation_button, reposition_button, scroll_mod)
    @extract cam.settings (
        mouse_translationspeed, mouse_rotationspeed, mouse_zoomspeed,
        cad, projectiontype, zoom_shift_lookat,
    )

    last_mousepos = RefValue(Vec2d(0, 0))
    dragging = RefValue((false, false)) # rotation, translation

    e = events(scene)

    function compute_diff(delta)
        if projectiontype[] == Perspective
            # TODO wrong scaling? :(
            ynorm = 2 * norm(cam.lookat[] - cam.eyeposition[]) * tand(0.5 * cam.fov[])
            return ynorm / size(scene, 2) * delta
        else
            viewnorm = norm(cam.eyeposition[] - cam.lookat[])
            return 2 * viewnorm / size(scene, 2) * delta
        end
    end

    # drag start/stop
    on(camera(scene), e.mousebutton) do event
        # Drag start translation/rotation
        if event.action == Mouse.press && is_mouseinside(scene)
            if ispressed(scene, translation_button[])
                last_mousepos[] = mouseposition_px(scene)
                dragging[] = (false, true)
                return Consume(true)
            elseif ispressed(scene, rotation_button[])
                last_mousepos[] = mouseposition_px(scene)
                dragging[] = (true, false)
                return Consume(true)
            end
            # drag stop & repostion
        elseif event.action == Mouse.release
            consume = false

            # Drag stop translation/rotation
            if dragging[][1]
                mousepos = mouseposition_px(scene)
                diff = compute_diff(last_mousepos[] .- mousepos)
                last_mousepos[] = mousepos
                dragging[] = (false, false)
                translate_cam!(scene, cam, mouse_translationspeed[] .* Vec3d(diff[1], diff[2], 0.0))
                consume = true
            elseif dragging[][2]
                mousepos = mouseposition_px(scene)
                dragging[] = (false, false)
                rot_scaling = mouse_rotationspeed[] * (e.window_dpi[] * 0.005)
                mp = (last_mousepos[] .- mousepos) .* 0.01 .* rot_scaling
                last_mousepos[] = mousepos
                rotate_cam!(scene, cam, Vec3d(-mp[2], mp[1], 0.0), true)
                consume = true
            end

            # reposition
            if ispressed(scene, reposition_button[], event.button) && is_mouseinside(scene)
                plt, _, p = ray_assisted_pick(scene)
                p3d = to_ndim(Point3d, p, 0.0)
                if !isnan(p3d) && is_data_space(plt) && parent_scene(plt) == scene
                    # if translation/rotation happens with on-click reposition,
                    # try uncommenting this
                    # dragging[] = (false, false)
                    shift = p3d - cam.lookat[]
                    update_cam!(scene, cam, cam.eyeposition[] + shift, p3d)
                end
                consume = true
            end

            return Consume(consume)
        end

        return Consume(false)
    end

    # in drag
    on(camera(scene), e.mouseposition) do mp
        if dragging[][2] && ispressed(scene, translation_button[])
            mousepos = screen_relative(scene, mp)
            diff = compute_diff(last_mousepos[] .- mousepos)
            last_mousepos[] = mousepos
            translate_cam!(scene, cam, mouse_translationspeed[] * Vec3d(diff[1], diff[2], 0.0))
            return Consume(true)
        elseif dragging[][1] && ispressed(scene, rotation_button[])
            mousepos = screen_relative(scene, mp)
            rot_scaling = mouse_rotationspeed[] * (e.window_dpi[] * 0.005)
            mp = (last_mousepos[] .- mousepos) * 0.01 * rot_scaling
            last_mousepos[] = mousepos
            rotate_cam!(scene, cam, Vec3d(-mp[2], mp[1], 0.0), true)
            return Consume(true)
        end
        return Consume(false)
    end

    #zoom
    return on(camera(scene), e.scroll) do scroll
        if is_mouseinside(scene) && ispressed(scene, scroll_mod[])
            zoom_step = (1.0 + 0.1 * mouse_zoomspeed[])^-scroll[2]
            zoom!(scene, cam, zoom_step, cad[], zoom_shift_lookat[])
            return Consume(true)
        end
        return Consume(false)
    end
end


################################################################################
### Camera transformations
################################################################################


# Simplified methods
"""
    translate_cam!(scene, cam::Camera3D, v::Vec3)

Translates the camera by the given vector in camera space, i.e. by `v[1]` to
the right, `v[2]` to the top and `v[3]` forward.

Note that this method reacts to `fix_x_key` etc. If any of those keys are
pressed the translation will be restricted to act in these directions.
"""
function translate_cam!(scene, cam::Camera3D, t::VecTypes)
    _translate_cam!(scene, cam, t)
    update_cam!(scene, cam)
    return nothing
end

"""
    rotate_cam!(scene, cam::Camera3D, angles::Vec3)

Rotates the camera by the given `angles` around the camera x- (left, right),
y- (up, down) and z-axis (in out). The rotation around the y axis is applied
first, then x, then y.

Note that this method reacts to `fix_x_key` etc and `fixed_axis`. The former
restrict the rotation around a specific axis when a given key is pressed. The
latter keeps the camera y axis fixed as the data space z axis.
"""
function rotate_cam!(scene, cam::Camera3D, angles::VecTypes, from_mouse = false)
    _rotate_cam!(scene, cam, angles, from_mouse)
    update_cam!(scene, cam)
    return nothing
end


zoom!(scene, zoom_step) = zoom!(scene, cameracontrols(scene), zoom_step, false, false)
"""
    zoom!(scene, cam::Camera3D, zoom_step[, cad = false, zoom_shift_lookat = false])

Zooms the camera in or out based on the multiplier `zoom_step`. A `zoom_step`
of 1.0 is neutral, larger zooms out and lower zooms in.

If `cad = true` zooming will also apply a rotation based on how far the cursor
is from the center of the scene. If `zoom_shift_lookat = true` and
`projectiontype = Orthographic` zooming will keep the data under the cursor at
the same screen space position.
"""
function zoom!(scene, cam::Camera3D, zoom_step, cad = false, zoom_shift_lookat = false)
    _zoom!(scene, cam, zoom_step, cad, zoom_shift_lookat)
    update_cam!(scene, cam)
    return nothing
end


function _translate_cam!(scene, cam::Camera3D, t)
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
        trans = Vec3d(fix_x, fix_y, fix_z) .* trans
    end

    cam.eyeposition[] = eyepos + trans
    cam.lookat[] = lookat + trans
    return
end


function _rotate_cam!(scene, cam::Camera3D, angles::VecTypes, from_mouse = false)
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
    y_axis = fixed_axis ? Vec3d(0, 0, ifelse(up[3] < 0, -1, 1)) : up
    z_axis = -viewdir

    fix_x = ispressed(scene, fix_x_key)::Bool
    fix_y = ispressed(scene, fix_y_key)::Bool
    fix_z = ispressed(scene, fix_z_key)::Bool
    cx, cy, cz = circular_rotation

    rotation = Quaternionf(0, 0, 0, 1)
    if !xor(fix_x, fix_y, fix_z)
        # if there are more or less than one restriction apply all rotations
        # Note that the y rotation needs to happen first here so that
        # fixed_axis = true actually keeps the the axis fixed.
        rotation *= qrotation(y_axis, angles[2])
        rotation *= qrotation(x_axis, angles[1])
        rotation *= qrotation(z_axis, angles[3])
    else
        # apply world space restrictions
        if from_mouse && ((fix_x && cx) || (fix_y && cy) || (fix_z && cz))
            # recontextualize the (dy, dx, 0) from mouse rotations so that
            # drawing circles creates continuous rotations around the fixed axis
            mp = mouseposition_px(scene)
            past_half = 0.5 .* size(scene) .> mp
            flip = 2.0 * past_half .- 1.0
            angle = flip[1] * angles[1] + flip[2] * angles[2]
            angles = Vec3d(-angle, -angle, angle)
            # only one fix is true so this only rotates around one axis
            rotation *= qrotation(
                Vec3d(fix_x, fix_y, fix_z) .* Vec3d(sign(right[1]), viewdir[2], sign(up[3])),
                dot(Vec3d(fix_x, fix_y, fix_z), angles)
            )
        else
            # restrict total quaternion rotation to one axis
            rotation *= qrotation(y_axis, angles[2])
            rotation *= qrotation(x_axis, angles[1])
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


function _zoom!(scene, cam::Camera3D, zoom_step, cad = false, zoom_shift_lookat = false)
    lookat = cam.lookat[]
    eyepos = cam.eyeposition[]
    viewdir = lookat - eyepos   # -z
    vp = viewport(scene)[]
    scene_width = widths(vp)
    if cad
        # Rotate view based on offset from center
        u_z = normalize(viewdir)
        u_x = normalize(cross(u_z, cam.upvector[]))
        u_y = normalize(cross(u_x, u_z))

        rel_pos = 2.0 * mouseposition_px(scene) ./ scene_width .- 1.0
        shift = rel_pos[1] * u_x + rel_pos[2] * u_y
        shift *= 0.1 * sign(1 - zoom_step) * norm(viewdir)

        cam.eyeposition[] = lookat - zoom_step * viewdir + shift
    elseif zoom_shift_lookat
        # keep data under cursor
        u_z = normalize(viewdir)
        u_x = normalize(cross(u_z, cam.upvector[]))
        u_y = normalize(cross(u_x, u_z))

        rel_pos = (2.0 .* mouseposition_px(scene) .- scene_width) ./ scene_width[2]
        shift = (1 - zoom_step) * (rel_pos[1] * u_x + rel_pos[2] * u_y)

        if cam.settings.projectiontype[] == Makie.Orthographic
            scale = norm(viewdir)
        else
            # With perspective projection depth scales shift, but there is no way
            # to tell which depth the user may want to keep in view. So we just
            # assume it's the same depth as "lookat".
            scale = norm(viewdir) * tand(0.5 * cam.fov[])
        end

        cam.lookat[] = lookat + scale * shift
        cam.eyeposition[] = lookat - zoom_step * viewdir + scale * shift
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
    @extractvalue cam (lookat, eyeposition, upvector, near, far, fov, bounding_sphere)

    view = Makie.lookat(eyeposition, lookat, upvector)

    if cam.settings.clipping_mode[] === :view_relative
        view_dist = norm(eyeposition - lookat)
        near = view_dist * near; far = view_dist * far
    elseif cam.settings.clipping_mode[] === :bbox_relative
        view_dist = norm(eyeposition - lookat)
        center_dist = norm(eyeposition - origin(bounding_sphere))
        far_dist = center_dist + radius(bounding_sphere)
        near = max(view_dist * near, center_dist - radius(bounding_sphere))
        far = far_dist * far
    elseif cam.settings.clipping_mode[] === :adaptive
        view_dist = norm(eyeposition - lookat)
        near = view_dist * near
        far = max(radius(bounding_sphere) / tand(0.5 * cam.fov[]), view_dist) * far
    elseif cam.settings.clipping_mode[] !== :static
        @error "clipping_mode = $(cam.settings.clipping_mode[]) not recognized, using :static."
    end

    aspect = Float64((/)(widths(scene)...))
    if cam.settings.projectiontype[] == Makie.Perspective
        proj = perspectiveprojection(fov, aspect, near, far)
    else
        h = norm(eyeposition - lookat); w = h * aspect
        proj = orthographicprojection(-w, w, -h, h, near, far)
    end

    set_proj_view!(camera(scene), proj, view)
    scene.camera.eyeposition[] = Vec3f(cam.eyeposition[])
    scene.camera.upvector[] = upvector
    return scene.camera.view_direction[] = Vec3f(normalize(cam.lookat[] - cam.eyeposition[]))
end


# Update camera position via bbox
function update_cam!(scene::Scene, cam::Camera3D, area3d::Rect, recenter::Bool = cam.settings.center[])
    bb = Rect3f(area3d)
    width = widths(bb)
    center = maximum(bb) - 0.5 * width
    radius = 0.5 * norm(width)
    (isnan(radius) || (radius == 0)) && return
    cam.bounding_sphere[] = Sphere(Point3d(center), radius)

    old_dir = normalize(cam.eyeposition[] .- cam.lookat[])
    if cam.settings.projectiontype[] == Makie.Perspective
        dist = radius / tand(0.5 * cam.fov[])
    else
        dist = radius
    end

    if recenter
        cam.lookat[] = center
        cam.eyeposition[] = cam.lookat[] .+ dist * old_dir
        cam.upvector[] = normalize(cross(old_dir, cross(cam.upvector[], old_dir)))
    end

    if cam.settings.clipping_mode[] === :static
        cam.near[] = 0.1 * dist
        cam.far[] = 2.0 * dist
    elseif cam.settings.clipping_mode[] === :adaptive
        cam.near[] = 0.1
        cam.far[] = 2.0
    end

    update_cam!(scene, cam)

    return
end

# Update camera position via camera Position & Orientation
function update_cam!(scene::Scene, camera::Camera3D, eyeposition::VecTypes, lookat::VecTypes, up::VecTypes = camera.upvector[])
    camera.lookat[] = Vec3d(lookat)
    camera.eyeposition[] = Vec3d(eyeposition)
    camera.upvector[] = Vec3d(up)
    update_cam!(scene, camera)
    return
end

update_cam!(scene::Scene, args::Real...) = update_cam!(scene, cameracontrols(scene), args...)

"""
    update_cam!(scene, cam::Camera3D, ϕ, θ[, radius])

Set the camera position based on two angles `0 ≤ ϕ ≤ 2π` and `-pi/2 ≤ θ ≤ pi/2`
and an optional radius around the current `cam.lookat[]`.
"""
function update_cam!(
        scene::Scene, camera::Camera3D, phi::Real, theta::Real,
        radius::Real = norm(camera.eyeposition[] - camera.lookat[]),
        center = camera.lookat[]
    )
    st, ct = sincos(theta)
    sp, cp = sincos(phi)
    v = Vec3d(ct * cp, ct * sp, st)
    u = Vec3d(-st * cp, -st * sp, ct)
    camera.lookat[] = center
    camera.eyeposition[] = center .+ radius * v
    camera.upvector[] = u
    update_cam!(scene, camera)
    return
end


function show_cam(scene)
    cam = cameracontrols(scene)
    println("cam=cameracontrols(scene)")
    println("cam.eyeposition[] = ", round.(cam.eyeposition[], digits = 2))
    println("cam.lookat[] = ", round.(cam.lookat[], digits = 2))
    println("cam.upvector[] = ", round.(cam.upvector[], digits = 2))
    println("cam.fov[] = ", round.(cam.fov[], digits = 2))
    return
end
