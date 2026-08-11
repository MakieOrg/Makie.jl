const STAGE_ELEVATION_LIMIT = 89.9

function azimuth_elevation_radius(azim, elev, radius)
    x = radius * cosd(elev) * cosd(azim)
    y = radius * cosd(elev) * sind(azim)
    z = radius * sind(elev)
    return Vec3d(x, y, z)
end

struct StageCamera <: AbstractCamera3D
    azimuth::Observable{Float64}
    elevation::Observable{Float64}
    stage_size::Observable{Float64}
    lookat::Observable{Vec3d}
    fov::Observable{Union{Nothing, Float64}}
    mm::Observable{Union{Nothing, Float64}}
    nearclip::Observable{Union{Makie.Automatic, Float64}}
    farclip::Observable{Union{Makie.Automatic, Float64}}
    crop_factor::Observable{Float64}
    relative_offset::Observable{Vec2d}
    upvector::Observable{Vec3d}
    bounding_sphere::Observable{Sphere{Float64}}

    controls::Attributes
    settings::Attributes
    selected::Observable{Bool}
end

"""
    StageCamera(scene; kwargs...)

A 3D camera whose settings follow the order in which a photographer works a scene, so that each
decision can be made and revised without undoing the previous ones:

- what do I point at? -> `lookat`
- how much around it do I want in frame? -> `stage_size`
- from which side and how high up do I shoot? -> `azimuth` and `elevation`
- which lens do I put on? -> `fov` or `mm`
- where in the frame does the subject sit? -> `relative_offset`
- do I crop the result a little? -> `crop_factor`

## Explanation

Adjusting a typical 3D camera means moving the camera position and changing the field of view over
and over, because the two are entangled: move closer for a better angle and the subject grows, then
widen the field of view to fit it again, which changes the perspective you had already settled on.
Field of view ends up used as a cropping tool and perspective is whatever falls out.

A photographer does not work that way. They decide what the picture is about and how much of the
surroundings belong in it, then walk around the subject to find the angle, then choose a lens. Those
are separate decisions, and changing the lens does not change what the picture is about.

The stage camera keeps them separate. The `lookat` point and the `stage_size` describe a region, the
stage, that stays in frame no matter what else changes. `azimuth` and `elevation` move the camera
around that stage. The lens, given as `fov` or as a full-frame focal length in `mm`, then no longer
decides how large the subject appears, since the stage has to fit either way: it decides how far the
camera has to stand back, and so how compressed or exaggerated the perspective looks and how much of
the background is drawn in. A long lens backs the camera off and flattens the scene, a wide lens
pushes it close and stretches it, and the subject stays the same size in frame throughout.

Framing is separate again. `relative_offset` pans and tilts the camera in fractions of the frame
rather than in degrees, so putting the subject on a rule-of-thirds line is the same instruction on any
lens, the way it is when panning by eye through a viewfinder.

# Arguments
- `azimuth::Real`: Azimuth angle in degrees (rotation around z-axis)
- `elevation::Real`: Elevation angle in degrees (rotation from xy-plane), applied clamped to ±$(STAGE_ELEVATION_LIMIT)
- `stage_size::Real`: The diameter of the region around `lookat` that stays in view
- `lookat::Union{Vec3, Tuple, Vector}`: Point the camera is looking at
- `fov::Union{Nothing, Real} = nothing`: Field of view in degrees (mutually exclusive with mm).
  Wide angles (e.g., 80°) create stronger perspective with more background visible and position
  the camera closer to the lookat point. Narrow angles (e.g., 20°) reduce perspective distortion,
  show less background, and position the camera further from the lookat point.
- `mm::Union{Nothing, Real} = nothing`: Focal length in mm relative to a classic full-frame
  35mm sensor (mutually exclusive with fov). Common values: 24mm (wide angle), 50mm (normal/standard),
  100mm (telephoto). Shorter focal lengths create wider fields of view with stronger perspective.
- `nearclip::Union{Makie.Automatic, Real} = Makie.automatic`: Near clipping plane distance, by default
  a hundredth of the camera distance
- `farclip::Union{Makie.Automatic, Real} = Makie.automatic`: Far clipping plane distance, by default
  far enough to reach past everything plotted in the scene so that a small stage in a large scene does
  not clip the background
- `crop_factor::Real = 1.0`: Crops into the framing without moving the camera, exactly like putting
  the same lens on a smaller sensor, so `1.5` is what an APS-C body would see. It changes how much of
  the stage is in view but not the perspective. Reach for it when the image is as desired but should
  be cropped in or out a little.
- `relative_offset::VecTypes{2} = (0.0, 0.0)`: Pans the camera right and tilts it up, in fractions of
  the distance from the frame center to its edge, so the lookat point ends up that fraction to the left
  of and below the center. `(1, 0)` pans until it reaches the left edge, `(1/3, 0)` until it sits on the
  left third of the frame. The rotation angles follow from the field of view, so the same fractions
  offset the frame equally at any focal length.
- `upvector::Vec3 = Vec3d(0, 0, 1)`: World up direction vector

Either `fov` or `mm` must be specified, but not both.

## Mouse Controls
- Drag with the left mouse button: orbit around the lookat point (`azimuth` and `elevation`)
- Shift + drag with the left mouse button: pan and tilt the camera so the frame follows the mouse
  (`relative_offset`), with the drag distance matching the frame movement
- Shift + right click: reset the pan and tilt back to a centered frame
- Alt + left click: make the point under the cursor the new `lookat`, so that further rotations happen
  around it. The camera stays where it is, `azimuth`, `elevation` and `stage_size` are derived from it.
- Scroll: change `stage_size`, moving the camera closer or further away
- Shift + scroll: change focal length (`mm` or `fov`) while keeping the stage in frame, so the
  camera moves closer or further away
- Alt + Shift + scroll: change focal length while keeping the camera in place, which zooms into the
  scene in the classic sense and shrinks or grows the stage

## Keyboard Controls
- `W/S`: Move lookat forward/backward in the camera's facing direction (projected onto the plane perpendicular to the world up vector)
- `A/D`: Move lookat left/right relative to the camera
- `Q/E`: Move lookat down/up along the world up vector
- `Left/Right Arrow`: Rotate azimuth (orbit around the subject)
- `Up/Down Arrow`: Change elevation (look up/down)
- `Shift + Arrow keys`: Pan and tilt the camera (`relative_offset`)
- `X/Z`: Increase/decrease field of view (or adjust mm focal length)
- `V/C`: Increase/decrease stage size (zoom the view in/out)

# Control Settings
- `keyboard_translationspeed = 0.5`: Speed multiplier for keyboard translations
- `keyboard_rotationspeed = 1.0`: Speed multiplier for keyboard rotations
- `keyboard_zoomspeed = 1.0`: Speed multiplier for keyboard focal length adjustments
- `keyboard_stagesizespeed = 1.0`: Speed multiplier for keyboard stage size adjustments
- `keyboard_offsetspeed = 1.125`: Speed multiplier for keyboard frame offsets
- `mouse_rotationspeed = 1.0`: Speed multiplier for mouse drag rotations
- `mouse_offsetspeed = 1.0`: Speed multiplier for mouse drag pans and tilts
- `mouse_zoomspeed = 1.0`: Speed multiplier for focal length adjustments via scroll
- `mouse_stagesizespeed = 1.0`: Speed multiplier for stage size adjustments via scroll

# Key Bindings (customizable)
- `forward_key = Keyboard.w`: Move lookat and camera forward
- `backward_key = Keyboard.s`: Move lookat and camera backward
- `left_key = Keyboard.a`: Move lookat and camera left
- `right_key = Keyboard.d`: Move lookat and camera right
- `up_key = Keyboard.e`: Move lookat and camera up
- `down_key = Keyboard.q`: Move lookat and camera down
- `azimuth_left_key = Keyboard.left`: Rotate azimuth left, or pan the camera left with `offset_mod`
- `azimuth_right_key = Keyboard.right`: Rotate azimuth right, or pan the camera right with `offset_mod`
- `elevation_up_key = Keyboard.up`: Increase elevation, or tilt the camera up with `offset_mod`
- `elevation_down_key = Keyboard.down`: Decrease elevation, or tilt the camera down with `offset_mod`
- `increase_fov_key = Keyboard.x`: Increase field of view while moving closer (stronger perspective)
- `decrease_fov_key = Keyboard.z`: Decrease field of view while moving further away (more compressed perspective)
- `increase_stage_size_key = Keyboard.c`: Increase stage size (move further away)
- `decrease_stage_size_key = Keyboard.v`: Decrease stage size (move closer)
- `rotation_button = Mouse.left`: Drag button for orbiting
- `offset_button = Keyboard.left_shift & Mouse.left`: Drag chord for panning and tilting
- `reset_offset_button = Keyboard.left_shift & Mouse.right`: Click chord that resets `relative_offset`
- `reposition_button = Keyboard.left_alt & Mouse.left`: Click chord that picks a new lookat point
- `scroll_mod = true`: Modifier that must be pressed for scroll to be handled
- `focal_length_mod = Keyboard.left_shift`: Modifier that switches scroll from stage size to focal length
- `zoom_mod = Keyboard.left_alt & Keyboard.left_shift`: Modifier that switches scroll to focal length at
  a fixed camera position
- `offset_mod = Keyboard.left_shift`: Modifier that switches the arrow keys from orbiting to
  offsetting the frame

# Example
```julia
cam = StageCamera(
    scene,
    azimuth = 45.0,
    elevation = 30.0,
    stage_size = 10.0,
    lookat = (0, 0, 0),
    mm = 50.0
)

# Update camera dynamically
cam.azimuth[] = 90.0
cam.crop_factor[] = 2.0
```
"""
function StageCamera(
        scene::Scene;
        azimuth = 0.0,
        elevation = 0.0,
        stage_size = 1.0,
        lookat = Vec3d(0, 0, 0),
        fov = nothing,
        mm = fov === nothing ? 50.0 : nothing,
        nearclip = Makie.automatic,
        farclip = Makie.automatic,
        crop_factor = 1.0,
        relative_offset = (0.0, 0.0),
        upvector = Vec3d(0, 0, 1),
        kwargs...
    )
    if mm === nothing && fov === nothing
        error("Either mm or fov must be set")
    elseif mm !== nothing && fov !== nothing
        error("Cannot set both mm and fov")
    end

    overwrites = Attributes(kwargs)

    controls = Attributes(
        forward_key = Keyboard.w,
        backward_key = Keyboard.s,
        left_key = Keyboard.a,
        right_key = Keyboard.d,
        up_key = Keyboard.e,
        down_key = Keyboard.q,
        azimuth_left_key = Keyboard.left,
        azimuth_right_key = Keyboard.right,
        elevation_up_key = Keyboard.up,
        elevation_down_key = Keyboard.down,
        increase_fov_key = Keyboard.x,
        decrease_fov_key = Keyboard.z,
        increase_stage_size_key = Keyboard.c,
        decrease_stage_size_key = Keyboard.v,
        rotation_button = Mouse.left,
        offset_button = Keyboard.left_shift & Mouse.left,
        reset_offset_button = Keyboard.left_shift & Mouse.right,
        reposition_button = Keyboard.left_alt & Mouse.left,
        scroll_mod = true,
        focal_length_mod = Keyboard.left_shift,
        zoom_mod = Keyboard.left_alt & Keyboard.left_shift,
        offset_mod = Keyboard.left_shift,
    )

    replace!(controls, :StageCamera, scene, overwrites)

    settings = Attributes(
        keyboard_translationspeed = 0.5,
        keyboard_rotationspeed = 1.0,
        keyboard_zoomspeed = 1.0,
        keyboard_stagesizespeed = 1.0,
        keyboard_offsetspeed = 1.125,
        mouse_rotationspeed = 1.0,
        mouse_offsetspeed = 1.0,
        mouse_zoomspeed = 1.0,
        mouse_stagesizespeed = 1.0,
    )

    replace!(settings, :StageCamera, scene, overwrites)

    cam = StageCamera(
        Observable(Float64(azimuth)),
        Observable(Float64(elevation)),
        Observable(Float64(stage_size)),
        Observable(to_ndim(Vec3d, lookat, 0)),
        Observable(fov === nothing ? nothing : Float64(fov)),
        Observable(mm === nothing ? nothing : Float64(mm)),
        Observable(nearclip === Makie.automatic ? Makie.automatic : Float64(nearclip)),
        Observable(farclip === Makie.automatic ? Makie.automatic : Float64(farclip)),
        Observable(Float64(crop_factor)),
        Observable(to_ndim(Vec2d, relative_offset, 0)),
        Observable(to_ndim(Vec3d, upvector, 0)),
        Observable(Sphere(Point3d(0), 0.0)),
        controls,
        settings,
        Observable(true)
    )

    disconnect!(camera(scene))
    deselect_all_cameras!(root(scene))
    cameracontrols!(scene, cam)

    on(camera(scene), events(scene).mousebutton, priority = 100) do event
        if event.action == Mouse.press
            cam.selected[] = is_mouseinside(scene)
        end
        return Consume(false)
    end

    on(camera(scene), events(scene).tick) do tick
        if cam.selected[]
            on_pulse(scene, cam, tick.delta_time)
        end
    end

    add_mouse_controls!(scene, cam)

    onany(
        camera(scene),
        cam.azimuth, cam.elevation, cam.stage_size, cam.lookat,
        cam.fov, cam.mm, cam.nearclip, cam.farclip, cam.crop_factor, cam.upvector,
        cam.relative_offset, cam.bounding_sphere
    ) do args...
        update_cam!(scene, cam)
    end

    on(camera(scene), scene.viewport) do _
        update_cam!(scene, cam)
    end

    update_cam!(scene, cam)

    return cam
