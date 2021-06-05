struct KeyCamera3D <: AbstractCamera
    eyeposition::Node{Vec3f0}
    lookat::Node{Vec3f0}
    upvector::Node{Vec3f0}

    zoom_mult::Node{Float32}
    near::Node{Float32}
    far::Node{Float32}
    pulser::Node{Float64}

    attributes::Attributes
end

"""

keyboard keys can be sets too
"""
function keyboard_cam!(scene; kwargs...)
    attr = merged_get!(:cam3d, scene, Attributes(kwargs)) do 
        Attributes(
            # Keyboard
            # Translations
            up_key        = Keyboard.left_shift,
            down_key      = Keyboard.left_control,
            left_key      = Keyboard.j,
            right_key     = Keyboard.l,
            forward_key   = Keyboard.w,
            backward_key  = Keyboard.s,
            # Zooms
            zoom_in_key   = Keyboard.i,
            zoom_out_key  = Keyboard.k,
            # TODO maybe lookat_forward_key, lookat_backward_key?
            # Rotations
            pan_left_key  = Keyboard.a,
            pan_right_key = Keyboard.d,
            tilt_up_key   = Keyboard.r,
            tilt_down_key = Keyboard.f,
            roll_clockwise_key        = Keyboard.e,
            roll_counterclockwise_key = Keyboard.q,
            # Mouse
            translation_button = Mouse.right,
            rotation_button    = Mouse.left,
            # TODO modifiers
            # Settings
            # TODO differentiate mouse and keyboard speeds
            rotationspeed = 1f0,
            translationspeed = 1f0,
            zoomspeed = 1f0,
            fov = 45f0, # base fov
            near = automatic,
            far = automatic,
            rotation_center = :lookat,
            enable_crosshair = true,
            update_rate = 1/30,
            projectiontype = Perspective,
            fixed_axis = true
        )
    end

    cam = KeyCamera3D(
        pop!(attr, :eyeposition, Vec3f0(3)),
        pop!(attr, :lookat,      Vec3f0(0)),
        pop!(attr, :upvector,    Vec3f0(0, 0, 1)),

        Node(1f0),
        Node(attr[:near][] === automatic ? 0.1f0 : attr[:near][]),
        Node(attr[:far][]  === automatic ? 100f0 : attr[:far][]),
        Node(-1.0),

        attr
    )

    disconnect!(camera(scene))

    # Keyboard controls
    # ticks every so often to get consistent position updates.
    on(cam.pulser) do prev_time
        current_time = time()
        active = on_pulse(scene, cam, Float32(current_time - prev_time))
        @async if active
            sleep(attr.update_rate[])
            cam.pulser[] = current_time
        else
            cam.pulser.val = -1.0
        end
    end

    keynames = (
        :up_key, :down_key, :left_key, :right_key, :forward_key, :backward_key, 
        :zoom_in_key, :zoom_out_key, :pan_left_key, :pan_right_key, :tilt_up_key, 
        :tilt_down_key, :roll_clockwise_key, :roll_counterclockwise_key
    )
    # This stops working with camera(scene)?
    # camera(scene),
    on(events(scene).keyboardbutton) do event
        if event.action == Keyboard.press && cam.pulser[] == -1.0 &&
            any(key -> ispressed(scene, attr[key][]), keynames)
              
            cam.pulser[] = time()
            return true
        end
        return false
    end
   
    # Mouse controls
    add_translation!(scene, cam, attr[:translation_button])
    add_rotation!(scene, cam, attr[:rotation_button])
    
    cameracontrols!(scene, cam)

    # Trigger updates on scene resize and settings change
    on(camera(scene), scene.px_area, attr[:fov], attr[:projectiontype]) do _, _, _
        update_cam!(scene, cam)
    end
    on(camera(scene), attr[:near], attr[:far]) do near, far
        near === automatic || (cam.near[] = near)
        far  === automatic || (cam.far[] = far)
        update_cam!(scene, cam)
    end

    # TODO remove this?
    center!(scene)
    
    # TODO how do you clean this up?
    scatter!(scene, 
        map(p -> [p], cam.lookat), 
        marker = '+', 
        # TODO this needs explicit cleanup
        markersize = lift(rect -> 0.01f0 * sum(widths(rect)), scene.data_limits), 
        markerspace = SceneSpace, color = :red, visible = attr[:enable_crosshair]
    )

    cam
end


