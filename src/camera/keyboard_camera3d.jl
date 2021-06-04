#=
pedestal    - up/down       - shift/ctrl and right drag
truck       - left right    - ?? and right drag
dolly       - in/out        - w/s

pan     - rotate left/right         - a/d and left drag
tilt    - rotate up/down            - ?? and left drag
roll    - rotate counter/clockwise  - q/e

zoom    - mouse wheel

keep lookat - maybe swithc on shift?
connects pedestal + tilt, truck + pan

don't be super exact
=#

struct KeyCamera3D <: AbstractCamera
    rotationspeed::Node{Float32}
    translationspeed::Node{Float32}
    zoomspeed::Node{Float32}
    enable_crosshair::Node{Bool}

    eyeposition::Node{Vec3f0}
    lookat::Node{Vec3f0}
    upvector::Node{Vec3f0}

    fov::Node{Float32}
    near::Node{Float32}
    far::Node{Float32}

    keep_lookat::Node{Bool}
    update_rate::Node{Float64}
    pulser::Node{Bool}

    key_controls::Dict{Symbol, Keyboard.Button}
end

to_node(x) = Node(x)
to_node(n::Node) = n

function keyboard_cam!(scene; kwargs...)
    kwdict = Dict(kwargs)
    key_controls = Dict{Symbol, Keyboard.Button}(
        # translations
        :up        => to_value(get(kwdict, :up, Keyboard.left_shift)),
        :down      => to_value(get(kwdict, :down, Keyboard.left_control)),
        :left      => to_value(get(kwdict, :left, Keyboard.j)),
        :right     => to_value(get(kwdict, :right, Keyboard.l)),
        :forward   => to_value(get(kwdict, :forward, Keyboard.w)),
        :backward  => to_value(get(kwdict, :backward, Keyboard.s)),
        # zooms
        :zoom_in   => to_value(get(kwdict, :backward, Keyboard.i)),
        :zoom_out  => to_value(get(kwdict, :backward, Keyboard.k)),
        # rotations
        :pan_left  => to_value(get(kwdict, :pan_left, Keyboard.a)),
        :pan_right => to_value(get(kwdict, :pan_right, Keyboard.d)),
        :tilt_up   => to_value(get(kwdict, :tilt_up, Keyboard.r)),
        :tilt_down => to_value(get(kwdict, :tilt_down, Keyboard.f)),
        :roll_clockwise => to_value(get(kwdict, :roll_clockwise, Keyboard.e)),
        :roll_counterclockwise => to_value(get(kwdict, :roll_counterclockwise, Keyboard.q))
    )

    cam = KeyCamera3D(
        to_node(get(kwdict, :rotationspeed, 1.0)),
        to_node(get(kwdict, :translationspeed, 1.0)),
        to_node(get(kwdict, :zoomspeed, 1.0)),
        to_node(get(kwdict, :enable_crosshair, true)),

        to_node(get(kwdict, :eyeposition, Vec3f0(3))),
        to_node(get(kwdict, :lookat, Vec3f0(0))),
        to_node(get(kwdict, :upvector, Vec3f0(0, 0, 1))),

        to_node(get(kwdict, :fov, 45f0)),
        to_node(get(kwdict, :near, 0.01f0)),
        to_node(get(kwdict, :far, 100f0)),

        to_node(get(kwdict, :keep_lookat, Node(true))),
        to_node(get(kwdict, :update_rate, Node(1/60))),
        Node(false),

        key_controls
    )

    disconnect!(camera(scene))

    # ticks every so often to get consistent position updates
    on(cam.pulser) do active
        @async if active
            sleep(cam.update_rate[])
            cam.pulser[] = any(key -> key in Set(values(cam.key_controls)), events(scene).keyboardstate)
        end
    end
    on(_ -> on_pulse(scene, cam), cam.pulser)

    # This stops working with camera(scene)?
    # camera(scene),
    on(events(scene).keyboardbutton) do event
        if event.action == Keyboard.press && event.key in values(cam.key_controls)
            if !cam.pulser[]
                cam.pulser[] = true
            end
            return true
        end
        return false
    end

    # TODO how do you clean this up?
    scatter!(scene, 
        map(p -> [p], cam.lookat), 
        marker = '+', 
        # TODO this needs explicit cleanup
        markersize = lift(rect -> 0.01f0 * sum(widths(rect)), scene.data_limits), 
        markerspace = SceneSpace, color = :red, visible = cam.enable_crosshair
    )

    cameracontrols!(scene, cam)
    on(camera(scene), scene.px_area) do area
        # update cam when screen ratio changes
        update_cam!(scene, cam)
    end

    center!(scene)

    cam
