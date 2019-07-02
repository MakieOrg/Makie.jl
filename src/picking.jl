

function AbstractPlotting.pick(
        scene::Scene, THREE::ThreeDisplay, xy::Vec{2, Float64}
    )
    raycaster = THREE.new.Raycaster();
    xy_device_coordinates = ((xy ./ Vec(size(scene))) .* 2.0) .- 1.0
    js, camera = to_jsscene(THREE, scene)
    raycaster.setFromCamera(xy_device_coordinates, camera);
    intersectedObjects = raycaster.intersectObjects(js.children);
    return jlvalue(intersectedObjects)
end