# TODO switch button and key because this is the wrong order
function add_translation!(scene, cam::KeyCamera3D, button = Node(Mouse.right))
    zoomspeed = cam.attributes[:zoomspeed]
    last_mousepos = RefValue(Vec2f0(0, 0))
    dragging = RefValue(false)

    # drag start/stop
    on(camera(scene), scene.events.mousebutton) do event
        if event.button == button[]
            if event.action == Mouse.press && is_mouseinside(scene)
                last_mousepos[] = mouseposition_px(scene)
                dragging[] = true
                return true
            elseif event.action == Mouse.release && dragging[]
                mousepos = mouseposition_px(scene)
                dragging[] = false
                diff = (last_mousepos[] - mousepos) * 0.01f0
                last_mousepos[] = mousepos
                translate_cam!(scene, cam, Vec3f0(diff[1], diff[2], 0f0))
                update_cam!(scene, cam)
                return true
            end
        end
        return false
    end

    # in drag
    on(camera(scene), scene.events.mouseposition) do mp
        if dragging[] && ispressed(scene, button[])
            mousepos = screen_relative(scene, mp)
            diff = (last_mousepos[] .- mousepos) * 0.01f0
            last_mousepos[] = mousepos
            translate_cam!(scene, cam, Vec3f0(diff[1], diff[2], 0f0))
            update_cam!(scene, cam)
            return true
        end
        return false
    end

    on(camera(scene), scene.events.scroll) do scroll
        if is_mouseinside(scene)
            cam_res = Vec2f0(widths(scene.px_area[]))
            mouse_pos_normalized = mouseposition_px(scene) ./ cam_res
            mouse_pos_normalized = 2*mouse_pos_normalized .- 1f0
            cam.zoom_mult[] = cam.zoom_mult[] * (1f0 + 0.1f0 * zoomspeed[]) ^ -scroll[2]
            _zoom!(scene, cam, mouse_pos_normalized)
            update_cam!(scene, cam)
            return true
        end
        return false
    end
end

function add_rotation!(scene, cam::KeyCamera3D, button = Node(Mouse.left))
    rotationspeed = cam.attributes[:rotationspeed]
    last_mousepos = RefValue(Vec2f0(0, 0))
    dragging = RefValue(false)
    e = events(scene)

    on(camera(scene), e.mousebutton) do event
        if event.button == button[]
            if event.action == Mouse.press && is_mouseinside(scene)
                last_mousepos[] = mouseposition_px(scene)
                dragging[] = true
                return true
            elseif event.action == Mouse.release && dragging[]
                mousepos = mouseposition_px(scene)
                dragging[] = false
                rot_scaling = rotationspeed[] * (e.window_dpi[] * 0.005)
                mp = (last_mousepos[] - mousepos) * 0.01f0 * rot_scaling
                last_mousepos[] = mousepos
                rotate_cam!(scene, cam, Vec3f0(-mp[2], mp[1], 0f0))
                update_cam!(scene, cam)
                return true
            end
        end
        return false
    end

    on(camera(scene), e.mouseposition) do mp
        if dragging[]
            mousepos = screen_relative(scene, mp)
            rot_scaling = rotationspeed[] * (e.window_dpi[] * 0.005)
            mp = (last_mousepos[] .- mousepos) * 0.01f0 * rot_scaling
            last_mousepos[] = mousepos
            rotate_cam!(scene, cam, Vec3f0(-mp[2], mp[1], 0f0))
            update_cam!(scene, cam)
            return true
        end
        return false
    end
end


function on_pulse(scene, cam, timestep)
    attr = cam.attributes

    right = ispressed(scene, attr[:right_key][])
    left = ispressed(scene, attr[:left_key][])
    up = ispressed(scene, attr[:up_key][])
    down = ispressed(scene, attr[:down_key][])
    backward = ispressed(scene, attr[:backward_key][])
    forward = ispressed(scene, attr[:forward_key][])
    translating = right || left || up || down || backward || forward

    if translating
        translation = timestep * Vec3f0(right - left, up - down, backward - forward)
        translate_cam!(scene, cam, translation)
    end

    up = ispressed(scene, attr[:tilt_up_key][])
    down = ispressed(scene, attr[:tilt_down_key][])
    left = ispressed(scene, attr[:pan_left_key][])
    right = ispressed(scene, attr[:pan_right_key][])
    counterclockwise = ispressed(scene, attr[:roll_counterclockwise_key][])
    clockwise = ispressed(scene, attr[:roll_clockwise_key][])
    rotating = up || down || left || right || counterclockwise || clockwise

    if rotating
        # rotations around x/y/z axes
        angles = attr[:rotationspeed][] * timestep * 
            Vec3f0(up - down, left - right, counterclockwise - clockwise)

        rotate_cam!(scene, cam, angles)
    end

    zoom_out = ispressed(scene, attr[:zoom_out_key][])
    zoom_in = ispressed(scene, attr[:zoom_in_key][])
    zooming = zoom_out || zoom_in

    if zooming
        cam.zoom_mult[] = cam.zoom_mult[] * 
            (1f0 + attr[:zoomspeed][] * timestep) ^ (zoom_out - zoom_in)
        _zoom!(scene, cam, cam.lookat[])
    end

    if translating || rotating || zooming
        update_cam!(scene, cam)
        return true
    else 
        return false 
    end
