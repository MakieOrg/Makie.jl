import AbstractPlotting: PixelCamera

"""
Creates a ThreeJS camera from the AbstractPlotting Scene camera
"""
function add_camera!(renderer, js_scene, scene::Scene)
    add_camera!(renderer, js_scene, scene, AbstractPlotting.camera(scene), cameracontrols(scene))
end

function add_camera!(renderer, js_scene, scene, cam, cam_controls::AbstractPlotting.EmptyCamera)
    return (nothing, ()-> nothing)
end

function setup_renderer(scene, renderer)
    renderer.autoClear = scene.clear[]
    bg = to_color(scene.backgroundcolor[])
    area = pixelarea(scene)[]
    x, y, w, h = minimum(area)..., widths(area)...
    renderer.setViewport(x, y, w, h)
    renderer.setScissor(x, y, w, h)
    renderer.setScissorTest(true)
    renderer.setClearColor(THREE.new.Color(red(bg), green(bg), blue(bg)))
end

function update_ortho(jscam, area, renderer, js_scene, scene)
    mini, maxi = minimum(area), maximum(area)
    left, right, top, bottom = mini[1], maxi[1], maxi[2], mini[2]
    jscam.left = left
    jscam.right = right
    jscam.top = top
    jscam.bottom = bottom
    jscam.updateProjectionMatrix()
    setup_renderer(scene, renderer)
    renderer.render(js_scene, jscam)
end

function add_camera!(renderer, js_scene, scene, cam, cam_controls::PixelCamera)
    area = pixelarea(scene)
    mini, maxi = minimum(area[]), maximum(area[])
    jscam = THREE.new.OrthographicCamera(
        mini[1], maxi[1], maxi[2], mini[2], -10_000, 10_000
    )
    return jscam, ()-> update_ortho(jscam, AbstractPlotting.zerorect(area[]), renderer, js_scene, scene)
end

function add_camera!(renderer, js_scene, scene, cam, cam_controls::Camera2D)
    area = cam_controls.area
    mini, maxi = minimum(area[]), maximum(area[])
    jscam = THREE.new.OrthographicCamera(
        mini[1], maxi[1], maxi[2], mini[2], -10_000, 10_000
    )
    return jscam, ()-> update_ortho(jscam, area[], renderer, js_scene, scene)
end

function add_camera!(renderer, js_scene, scene, cam, cam_controls::Camera3D)
    jscam = THREE.new.PerspectiveCamera(cam_controls.fov[], (/)(cam.resolution[]...), 1, 1000)
    eyeposition, lookat, upvector, fov, near, far = getfield.(
        (cam_controls,),
        (:eyeposition, :lookat, :upvector, :fov, :near, :far)
    )
    area = pixelarea(scene)
    function update_camera()
        jscam.up.set(upvector[]...)
        jscam.position.set(eyeposition[]...)
        jscam.lookAt(lookat[]...)
        jscam.fov = fov[]
        jscam.near = near[]
        jscam.far = far[]
        jscam.aspect = (/)(widths(area[])...)
        jscam.updateProjectionMatrix()
        setup_renderer(scene, renderer)
        renderer.render(js_scene, jscam);
    end
    return jscam, update_camera
end
