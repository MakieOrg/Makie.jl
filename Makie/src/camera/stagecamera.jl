function azimuth_elevation_radius(azim, elev, radius)
    x = radius * cosd(elev) * cosd(azim)
    y = radius * cosd(elev) * sind(azim)
    z = radius * sind(elev)
    Vec3d(x, y, z)
end

struct StageCamera <: AbstractCamera3D
    # Camera parameters as observables
    azimuth::Observable{Float64}
    elevation::Observable{Float64}
    stage_size::Observable{Float64}
    lookat::Observable{Vec3f}
    fov::Observable{Union{Nothing, Float64}}
    mm::Observable{Union{Nothing, Float64}}
    nearclip::Observable{Union{Makie.Automatic, Float64}}
    zoom::Observable{Float64}
    upvector::Observable{Vec3f}
    
    # Keyboard controls
    controls::Attributes
    settings::Attributes
    selected::Observable{Bool}
end

get_space(::StageCamera) = :data

"""
    StageCamera(scene; kwargs...)

A 3D camera that allows for more "photographic" tweaking of camera parameters.
Adjusting a typical 3D camera often involves repeatedly changing camera position and
field of view, to find a pleasing camera angle without clipping into the subject or having it be too small in frame.
Perspective is often an afterthought and field of view is simply used as a "cropping" tool after camera position is fixed.

The idea of the stage camera is that one usually wants to show an object of a certain size and position.
These parameters correspond to the `lookat` and the `stage_size` which is the amount of space that should be in frame around
the object of interest.

The next parameters that determine the look are the two camera angles, `azimuth` and `elevation`.
With `azimuth` you move the camera around the object and with `elevation` you decide from how far up
you look down on it.

The last parameter is the field of view or camera angle. Given that we've already fixed the stage width we
want to have in view, the camera angle does not primarily change the size of the object that's in view (what is commonly
called "zooming" in photography) but it decides how close or far the camera has to be from the subject and
therefore how strong the perspective look is and how much the background is emphasized.

# Keyboard Controls

The StageCamera supports keyboard navigation:
- `W/S`: Move lookat forward/backward in the camera's facing direction (projected onto the plane perpendicular to the world up vector)
- `A/D`: Move lookat left/right relative to the camera
- `Q/E`: Move lookat down/up along the world up vector
- `Left/Right Arrow`: Rotate azimuth (orbit around the subject)
- `Up/Down Arrow`: Change elevation (look up/down)
- `X/Z`: Increase/decrease field of view (or adjust mm focal length)

# Arguments
- `azimuth::Float64`: Azimuth angle in degrees (rotation around z-axis)
- `elevation::Float64`: Elevation angle in degrees (rotation from xy-plane)
- `stage_size::Float64`: The size of a sphere at the lookat point that should always fit in view
- `lookat::Union{Vec3f, Tuple, Vector}`: Point the camera is looking at
- `fov::Union{Nothing, Float64} = nothing`: Field of view in degrees (mutually exclusive with mm). 
  Wide angles (e.g., 80°) create stronger perspective with more background visible and position 
  the camera closer to the lookat point. Narrow angles (e.g., 20°) reduce perspective distortion, 
  show less background, and position the camera further from the lookat point.
- `mm::Union{Nothing, Float64} = nothing`: Focal length in mm relative to a classic full-frame 
  35mm sensor (mutually exclusive with fov). Common values: 24mm (wide angle), 50mm (normal/standard), 
  100mm (telephoto). Shorter focal lengths create wider fields of view with stronger perspective.
- `nearclip::Union{Makie.Automatic, Float64} = Makie.automatic`: Near clipping plane distance
- `zoom::Float64 = 1.0`: Zoom factor, should only be changed if the image is as desired but
   should be cropped in our out a little.
- `upvector::Union{Vec3f, Tuple, Vector} = Vec3f(0, 0, 1)`: World up direction vector

# Keyboard Control Settings
- `keyboard_translationspeed = 0.5`: Speed multiplier for keyboard translations
- `keyboard_rotationspeed = 1.0`: Speed multiplier for keyboard rotations
- `keyboard_zoomspeed = 1.0`: Speed multiplier for FOV/mm adjustments

# Key Bindings (customizable)
- `forward_key = Keyboard.w`: Move lookat forward
- `backward_key = Keyboard.s`: Move lookat backward
- `left_key = Keyboard.a`: Move lookat left
- `right_key = Keyboard.d`: Move lookat right
- `up_key = Keyboard.e`: Move lookat up
- `down_key = Keyboard.q`: Move lookat down
- `azimuth_left_key = Keyboard.left`: Rotate azimuth left
- `azimuth_right_key = Keyboard.right`: Rotate azimuth right
- `elevation_up_key = Keyboard.up`: Increase elevation
- `elevation_down_key = Keyboard.down`: Decrease elevation
- `increase_fov_key = Keyboard.x`: Increase field of view
- `decrease_fov_key = Keyboard.z`: Decrease field of view

Either `fov` or `mm` must be specified, but not both.

# Example
```julia
cam = StageCamera(scene, 
    azimuth = 45.0,
    elevation = 30.0,
    stage_size = 10.0,
    lookat = (0, 0, 0),
    mm = 50.0
)

# Update camera dynamically
cam.azimuth[] = 90.0
cam.zoom[] = 2.0

# Or use keyboard controls by clicking on the scene
```
"""
function StageCamera(scene::Scene; 
    azimuth = 0.0,
    elevation = 0.0,
    stage_size = 1.0,
    lookat = Vec3d(0, 0, 0),
    fov = nothing,
    mm = fov === nothing ? 50.0 : nothing,
    nearclip = Makie.automatic,
    zoom = 1.0,
    upvector = Vec3d(0, 0, 1),
    kwargs...
)
    # Validate that either fov or mm is set
    if mm === nothing && fov === nothing
        error("Either mm or fov must be set")
    elseif mm !== nothing && fov !== nothing
        error("Cannot set both mm and fov")
    end
    
    # Convert lookat and upvector to Vec3f if needed
    lookat_vec = lookat isa Vec3f ? lookat : Vec3f(lookat...)
    upvector_vec = upvector isa Vec3f ? upvector : Vec3f(upvector...)
    
    # Set up keyboard controls
    overwrites = Attributes(kwargs)
    
    controls = Attributes(
        # Translation keys
        forward_key = Keyboard.w,
        backward_key = Keyboard.s,
        left_key = Keyboard.a,
        right_key = Keyboard.d,
        up_key = Keyboard.e,
        down_key = Keyboard.q,
        # Rotation keys
        azimuth_left_key = Keyboard.left,
        azimuth_right_key = Keyboard.right,
        elevation_up_key = Keyboard.up,
        elevation_down_key = Keyboard.down,
        # FOV/mm keys
        increase_fov_key = Keyboard.x,
        decrease_fov_key = Keyboard.z,
    )
    
    replace!(controls, :StageCamera, scene, overwrites)
    
    settings = Attributes(
        keyboard_translationspeed = 0.5,
        keyboard_rotationspeed = 1.0,
        keyboard_zoomspeed = 1.0,
    )
    
    replace!(settings, :StageCamera, scene, overwrites)
    
    # Create the camera with observables
    cam = StageCamera(
        Observable(azimuth),
        Observable(elevation),
        Observable(stage_size),
        Observable(lookat_vec),
        Observable(fov),
        Observable(mm),
        Observable(nearclip),
        Observable(zoom),
        Observable(upvector_vec),
        controls,
        settings,
        Observable(true)
    )
    
    # Disconnect previous camera
    disconnect!(camera(scene))
    
    # Set this camera as the scene's camera control
    cameracontrols!(scene, cam)
    
    # Keyboard controls
    # Deselect all cameras first
    deselect_all_stagecameras!(root(scene))
    
    # de/select camera on click outside/inside
    on(camera(scene), events(scene).mousebutton, priority = 100) do event
        if event.action == Mouse.press
            cam.selected[] = is_mouseinside(scene)
        end
        return Consume(false)
    end
    
    # Keyboard controls via tick
    on(camera(scene), events(scene).tick) do tick
        if cam.selected[]
            on_pulse(scene, cam, tick.delta_time)
        end
    end
    
    # Set up automatic updates when observables change
    onany(camera(scene),
        cam.azimuth, cam.elevation, cam.stage_size, cam.lookat,
        cam.fov, cam.mm, cam.nearclip, cam.zoom, cam.upvector
    ) do args...
        update_cam!(scene, cam)
    end
    
    # Trigger update on scene resize
    on(camera(scene), scene.viewport) do _
        update_cam!(scene, cam)
    end
    
    # Initial update
    update_cam!(scene, cam)
    
    return cam
