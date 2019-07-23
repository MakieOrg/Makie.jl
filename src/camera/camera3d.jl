
@enum ProjectionEnum Perspective Orthographic

struct Camera3D <: AbstractCamera
    rotationspeed::Node{Float32}
    translationspeed::Node{Float32}
    eyeposition::Node{Vec3f0}
    lookat::Node{Vec3f0}
    upvector::Node{Vec3f0}
    fov::Node{Float32}
    near::Node{Float32}
    far::Node{Float32}
    projectiontype::Node{ProjectionEnum}
    pan_button::Node{ButtonTypes}
    rotate_button::Node{ButtonTypes}
    move_key::Node{ButtonTypes}
end

"""
    cam3d_cad!(scene; kw_args...)

Creates a 3D camera for `scene` which rotates around
the _viewer_'s "up" axis - similarly to how it's done
in CAD software cameras.
"""
function cam3d_cad!(scene; kw_args...)
    cam_attributes, rest = merged_get!(:cam3d, scene, Attributes(kw_args)) do
        Theme(
            rotationspeed = 0.3,
            translationspeed = 1.0,
            eyeposition = Vec3f0(3),
            lookat = Vec3f0(0),
            upvector = Vec3f0(0, 0, 1),
            fov = 45f0,
            near = 0.01f0,
            far = 100f0,
            projectiontype = Perspective,
            pan_button = Mouse.right,
            rotate_button = Mouse.left,
            move_key = nothing
        )
    end
    cam = from_dict(Camera3D, cam_attributes)
    # remove previously connected camera
    disconnect!(scene.camera)
    add_translation!(scene, cam, cam.pan_button, cam.move_key, false)
    add_rotation!(scene, cam, cam.rotate_button, cam.move_key, false)
    cameracontrols!(scene, cam)
    on(camera(scene), scene.px_area) do area
        # update cam when screen ratio changes
        update_cam!(scene, cam)
    end
    cam
end

"""
    cam3d_turntable!(scene; kw_args...)

Creates a 3D camera for `scene`, which rotates around
the plot's axis.
"""
function cam3d_turntable!(scene; kw_args...)
    cam_attributes, rest = merged_get!(:cam3d, scene, Attributes(kw_args)) do
        Theme(
            rotationspeed = 0.3,
            translationspeed = 1.0,
            eyeposition = Vec3f0(3),
            lookat = Vec3f0(0),
            upvector = Vec3f0(0, 0, 1),
            fov = 45f0,
            near = 0.01f0,
            far = 100f0,
            projectiontype = Perspective,
            pan_button = Mouse.right,
            rotate_button = Mouse.left,
            move_key = nothing
        )
    end
    cam = from_dict(Camera3D, cam_attributes)
    # remove previously connected camera
    disconnect!(scene.camera)
    add_translation!(scene, cam, cam.pan_button, cam.move_key, true)
    add_rotation!(scene, cam, cam.rotate_button, cam.move_key, true)
    cameracontrols!(scene, cam)
    on(camera(scene), scene.px_area) do area
        # update cam when screen ratio changes
        update_cam!(scene, cam)
    end
    cam
end

"""
    cam3d!(scene; kwargs...)

An alias to [`cam3d_turntable!`](@ref).
Creates a 3D camera for `scene`, which rotates around
the plot's axis.
"""
const cam3d! = cam3d_turntable!

function projection_switch(
        wh::Rect2D,
        fov::T, near::T, far::T,
        projectiontype::ProjectionEnum, zoom::T
    ) where T <: Real
    aspect = T((/)(widths(wh)...))
    h = T(tan(fov / 360.0 * pi) * near)
    w = T(h * aspect)
    projectiontype == Perspective && return frustum(-w, w, -h, h, near, far)
    h, w = h * zoom, w * zoom
    orthographicprojection(-w, w, -h, h, near, far)
end

