"""
Creates a ThreeJS camera from the AbstractPlotting Scene camera
"""
function get_camera(renderer, js_scene, scene::Scene)
    get_camera(renderer, js_scene, AbstractPlotting.camera(scene), cameracontrols(scene))
end

function get_camera(renderer, js_scene, cam, cam_controls::Camera2D)
    area = cam_controls.area
    mini, maxi = minimum(area[]), maximum(area[])
    jscam = THREE.new.OrthographicCamera(mini[1], maxi[1], maxi[2], mini[2], -1, 1000)
    onany(area) do area
        mini, maxi = minimum(area), maximum(area)
        jscam.left = mini[1]
        jscam.right = maxi[1]
        jscam.top = maxi[2]
        jscam.bottom = mini[2]
        jscam.updateProjectionMatrix()
        renderer.render(js_scene, jscam)
    end
    return jscam
end

function get_camera(renderer, js_scene, cam, cam_controls::Camera3D)
    jscam = THREE.new.PerspectiveCamera(cam_controls.fov[], (/)(cam.resolution[]...), 1, 1000)
    jscam.up.set()
    update = Observable(false)
    args = (
        cam.projection, cam_controls.eyeposition, cam_controls.lookat, cam_controls.upvector,
        cam_controls.fov, cam_controls.near, cam_controls.far
    )
    onany(update, args...) do _, proj, pos, lookat, up, fov, near, far
        jscam.up.set(up...)
        jscam.position.set(pos...)
        jscam.lookAt(lookat...)
        jscam.fov = fov
        jscam.near = near
        jscam.far = far
        jscam.updateProjectionMatrix()
        renderer.render(js_scene, jscam);
    end
    update[] = true # run onany first time
    jscam
end


function get_camera(renderer, js_scene, cam, cam_controls::Camera3D)
    jscam = THREE.new.PerspectiveCamera(cam_controls.fov[], (/)(cam.resolution[]...), 1, 1000)
    update = Observable(false)
    args = (
        cam.projection, cam_controls.eyeposition, cam_controls.lookat, cam_controls.upvector,
        cam_controls.fov, cam_controls.near, cam_controls.far
    )
    onany(update, args...) do _, proj, pos, lookat, up, fov, near, far
        jscam.position.set(pos...)
        jscam.lookAt(lookat...)
        jscam.up.set(up...)
        jscam.fov = fov
        jscam.near = near
        jscam.far = far
        jscam.updateProjectionMatrix()
        renderer.render(js_scene, jscam);
    end
    update[] = true # run onany first time
    jscam
end