end

"""
    stage_cam!(scene; kwargs...)

Creates and sets up a StageCamera for the scene. This is the preferred way to create
a stage camera, similar to how `cam3d!` works for Camera3D.

See [`StageCamera`](@ref) for keyword arguments.
"""
stage_cam!(scene::Scene; kwargs...) = StageCamera(scene; kwargs...)

function fov_degrees(cam::StageCamera)
    fov = cam.fov[]
    mm = cam.mm[]
    if mm !== nothing && fov === nothing
        return 2 * atand(36, 2 * mm)
    elseif fov !== nothing && mm === nothing
        return fov
    else
        error("Either mm or fov must be set")
    end
end

stage_elevation(cam::StageCamera) = clamp(cam.elevation[], -STAGE_ELEVATION_LIMIT, STAGE_ELEVATION_LIMIT)

stage_distance(cam::StageCamera) = 0.5 * cam.stage_size[] / tand(0.5 * fov_degrees(cam))

function stage_eyeposition(cam::StageCamera)
    return cam.lookat[] + azimuth_elevation_radius(cam.azimuth[], stage_elevation(cam), stage_distance(cam))
end

function clip_planes(cam::StageCamera, eyeposition, cam_distance)
    near::Float64 = cam.nearclip[] === Makie.automatic ? 0.01 * cam_distance : cam.nearclip[]
    cam.farclip[] === Makie.automatic || return near, Float64(cam.farclip[])

    # reach past everything that has been plotted so far, so that a small stage in a large
    # scene doesn't clip the background away
    sphere = cam.bounding_sphere[]
    scene_far = norm(eyeposition - origin(sphere)) + radius(sphere)
    return near, max(10 * cam_distance, 1.05 * scene_far)
