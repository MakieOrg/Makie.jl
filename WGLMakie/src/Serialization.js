import * as THREE from "./THREE.js";
import * as Camera from "./Camera.js";
import { create_line, create_linesegments } from "./Lines.js";

// global scene cache to look them up for dynamic operations in Makie
// e.g. insert!(scene, plot) / delete!(scene, plot)
const scene_cache = {};
const plot_cache = {};
const TEXTURE_ATLAS = [undefined];

function add_scene(scene_id, three_scene) {
    scene_cache[scene_id] = three_scene;
}

export function find_scene(scene_id) {
    return scene_cache[scene_id];
}

export function delete_scene(scene_id) {
    const scene = scene_cache[scene_id];
    if (!scene) {
        return;
    }
    delete_three_scene(scene);
    while (scene.children.length > 0) {
        scene.remove(scene.children[0]);
    }
    delete scene_cache[scene_id];
}

export function find_plots(plot_uuids) {
    const plots = [];
    plot_uuids.forEach((id) => {
        const plot = plot_cache[id];
        if (plot) {
            plots.push(plot);
        }
    });
    return plots;
}

export function delete_scenes(scene_uuids, plot_uuids) {
    plot_uuids.forEach((plot_id) => {
        const plot = plot_cache[plot_id];
        if (plot) {
            delete_plot(plot);
        }
    });
    scene_uuids.forEach((scene_id) => {
        delete_scene(scene_id);
    });
}

export function insert_plot(scene_id, plot_data) {
    const scene = find_scene(scene_id);
    plot_data.forEach((plot) => {
        add_plot(scene, plot);
    });
}

export function delete_plots(plot_uuids) {
    const plots = find_plots(plot_uuids);
    plots.forEach(delete_plot);
}

