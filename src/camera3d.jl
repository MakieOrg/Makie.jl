import Quaternions
const Q = Quaternions

@enum ProjectionEnum Perspective Orthographic


struct Camera3D
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

signal_convert(::Type{Signal{T1}}, x::Signal{T2}) where {T1, T2} = map(x-> convert(T1, x), x, typ = T1)
signal_convert(::Type{Signal{T1}}, x::T2) where {T1, T2} = Signal(T1, convert(T1, x))
signal_convert(t, x) = x



function cam3d!(scene; kw_args...)
    cam_attributes, rest = merged_get!(:cam3d, scene, Attributes(kw_args)) do
        Theme(
            rotationspeed = 1.0,
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
    camera = from_dict(Camera3D, cam_attributes)
    # remove previously connected camera
    disconnect!(scene.camera)
    add_translation!(scene, camera, camera.pan_button, camera.move_key)
    add_rotation!(scene, camera, camera.rotate_button, camera.move_key)
    camera
end


function projection_switch{T <: Real}(
        wh::Rect2D,
        fov::T, near::T, far::T,
        projection::ProjectionEnum, zoom::T
    )
    aspect = T((/)(widths(wh)...))
    h = T(tan(fov / 360.0 * pi) * near)
    w = T(h * aspect)
    projection == Perspective && return GLAbstraction.frustum(-w, w, -h, h, near, far)
    h, w = h * zoom, w * zoom
     GLAbstraction.orthographicprojection(-w, w, -h, h, near, far)
end

function rotate_cam{T}(
        theta::Vec{3, T},
        cam_right::Vec{3, T}, cam_up::Vec{3, T}, cam_dir::Vec{3, T}
    )
    rotation = one(Q.Quaternion{T})
    # first the rotation around up axis, since the other rotation should be relative to that rotation
    if theta[1] != 0
        rotation *= Q.qrotation(cam_up, theta[1])
    end
    # then right rotation
    if theta[2] != 0
        rotation *= Q.qrotation(cam_right, theta[2])
    end
    # last rotation around camera axis
    if theta[3] != 0
        rotation *= Q.qrotation(cam_dir, theta[3])
    end
    rotation
end


function add_translation!(scene, cam, key, button)
    last_mousepos = RefValue(Vec2f0(0, 0))
    map(scene.camera, scene.events.mousedrag) do drag
        if ispressed(scene, key[]) && ispressed(scene, button[])
            if drag == Mouse.down
                #just started pressing, nothing to do yet
                last_mousepos[] = Vec2f0(scene.events.mouseposition[])
            elseif drag == Mouse.pressed
                mousepos = Vec2f0(scene.events.mouseposition[])
                diff = (last_mousepos[] - mousepos) * cam.translationspeed[]
                last_mousepos[] = mousepos
                translate_cam!(scene, cam, Vec3f0(0f0, diff[1], diff[2]))
            end
        end
        return
    end
    map_once(scene.events.scroll) do scroll
        if ispressed(scene, button[])
            translate_cam!(scene, cam, Vec3f0(scroll[2], 0f0, 0f0))
        end
        return
    end
end


function add_rotation!(scene, cam, button, key)
    last_mousepos = RefValue(Vec2f0(0, 0))
    map(scene.camera, scene.events.mousedrag) do drag
        if ispressed(scene, button[]) && ispressed(scene, key[])
            if drag == Mouse.down
                last_mousepos[] = Vec2f0(scene.events.mouseposition[])
            elseif drag == Mouse.pressed
                mousepos = Vec2f0(scene.events.mouseposition[])
                rot_scaling = cam.rotationspeed[] * (scene.events.window_dpi[] * 0.001)
                mp = (last_mousepos[] - mousepos) * rot_scaling
                last_mousepos[] = mousepos
                rotate_cam!(scene, cam, Vec3f0(mp[1], -mp[2], 0f0))
            end
        end
        return
    end
end

function translate_cam!(scene, cam, translation)
    translation == Vec3f0(0) && return
    @getfields cam (projectiontype, lookat, eyeposition, upvector)

    dir = eyeposition - lookat
    dir_len = norm(dir)
    cam_res = Vec2f0(widths(scene.px_area[]))
    zoom, x, y = translation
    zoom *= 0.1f0 * dir_len

    if projectiontype != Perspective
        x, y = GLAbstraction.to_worldspace(Vec2f0(x, y), scene.projectionview[], cam_res)
    else
        x, y = (Vec2f0(x, y) ./ cam_res) .* dir_len
    end
    dir_norm = normalize(dir)
    right = normalize(cross(dir_norm, upvector))
    zoom_trans = dir_norm * zoom

    side_trans = right * (-x) + normalize(upvector) * y
    newpos = eyeposition + side_trans + zoom_trans

    cam.eyeposition[] = newpos
    cam.lookat[] = lookat + side_trans
    update_cam!(scene, cam)
    return
end

function rotate_cam!(scene, cam, theta_v)
    theta_v == Vec3f0(0) && return #nothing to do!
    @getfields cam (eyeposition, lookat, upvector)

    dir = normalize(eyeposition - lookat)
    right_v = normalize(cross(upvector, dir))
    upvector = normalize(cross(dir, right_v))
    rotation = rotate_cam(theta_v, right_v, Vec3f0(0, 0, sign(upvector[3])), dir)
    r_eyepos = lookat + rotation * (eyeposition - lookat)
    r_up = normalize(rotation * upvector)
    cam.eyeposition[] = r_eyepos
    cam.upvector[] = r_up
    update_cam!(scene, cam)
    return
end



function update_cam!(scene::Scene, cam::Camera3D)
    @getfields cam (fov, near, projectiontype, lookat, eyeposition, upvector)

    zoom = norm(lookat - eyeposition)
    # TODO this means you can't set FarClip... SAD!
    # TODO use boundingbox(scene) for optimal far/near
    far = max(zoom * 5f0, 30f0)
    proj = projection_switch(scene.px_area[], fov, near, far, projectiontype, zoom)
    view = GLAbstraction.lookat(eyeposition, lookat, upvector)

    set_value!(scene.camera.projection, proj)
    set_value!(scene.camera.view, view)
    set_value!(scene.camera.projectionview, proj * view)
end