end

"""
    update_cam!(scene::Scene, cam::StageCamera, area3d::Rect)

Records the extent of the scene's contents, which the automatic `farclip` is derived from.
"""
function update_cam!(::Scene, cam::StageCamera, area3d::Rect)
    bb = Rect3d(area3d)
    width = widths(bb)
    r = 0.5 * norm(width)
    (isnan(r) || iszero(r)) && return
    cam.bounding_sphere[] = Sphere(Point3d(maximum(bb) - 0.5 * width), r)
    return
end

"""
    update_cam!(scene::Scene, cam::StageCamera)

Updates the scene's camera matrices based on the StageCamera's current observable values.
"""
function update_cam!(scene::Scene, cam::StageCamera)
    lookat = cam.lookat[]
    crop_factor = cam.crop_factor[]
    upvector = cam.upvector[]

    tan_half_fov = tand(0.5 * fov_degrees(cam))
    cam_distance = stage_distance(cam)

    viewport = scene.viewport[]
    aspect = Float64(viewport.widths[1] / viewport.widths[2])
    # the stage has to fit into the smaller viewport dimension, and the crop factor
    # narrows that framing without moving the camera
    tan_half_fit = tan_half_fov / crop_factor
    tan_half_y = aspect >= 1 ? tan_half_fit : tan_half_fit / aspect

    eyeposition = stage_eyeposition(cam)
    cam_forward = normalize(lookat - eyeposition)
    cam_right = normalize(cross(cam_forward, upvector))
    cam_up = cross(cam_right, cam_forward)

    # the rotation angles follow from the field of view, so a given fraction offsets the frame
    # by the same amount no matter the focal length
    tilt_angle = atan(cam.relative_offset[][2] * tan_half_y)
    # the cos factor compensates the tilt foreshortening the pan, so both fractions stay exact
    pan_angle = -atan(cam.relative_offset[][1] * tan_half_y * aspect * cos(tilt_angle))

    pan = qrotation(cam_up, pan_angle)
    forward_panned = pan * cam_forward
    right_panned = pan * cam_right
    tilt = qrotation(right_panned, tilt_angle)
    view_direction = tilt * forward_panned
    view_up = cross(right_panned, view_direction)

    nearclip, farclip = clip_planes(cam, eyeposition, cam_distance)

    view_mat = Makie.lookat(eyeposition, eyeposition + view_direction, view_up)
    proj_mat = perspectiveprojection(2 * atand(tan_half_y), aspect, nearclip, farclip)

    set_proj_view!(camera(scene), proj_mat, view_mat)
    camera(scene).eyeposition[] = Vec3f(eyeposition)
    camera(scene).upvector[] = Vec3f(view_up)
    camera(scene).view_direction[] = Vec3f(view_direction)

    return