function rotate_cam(
        theta::Vec{3, T},
        cam_right::Vec{3, T}, cam_up::Vec{3, T}, cam_dir::Vec{3, T}
    ) where T
    rotation = Quaternion{T}(0, 0, 0, 1)
    # first the rotation around up axis, since the other rotation should be relative to that rotation
    if theta[1] != 0
        rotation *= qrotation(cam_up, theta[1])
    end
    # then right rotation
    if theta[2] != 0
        rotation *= qrotation(cam_right, theta[2])
    end
    # last rotation around camera axis
    if theta[3] != 0
        rotation *= qrotation(cam_dir, theta[3])
    end
    rotation
end

function add_translation!(scene, cam, key, button, zoom_shift_lookat::Bool)
    last_mousepos = RefValue(Vec2f0(0, 0))
    on(camera(scene), scene.events.mousedrag) do drag
        mp = Vec2f0(scene.events.mouseposition[])
        if ispressed(scene, key[]) && ispressed(scene, button[]) && is_mouseinside(scene)
            if drag == Mouse.down
                #just started pressing, nothing to do yet
                last_mousepos[] = mp
            elseif drag == Mouse.pressed
                mousepos = mp
                diff = (last_mousepos[] - mousepos) * cam.translationspeed[]
                last_mousepos[] = mousepos
                translate_cam!(scene, cam, Vec3f0(0f0, diff[1], diff[2]))
            end
        end
        return
    end
    on(camera(scene), scene.events.scroll) do scroll
        if ispressed(scene, button[]) && is_mouseinside(scene)
            cam_res = Vec2f0(widths(scene.px_area[]))
            mouse_pos_normalized = Vec2f0(scene.events.mouseposition[]) ./ cam_res
            mouse_pos_normalized = 2*mouse_pos_normalized .- 1f0
            zoom_step = scroll[2]
            zoom!(scene, mouse_pos_normalized, zoom_step, zoom_shift_lookat)
        end
        return
    end
end

function add_rotation!(scene, cam, button, key, fixed_axis::Bool)
    last_mousepos = RefValue(Vec2f0(0, 0))
    on(camera(scene), scene.events.mousedrag) do drag
        if ispressed(scene, button[]) && ispressed(scene, key[]) && is_mouseinside(scene)
            if drag == Mouse.down
                last_mousepos[] = Vec2f0(scene.events.mouseposition[])
            elseif drag == Mouse.pressed
                mousepos = Vec2f0(scene.events.mouseposition[])
                rot_scaling = cam.rotationspeed[] * (scene.events.window_dpi[] * 0.001)
                mp = (last_mousepos[] - mousepos) * rot_scaling
                last_mousepos[] = mousepos
                rotate_cam!(scene, cam, Vec3f0(mp[1], -mp[2], 0f0), fixed_axis)
            end
        end
        return
    end
end

translate_cam!(scene::Scene, translation::VecTypes) = translate_cam!(scene, cameracontrols(scene), translation)
function translate_cam!(scene::Scene, cam::Camera3D, _translation::VecTypes)
    translation = Vec3f0(_translation)
    translation == Vec3f0(0) && return
    @extractvalue cam (projectiontype, lookat, eyeposition, upvector)

    dir = eyeposition - lookat
    dir_len = norm(dir)
    cam_res = Vec2f0(widths(scene.px_area[]))
    z, x, y = translation
    z *= 0.1f0 * dir_len

    x, y = (Vec2f0(x, y) ./ cam_res) .* dir_len

    dir_norm = normalize(dir)
    right = normalize(cross(dir_norm, upvector))
    z_trans = dir_norm * z
    side_trans = right * (-x) + normalize(upvector) * y
    newpos = eyeposition + side_trans + z_trans
    cam.eyeposition[] = newpos
    cam.lookat[] = lookat + side_trans
    update_cam!(scene, cam)
    return
end

