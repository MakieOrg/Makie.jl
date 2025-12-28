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
    stage_width::Observable{Float64}
    lookat::Observable{Vec3f}
    fov::Observable{Union{Nothing, Float64}}
    mm::Observable{Union{Nothing, Float64}}
    nearclip::Observable{Union{Makie.Automatic, Float64}}
    zoom::Observable{Float64}
    upvector::Observable{Vec3f}
end

get_space(::StageCamera) = :data

"""
    StageCamera(scene; kwargs...)

A 3D camera that allows for more "photographic" tweaking of camera parameters.
Adjusting a typical 3D camera often involves repeatedly changing camera position and
field of view, to find a pleasing camera angle without clipping into the subject or having it be too small in frame.
Perspective is often an afterthought and field of view is simply used as a "cropping" tool after camera position is fixed.

The idea of the stage camera is that one usually wants to show an object of a certain size and position.
These parameters correspond to the `lookat` and the `stage_width` (the stage width being
the amount of space that should be in frame around the object of interest).

The next parameters that determine the look are the two camera angles, `azimuth` and `elevation`.
With `azimuth` you move the camera around the object and with `elevation` you decide from how far up
you look down on it.

The last parameter is the field of view or camera angle. Given that we've already fixed the stage width we
want to have in view, the camera angle does not primarily change the size of the object that's in view (what is commonly
called "zooming" in photography) but it decides how close or far the camera has to be from the subject and
therefore how strong the perspective look is and how much the background is emphasized.

# Arguments
- `azimuth::Float64`: Azimuth angle in degrees (rotation around z-axis)
- `elevation::Float64`: Elevation angle in degrees (rotation from xy-plane)
- `stage_width::Float64`: How large an object parallel to the camera plane should fit in view
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

Either `fov` or `mm` must be specified, but not both.

# Example
```julia
cam = StageCamera(scene, 
    azimuth = 45.0,
    elevation = 30.0,
    stage_width = 10.0,
    lookat = (0, 0, 0),
    mm = 50.0
)

# Update camera dynamically
cam.azimuth[] = 90.0
cam.zoom[] = 2.0
```
"""
function StageCamera(scene::Scene; 
    azimuth = 0.0,
    elevation = 0.0,
    stage_width = 1.0,
    lookat = Vec3d(0, 0, 0),
    fov = nothing,
    mm = fov === nothing ? 50.0 : nothing,
    nearclip = Makie.automatic,
    zoom = 1.0,
    upvector = Vec3d(0, 0, 1),
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
    
    # Create the camera with observables
    cam = StageCamera(
        Observable(azimuth),
        Observable(elevation),
        Observable(stage_width),
        Observable(lookat_vec),
        Observable(fov),
        Observable(mm),
        Observable(nearclip),
        Observable(zoom),
        Observable(upvector_vec)
    )
    
    # Disconnect previous camera
    disconnect!(camera(scene))
    
    # Set this camera as the scene's camera control
    cameracontrols!(scene, cam)
    
    # Set up automatic updates when observables change
    onany(camera(scene),
        cam.azimuth, cam.elevation, cam.stage_width, cam.lookat,
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
    stage_width = cam.stage_width[]
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
    
    # Calculate camera distance based on stage_width fitting horizontally
    cam_distance = stage_width / (2 * tand(fov / zoom / 2))
    farclip = 2 * cam_distance
    nearclip_val::Float64 = nearclip === Makie.automatic ? 0.01 * cam_distance : nearclip
    
    # Calculate camera position and orientation
    eyeposition = lookat + azimuth_elevation_radius(azimuth, elevation, cam_distance)
    cam_forward = normalize(lookat - eyeposition)
    cam_right = cross(cam_forward, upvector)
    upvector = cross(cam_right, cam_forward)
    
    # Update camera view and projection
    view_mat = Makie.lookat(eyeposition, Vec3d(lookat), upvector)
    viewport = scene.viewport[]
    aspect = Float64(viewport.widths[1] / viewport.widths[2])
    proj_mat = perspectiveprojection(fov / zoom, aspect, nearclip_val, farclip)
    
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