end

"""
    scale_focal_length!(cam::StageCamera, factor)

Multiplies the focal length of the camera by `factor`, i.e. narrows the field of view
for `factor > 1`. Acts on `cam.mm` or `cam.fov`, whichever is in use.
"""
function scale_focal_length!(cam::StageCamera, factor)
    if cam.fov[] !== nothing
        cam.fov[] = clamp(cam.fov[] / factor, 1.0, 179.0)
    else
        cam.mm[] = clamp(cam.mm[] * factor, 1.0, 500.0)
    end
    return
end

"""
    zoom_cam!(cam::StageCamera, factor)

Multiplies the focal length of the camera by `factor` while keeping the camera position fixed,
which shrinks the stage for `factor > 1`.
"""
function zoom_cam!(cam::StageCamera, factor)
    tan_half_before = tand(0.5 * fov_degrees(cam))
    scale_focal_length!(cam, factor)
    tan_half_after = tand(0.5 * fov_degrees(cam))
    cam.stage_size[] = cam.stage_size[] * tan_half_after / tan_half_before
    return
end

function orbit_cam!(cam::StageCamera, delta_azimuth, delta_elevation)
    cam.azimuth[] = cam.azimuth[] + delta_azimuth
    cam.elevation[] = clamp(
        cam.elevation[] + delta_elevation,
        -STAGE_ELEVATION_LIMIT, STAGE_ELEVATION_LIMIT
    )
    return
