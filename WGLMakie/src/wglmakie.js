import * as THREE from "https://cdn.esm.sh/v66/three@0.136/es2021/three.js";
import { getWebGLErrorMessage } from "./WEBGL.js";
window.THREE = THREE;

const TEXTURE_ATLAS = [undefined];

const pixelRatio = window.devicePixelRatio || 1.0;
// global scene cache to look them up for dynamic operations in Makie
// e.g. insert!(scene, plot) / delete!(scene, plot)
const scene_cache = {};
const plot_cache = {};

function add_scene(scene_id, three_scene) {
    scene_cache[scene_id] = three_scene;
}

function find_scene(scene_id) {
    return scene_cache[scene_id];
}

function delete_scene(scene_id) {
    const scene = scene_cache[scene_id];
    if (!scene) {
        return;
    }
    while (scene.children.length > 0) {
        scene.remove(scene.children[0]);
    }
    delete scene_cache[scene_id];
}

function find_plots(plot_uuids) {
    const plots = [];
    plot_uuids.forEach((id) => {
        const plot = plot_cache[id];
        if (plot) {
            plots.push(plot);
        }
    });
    return plots;
}

function delete_scenes(scene_uuids, plot_uuids) {
    plot_uuids.forEach((plot_id) => {
        delete plot_cache[plot_id];
    });
    scene_uuids.forEach((scene_id) => {
        delete_scene(scene_id);
    });
}

function insert_plot(scene_id, plot_data) {
    const scene = find_scene(scene_id);
    plot_data.forEach((plot) => {
        add_plot(scene, plot);
    });
}

function delete_plots(scene_id, plot_uuids) {
    const scene = find_scene(scene_id);
    const plots = find_plots(plot_uuids);
    plots.forEach((p) => {
        scene.remove(p);
        delete plot_cache[p];
    });
}

function to_world(scene, x, y) {
    const proj_inv = scene.wgl_camera.projectionview.value.clone().invert();
    const [_x, _y, w, h] = JSServe.get_observable(scene.pixelarea);
    const pix_space = new THREE.Vector4(
        ((x - _x) / w) * 2 - 1,
        ((y - _y) / h) * 2 - 1,
        0,
        1.0
    );
    pix_space.applyMatrix4(proj_inv);
    return new THREE.Vector2(
        pix_space.x / pix_space.w,
        pix_space.y / pix_space.w
    );
}

function clip_to_space(cam, space) {
    if (space == "data") {
        return cam.projectionview.value.clone().invert();
    } else if (space == "pixel") {
        const [w, h] = cam.resolution.value;
        const mati = new THREE.Matrix4();
        mati.fromArray([
            0.5 * w,
            0,
            0,
            0,
            0,
            0.5 * h,
            0,
            0,
            0,
            0,
            -10_000,
            0,
            0.5 * w,
            0.5 * h,
            0,
            1,
        ]);
        return mati;
    } else if (space == "relative") {
        const mati2 = new THREE.Matrix4();
        mati2.fromArray([
            0.5, 0.0, 0.0, 0.0, 0.0, 0.5, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.5,
            0.5, 0.0, 1.0,
        ]);
        return mati2;
    } else if (space == "clip") {
        return new THREE.Matrix4();
    } else {
        throw new Error(`Space ${space} not recognized`);
    }
}

function space_to_clip(cam, space) {
    if (space == "data") {
        return cam.projectionview.value;
    } else if (space == "pixel") {
        return cam.pixel_space.value;
    } else if (space == "relative") {
        const mati = new THREE.Matrix4();
        mati.fromArray([2, 0, 0, 0, 0, 2, 0, 0, 0, 0, 1, 0, -1, -1, 0, 1]);
        return mati;
    } else if (space == "clip") {
        return new THREE.Matrix4();
    } else {
        throw new Error(`Space ${space} not recognized`);
    }
}

function preprojection_matrix(cam, space, mspace) {
    const cp = clip_to_space(cam, mspace);
    const sc = space_to_clip(cam, space);
    const result = cp.clone();
    result.multiply(sc);
    return result;
}