end


function translate_cam!(scene, cam, translation)
    # This uses a camera based coordinate system where
    # x expands right, y expands up and z expands towards the screen
    lookat = cam.lookat[]
    eyepos = cam.eyeposition[]
    up = cam.upvector[]         # +y
    viewdir = lookat - eyepos   # -z
    right = cross(viewdir, up)  # +x

    t = cam.attributes[:translationspeed][] * norm(viewdir) * translation
    trans = normalize(right) * t[1] + normalize(up) * t[2] - normalize(viewdir) * t[3]

    cam.eyeposition[] = eyepos + trans
    cam.lookat[] = lookat + trans
    nothing
end

function rotate_cam!(scene, cam::KeyCamera3D, angles)
    # This applies rotations around the x/y/z axis of the camera coordinate system
    # x expands right, y expands up and z expands towards the screen
    lookat = cam.lookat[]
    eyepos = cam.eyeposition[]
    up = cam.upvector[]         # +y
    viewdir = lookat - eyepos   # -z
    right = cross(viewdir, up)  # +x

    if cam.attributes[:fixed_axis][]
        rotation = qrotation(Vec3f0(0, 0, sign(up[3])), angles[2]) * 
                    qrotation(right, angles[1]) * qrotation(-viewdir, angles[3])
    else
        rotation = qrotation(up, angles[2]) * qrotation(right, angles[1]) * 
                    qrotation(-viewdir, angles[3])
    end
    
    cam.upvector[] = rotation * up
    viewdir = rotation * viewdir
    # TODO maybe generalize this to arbitrary center?
    if cam.attributes[:rotation_center][] == :lookat
        cam.eyeposition[] = lookat - viewdir    
    else
        cam.lookat[] = eyepos + viewdir
    end
    nothing
end

function _zoom!(scene::Scene, cam::KeyCamera3D, mouse_pos_normalized)
    # lookat = cam.lookat[]
    # eyepos = cam.eyeposition[]
    # viewdir = lookat - eyepos
    # cam.eyeposition[] = lookat - zoom * viewdir
    
    nothing
end


function update_cam!(scene::Scene, cam::KeyCamera3D)
    @extractvalue cam (lookat, eyeposition, upvector)

    zoom = norm(lookat - eyeposition)
    near = cam.near[]; far = cam.far[]
    aspect = Float32((/)(widths(scene.px_area[])...))

    if cam.attributes[:projectiontype][] == Perspective
        fov = clamp(cam.zoom_mult[] * cam.attributes[:fov][], 0.01f0, 175f0)
        proj = perspectiveprojection(fov, aspect, near, far)
    else
        w = 0.5f0 * (1f0 + aspect) * cam.zoom_mult[]
        h = 0.5f0 * (1f0 + 1f0 / aspect) * cam.zoom_mult[]
        proj = orthographicprojection(-w, w, -h, h, near, far)
    end

    view = Makie.lookat(eyeposition, lookat, upvector)

    scene.camera.projection[] = proj
    scene.camera.view[] = view
    scene.camera.projectionview[] = proj * view
    scene.camera.eyeposition[] = cam.eyeposition[]
end

# TODO
function update_cam!(scene::Scene, camera::KeyCamera3D, area3d::Rect)
    @extractvalue camera (lookat, eyeposition, upvector)
    bb = FRect3D(area3d)
    width = widths(bb)
    half_width = width/2f0
    lower_corner = minimum(bb)
    middle = maximum(bb) - half_width
    old_dir = normalize(eyeposition .- lookat)
    camera.lookat[] = middle
    neweyepos = middle .+ (1.2*norm(width) .* old_dir)
    camera.eyeposition[] = neweyepos
    camera.upvector[] = Vec3f0(0,0,1)
    if camera.attributes[:near][] === automatic
        camera.near[] = 0.1f0 * norm(widths(bb))
    end
    if camera.attributes[:far][] === automatic
        camera.far[]  = 3f0 * norm(widths(bb))
    end
    update_cam!(scene, camera)
    return
end

# used in general and by on_pulse
function update_cam!(scene::Scene, camera::KeyCamera3D, eyeposition, lookat, up = Vec3f0(0, 0, 1))
    camera.lookat[] = Vec3f0(lookat)
    camera.eyeposition[] = Vec3f0(eyeposition)
    camera.upvector[] = Vec3f0(up)
    update_cam!(scene, camera)
    return
end