end

"""
    reposition_cam!(cam::StageCamera, lookat)

Makes `lookat` the new lookat point without moving the camera, by deriving `azimuth`, `elevation`
and `stage_size` from the camera's current position.
"""
function reposition_cam!(cam::StageCamera, lookat)
    eyeposition = stage_eyeposition(cam)
    offset = eyeposition - to_ndim(Vec3d, lookat, 0)
    radius = norm(offset)
    iszero(radius) && return

    cam.azimuth[] = atand(offset[2], offset[1])
    cam.elevation[] = clamp(
        atand(offset[3], hypot(offset[1], offset[2])),
        -STAGE_ELEVATION_LIMIT, STAGE_ELEVATION_LIMIT
    )
    cam.stage_size[] = 2 * radius * tand(0.5 * fov_degrees(cam))
    cam.lookat[] = to_ndim(Vec3d, lookat, 0)
    return
end

function offset_cam!(cam::StageCamera, delta)
    cam.relative_offset[] = clamp.(cam.relative_offset[] + Vec2d(delta), -1.0, 1.0)
    return
end

function add_mouse_controls!(scene, cam::StageCamera)
    @extract cam.controls (
        rotation_button, offset_button, reset_offset_button, reposition_button,
        scroll_mod, focal_length_mod, zoom_mod,
    )
    @extract cam.settings (mouse_rotationspeed, mouse_offsetspeed, mouse_zoomspeed, mouse_stagesizespeed)

    last_mousepos = RefValue(Vec2d(0, 0))
    dragging = RefValue((false, false)) # rotation, offset
    e = events(scene)

    on(camera(scene), e.mousebutton) do event
        if event.action == Mouse.press && is_mouseinside(scene)
            if ispressed(scene, reposition_button[])
                plot, _, position = ray_assisted_pick(scene)
                p3d = to_ndim(Point3d, position, 0.0)
                if !isnan(p3d) && is_data_space(plot) && parent_scene(plot) == scene
                    reposition_cam!(cam, p3d)
                end
                return Consume(true)
            elseif ispressed(scene, reset_offset_button[])
                cam.relative_offset[] = Vec2d(0, 0)
                return Consume(true)
            elseif ispressed(scene, offset_button[])
                last_mousepos[] = mouseposition_px(scene)
                dragging[] = (false, true)
                return Consume(true)
            elseif ispressed(scene, rotation_button[])
                last_mousepos[] = mouseposition_px(scene)
                dragging[] = (true, false)
                return Consume(true)
            end
        elseif event.action == Mouse.release && any(dragging[])
            dragging[] = (false, false)
            return Consume(true)
        end
        return Consume(false)
    end

    on(camera(scene), e.mouseposition) do mp
        if dragging[][1] && ispressed(scene, rotation_button[])
            mousepos = screen_relative(scene, mp)
            delta = 0.5 * mouse_rotationspeed[] * (mousepos - last_mousepos[])
            last_mousepos[] = mousepos
            orbit_cam!(cam, -delta[1], -delta[2])
            return Consume(true)
        elseif dragging[][2] && ispressed(scene, offset_button[])
            mousepos = screen_relative(scene, mp)
            # the frame moves with the mouse, and the offsets span the frame center to its edge
            delta = 2 * mouse_offsetspeed[] * (mousepos - last_mousepos[]) ./ widths(viewport(scene)[])
            last_mousepos[] = mousepos
            offset_cam!(cam, -delta)
            return Consume(true)
        end
        return Consume(false)
    end

    return on(camera(scene), e.scroll) do scroll
        if is_mouseinside(scene) && ispressed(scene, scroll_mod[])
            if ispressed(scene, zoom_mod[])
                zoom_cam!(cam, (1.0 + 0.1 * mouse_zoomspeed[])^scroll[2])
            elseif ispressed(scene, focal_length_mod[])
                scale_focal_length!(cam, (1.0 + 0.1 * mouse_zoomspeed[])^scroll[2])
            else
                cam.stage_size[] = cam.stage_size[] * (1.0 + 0.1 * mouse_stagesizespeed[])^-scroll[2]
            end
            return Consume(true)
        end
        return Consume(false)
    end