end

"""
    update_cam!(scene::Scene, cam::StageCamera)

Updates the scene's camera matrices based on the StageCamera's current observable values.
"""
function update_cam!(scene::Scene, cam::StageCamera)
    # Extract current values from observables
    azimuth = cam.azimuth[]
    elevation = cam.elevation[]
    stage_size = cam.stage_size[]
    lookat = cam.lookat[]
    fov_val = cam.fov[]
    mm_val = cam.mm[]
    nearclip = cam.nearclip[]
    zoom = cam.zoom[]
    upvector = cam.upvector[]
    
    # Calculate FOV from mm or use provided fov
    fov::Float64 = if mm_val !== nothing && fov_val === nothing
        2 * atand(36, 2 * mm_val)
    elseif fov_val !== nothing && mm_val === nothing
        fov_val
    else
        error("Either mm or fov must be set")
    end
    
    # Calculate camera distance based on stage dimension fitting in view
    viewport = scene.viewport[]
    aspect = Float64(viewport.widths[1] / viewport.widths[2])
    
    cam_distance = stage_size / (2 * tand(fov / zoom / 2))
    y_fov = if aspect <= 1
        # stage_size fits horizontally
        fov  / zoom / aspect
    else
        fov / zoom
    end

    farclip = 10 * cam_distance
    nearclip_val::Float64 = nearclip === Makie.automatic ? 0.01 * cam_distance : nearclip
    
    # Calculate camera position and orientation
    eyeposition = lookat + azimuth_elevation_radius(azimuth, elevation, cam_distance)
    cam_forward = normalize(lookat - eyeposition)
    cam_right = cross(cam_forward, upvector)
    upvector = cross(cam_right, cam_forward)
    
    # Update camera view and projection
    view_mat = Makie.lookat(eyeposition, Vec3d(lookat), upvector)
    proj_mat = perspectiveprojection(y_fov, aspect, nearclip_val, farclip)
    
    camera(scene).view[] = view_mat
    camera(scene).projection[] = proj_mat
    camera(scene).projectionview[] = proj_mat * view_mat
    camera(scene).eyeposition[] = Vec3f(eyeposition)
    camera(scene).upvector[] = Vec3f(upvector)
    camera(scene).view_direction[] = Vec3f(cam_forward)
    
    return