function convert_texture(scene, data) {
    const tex = create_texture(scene, data);
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

function is_three_fixed_array(value) {
    return (
        value instanceof THREE.Vector2 ||
        value instanceof THREE.Vector3 ||
        value instanceof THREE.Vector4 ||
        value instanceof THREE.Matrix4
    );
}

function to_uniform(scene, data) {
    if (data.type !== undefined) {
        if (data.type == "Sampler") {
            return convert_texture(scene, data);
        }
        throw new Error(`Type ${data.type} not known`);
    }
    if (Array.isArray(data) || ArrayBuffer.isView(data)) {
        if (!data.every((x) => typeof x === "number")) {
            // if not all numbers, we just leave it
            return data;
        }
        // else, we convert it to THREE vector/matrix types
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
    }
    // else, leave unchanged
    return data;
}

export function deserialize_uniforms(scene, data) {
    const result = {};
    // Deno may change constructor names..so...

    for (const name in data) {
        const value = data[name];
        // this is already a uniform - happens when we attach additional
        // uniforms like the camera matrices in a later stage!
        if (value instanceof THREE.Uniform) {
            // nothing needs to be converted
            result[name] = value;
        } else {
            const ser = to_uniform(scene, value);
            result[name] = new THREE.Uniform(ser);
        }
    }
    return result;
}

export function deserialize_plot(scene, data) {
    let mesh;
    const update_visible = (v) => {
        mesh.visible = v;
        // don't return anything, since that will disable on_update callback
        return;
    };
    if (data.plot_type === "lines") {
        mesh = create_line(scene, data);
    } else if (data.plot_type === "linesegments") {
        mesh = create_linesegments(scene, data);
    } else if ("instance_attributes" in data) {
        mesh = create_instanced_mesh(scene, data);
    } else {
        mesh = create_mesh(scene, data);
    }
    mesh.name = data.name;
    mesh.frustumCulled = false;
    mesh.matrixAutoUpdate = false;
    mesh.plot_uuid = data.uuid;
    update_visible(data.visible.value);
    data.visible.on(update_visible);
    connect_uniforms(mesh, data.uniform_updater);
    if (!(data.plot_type === "lines" || data.plot_type === "linesegments")) {
        connect_attributes(mesh, data.attribute_updater);
    }
    return mesh;
}

const ON_NEXT_INSERT = new Set();

export function on_next_insert(f) {
    ON_NEXT_INSERT.add(f);
}

export function add_plot(scene, plot_data) {
    // fill in the camera uniforms, that we don't sent in serialization per plot
    const cam = scene.wgl_camera;
    const identity = new THREE.Uniform(new THREE.Matrix4());
    if (plot_data.cam_space == "data") {
        plot_data.uniforms.view = cam.view;
        plot_data.uniforms.projection = cam.projection;
        plot_data.uniforms.projectionview = cam.projectionview;
        plot_data.uniforms.eyeposition = cam.eyeposition;
    } else if (plot_data.cam_space == "pixel") {
        plot_data.uniforms.view = identity;
        plot_data.uniforms.projection = cam.pixel_space;
        plot_data.uniforms.projectionview = cam.pixel_space;
    } else if (plot_data.cam_space == "relative") {
        plot_data.uniforms.view = identity;
        plot_data.uniforms.projection = cam.relative_space;
        plot_data.uniforms.projectionview = cam.relative_space;
    } else {
        // clip space
        plot_data.uniforms.view = identity;
        plot_data.uniforms.projection = identity;
        plot_data.uniforms.projectionview = identity;
    }
    const { px_per_unit } = scene.screen;
    plot_data.uniforms.resolution = cam.resolution;
    plot_data.uniforms.px_per_unit = new THREE.Uniform(px_per_unit);

    if (plot_data.uniforms.preprojection) {
        const { space, markerspace } = plot_data;
        plot_data.uniforms.preprojection = cam.preprojection_matrix(
            space.value,
            markerspace.value
        );
    }

    if (scene.camera_relative_light) {
        plot_data.uniforms.light_direction = cam.light_direction;
        scene.light_direction.on((value) => {
            cam.update_light_dir(value);
        });
    } else {
        // TODO how update?
        const light_dir = new THREE.Vector3().fromArray(
            scene.light_direction.value
        );
        plot_data.uniforms.light_direction = new THREE.Uniform(light_dir);
        scene.light_direction.on((value) => {
            plot_data.uniforms.light_direction.value.fromArray(value);
        });
    }

    const p = deserialize_plot(scene, plot_data);
    plot_cache[p.plot_uuid] = p;
    scene.add(p);
    // execute all next insert callbacks
    const next_insert = new Set(ON_NEXT_INSERT); // copy
    next_insert.forEach((f) => f());
}

function connect_uniforms(mesh, updater) {
    updater.on(([name, data]) => {
        // this is the initial value, which shouldn't end up getting updated -
        // TODO, figure out why this gets pushed!!
        if (name === "none") {
            return;
        }
        const uniform = mesh.material.uniforms[name];
        if (uniform.value.isTexture) {
            const im_data = uniform.value.image;
            const [size, tex_data] = data;
            if (tex_data.length == im_data.data.length) {
                im_data.data.set(tex_data);
            } else {
                const old_texture = uniform.value;
                uniform.value = re_create_texture(old_texture, tex_data, size);
                old_texture.dispose();
            }
            uniform.value.needsUpdate = true;
        } else {
            if (is_three_fixed_array(uniform.value)) {
                uniform.value.fromArray(data);
            } else {
                uniform.value = data;
            }
        }
    });
}

function convert_RGB_to_RGBA(rgbArray) {
    const length = rgbArray.length;
    const rgbaArray = new Float32Array((length / 3) * 4);

    for (let i = 0, j = 0; i < length; i += 3, j += 4) {
        rgbaArray[j] = rgbArray[i]; // R
        rgbaArray[j + 1] = rgbArray[i + 1]; // G
        rgbaArray[j + 2] = rgbArray[i + 2]; // B
        rgbaArray[j + 3] = 1.0; // A
    }

    return rgbaArray;
}

function create_texture_from_data(data) {
    let buffer = data.data;
    if (data.size.length == 3) {
        const tex = new THREE.Data3DTexture(
            buffer,
            data.size[0],
            data.size[1],
            data.size[2]
        );
        tex.format = THREE[data.three_format];
        tex.type = THREE[data.three_type];
        return tex;
    } else {
        let format = THREE[data.three_format];
        if (data.three_format == "RGBFormat") {
            buffer = convert_RGB_to_RGBA(buffer);
            format = THREE.RGBAFormat;
        }
        return new THREE.DataTexture(
            buffer,
            data.size[0],
            data.size[1],
            format,
            THREE[data.three_type]
        );
    }
}

function create_texture(scene, data) {
    const buffer = data.data;
    // we allow to have a global texture atlas which gets only uploaded once to the browser
    // it's not the nicest way, but by setting buffer to "texture_atlas" on the julia side
    // instead of actual data, we just get the texture atlas from the global.
    // Special care has to be taken to deregister the callback when the context gets destroyed
    // Since TEXTURE_ATLAS uses "Bonito.Retain" and will live for the whole browser session.
    if (buffer == "texture_atlas") {
        const {texture_atlas} = scene.screen
        if (texture_atlas) {
            return texture_atlas;
        } else {
            data.data = TEXTURE_ATLAS[0].value
            const texture = create_texture_from_data(data);
            scene.screen.texture_atlas = texture;
            TEXTURE_ATLAS[0].on((new_data) => {
                if (new_data === texture) {
                    // if the data is our texture, it means the WGL context got destroyed and we want to deregister
                    // TODO, better Observables.js API for this
                    return false; // deregisters the callback
                } else {
                    texture.image.data.set(new_data);
                    texture.needsUpdate = true;
                    return
                }
            });
            return texture;
        }
    } else {
        return create_texture_from_data(data);
    }
}

function re_create_texture(old_texture, buffer, size) {
    let tex;
    if (size.length == 3) {
        tex = new THREE.Data3DTexture(buffer, size[0], size[1], size[2]);
        tex.format = old_texture.format;
        tex.type = old_texture.type;
    } else {
        tex = new THREE.DataTexture(
            buffer,
            size[0],
            size[1] ? size[1] : 1,
            old_texture.format,
            old_texture.type
        );
    }
    tex.minFilter = old_texture.minFilter;
    tex.magFilter = old_texture.magFilter;
    tex.anisotropy = old_texture.anisotropy;
    tex.wrapS = old_texture.wrapS;
    if (size.length > 1) {
        tex.wrapT = old_texture.wrapT;
    }
    if (size.length > 2) {
        tex.wrapR = old_texture.wrapR;
    }
    return tex;
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
        const buff = vertexarrays[name];
        let buffer;
        if (buff.to_update) {
            buffer = new THREE.BufferAttribute(buff.to_update, buff.itemSize);
        } else {
            buffer = BufferAttribute(buff);
        }
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

function recreate_geometry(mesh, vertexarrays, faces) {
    const buffer_geometry = new THREE.BufferGeometry();
    attach_geometry(buffer_geometry, vertexarrays, faces);
    mesh.geometry.dispose();
    mesh.geometry = buffer_geometry;
    mesh.needsUpdate = true;
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

function create_material(scene, program) {
    const is_volume = "volumedata" in program.uniforms;
    return new THREE.RawShaderMaterial({
        uniforms: deserialize_uniforms(scene, program.uniforms),
        vertexShader: program.vertex_source,
        fragmentShader: program.fragment_source,
        side: is_volume ? THREE.BackSide : THREE.DoubleSide,
        transparent: true,
        glslVersion: THREE.GLSL3,
        depthTest: !program.overdraw.value,
        depthWrite: !program.transparency.value,
    });
}

function create_mesh(scene, program) {
    const buffer_geometry = new THREE.BufferGeometry();
    const faces = new THREE.BufferAttribute(program.faces.value, 1);
    attach_geometry(buffer_geometry, program.vertexarrays, faces);
    const material = create_material(scene, program);
    const mesh = new THREE.Mesh(buffer_geometry, material);
    program.faces.on((x) => {
        mesh.geometry.setIndex(new THREE.BufferAttribute(x, 1));
    });
    return mesh;
}

function create_instanced_mesh(scene, program) {
    const buffer_geometry = new THREE.InstancedBufferGeometry();
    const faces = new THREE.BufferAttribute(program.faces.value, 1);
    attach_geometry(buffer_geometry, program.vertexarrays, faces);
    attach_instanced_geometry(buffer_geometry, program.instance_attributes);
    const material = create_material(scene, program);
    const mesh = new THREE.Mesh(buffer_geometry, material);
    program.faces.on((x) => {
        mesh.geometry.setIndex(new THREE.BufferAttribute(x, 1));
    });
    return mesh;
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
            const all_have_same_length = Object.values(buffers).every(
                (x) => x.to_update && x.to_update.length / x.itemSize == length
            );
            if (all_have_same_length) {
                if (is_instance) {
                    recreate_instanced_geometry(mesh);
                    // we just replaced geometry & all buffers, so we need to update these
                    re_assign_buffers();
                    mesh.geometry.instanceCount =
                        new_values.length / buffer.itemSize;
                } else {
                    recreate_geometry(mesh, buffers, mesh.geometry.index);
                    re_assign_buffers();
                }
            }
        }
    });
}

