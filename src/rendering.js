function render_camera(renderer, scene, camera){
    renderer.autoClear = scene.clearscene;
    const area = scene.pixelarea;
    if(area){
        var x = area[0];
        var y = area[1];
        var w = area[2];
        var h = area[3];
        if(camera.matrixAutoUpdate){
            camera.aspect = w/h;
            camera.updateProjectionMatrix()
        }
        renderer.setViewport(x, y, w, h);
        renderer.setScissor(x, y, w, h);
        renderer.setScissorTest(true);
        renderer.setClearColor(scene.backgroundcolor);
        renderer.render(scene, camera);
    }
}

function render_scene(renderer, scene){
    var camera = scene.getObjectByName("camera");
    if(camera){
        const old_visibilities = scene.children.map(child=>{
            // Set all subscenes to invisible, so we don't render them here
            const vis = child.visible
            if (child.type == "Scene"){
                child.visible = false
            }
            return vis
        })
        render_camera(renderer, scene, camera);
        scene.children.map((child, idx)=>{
            child.visible = old_visibilities[idx]
        })
    }
    for(var i = 0; i < scene.children.length; i++){
        var child = scene.children[i];
        if (child.type == "Scene"){
            render_scene(renderer, child);
        }
    }
}

function start_renderloop(js_scene){
    render_scene(js_scene);
    window.requestAnimationFrame(()=> render_scene(js_scene));
}


function threejs_module(canvas, width, height){
    var context = canvas.getContext("webgl2", {preserveDrawingBuffer: true});

    if(!context){
        context = canvas.getContext("webgl", {preserveDrawingBuffer: true});
    }

    var renderer = new $THREE.WebGLRenderer({
        antialias: true, canvas: canvas, context: context,
        powerPreference: "high-performance"
    });

    var ratio = window.devicePixelRatio || 1;
    // var corrected_width = $width / ratio;
    // var corrected_height = $height / ratio;
    // canvas.style.width = corrected_width;
    // canvas.style.height = corrected_height;

    renderer.setSize(width, height);
    renderer.setClearColor("#ffffff");
    renderer.setPixelRatio(ratio);

    put_on_heap($(uuidstr(renderer)), renderer);
    put_on_heap($(uuidstr(window)), window);

    function mousemove(event){
        var rect = canvas.getBoundingClientRect();
        var x = event.clientX - rect.left;
        var y = event.clientY - rect.top;
        update_obs($comm, {
            mouseposition: [x, y]
        })
        return false
    }

    canvas.addEventListener("mousemove", mousemove);

    function mousedown(event){
        update_obs($comm, {
            mousedown: event.buttons
        })
        return false;
    }

    canvas.addEventListener("mousedown", mousedown);

    function mouseup(event){
        update_obs($comm, {
            mouseup: event.buttons
        })
        return false;
    }
    canvas.addEventListener("mouseup", mouseup);

    function wheel(event){
        update_obs($comm, {
            scroll: [event.deltaX, -event.deltaY]
        })
        event.preventDefault()
        return false;
    }
    canvas.addEventListener("wheel", wheel);

    function keydown(event){
        update_obs($comm, {
            keydown: event.code
        })
        return false;
    }
    document.addEventListener("keydown", keydown);

    function keyup(event){
        update_obs($comm, {
            keyup: event.code
        })
        return false;
    }
    document.addEventListener("keyup", keyup);
    // This is a pretty ugly work around......
    // so on keydown, we add the key to the currently pressed keys set
    // if we open the contextmenu before releasing the key, we'll never
    // receive an up event, so the key will stay inside the currently_pressed
    // set... Only option I found is to actually listen to the contextmenu
    // and remove all keys if its opened.
    function contextmenu(event){
        update_obs($comm, {
            keyup: "delete_keys"
        })
        return false;
    }
    document.addEventListener("contextmenu", contextmenu);
    document.addEventListener("focusout", contextmenu);
}
