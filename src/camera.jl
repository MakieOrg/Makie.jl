import AbstractPlotting: PixelCamera

"""
Creates a ThreeJS camera from the AbstractPlotting Scene camera
"""
function add_camera!(jsctx, js_scene, scene::Scene)
    add_camera!(jsctx, js_scene, scene, AbstractPlotting.camera(scene), cameracontrols(scene))
end

function add_camera!(jsctx, js_scene, scene, cam, cam_controls::AbstractPlotting.EmptyCamera)
    return
end


function update_ortho(jscam, area)
    mini, maxi = minimum(area), maximum(area)
    left, right, top, bottom = mini[1], maxi[1], maxi[2], mini[2]
    jscam.left = left
    jscam.right = right
    jscam.top = top
    jscam.bottom = bottom
    jscam.updateProjectionMatrix()
end

function add_camera!(jsctx, js_scene, scene, cam, cam_controls::PixelCamera)
    area = pixelarea(scene)
    mini, maxi = minimum(area[]), maximum(area[])
    jscam = jsctx.THREE.new.OrthographicCamera(
        mini[1], maxi[1], maxi[2], mini[2], -10_000, 10_000
    )
    jscam.name = "camera"
    js_scene.add(jscam)
    on(area) do area
        update_ortho(jscam, AbstractPlotting.zerorect(area))
    end
    return
end

function add_camera!(jsctx, js_scene, scene, cam, cam_controls::Camera2D)
    area = cam_controls.area
    mini, maxi = minimum(area[]), maximum(area[])
    jscam = jsctx.THREE.new.OrthographicCamera(
        mini[1], maxi[1], maxi[2], mini[2], -10_000, 10_000
    )
    jscam.name = "camera"
    js_scene.add(jscam)
    on(area) do area
        update_ortho(jscam, area)
    end
    return
end

function add_camera!(jsctx, js_scene, scene, cam, cam_controls::Camera3D)
    jscam = jsctx.THREE.new.PerspectiveCamera(cam_controls.fov[], (/)(cam.resolution[]...), 1, 1000)
    jscam.name = "camera"
    js_scene.add(jscam)
    eyeposition, lookat, upvector, fov, near, far = getfield.(
        (cam_controls,),
        (:eyeposition, :lookat, :upvector, :fov, :near, :far)
    )
    area = pixelarea(scene)
    on(eyeposition) do eyeposition
        jscam.position.set(eyeposition...)
        jscam.updateProjectionMatrix()
    end
    on(lookat) do lookat
        jscam.lookAt(lookat...)
        jscam.updateProjectionMatrix()
    end
    on(upvector) do upvector
        jscam.up.set(upvector...)
        jscam.updateProjectionMatrix()
    end
    on(fov) do fov
        jscam.fov = fov
        jscam.updateProjectionMatrix()
    end
    on(far) do far
        jscam.far = far
        jscam.updateProjectionMatrix()
    end
    on(far) do far
        jscam.far = far
        jscam.updateProjectionMatrix()
    end
    on(area) do area
        jscam.aspect = (/)(widths(area)...)
        jscam.updateProjectionMatrix()
    end
    return
end
