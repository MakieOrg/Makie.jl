import * as THREE from "./THREE.js";
import * as Camera from "./Camera.js";
import { create_line, create_linesegments } from "./Lines.js";


/**
 * Updates the value of a given uniform with a new value.
 *
 * @param {THREE.Uniform} uniform - The uniform to update.
 * @param {Object|Array} new_value - The new value to set for the uniform. If the uniform is a texture, this should be an array containing the size and texture data.
 */
function update_uniform(uniform, new_value) {
    if (uniform.value.isTexture) {
        const im_data = uniform.value.image;
        const [size, tex_data] = new_value;
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
            uniform.value.fromArray(new_value);
        } else {
            uniform.value = new_value;
        }
    }
}

function re_create_buffer(buffer, is_segments) {
    // interleaved buffer attribute is special, since we
    // Manually re-create the (shared) InterleavedBuffer before calling re_create_buffer
    // So we just need to create a copy
    if (buffer instanceof THREE.InterleavedBufferAttribute) {
        return new THREE.InterleavedBufferAttribute(
            buffer.data,
            buffer.itemSize,
            buffer.offset
        );
    }
    let { new_data } = buffer;

    if (!new_data) {
        // only re-create buffers with new data;
        new_data = buffer.array;
    }
    let new_buffer;
    if (buffer instanceof THREE.InstancedInterleavedBuffer) {
        // Recreate InstancedInterleavedBuffer
        new_buffer = new THREE.InstancedInterleavedBuffer(
            new_data,
            buffer.stride,
            buffer.meshPerAttribute
        );
        new_buffer.count = Math.max(
            0,
            is_segments
                ? Math.floor(new_buffer.count - 1)
                : new_buffer.count - 3
        );
    } else if (buffer instanceof THREE.InstancedBufferAttribute) {
        // Recreate InstancedBufferAttribute
        new_buffer = new THREE.InstancedBufferAttribute(
            new_data,
            buffer.itemSize,
            buffer.normalized,
            buffer.meshPerAttribute
        );
    } else if (buffer instanceof THREE.BufferAttribute) {
        // Recreate BufferAttribute (fallback for standard attributes)
        new_buffer = new THREE.BufferAttribute(
            new_data,
            buffer.itemSize,
            buffer.normalized
        );
    } else {
        throw new Error(
            "Unsupported buffer type. Must be THREE.BufferAttribute, THREE.InstancedBufferAttribute, or THREE.InstancedInterleavedBuffer."
        );
    }

    // Copy common properties from the original buffer
    if (buffer.usage) {
        new_buffer.usage = buffer.usage;
    }
    if (buffer.updateRange) {
        new_buffer.updateRange = {
            offset: buffer.updateRange.offset,
            count: buffer.updateRange.count,
        };
    }
    // now that we have created the new one we dispose of the old
    // This is done here, since this function hides if we re-use the old buffer or create a new one
    return new_buffer;
}

function re_create_geometry(geometry, is_segments) {
    let new_geometry;
    if (geometry instanceof THREE.InstancedBufferGeometry) {
        new_geometry = new THREE.InstancedBufferGeometry();
    } else {
        new_geometry = new THREE.BufferGeometry();
    }
    new_geometry.boundingSphere = new THREE.Sphere();
    // don't use intersection / culling
    new_geometry.boundingSphere.radius = 10000000000000;
    new_geometry.frustumCulled = false;

    const interleaved_attributes = new Map(); // To avoid duplicating interleaved buffers
    // Recreate all attributes of the geometry
    let instance_count = geometry.instanceCount;
    for (const [name, attribute] of Object.entries(geometry.attributes)) {
        let new_attribute;
        if (attribute.isInterleavedBufferAttribute) {
            const old_buffer = attribute.data;
            let new_buffer;
            if (!interleaved_attributes.has(old_buffer)) {
                new_buffer = re_create_buffer(old_buffer, is_segments);
                interleaved_attributes.set(old_buffer, new_buffer);
            } else {
                new_buffer = interleaved_attributes.get(old_buffer);
            }
            attribute.data = new_buffer;
            new_attribute = re_create_buffer(attribute, is_segments); // maybe needs re-recreate?
            instance_count = new_attribute.count;
        } else {
            new_attribute = re_create_buffer(attribute, is_segments);
        }
        new_geometry.setAttribute(name, new_attribute);
        if (new_attribute instanceof THREE.InstancedBufferAttribute) {
            instance_count = new_attribute.count;
        }
    }
    if (geometry.interleaved_attributes) {
        new_geometry.interleaved_attributes = {};
        Object.keys(geometry.interleaved_attributes).forEach((name) => {
            const old = geometry.interleaved_attributes[name];
            new_geometry.interleaved_attributes[name] = interleaved_attributes.get(old)
        })
    }
    if (geometry instanceof THREE.InstancedBufferGeometry) {
        geometry.instanceCount = instance_count;
    }
    if (geometry.index) {
        new_geometry.index = re_create_buffer(geometry.index, is_segments);
    }

    return new_geometry;
}