"""
    zoom!(scene, point, zoom_step)

Zooms the camera of `scene` in towards `point` by a factor of `zoom_step`.
"""
function zoom!(scene, point, zoom_step, shift_lookat::Bool)
    cam = cameracontrols(scene)
    @extractvalue cam (projectiontype, lookat, eyeposition, upvector)

    dir = eyeposition - lookat
    dir_len = norm(dir)
    zoom_step *= 0.1f0 * dir_len

    ray_eye = inv(scene.camera.projection[]) * Vec4f0(point[1],point[2],-1,1)
    ray_eye = Vec4f0(ray_eye[1:2]...,-1,0)
    ray_dir = Vec3f0((inv(scene.camera.view[]) * ray_eye))
    ray_dir = normalize(ray_dir)
    zoom_translation = ray_dir * zoom_step
    cam.eyeposition[] = eyeposition + zoom_translation
    if shift_lookat
        cam.lookat[] = lookat + zoom_translation
    end
    update_cam!(scene, cam)
end


rotate_cam!(scene::Scene, theta_v::Number...) = rotate_cam!(scene, cameracontrols(scene), theta_v)
rotate_cam!(scene::Scene, theta_v::VecTypes) = rotate_cam!(scene, cameracontrols(scene), theta_v)
function rotate_cam!(scene::Scene, cam::Camera3D, _theta_v::VecTypes, fixed_axis::Bool = true)
    theta_v = Vec3f0(_theta_v)
    theta_v == Vec3f0(0) && return #nothing to do!
    @extractvalue cam (eyeposition, lookat, upvector)

    dir = normalize(eyeposition - lookat)
    right_v = normalize(cross(upvector, dir))
    upvector = normalize(cross(dir, right_v))
    axis = fixed_axis ? Vec3f0(0, 0, sign(upvector[3])) : upvector
    rotation = rotate_cam(theta_v, right_v, axis, dir)
    r_eyepos = lookat + rotation * (eyeposition - lookat)
    r_up = normalize(rotation * upvector)
    cam.eyeposition[] = r_eyepos
    cam.upvector[] = r_up
    update_cam!(scene, cam)
    return
end

function update_cam!(scene::Scene, cam::Camera3D)
    @extractvalue cam (fov, near, projectiontype, lookat, eyeposition, upvector)

    zoom = norm(lookat - eyeposition)
    # TODO this means you can't set FarClip... SAD!
    # TODO use boundingbox(scene) for optimal far/near
    far = max(zoom * 5f0, 30f0)
    proj = projection_switch(scene.px_area[], fov, near, far, projectiontype, zoom)
    view = AbstractPlotting.lookat(eyeposition, lookat, upvector)

    scene.camera.projection[] = proj
    scene.camera.view[] = view
    scene.camera.projectionview[] = proj * view
    scene.camera.eyeposition[] = cam.eyeposition[]
end

function update_cam!(scene::Scene, camera::Camera3D, area3d::Rect)
    @extractvalue camera (fov, near, lookat, eyeposition, upvector)
    bb = FRect3D(area3d)
    width = widths(bb)
    half_width = width/2f0
    lower_corner = minimum(bb)
    middle = maximum(bb) - half_width
    camera.lookat[] = middle
    neweyepos = middle + 1.2width
    camera.eyeposition[] = neweyepos
    camera.upvector[] = Vec3f0(0,0,1)
    camera.near[] = 0.1f0 * norm(widths(bb))
    camera.far[] = 3f0 * norm(widths(bb))
    update_cam!(scene, camera)
    return
end

update_cam!(scene::Scene, eyeposition, lookat, up = Vec3f0(0, 0, 1)) = update_cam!(scene, cameracontrols(scene), eyeposition, lookat, up)

function update_cam!(scene::Scene, camera::Camera3D, eyeposition, lookat, up = Vec3f0(0, 0, 1))
    camera.lookat[] = Vec3f0(lookat)
    camera.eyeposition[] = Vec3f0(eyeposition)
    camera.upvector[] = Vec3f0(up)
    update_cam!(scene, camera)
    return
end