function add_plot(scene, plot_data) {
    // fill in the camera uniforms, that we don't sent in serialization per plot
    const cam = scene.wgl_camera;
    const rel = new THREE.Matrix4();
    rel.set(
        2.0,
        0.0,
        0.0,
        -1.0,
        0.0,
        2.0,
        0.0,
        -1.0,
        0.0,
        0.0,
        1.0,
        0.0,
        0.0,
        0.0,
        0.0,
        1.0
    );
    const id = new THREE.Uniform(new THREE.Matrix4());

    if (plot_data.cam_space == "data") {
        plot_data.uniforms.view = cam.view;
        plot_data.uniforms.projection = cam.projection;
        plot_data.uniforms.projectionview = cam.projectionview;
        plot_data.uniforms.eyeposition = cam.eyeposition;
    } else if (plot_data.cam_space == "pixel") {
        plot_data.uniforms.view = id;
        plot_data.uniforms.projection = cam.pixel_space;
        plot_data.uniforms.projectionview = cam.pixel_space;
    } else if (plot_data.cam_space == "relative") {
        plot_data.uniforms.view = id;
        plot_data.uniforms.projection = rel;
        plot_data.uniforms.projectionview = rel;
    } else {
        // clip space
        plot_data.uniforms.view = id;
        plot_data.uniforms.projection = id;
        plot_data.uniforms.projectionview = id;
    }
    plot_data.uniforms.resolution = cam.resolution;

    if (plot_data.uniforms.preprojection) {
        const { space, markerspace } = plot_data;
        const preprojection = new THREE.Uniform(
            preprojection_matrix(cam, space.value, markerspace.value)
        );
        plot_data.uniforms.preprojection = preprojection;
        cam.cam_uniform.on((new_cam_data) => {
            preprojection.value = preprojection_matrix(
                cam,
                space.value,
                markerspace.value
            );
        });
    }
    const p = deserialize_plot(plot_data);
    plot_cache[plot_data.uuid] = p;
    scene.add(p);
}