end

function on_pulse(scene, cam::StageCamera, timestep)
    @extractvalue cam.controls (
        forward_key, backward_key, left_key, right_key, up_key, down_key,
        azimuth_left_key, azimuth_right_key, elevation_up_key, elevation_down_key,
        increase_fov_key, decrease_fov_key,
        increase_stage_size_key, decrease_stage_size_key,
        offset_mod,
    )

    if !ispressed(
            scene, forward_key | backward_key | left_key | right_key | up_key | down_key |
                azimuth_left_key | azimuth_right_key | elevation_up_key | elevation_down_key |
                increase_fov_key | decrease_fov_key |
                increase_stage_size_key | decrease_stage_size_key
        )
        return
    end

    @extractvalue cam.settings (
        keyboard_translationspeed, keyboard_rotationspeed, keyboard_zoomspeed,
        keyboard_stagesizespeed, keyboard_offsetspeed,
    )

    forward = ispressed(scene, forward_key)
    backward = ispressed(scene, backward_key)
    left = ispressed(scene, left_key)
    right = ispressed(scene, right_key)
    up = ispressed(scene, up_key)
    down = ispressed(scene, down_key)
    translating = forward || backward || left || right || up || down

    if translating
        azimuth = cam.azimuth[]
        upvector = normalize(cam.upvector[])

        horizontal_forward = Vec3d(cosd(azimuth), sind(azimuth), 0)
        cam_forward = normalize(horizontal_forward - dot(horizontal_forward, upvector) * upvector)
        cam_right = normalize(cross(cam_forward, upvector))

        speed = keyboard_translationspeed * timestep * cam.stage_size[]

        translation = speed * (
            (backward - forward) * cam_forward +
                (left - right) * cam_right +
                (up - down) * upvector
        )

        cam.lookat[] = cam.lookat[] + translation
    end

    arrow_left = ispressed(scene, azimuth_left_key)
    arrow_right = ispressed(scene, azimuth_right_key)
    arrow_up = ispressed(scene, elevation_up_key)
    arrow_down = ispressed(scene, elevation_down_key)
    arrows = arrow_left || arrow_right || arrow_up || arrow_down
    offsetting = arrows && ispressed(scene, offset_mod)
    rotating = arrows && !offsetting

    if rotating
        rotation_speed = keyboard_rotationspeed * timestep * 60.0
        orbit_cam!(cam, (arrow_right - arrow_left) * rotation_speed, (arrow_up - arrow_down) * rotation_speed)
    end

    if offsetting
        speed = keyboard_offsetspeed * timestep
        offset_cam!(cam, speed * Vec2d(arrow_right - arrow_left, arrow_up - arrow_down))
    end

    fov_inc = ispressed(scene, increase_fov_key)
    fov_dec = ispressed(scene, decrease_fov_key)
    fov_adjustment = fov_inc || fov_dec

    if fov_adjustment
        scale_focal_length!(cam, (1 + keyboard_zoomspeed * timestep)^(fov_dec - fov_inc))
    end

    stage_inc = ispressed(scene, increase_stage_size_key)
    stage_dec = ispressed(scene, decrease_stage_size_key)
    stage_adjustment = stage_inc || stage_dec

    if stage_adjustment
        step = (1 + keyboard_stagesizespeed * timestep)^(stage_inc - stage_dec)
        cam.stage_size[] = cam.stage_size[] * step
    end

    return translating || rotating || offsetting || fov_adjustment || stage_adjustment
end
