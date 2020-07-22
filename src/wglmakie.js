const WGLMakie = function (){
    function create_texture(data){
        const buffer = deserialize_three(data.data)
        if (data.size.length == 3){
            const tex = new THREE.DataTexture3D(
                buffer, data.size[0], data.size[1], data.size[2],
            )
            tex.format = THREE[data.three_format]
            tex.type = THREE[data.three_type]
            return tex
        } else {
            return new THREE.DataTexture(
                buffer, data.size[0], data.size[1],
                THREE[data.three_format], THREE[data.three_type]
            )
        }
    }

    function convert_texture(data){
        const tex = create_texture(data)
        tex.needsUpdate = true
        tex.minFilter = THREE[data.minFilter]
        tex.magFilter = THREE[data.magFilter]
        tex.anisotropy = data.anisotropy
        tex.wrapS = THREE[data.wrapS]
        if (data.size.length > 2){
            tex.wrapT = THREE[data.wrapT]
        }
        if (data.size.length > 3){
            tex.wrapR = THREE[data.wrapR]
        }
        return tex
    }

    function deserialize_three(data){
        if (typeof data === "number"){
            return data
        }
        if (typeof data === "boolean"){
            return data
        }
        if (typeof data === "string"){
            // since we don't use strings together with deserialize_three, this must be
            // a three global!
            return THREE[data]
        }
        if (data.isMatrix4) {
            return data
        }
        if (data.type !== undefined) {
            if (data.type == "Sampler"){
                return convert_texture(data)
            }
            const array_types = [
                "Uint8Array",
                "Int32Array",
                "Uint32Array",
                "Float32Array"]

            if (array_types.includes(data.type)) {
                return new window[data.type](data.data)
            }
        }
        if (is_list(data)) {
            if (data.length == 2) {
                return new THREE.Vector2().fromArray(data)
            }
            if (data.length == 3) {
                return new THREE.Vector3().fromArray(data)
            }
            if (data.length == 4) {
                return new THREE.Vector4().fromArray(data)
            }
            if (data.length == 16){
                const mat = new THREE.Matrix4()
                mat.fromArray(data)
                return mat
            }
        }
        // Ok, WHAT ON EARTH IS THIS?!!? WHAT HAVE WE DONE?
        throw `Object isn't a recognized three data type: ${JSON.stringify(data)}`
    }

    function BufferAttribute(buffer) {
        const buff = deserialize_three(buffer.flat)
        const jsbuff = new THREE.Float32BufferAttribute(buff, buffer.type_length);
        jsbuff.setUsage(THREE.DynamicDrawUsage);
        return jsbuff
    }

    function InstanceBufferAttribute(buffer) {
        const buff = deserialize_three(buffer.flat)
        const jsbuff = new THREE.InstancedBufferAttribute(buff, buffer.type_length);
        jsbuff.setUsage(THREE.DynamicDrawUsage);
        return jsbuff
    }

    function attach_geometry(buffer_geometry, vertexarrays, faces) {
        for(const name in vertexarrays) {
            const buffer = BufferAttribute(vertexarrays[name]);
            buffer_geometry.setAttribute(name, buffer);
        }
        buffer_geometry.setIndex(faces);
        buffer_geometry.boundingSphere = new THREE.Sphere()
        // don't use intersection / culling
        buffer_geometry.boundingSphere.radius = 10000000000000
        buffer_geometry.frustumCulled = false
        return buffer_geometry;
    }

    function attach_instanced_geometry(buffer_geometry, instance_attributes) {
        let count = 0;
        for(const name in instance_attributes) {
            count += 1;
            const buffer = InstanceBufferAttribute(instance_attributes[name]);
            buffer_geometry.setAttribute(name, buffer);
        }
    }

    function recreate_instanced_geometry(mesh, vertexarrays, faces, instance_attributes) {
        const buffer_geometry = new THREE.InstancedBufferGeometry();
        attach_geometry(buffer_geometry, vertexarrays, faces)
        attach_instanced_geometry(buffer_geometry, instance_attributes);
        mesh.geometry = buffer_geometry;
        mesh.needsUpdate = true;
    }

    function recreate_geometry(mesh, vertexarrays, faces) {
        const buffer_geometry = new THREE.BufferGeometry();
        attach_geometry(buffer_geometry, vertexarrays, faces);
        mesh.geometry = buffer_geometry;
        mesh.needsUpdate = true;
    }

    function update_buffer(mesh, buffer){
        const {name, flat, len} = buffer;
        const geometry = mesh.geometry;
        const jsb = geometry.attributes[name];
        jsb.set(flat, 0)
        jsb.needsUpdate = true
        geometry.instanceCount = len
    }

    function deserialize_uniforms(data) {
        const result = {}
        for (const name in data) {
            result[name] = {value: deserialize_three(data[name])}
        }
        return result
    }

    function create_material(program){
        const is_volume = 'volumedata' in program.uniforms
        return new THREE.RawShaderMaterial({
            uniforms: deserialize_uniforms(program.uniforms),
            vertexShader: program.vertex_source,
            fragmentShader: program.fragment_source,
            side: is_volume ? THREE.BackSide : THREE.DoubleSide,
            transparent: true,
            // depthTest: true,
            // depthWrite: true
        })
    }

    function create_mesh(program){
        const buffer_geometry = new THREE.BufferGeometry()
        attach_geometry(buffer_geometry, program.vertexarrays, program.faces)
        const material = create_material(program)
        return new THREE.Mesh(buffer_geometry, material);
    }

    function create_instanced_mesh(program){
        const buffer_geometry = new THREE.InstancedBufferGeometry()
        attach_geometry(buffer_geometry, program.vertexarrays, program.faces)
        attach_instanced_geometry(buffer_geometry, program.instance_attributes);
        const material = create_material(program)

        return new THREE.Mesh(buffer_geometry, material);
    }

    function deserialize_plot(data){
        let mesh;
        if ("instance_attributes" in data) {
            mesh = create_instanced_mesh(data)
        } else {
            mesh = create_mesh(data)
        }
        mesh.frustumCulled = false
        mesh.matrixAutoUpdate = false
        const update_visible = (v) => (mesh.visible = v)
        update_visible(get_observable(data.visible))
        on_update(data.visible, update_visible)
        connect_uniforms(mesh, data.uniform_updater)
        connect_attributes(mesh, data.attribute_updater)
        return mesh
    }

    function deserialize_scene(data){
        scene = new THREE.Scene()
        scene.frustumCulled = false
        scene.pixelarea = data.pixelarea
        scene.backgroundcolor = data.backgroundcolor
        scene.clearscene = data.clearscene

        cam = {
            view: new THREE.Matrix4(),
            projection: new THREE.Matrix4(),
            projectionview: new THREE.Matrix4(),
        }

        function update_cam(camera){
            const [view, projection, projectionview] = camera
            cam.view.fromArray(view)
            cam.projection.fromArray(projection)
            cam.projectionview.fromArray(projectionview)
        }

        update_cam(get_observable(data.camera))
        on_update(data.camera, update_cam)

        data.plots.forEach(plot => {
            // fill in the camera uniforms, that we don't sent in serialization per plot
            plot.uniforms.view = cam.view
            plot.uniforms.projection = cam.projection
            plot.uniforms.projectionview = cam.projectionview
            const p = deserialize_plot(plot)
            scene.add(p)
        })
        return scene
    }

    function connect_uniforms(mesh, updater){
        on_update(updater, ([name, data]) => {
            const uniform = mesh.material.uniforms[name]
            const deserialized = deserialize_three(deserialize_js(data))

            if (uniform.value.isTexture) {
                uniform.value.image.data.set(deserialized)
                uniform.value.needsUpdate = true
            } else {
                uniform.value = deserialized
                uniform.needsUpdate = true
            }
        })
    }

    function connect_attributes(mesh, updater){
        const attributes = mesh.geometry.attributes;
        on_update(updater, ([name, array, length]) => {
            const buffer = attributes[name]
            buffer.set(deserialize_js(array))
            buffer.needsUpdate = true
        })
    }

    function render_scene(renderer, scene, cam){
        renderer.autoClear = scene.clearscene;
        const area = get_observable(scene.pixelarea)
        if(area){
            const [x, y, w, h] = area;
            renderer.setViewport(x, y, w, h);
            renderer.setScissor(x, y, w, h);
            renderer.setScissorTest(true);
            renderer.setClearColor(get_observable(scene.backgroundcolor));
            renderer.render(scene, cam);
        }
    }

    function render_scenes(renderer, scenes, cam){
        scenes.forEach((scene)=> render_scene(renderer, scene, cam))
    }

    function start_renderloop(renderer, three_scenes, cam){
        function renderloop() {
            render_scenes(renderer, three_scenes, cam);
            window.requestAnimationFrame(renderloop)
        }
        renderloop()
    }

    function threejs_module(canvas, comm, width, height){

        var context = canvas.getContext("webgl2", {preserveDrawingBuffer: true});

        if(!context){
            context = canvas.getContext("webgl", {preserveDrawingBuffer: true});
        }

        var renderer = new THREE.WebGLRenderer({
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

        function mousemove(event){
            var rect = canvas.getBoundingClientRect();
            var x = event.clientX - rect.left;
            var y = event.clientY - rect.top;
            update_obs(comm, {
                mouseposition: [x, y]
            })
            return false
        }

        canvas.addEventListener("mousemove", mousemove);

        function mousedown(event){
            update_obs(comm, {
                mousedown: event.buttons
            })
            return false;
        }

        canvas.addEventListener("mousedown", mousedown);

        function mouseup(event){
            update_obs(comm, {
                mouseup: event.buttons
            })
            return false;
        }
        canvas.addEventListener("mouseup", mouseup);

        function wheel(event){
            update_obs(comm, {
                scroll: [event.deltaX, -event.deltaY]
            })
            event.preventDefault()
            return false;
        }
        canvas.addEventListener("wheel", wheel);

        function keydown(event){
            update_obs(comm, {
                keydown: event.code
            })
            return false;
        }
        document.addEventListener("keydown", keydown);

        function keyup(event){
            update_obs(comm, {
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
            update_obs(comm, {
                keyup: "delete_keys"
            })
            return false;
        }
        document.addEventListener("contextmenu", contextmenu);
        document.addEventListener("focusout", contextmenu);
        return renderer
    }

    return {
        deserialize_scene,
        threejs_module,
        start_renderloop,
        deserialize_three,
        render_scenes
    }
}()
