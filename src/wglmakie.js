const WGLMakie = function (){
    // Taken from https://andreasrohner.at/posts/Web%20Development/JavaScript/Simple-orbital-camera-controls-for-THREE-js/
    function attach_3d_camera(domElement, camera_matrices, cam3d){
        if (cam3d === undefined) {
            // we just support 3d cameras atm
            return
        }
        const w = camera_matrices.resolution.value.x
        const h = camera_matrices.resolution.value.y
        const camera = new THREE.PerspectiveCamera(
            cam3d.fov,
            w/h,
            cam3d.near, cam3d.far);

        const center = new THREE.Vector3(...cam3d.lookat);
        camera.up = new THREE.Vector3(...cam3d.upvector);
        camera.position.set(...cam3d.eyeposition)
        camera.lookAt(center);

        function update(){
            camera.updateProjectionMatrix()
            camera.updateWorldMatrix()
            camera_matrices.view.value = camera.matrixWorldInverse
            camera_matrices.projection.value = camera.projectionMatrix
            camera_matrices.eyeposition.value = camera.position
        }

        function addMouseHandler(domObject, drag, zoomIn, zoomOut) {
            let startDragX = null
            let startDragY = null
            function mouseWheelHandler(e) {
                e = window.event || e;
                const delta = Math.max(-1, Math.min(1, (e.wheelDelta || -e.detail)));
                if (delta < 0 && zoomOut) {
                    zoomOut(delta);
                } else if (zoomIn) {
                    zoomIn(delta);
                }

                e.preventDefault();
            }
            function mouseDownHandler(e) {
                startDragX = e.clientX;
                startDragY = e.clientY;

                e.preventDefault();
            }
            function mouseMoveHandler(e) {
                if (startDragX === null || startDragY === null)
                    return;

                if (drag)
                    drag(e.clientX - startDragX, e.clientY - startDragY);

                startDragX = e.clientX;
                startDragY = e.clientY;
                e.preventDefault();
            }
            function mouseUpHandler(e) {
                mouseMoveHandler.call(this, e);
                startDragX = null;
                startDragY = null;
                e.preventDefault();
            }
            domObject.addEventListener("wheel", mouseWheelHandler);
            domObject.addEventListener("mousedown", mouseDownHandler);
            domObject.addEventListener("mousemove", mouseMoveHandler);
            domObject.addEventListener("mouseup", mouseUpHandler);
        }

        function drag(deltaX, deltaY) {
            const radPerPixel = (Math.PI / 450)
            const deltaPhi = radPerPixel * deltaX
            const deltaTheta = radPerPixel * deltaY
            const pos = camera.position.sub(center)
            const radius = pos.length()
            let theta = Math.acos(pos.z / radius)
            let phi = Math.atan2(pos.y, pos.x)

            // Subtract deltaTheta and deltaPhi
            theta = Math.min(Math.max(theta - deltaTheta, 0), Math.PI);
            phi -= deltaPhi;

            // Turn back into Cartesian coordinates
            pos.x = radius * Math.sin(theta) * Math.cos(phi);
            pos.y = radius * Math.sin(theta) * Math.sin(phi);
            pos.z = radius * Math.cos(theta);

            camera.position.add(center);
            camera.lookAt(center);
            update()
        }

        function zoomIn() {
            camera.position.sub(center).multiplyScalar(0.9).add(center);
            update()
        }

        function zoomOut() {
            camera.position.sub(center).multiplyScalar(1.1).add(center);
            update()
        }

        addMouseHandler(domElement, drag, zoomIn, zoomOut);
    }


    const cached_textures = {}

    function _create_texture(data) {
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
    function create_texture(data){
        if (data.type == "Reference") {
            let tex = cached_textures[data.id]
            if (tex == undefined) {
                tex = _create_texture(data)
            }
            cached_textures[data.id] = tex
            return tex
        } else {
            return _create_texture(data)
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

    const typed_array_names = [
        "Uint8Array",
        "Int32Array",
        "Uint32Array",
        "Float32Array"]

    let serialized_references = undefined

    function set_duplicate_references(refs){
        serialized_references = refs;
    }

    function deserialize_three(data){
        if (typeof data === "number"){
            return data
        }
        if (typeof data === "boolean"){
            return data
        }
        if (typed_array_names.includes(data.constructor.name)) {
            return data
        }
        if (data.type !== undefined) {
            if (data.type == "Reference"){
                if (serialized_references == undefined){
                    throw "No duplicate references defined"
                } else if (serialized_references.length < data.index) {
                    throw "Inconsistent reference found!"
                }
                return deserialize_three(serialized_references[data.index - 1])
            }
            if (data.type == "Sampler"){
                return convert_texture(data)
            }
            if (typed_array_names.includes(data.type)) {
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
            return data
        }
        return data // we just leave data we dont know alone!
    }

    function BufferAttribute(buffer) {
        const buff = deserialize_three(buffer.flat)
        const jsbuff = new THREE.BufferAttribute(buff, buffer.type_length);
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
        for(const name in instance_attributes) {
            const buffer = InstanceBufferAttribute(instance_attributes[name]);
            buffer_geometry.setAttribute(name, buffer);
        }
    }

    function recreate_instanced_geometry(mesh) {
        const buffer_geometry = new THREE.InstancedBufferGeometry();
        const vertexarrays = {}
        const instance_attributes = {}
        const faces = [...mesh.geometry.index.array]
        Object.keys(mesh.geometry.attributes).forEach(name=>{
            const buffer = mesh.geometry.attributes[name]
            // really dont know why copying an array is considered rocket science in JS
            const copy = buffer.to_update ? buffer.to_update : buffer.array.map(x=> x)
            if (buffer.isInstancedBufferAttribute) {
                instance_attributes[name] = {flat: copy, type_length: buffer.itemSize}
            } else {
                vertexarrays[name] = {flat: copy, type_length: buffer.itemSize}
            }
        })
        attach_geometry(buffer_geometry, vertexarrays, faces)
        attach_instanced_geometry(buffer_geometry, instance_attributes)
        mesh.geometry.dispose()
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
            const value = data[name]
            // this is already a uniform - happens when we attach additional
            // uniforms like the camera matrices in a later stage!
            if (value.constructor.name == "Uniform"){
                result[name] = value
            } else {
                result[name] = new THREE.Uniform(deserialize_three(value))
            }
        }
        return result
    }

    function create_material(program){
        const is_volume = 'volumedata' in program.uniforms
        return new THREE.RawShaderMaterial({
            uniforms: deserialize_uniforms(program.uniforms),
            vertexShader: deserialize_three(program.vertex_source),
            fragmentShader: deserialize_three(program.fragment_source),
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
        mesh.name = data.name
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

        const cam = {
            view: new THREE.Uniform(new THREE.Matrix4()),
            projection: new THREE.Uniform(new THREE.Matrix4()),
            projectionview: new THREE.Uniform(new THREE.Matrix4()),
            resolution: new THREE.Uniform(new THREE.Vector2()),
            eyeposition: new THREE.Uniform(new THREE.Vector3())
        }

        function update_cam(camera){
            const [view, projection, projectionview, resolution, eyepos] = camera
            cam.view.value.fromArray(view)
            cam.projection.value.fromArray(projection)
            cam.projectionview.value.fromArray(projectionview)
            cam.resolution.value.fromArray(deserialize_js(resolution))
            cam.eyeposition.value.fromArray(deserialize_js(eyepos))
        }

        update_cam(get_observable(data.camera))

        if (data.cam3d_state){
            attach_3d_camera(window.renderer.domElement, cam, data.cam3d_state)
        } else {
            on_update(data.camera, update_cam)
        }

        data.plots.forEach(plot => {
            // fill in the camera uniforms, that we don't sent in serialization per plot
            plot.uniforms.view = cam.view
            plot.uniforms.projection = cam.projection
            plot.uniforms.projectionview = cam.projectionview
            plot.uniforms.resolution = cam.resolution
            plot.uniforms.eyeposition = cam.eyeposition
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
            }
        })
    }
    function first(x){
        return x[Object.keys(x)[0]]
    }
    function connect_attributes(mesh, updater){
        const instance_buffers = {}
        const geometry_buffers = {}
        let first_instance_buffer;
        const real_instance_length = [0]
        let first_geometry_buffer;
        const real_geometry_length = [0]

        function re_assign_buffers() {
            const attributes = mesh.geometry.attributes;
            const buffers = Object.values(attributes)
            Object.keys(attributes).forEach(name=>{
                const buffer = attributes[name]
                if (buffer.isInstancedBufferAttribute){
                    instance_buffers[name] = buffer
                } else {
                    geometry_buffers[name] = buffer
                }
            })
            first_instance_buffer = first(instance_buffers)
            // not all meshes have instances!
            if (first_instance_buffer){
                real_instance_length[0] = first_instance_buffer.count
            }
            first_geometry_buffer = first(geometry_buffers)
            real_geometry_length[0] = first_geometry_buffer.count
        }

        re_assign_buffers()

        on_update(updater, ([name, array, length]) => {
            const new_values = deserialize_three(deserialize_js(array))
            const buffer = mesh.geometry.attributes[name]
            let buffers;
            let first_buffer;
            let real_length;
            let is_instance = false;
            // First, we need to figure out if this is an instance / geometry buffer
            if (name in instance_buffers) {
                buffers = instance_buffers
                first_buffer = first_instance_buffer
                real_length = real_instance_length
                is_instance = true
            } else {
                buffers = geometry_buffers
                first_buffer = first_geometry_buffer
                real_length = real_geometry_length
            }
            if(length <= real_length[0]){
                // this is simple - we can just update the values
                buffer.set(new_values)
                buffer.needsUpdate = true
                if (is_instance){
                    mesh.geometry.instanceCount = length
                }
            } else {
                // resizing is a bit more complex
                // first we directly overwrite the array - this
                // won't have any effect, but like this we can collect the
                // newly sized arrays untill all of them have the same length
                buffer.to_update = new_values
                if (Object.values(buffers).every(x=> x.to_update && ((x.to_update.length / x.itemSize) == length))){
                    if (is_instance) {
                        recreate_instanced_geometry(mesh)
                        // we just replaced geometry & all buffers, so we need to update thise
                        re_assign_buffers()
                        mesh.geometry.instanceCount = new_values.length / buffer.itemSize
                    }
                } else {
                }
            }
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
        window.renderer = renderer
        return renderer
    }

    return {
        deserialize_scene,
        threejs_module,
        start_renderloop,
        deserialize_three,
        render_scenes,
        set_duplicate_references
    }
}()