end

"""
    stage_cam!(scene; kwargs...)

Creates and sets up a StageCamera for the scene. This is the preferred way to create
a stage camera, similar to how `cam3d!` works for Camera3D.

See [`StageCamera`](@ref) for keyword arguments.
"""
stage_cam!(scene::Scene; kwargs...) = StageCamera(scene; kwargs...)

function deselect_all_stagecameras!(scene)
    cam = cameracontrols(scene)
    cam isa StageCamera && (cam.selected[] = false)
    for child in scene.children
        deselect_all_stagecameras!(child)
    end
    return nothing
end

function on_pulse(scene, cam::StageCamera, timestep)
    @extractvalue cam.controls (
        forward_key, backward_key, left_key, right_key, up_key, down_key,
        azimuth_left_key, azimuth_right_key, elevation_up_key, elevation_down_key,
        increase_fov_key, decrease_fov_key,
    )

    # Check if any keys are pressed
    if !ispressed(
            scene, forward_key | backward_key | left_key | right_key | up_key | down_key |
                azimuth_left_key | azimuth_right_key | elevation_up_key | elevation_down_key |
                increase_fov_key | decrease_fov_key
        )
        return
    end

    @extractvalue cam.settings (
        keyboard_translationspeed, keyboard_rotationspeed, keyboard_zoomspeed,
    )

    # Translation - move lookat
    forward = ispressed(scene, forward_key)
    backward = ispressed(scene, backward_key)
    left = ispressed(scene, left_key)
    right = ispressed(scene, right_key)
    up = ispressed(scene, up_key)
    down = ispressed(scene, down_key)
    translating = forward || backward || left || right || up || down

    if translating
        # Get camera direction in the plane orthogonal to upvector
        azimuth = cam.azimuth[]
        upvector = cam.upvector[]
        
        # Forward direction in the horizontal plane (projected onto plane perpendicular to upvector)
        cam_forward_3d = Vec3d(cosd(azimuth), sind(azimuth), 0)
        # Normalize the projection onto the plane perpendicular to upvector
        cam_forward = normalize(cam_forward_3d - dot(cam_forward_3d, upvector) * upvector)
        # Right direction (perpendicular to both forward and upvector)
        cam_right = normalize(cross(cam_forward, upvector))
        
        # Calculate translation based on stage dimension
        stage_size = cam.stage_size[] !== nothing ? cam.stage_size[] : cam.stage_height[]
        speed = keyboard_translationspeed * timestep * stage_size
        
        translation = speed * (
            (backward - forward) * cam_forward +
            (left - right) * cam_right +
            (up - down) * normalize(upvector)
        )
        
        cam.lookat[] = cam.lookat[] + Vec3f(translation)
    end

    # Rotation - change azimuth and elevation
    az_left = ispressed(scene, azimuth_left_key)
    az_right = ispressed(scene, azimuth_right_key)
    el_up = ispressed(scene, elevation_up_key)
    el_down = ispressed(scene, elevation_down_key)
    rotating = az_left || az_right || el_up || el_down

    if rotating
        # Rotation speed in degrees per second
        rotation_speed = keyboard_rotationspeed * timestep * 90.0
        
        cam.azimuth[] = cam.azimuth[] + (az_right - az_left) * rotation_speed
        cam.elevation[] = clamp(
            cam.elevation[] + (el_up - el_down) * rotation_speed,
            -89.0, 89.0
        )
    end

    # FOV/mm adjustment
    fov_inc = ispressed(scene, increase_fov_key)
    fov_dec = ispressed(scene, decrease_fov_key)
    fov_adjustment = fov_inc || fov_dec

    if fov_adjustment
        step = (1 + keyboard_zoomspeed * timestep)^(fov_inc - fov_dec)
        
        if cam.fov[] !== nothing
            cam.fov[] = clamp(cam.fov[] * step, 1.0, 179.0)
        elseif cam.mm[] !== nothing
            # Decrease mm to increase fov, increase mm to decrease fov
            cam.mm[] = clamp(cam.mm[] / step, 1.0, 500.0)
        end
    end

    # Return true if we should keep processing
    return translating || rotating || fov_adjustment
end