// Taken from https://andreasrohner.at/posts/Web%20Development/JavaScript/Simple-orbital-camera-controls-for-THREE-js/
function attach_3d_camera(domElement, camera_matrices, cam3d) {
    if (cam3d === undefined) {
        // we just support 3d cameras atm
        return;
    }
    const w = camera_matrices.resolution.value.x;
    const h = camera_matrices.resolution.value.y;
    const camera = new THREE.PerspectiveCamera(
        cam3d.fov,
        w / h,
        cam3d.near,
        cam3d.far
    );

    const center = new THREE.Vector3(...cam3d.lookat);
    camera.up = new THREE.Vector3(...cam3d.upvector);
    camera.position.set(...cam3d.eyeposition);
    camera.lookAt(center);

    function update() {
        camera.updateProjectionMatrix();
        camera.updateWorldMatrix();
        camera_matrices.view.value = camera.matrixWorldInverse;
        camera_matrices.projection.value = camera.projectionMatrix;
        camera_matrices.eyeposition.value = camera.position;
    }

    function addMouseHandler(domObject, drag, zoomIn, zoomOut) {
        let startDragX = null;
        let startDragY = null;
        function mouseWheelHandler(e) {
            e = window.event || e;
            const delta = Math.sign(e.deltaY);
            if (delta == -1) {
                zoomOut();
            } else if (delta == 1) {
                zoomIn();
            }

            e.preventDefault();
        }
        function mouseDownHandler(e) {
            startDragX = e.clientX;
            startDragY = e.clientY;

            e.preventDefault();
        }
        function mouseMoveHandler(e) {
            if (startDragX === null || startDragY === null) return;

            if (drag) drag(e.clientX - startDragX, e.clientY - startDragY);

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
        const radPerPixel = Math.PI / 450;
        const deltaPhi = radPerPixel * deltaX;
        const deltaTheta = radPerPixel * deltaY;
        const pos = camera.position.sub(center);
        const radius = pos.length();
        let theta = Math.acos(pos.z / radius);
        let phi = Math.atan2(pos.y, pos.x);

        // Subtract deltaTheta and deltaPhi
        theta = Math.min(Math.max(theta - deltaTheta, 0), Math.PI);
        phi -= deltaPhi;

        // Turn back into Cartesian coordinates
        pos.x = radius * Math.sin(theta) * Math.cos(phi);
        pos.y = radius * Math.sin(theta) * Math.sin(phi);
        pos.z = radius * Math.cos(theta);

        camera.position.add(center);
        camera.lookAt(center);
        update();
    }

    function zoomIn() {
        camera.position.sub(center).multiplyScalar(0.9).add(center);
        update();
    }

    function zoomOut() {
        camera.position.sub(center).multiplyScalar(1.1).add(center);
        update();
    }

    addMouseHandler(domElement, drag, zoomIn, zoomOut);
}

function create_texture(data) {
    const buffer = data.data;
    if (data.size.length == 3) {
        const tex = new THREE.DataTexture3D(
            buffer,
            data.size[0],
            data.size[1],
            data.size[2]
        );
        tex.format = THREE[data.three_format];
        tex.type = THREE[data.three_type];
        return tex;
    } else {
        // a little optimization to not send the texture atlas over & over again
        const tex_data =
            buffer == "texture_atlas" ? TEXTURE_ATLAS[0].value : buffer;
        return new THREE.DataTexture(
            tex_data,
            data.size[0],
            data.size[1],
            THREE[data.three_format],
            THREE[data.three_type]
        );
    }
}

function re_create_texture(old_texture, buffer, size) {
    if (size.length == 3) {
        const tex = new THREE.DataTexture3D(buffer, size[0], size[1], size[2]);
        tex.format = old_texture.format;
        tex.type = old_texture.type;
        return tex;
    } else {
        return new THREE.DataTexture(
            buffer,
            size[0],
            size[1] ? size[1] : 1,
            old_texture.format,
            old_texture.type
        );
    }
}

function convert_texture(data) {
    const tex = create_texture(data);
    tex.needsUpdate = true;
    tex.minFilter = THREE[data.minFilter];
    tex.magFilter = THREE[data.magFilter];
    tex.anisotropy = data.anisotropy;
    tex.wrapS = THREE[data.wrapS];
    if (data.size.length > 1) {
        tex.wrapT = THREE[data.wrapT];
    }
    if (data.size.length > 2) {
        tex.wrapR = THREE[data.wrapR];
    }
    return tex;
}

const typed_array_names = [
    "Uint8Array",
    "Int32Array",
    "Uint32Array",
    "Float32Array",
];

function to_uniform(data) {
    if (!data.every((x) => typeof x === "number")) {
        return data;
    }
    if (data.length == 2) {
        return new THREE.Vector2().fromArray(data);
    }
    if (data.length == 3) {
        return new THREE.Vector3().fromArray(data);
    }
    if (data.length == 4) {
        return new THREE.Vector4().fromArray(data);
    }
    if (data.length == 16) {
        const mat = new THREE.Matrix4();
        mat.fromArray(data);
        return mat;
    }
    return data;
}

function deserialize_three(data) {
    if (typeof data === "number") {
        return data;
    }

    if (typeof data === "boolean") {
        return data;
    }

    if (typed_array_names.includes(data.constructor.name)) {
        return to_uniform(data);
    }

    if (data.type !== undefined) {
        if (data.type == "Sampler") {
            return convert_texture(data);
        }
        if (typed_array_names.includes(data.type)) {
            return new window[data.type](data.data);
        }
    }

    if (Array.isArray(data)) {
        return to_uniform(data);
    }
    return data; // we just leave data we dont know alone!
}

function BufferAttribute(buffer) {
    const jsbuff = new THREE.BufferAttribute(buffer.flat, buffer.type_length);
    jsbuff.setUsage(THREE.DynamicDrawUsage);
    return jsbuff;
}

function InstanceBufferAttribute(buffer) {
    const jsbuff = new THREE.InstancedBufferAttribute(
        buffer.flat,
        buffer.type_length
    );
    jsbuff.setUsage(THREE.DynamicDrawUsage);
    return jsbuff;
}

function attach_geometry(buffer_geometry, vertexarrays, faces) {
    for (const name in vertexarrays) {
        const buffer = BufferAttribute(vertexarrays[name]);
        buffer_geometry.setAttribute(name, buffer);
    }
    buffer_geometry.setIndex(faces);
    buffer_geometry.boundingSphere = new THREE.Sphere();
    // don't use intersection / culling
    buffer_geometry.boundingSphere.radius = 10000000000000;
    buffer_geometry.frustumCulled = false;
    return buffer_geometry;
}

function attach_instanced_geometry(buffer_geometry, instance_attributes) {
    for (const name in instance_attributes) {
        const buffer = InstanceBufferAttribute(instance_attributes[name]);
        buffer_geometry.setAttribute(name, buffer);
    }
}

function recreate_instanced_geometry(mesh) {
    const buffer_geometry = new THREE.InstancedBufferGeometry();
    const vertexarrays = {};
    const instance_attributes = {};
    const faces = [...mesh.geometry.index.array];
    Object.keys(mesh.geometry.attributes).forEach((name) => {
        const buffer = mesh.geometry.attributes[name];
        // really dont know why copying an array is considered rocket science in JS
        const copy = buffer.to_update
            ? buffer.to_update
            : buffer.array.map((x) => x);
        if (buffer.isInstancedBufferAttribute) {
            instance_attributes[name] = {
                flat: copy,
                type_length: buffer.itemSize,
            };
        } else {
            vertexarrays[name] = {
                flat: copy,
                type_length: buffer.itemSize,
            };
        }
    });
    attach_geometry(buffer_geometry, vertexarrays, faces);
    attach_instanced_geometry(buffer_geometry, instance_attributes);
    mesh.geometry.dispose();
    mesh.geometry = buffer_geometry;
    mesh.needsUpdate = true;
}

function deserialize_uniforms(data) {
    const result = {};
    // Threejs changes constructor names from some version to another..so...
    const uniform_constructor = new THREE.Uniform(2).constructor.name;
    for (const name in data) {
        const value = data[name];
        // this is already a uniform - happens when we attach additional
        // uniforms like the camera matrices in a later stage!
        if (value.constructor.name == uniform_constructor) {
            result[name] = value;
        } else {
            const ser = deserialize_three(value);
            result[name] = new THREE.Uniform(ser);
        }
    }
    return result;
}

function create_material(program) {
    const is_volume = "volumedata" in program.uniforms;
    return new THREE.RawShaderMaterial({
        uniforms: deserialize_uniforms(program.uniforms),
        vertexShader: program.vertex_source,
        fragmentShader: program.fragment_source,
        side: is_volume ? THREE.BackSide : THREE.DoubleSide,
        transparent: true,
        depthTest: !program.overdraw.value,
        depthWrite: !program.transparency.value,
    });
}

function create_mesh(program) {
    const buffer_geometry = new THREE.BufferGeometry();
    const faces = new THREE.BufferAttribute(program.faces, 1);
    attach_geometry(buffer_geometry, program.vertexarrays, faces);
    const material = create_material(program);
    return new THREE.Mesh(buffer_geometry, material);
}

function create_instanced_mesh(program) {
    const buffer_geometry = new THREE.InstancedBufferGeometry();
    const faces = new THREE.BufferAttribute(program.faces, 1);
    attach_geometry(buffer_geometry, program.vertexarrays, faces);
    attach_instanced_geometry(buffer_geometry, program.instance_attributes);
    const material = create_material(program);
    return new THREE.Mesh(buffer_geometry, material);
}

function deserialize_plot(data) {
    let mesh;
    if ("instance_attributes" in data) {
        mesh = create_instanced_mesh(data);
    } else {
        mesh = create_mesh(data);
    }
    mesh.name = data.name;
    mesh.frustumCulled = false;
    mesh.matrixAutoUpdate = false;
    const update_visible = (v) => {
        mesh.visible = v;
        // don't return anything, since that will disable on_update callback
        return;
    };
    update_visible(data.visible.value);
    data.visible.on(update_visible);
    connect_uniforms(mesh, data.uniform_updater);
    connect_attributes(mesh, data.attribute_updater);
    return mesh;
}

function deserialize_scene(data, canvas) {
    const scene = new THREE.Scene();
    add_scene(data.uuid, scene);
    scene.frustumCulled = false;
    scene.pixelarea = data.pixelarea;
    scene.backgroundcolor = data.backgroundcolor;
    scene.clearscene = data.clearscene;

    const cam = {
        view: new THREE.Uniform(new THREE.Matrix4()),
        projection: new THREE.Uniform(new THREE.Matrix4()),
        projectionview: new THREE.Uniform(new THREE.Matrix4()),
        pixel_space: new THREE.Uniform(new THREE.Matrix4()),
        resolution: new THREE.Uniform(new THREE.Vector2()),
        eyeposition: new THREE.Uniform(new THREE.Vector3()),
        cam_uniform: data.camera,
    };

    scene.wgl_camera = cam;

    function update_cam(camera) {
        const [
            view,
            projection,
            projectionview,
            resolution,
            eyepos,
            pixel_space,
        ] = camera;
        const resolution_scaled = resolution;
        cam.view.value.fromArray(view);
        cam.projection.value.fromArray(projection);
        cam.projectionview.value.fromArray(projectionview);
        cam.pixel_space.value.fromArray(pixel_space);
        cam.resolution.value.fromArray(resolution_scaled);
        cam.eyeposition.value.fromArray(eyepos);
    }

    update_cam(data.camera.value);

    if (data.cam3d_state) {
        attach_3d_camera(canvas, cam, data.cam3d_state);
    } else {
        data.camera.on(update_cam);
    }
    data.plots.forEach((plot_data) => {
        add_plot(scene, plot_data);
    });
    return scene;
}

function connect_uniforms(mesh, updater) {
    updater.on(([name, data]) => {
        // this is the initial value, which shouldn't end up getting updated -
        // TODO, figure out why this gets pushed!!
        if (name === "none") {
            return;
        }
        const uniform = mesh.material.uniforms[name];
        const deserialized = deserialize_three(data);

        if (uniform.value.isTexture) {
            const im_data = uniform.value.image;
            const [size, tex_data] = deserialized;
            if (tex_data.length == im_data.data.length) {
                im_data.data.set(tex_data);
            } else {
                const old_texture = uniform.value;
                uniform.value = re_create_texture(old_texture, tex_data, size);
                old_texture.dispose();
            }
            uniform.value.needsUpdate = true;
        } else {
            uniform.value = deserialized;
        }
    });
}

function first(x) {
    return x[Object.keys(x)[0]];
}

function connect_attributes(mesh, updater) {
    const instance_buffers = {};
    const geometry_buffers = {};
    let first_instance_buffer;
    const real_instance_length = [0];
    let first_geometry_buffer;
    const real_geometry_length = [0];

    function re_assign_buffers() {
        const attributes = mesh.geometry.attributes;
        Object.keys(attributes).forEach((name) => {
            const buffer = attributes[name];
            if (buffer.isInstancedBufferAttribute) {
                instance_buffers[name] = buffer;
            } else {
                geometry_buffers[name] = buffer;
            }
        });
        first_instance_buffer = first(instance_buffers);
        // not all meshes have instances!
        if (first_instance_buffer) {
            real_instance_length[0] = first_instance_buffer.count;
        }
        first_geometry_buffer = first(geometry_buffers);
        real_geometry_length[0] = first_geometry_buffer.count;
    }

    re_assign_buffers();

    updater.on(([name, new_values, length]) => {
        if (length > 0) {
            const buffer = mesh.geometry.attributes[name];
            let buffers;
            let first_buffer;
            let real_length;
            let is_instance = false;
            // First, we need to figure out if this is an instance / geometry buffer
            if (name in instance_buffers) {
                buffers = instance_buffers;
                first_buffer = first_instance_buffer;
                real_length = real_instance_length;
                is_instance = true;
            } else {
                buffers = geometry_buffers;
                first_buffer = first_geometry_buffer;
                real_length = real_geometry_length;
            }
            if (length <= real_length[0]) {
                // this is simple - we can just update the values
                buffer.set(new_values);
                buffer.needsUpdate = true;
                if (is_instance) {
                    mesh.geometry.instanceCount = length;
                }
            } else {
                // resizing is a bit more complex
                // first we directly overwrite the array - this
                // won't have any effect, but like this we can collect the
                // newly sized arrays untill all of them have the same length
                buffer.to_update = new_values;
                if (
                    Object.values(buffers).every(
                        (x) =>
                            x.to_update &&
                            x.to_update.length / x.itemSize == length
                    )
                ) {
                    if (is_instance) {
                        recreate_instanced_geometry(mesh);
                        // we just replaced geometry & all buffers, so we need to update thise
                        re_assign_buffers();
                        mesh.geometry.instanceCount =
                            new_values.length / buffer.itemSize;
                    }
                }
            }
        }
    });
}

export function render_scene(scene) {
    const { camera, renderer } = scene.screen;
    const canvas = renderer.domElement;
    if (!document.body.contains(canvas)) {
        console.log("EXITING WGL");
        renderer.state.reset();
        renderer.dispose();
        return false;
    }
    renderer.autoClear = scene.clearscene;
    const area = scene.pixelarea.value;
    if (area) {
        const [x, y, w, h] = area.map((t) => t / pixelRatio);
        renderer.setViewport(x, y, w, h);
        renderer.setScissor(x, y, w, h);
        renderer.setScissorTest(true);
        renderer.setClearColor(scene.backgroundcolor.value);
        renderer.render(scene, camera);
    }
    return true;
}

function start_renderloop(three_scenes) {
    if (three_scenes.length == 0) {
        return;
    }
    // extract the first scene for screen, which should be shared by all scenes!
    const scene1 = three_scenes[0];
    const { fps } = scene1.screen;
    const time_per_frame = (1 / fps) * 1000; // default is 30 fps
    // make sure we immediately render the first frame and dont wait 30ms
    let last_time_stamp = performance.now();
    function renderloop(timestamp) {
        if (timestamp - last_time_stamp > time_per_frame) {
            const all_rendered = three_scenes.every(render_scene);
            if (!all_rendered) {
                // if scenes don't render it means they're not displayed anymore
                // - time to quit the renderin' business
                return;
            }
            last_time_stamp = performance.now();
        }
        window.requestAnimationFrame(renderloop);
    }
    // render one time before starting loop, so that we don't wait 30ms before first render
    three_scenes.forEach(render_scene);
    renderloop();
}

// from: https://www.geeksforgeeks.org/javascript-throttling/
function throttle_function(func, delay) {
    // Previously called time of the function
    let prev = 0;
    return (...args) => {
        // Current called time of the function
        const now = new Date().getTime();
        // If difference is greater than delay call
        // the function again.
        if (now - prev > delay) {
            prev = now;
            // "..." is the spread operator here
            // returning the function with the
            // array of arguments
            return func(...args);
        }
    };
}

function threejs_module(canvas, comm, width, height) {
    let context = canvas.getContext("webgl2", {
        preserveDrawingBuffer: true,
    });
    if (!context) {
        console.warn(
            "WebGL 2.0 not supported by browser, falling back to WebGL 1.0 (Volume plots will not work)"
        );
        context = canvas.getContext("webgl", {
            preserveDrawingBuffer: true,
        });
    }
    if (!context) {
        // Sigh, safari or something
        // we return nothing which will be handled by caller
        return;
    }
    const renderer = new THREE.WebGLRenderer({
        antialias: true,
        canvas: canvas,
        context: context,
        powerPreference: "high-performance",
    });

    renderer.setClearColor("#ffffff");

    // The following handles high-DPI devices
    // `renderer.setSize` also updates `canvas` size
    renderer.setPixelRatio(pixelRatio);
    renderer.setSize(width / pixelRatio, height / pixelRatio);

    const mouse_callback = (x, y) => comm.notify({ mouseposition: [x, y] });
    const notify_mouse_throttled = throttle_function(mouse_callback, 40);

    function mousemove(event) {
        var rect = canvas.getBoundingClientRect();
        var x = (event.clientX - rect.left) * pixelRatio;
        var y = (event.clientY - rect.top) * pixelRatio;

        notify_mouse_throttled(x, y);
        return false;
    }

    canvas.addEventListener("mousemove", mousemove);

    function mousedown(event) {
        comm.notify({
            mousedown: event.buttons,
        });
        return false;
    }
    canvas.addEventListener("mousedown", mousedown);

    function mouseup(event) {
        comm.notify({
            mouseup: event.buttons,
        });
        return false;
    }

    canvas.addEventListener("mouseup", mouseup);

    function wheel(event) {
        comm.notify({
            scroll: [event.deltaX, -event.deltaY],
        });
        event.preventDefault();
        return false;
    }
    canvas.addEventListener("wheel", wheel);

    function keydown(event) {
        comm.notify({
            keydown: event.code,
        });
        return false;
    }

    canvas.addEventListener("keydown", keydown);

    function keyup(event) {
        comm.notify({
            keyup: event.code,
        });
        return false;
    }

    canvas.addEventListener("keyup", keyup);
    // This is a pretty ugly work around......
    // so on keydown, we add the key to the currently pressed keys set
    // if we open the contextmenu before releasing the key, we'll never
    // receive an up event, so the key will stay inside the currently_pressed
    // set... Only option I found is to actually listen to the contextmenu
    // and remove all keys if its opened.
    function contextmenu(event) {
        comm.notify({
            keyup: "delete_keys",
        });
        return false;
    }

    canvas.addEventListener("contextmenu", (e) => e.preventDefault());
    canvas.addEventListener("focusout", contextmenu);

    return renderer;
}

function create_scene(
    wrapper,
    canvas,
    canvas_width,
    scenes,
    comm,
    width,
    height,
    fps,
    texture_atlas_obs
) {
    const renderer = threejs_module(canvas, comm, width, height);
    TEXTURE_ATLAS[0] = texture_atlas_obs;

    if (renderer) {
        const camera = new THREE.PerspectiveCamera(45, 1, 0, 100);
        camera.updateProjectionMatrix();
        const size = new THREE.Vector2();
        renderer.getDrawingBufferSize(size);
        const picking_target = new THREE.WebGLRenderTarget(size.x, size.y);
        const screen = { renderer, picking_target, camera, fps };

        const three_scenes = scenes.map((x) => {
            const three_scene = deserialize_scene(x, canvas);
            three_scene.screen = screen;
            return three_scene;
        });

        start_renderloop(three_scenes);

        canvas_width.on((w_h) => {
            // `renderer.setSize` correctly updates `canvas` dimensions
            const pixelRatio = renderer.getPixelRatio();
            renderer.setSize(w_h[0] / pixelRatio, w_h[1] / pixelRatio);
        });
    } else {
        const warning = getWebGLErrorMessage();
        // wrapper.removeChild(canvas)
        wrapper.appendChild(warning);
    }
}

export function event2scene_pixel(scene, event) {
    const canvas = scene.screen.renderer.domElement;
    const rect = canvas.getBoundingClientRect();
    const pixelRatio = window.devicePixelRatio || 1.0;
    const x = (event.clientX - rect.left) * pixelRatio;
    const y = (rect.height - (event.clientY - rect.top)) * pixelRatio;
    return [x, y];
}

function set_picking_uniforms(scene, last_id, picking, picked_plots, plots) {
    scene.children.forEach((plot, index) => {
        const { material } = plot;
        const { uniforms } = material;
        if (picking) {
            uniforms.object_id.value = last_id + index;
            uniforms.picking.value = true;
            material.blending = THREE.NoBlending;
        } else {
            // clean up after picking
            uniforms.picking.value = false;
            material.blending = THREE.NormalBlending;
            // we also collect the picked/matched plots as part of the clean up
            const id = uniforms.object_id.value;
            if (id in picked_plots) {
                plots.push([plot, picked_plots[id]]);
            }
        }
    });
    return last_id + scene.children.length;
}

export function pick_native(scenes, x, y, w, h) {
    const { renderer, camera, picking_target } = scenes[0].screen;
    // render the scene
    renderer.setRenderTarget(picking_target);

    const pixelRatio = window.devicePixelRatio || 1.0;

    let last_id = 1;
    scenes.forEach((scene) => {
        last_id = set_picking_uniforms(scene, last_id, true);

        const area = JSServe.get_observable(scene.pixelarea);
        const [_x, _y, _w, _h] = area.map((t) => t / pixelRatio);
        renderer.autoClear = true;
        renderer.setViewport(_x, _y, _w, _h);
        renderer.setScissor(_x, _y, _w, _h);
        renderer.setScissorTest(true);
        renderer.setClearAlpha(0);
        renderer.setClearColor(new THREE.Color(0), 0.0);
        renderer.render(scene, camera);
    });

    renderer.setRenderTarget(null); // reset render target

    const nbytes = w * h * 4;
    const pixel_bytes = new Uint8Array(nbytes);

    //read the pixel
    renderer.readRenderTargetPixels(
        picking_target,
        x, // x
        y, // y
        w, // width
        h, // height
        pixel_bytes
    );

    const picked_plots = {};
    const reinterpret_view = new DataView(pixel_bytes.buffer);

    for (let i = 0; i < pixel_bytes.length / 4; i++) {
        const id = reinterpret_view.getUint16(i * 4);
        const index = reinterpret_view.getUint16(i * 4 + 2);
        picked_plots[id] = index;
    }
    // dict of plot_uuid => primitive_index (e.g. instance id or triangle index)
    const plots = [];
    scenes.forEach((scene) =>
        set_picking_uniforms(scene, 0, false, picked_plots, plots)
    );
    return plots;
}

export function pick_native_uuid(scenes, x, y, w, h) {
    const picked_plots = pick_native(scenes, x, y, w, h);
    return picked_plots.map((x) => [x[0].uuid, x[1]]);
}

export {
    deserialize_scene,
    threejs_module,
    start_renderloop,
    deserialize_three,
    delete_plots,
    insert_plot,
    find_plots,
    delete_scene,
    find_scene,
    scene_cache,
    plot_cache,
    delete_scenes,
    create_scene,
};