function find_interleaved_attribute(geometry, buffer) {
    for (const [name, attribute] of Object.entries(geometry.attributes)) {
        if (attribute.data === buffer) {
            return attribute;
        }
    }
    return null; // Return null if no matching attribute is found
}



class Plot {
    mesh = undefined;
    parent = undefined;
    uuid = "";
    name = "";
    is_instanced = false;
    geometry_needs_recreation = false;
    plot_data = {};
    type = "";

    constructor(scene, data) {
        this.plot_data = data;

        connect_plot(scene, this);

        this.type = data.plot_type;
        if (data.plot_type === "lines") {
            this.is_instanced = true;
            this.mesh = create_line(scene, this.plot_data);
        } else if (data.plot_type === "linesegments") {
            this.is_instanced = true;
            this.mesh = create_linesegments(scene, this.plot_data);
        } else if ("instance_attributes" in data) {
            this.is_instanced = true;
            this.mesh = create_instanced_mesh(scene, this.plot_data);
        } else {
            this.mesh = create_mesh(scene, this.plot_data);
        }

        this.name = data.name;
        this.uuid = data.uuid;
        this.mesh.plot_uuid = data.uuid;

        this.mesh.frustumCulled = false;
        this.mesh.matrixAutoUpdate = false;
        this.mesh.renderOrder = data.zvalue;

        if (data.uniform_updater) {
            data.uniform_updater.on(([name, data]) => {
                this.update_uniform(name, data);
            });
        } else if (data.updater) {
            data.updater.on((data) => {
                this.update(data);
            });
        }

        if (
            !(data.plot_type === "lines" || data.plot_type === "linesegments")
        ) {
            connect_attributes(this.mesh, data.attribute_updater);
        }
        this.parent = scene;
        // Give mesh a reference to the plot object.
        this.mesh.plot_object = this;
        this.mesh.visible = data.visible.value;
        data.visible.on((v) => {
            this.mesh.visible = v;
        });
    }
    dispose() {
        delete plot_cache[this.uuid];
        this.parent.remove(this.mesh);
        this.mesh.geometry.dispose();
        this.mesh.material.dispose();
        this.mesh = undefined;
        this.parent = undefined;
        this.uuid = "";
        this.name = "";
        this.is_instanced = false;
        this.geometry_needs_recreation = false;
        this.plot_data = {};
    }
    move_to(scene) {
        if (scene === this.parent) {
            return;
        }
        this.parent.remove(this.mesh);
        connect_plot(scene, this);
        scene.add(this.mesh);
        this.parent = scene;
        return;
    }

    update(data) {
        const { mesh } = this;
        const { geometry } = mesh;
        const { attributes, interleaved_attributes } = geometry;
        const { uniforms } = mesh.material;
        data.forEach(([key, value]) => {
            if (
                uniforms.color_start && key === "color" &&
                (this.type === "lines" || this.type === "linesegments")
            ) {
                if (uniforms.color_start) {
                    this.update_uniform(key + "_start", value);
                    this.update_uniform(key + "_end", value);
                }
                return;
            }
            if (key in uniforms) {
                this.update_uniform(key, value);
            } else if (key in attributes || (interleaved_attributes &&
                key in interleaved_attributes)) {
                this.update_buffer(key, value);
            } else if (key === "faces") {
                this.update_faces(value);
            } else if (key === "visible") {
                this.mesh.visible = value;
            } else {
                console.warn(`Unknown key ${key} in Plot: ${this.name}`);
            }
        });
        // For e.g. when we need to re-create the geometry
        this.apply_updates();
    }

    update_uniform(name, new_data) {
        const uniform = this.mesh.material.uniforms[name];
        if (!uniform) {
            throw new Error(
                `Uniform ${name} doesn't exist in Plot: ${this.name}`
            );
        }
        update_uniform(uniform, new_data);
    }

    update_buffer(name, new_data) {
        const {geometry} = this.mesh;
        let buffer = geometry.attributes[name];

        if (!buffer) {
            buffer = geometry.interleaved_attributes[name];
            if (!buffer) {
                throw new Error(
                    `Buffer ${name} doesn't exist in Plot: ${this.name}`
                );
            }
        }
        const old_length = buffer.array.length;
        const is_interleaved =  buffer instanceof THREE.InstancedInterleavedBuffer;
        const attribute = is_interleaved ? find_interleaved_attribute(geometry, buffer) : buffer;
        if (attribute == null) {
            console.log(name)
            console.log(geometry.interleaved_attributes);
            console.log(geometry.attributes);
        }
        const new_count = new_data.length / attribute.itemSize;
        if (new_data.length <= old_length) {
            buffer.set(new_data);
            buffer.count = new_count;
            const is_segments = this.type == "linesegments";
            if (this.type == "lines" || is_segments) {
                const skipped = new_count / (buffer.stride / attribute.itemSize);
                buffer.count = Math.max(
                    0,
                    is_segments ? Math.floor(skipped - 1) : skipped - 3
                );
            }
            buffer.needsUpdate = true;
        } else {
            // if we have a larger size we need resizing + recreation of the buffer geometry
            buffer.new_data = new_data;
            this.geometry_needs_recreation = true;
        }
        if (this.is_instanced) {
            this.mesh.geometry.instanceCount = attribute.count;
        }
    }