end

function on_pulse(scene, cc)
    controls = cc.key_controls

    lookat = cc.lookat[]
    eyepos = cc.eyeposition[]
    up = cc.upvector[]          # +y
    viewdir = lookat - eyepos   # -z
    right = cross(viewdir, up)  # +x

    # TODO scale translation with zoom or ||lookat-eyeposition||
    view_trans = cc.translationspeed[] * norm(viewdir) * cc.update_rate[] * Vec3f0(
        ispressed(scene, controls[:right])    - ispressed(scene, controls[:left]),
        ispressed(scene, controls[:up])       - ispressed(scene, controls[:down]),
        ispressed(scene, controls[:backward]) - ispressed(scene, controls[:forward])
    )

    translation = normalize(right) * view_trans[1] + 
        normalize(up) * view_trans[2] - normalize(viewdir) * view_trans[3]

    
    eyepos = eyepos + translation
    lookat = lookat + translation

    # rotations around x/y/z axes
    angles = cc.rotationspeed[] * cc.update_rate[] * Vec3f0(
        ispressed(scene, controls[:tilt_up])        - ispressed(scene, controls[:tilt_down]),
        ispressed(scene, controls[:pan_left])       - ispressed(scene, controls[:pan_right]),
        ispressed(scene, controls[:roll_counterclockwise]) - ispressed(scene, controls[:roll_clockwise])
    )

    rotation = qrotation(right, angles[1]) * qrotation(up, angles[2]) * qrotation(-viewdir, angles[3])
    up = rotation * up
    viewdir = rotation * viewdir
    if cc.keep_lookat[]
        eyepos = lookat - viewdir    
    else
        lookat = eyepos + viewdir
    end

    # apply zoom (lookat - eyepos distance)
    zoom = (1f0 + cc.zoomspeed[] * cc.update_rate[]) ^ 
        (ispressed(scene, controls[:zoom_out]) - ispressed(scene, controls[:zoom_in]))
    
    eyepos = lookat - zoom * viewdir

    update_cam!(scene, cc, eyepos, lookat, up)
end

function update_cam!(scene::Scene, cam::KeyCamera3D)
    @extractvalue cam (fov, near, lookat, eyeposition, upvector)

    zoom = norm(lookat - eyeposition)
    # TODO this means you can't set FarClip... SAD!
    # TODO use boundingbox(scene) for optimal far/near
    far = max(zoom * 5f0, 30f0)
    aspect = Float32((/)(widths(scene.px_area[])...))
    proj = perspectiveprojection(fov, aspect, near, far)
    view = Makie.lookat(eyeposition, lookat, upvector)

    scene.camera.projection[] = proj
    scene.camera.view[] = view
    scene.camera.projectionview[] = proj * view
    scene.camera.eyeposition[] = cam.eyeposition[]
end

# TODO
function update_cam!(scene::Scene, camera::KeyCamera3D, area3d::Rect)
    @extractvalue camera (fov, near, lookat, eyeposition, upvector)
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
    camera.near[] = 0.1f0 * norm(widths(bb))
    camera.far[] = 3f0 * norm(widths(bb))
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