export function deserialize_scene(data, screen) {
    const scene = new THREE.Scene();
    scene.screen = screen;
    const { canvas } = screen;
    add_scene(data.uuid, scene);
    scene.scene_uuid = data.uuid;
    scene.frustumCulled = false;
    scene.viewport = data.viewport;
    scene.backgroundcolor = data.backgroundcolor;
    scene.backgroundcolor_alpha = data.backgroundcolor_alpha;
    scene.clearscene = data.clearscene;
    scene.visible = data.visible;
    scene.camera_relative_light = data.camera_relative_light;
    scene.light_direction = data.light_direction;

    const camera = new Camera.MakieCamera();

    scene.wgl_camera = camera;

    function update_cam(camera_matrices, force) {
        if (!force) {
            // we use the threejs orbit controls, if the julia connection is gone
            // at least for 3d ... 2d is still a todo, and will stay static right now
            if (!(Bonito.can_send_to_julia && Bonito.can_send_to_julia())) {
                return;
            }
        }
        const [view, projection, resolution, eyepos] = camera_matrices;
        camera.update_matrices(view, projection, resolution, eyepos);
    }

    if (data.cam3d_state) {
        Camera.attach_3d_camera(
            canvas,
            camera,
            data.cam3d_state,
            data.light_direction,
            scene
        );
    }

    update_cam(data.camera.value, true); // force update on first call
    camera.update_light_dir(data.light_direction.value);
    data.camera.on(update_cam);

    data.plots.forEach((plot_data) => {
        add_plot(scene, plot_data);
    });
    scene.scene_children = data.children.map((child) => {
        const childscene = deserialize_scene(child, screen);
        return childscene;
    });
    return scene;
}

export function delete_plot(plot) {
    delete plot_cache[plot.plot_uuid];
    const { parent } = plot;
    if (parent) {
        parent.remove(plot);
    }
    plot.geometry.dispose();
    plot.material.dispose();
}

export function delete_three_scene(scene) {
    delete scene_cache[scene.scene_uuid];
    scene.scene_children.forEach(delete_three_scene);
    while (scene.children.length > 0) {
        delete_plot(scene.children[0]);
    }
}

export { TEXTURE_ATLAS, scene_cache, plot_cache };