    apply_updates() {
        if (this.geometry_needs_recreation) {
            const { geometry } = this.mesh;
            const new_geometry = re_create_geometry(
                geometry,
                this.type == "linesegments"
            );
            geometry.dispose();
            this.mesh.geometry = new_geometry;
            this.mesh.needsUpdate = true;
        }
        this.geometry_needs_recreation = false;
    }

    update_faces(face_data) {
        this.mesh.geometry.setIndex(new THREE.BufferAttribute(face_data, 1));
    }
}


function recreate_instanced_geometry(mesh) {
    const {geometry} = mesh;
    const buffer_geometry = new THREE.InstancedBufferGeometry();
    if (geometry.interleaved_attributes) {
        geometry.interleaved_attributes = {};
    }
    const vertexarrays = {};
    const instance_attributes = {};
    const n_instances = geometry.instanceCount;
    const faces = [...geometry.index.array];
    Object.keys(geometry.attributes).forEach((name) => {
        const buffer = geometry.attributes[name];
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
    mesh.geometry.instanceCount = n_instances;
    mesh.needsUpdate = true;
}

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
    tex.generateMipmaps = data.mipmap;
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

const ON_NEXT_INSERT = new Set();

export function on_next_insert(f) {
    ON_NEXT_INSERT.add(f);
}

/**
 * Connects a plot to a scene by setting up the necessary camera uniforms.
 *
 * @param {THREE.Scene} scene - The scene object containing the camera and screen information.
 * @param {Plot} plot - The plot object to be connected to the scene.
 */
function connect_plot(scene, plot) {
    // fill in the camera uniforms, that we don't sent in serialization per plot
    const cam = scene.wgl_camera;
    const identity = new THREE.Uniform(new THREE.Matrix4());
    const uniforms = plot.mesh ? plot.mesh.material.uniforms : plot.plot_data.uniforms;
    const space = plot.plot_data.cam_space;
    if (space == "data") {
        uniforms.view = cam.view;
        uniforms.projection = cam.projection;
        uniforms.projectionview = cam.projectionview;
        uniforms.eyeposition = cam.eyeposition;
    } else if (space == "pixel") {
        uniforms.view = identity;
        uniforms.projection = cam.pixel_space;
        uniforms.projectionview = cam.pixel_space;
    } else if (space == "relative") {
        uniforms.view = identity;
        uniforms.projection = cam.relative_space;
        uniforms.projectionview = cam.relative_space;
    } else if (space == "clip") {
        // clip space
        uniforms.view = identity;
        uniforms.projection = identity;
        uniforms.projectionview = identity;
    } else {
        throw new Error(`Space ${space} not supported!`)
    }
    const { px_per_unit } = scene.screen;
    uniforms.resolution = cam.resolution;
    uniforms.px_per_unit = new THREE.Uniform(px_per_unit);

    if (plot.plot_data.uniforms.preprojection) {
        const { space, markerspace } = plot.plot_data;
        uniforms.preprojection = cam.preprojection_matrix(
            space.value,
            markerspace.value
        );
    }

    uniforms.light_direction = scene.light_direction;
}


export function add_plot(scene, plot_data) {
    // fill in the camera uniforms, that we don't sent in serialization per plot
    const p = new Plot(scene, plot_data);
    plot_cache[p.uuid] = p.mesh;
    scene.add(p.mesh);
    // execute all next insert callbacks
    const next_insert = new Set(ON_NEXT_INSERT); // copy
    next_insert.forEach((f) => f());
}

function convert_RGB_to_RGBA(rgbArray) {
    const length = rgbArray.length;
    const rgbaArray = new rgbArray.constructor((length / 3) * 4);
    const a = (rgbArray instanceof Uint8Array) ? 255 : 1.0;

    for (let i = 0, j = 0; i < length; i += 3, j += 4) {
        rgbaArray[j] = rgbArray[i]; // R
        rgbaArray[j + 1] = rgbArray[i + 1]; // G
        rgbaArray[j + 2] = rgbArray[i + 2]; // B
        rgbaArray[j + 3] = a; // A
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

    if (data.camera_relative_light) {
        scene.light_direction = camera.light_direction;
    } else {
        const light_dir = new THREE.Vector3().fromArray(
            data.light_direction.value
        );
        scene.light_direction = new THREE.Uniform(light_dir);
        data.light_direction.on((value) => {
            plot_data.uniforms.light_direction.value.fromArray(value);
        });
    }


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
    plot.plot_object.dispose()
}

export function delete_three_scene(scene) {
    delete scene_cache[scene.scene_uuid];
    scene.scene_children.forEach(delete_three_scene);
    while (scene.children.length > 0) {
        delete_plot(scene.children[0]);
    }
}

export { TEXTURE_ATLAS, scene_cache, plot_cache };
