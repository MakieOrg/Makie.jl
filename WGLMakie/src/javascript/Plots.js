import * as THREE from "https://cdn.esm.sh/v66/three@0.173/es2021/three.js";
import { create_line, add_line_attributes } from "./Lines.js";
import {
    find_interleaved_attribute,
    re_create_geometry,
    create_mesh,
    create_instanced_mesh,
    update_uniform
} from "./ThreeHelper.js";
import { deserialize_uniforms, plot_cache } from "./Serialization.js";
import { get_texture_atlas } from "./TextureAtlas.js";




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
            space,
            markerspace
        );
    }
    uniforms.light_direction = scene.light_direction;
    uniforms.ambient = scene.ambient;
    uniforms.light_color = scene.light_color;
}


export function expand_compressed(new_data) {
    // Check if new_data is in compressed format
    if (
        new_data &&
        typeof new_data === "object" &&
        "value" in new_data &&
        "length" in new_data
    ) {
        // Expand compressed format back to full array
        const value = new_data.value;
        if (value instanceof Float32Array || Array.isArray(value)) {
            // Handle Vec3f case - value is an array/Float32Array that needs to be repeated
            const element_size = value.length;
            const total_size = new_data.length * element_size;
            const expanded_array = new Float32Array(total_size);
            for (let i = 0; i < new_data.length; i++) {
                expanded_array.set(value, i * element_size);
            }
            return expanded_array;
        } else {
            // Handle scalar case - single value repeated
            return new Float32Array(new_data.length).fill(value);
        }
    }
    return new_data; // Return as is if not compressed
}

export class Plot {
    mesh = undefined;
    parent = undefined;
    uuid = "";
    name = "";
    is_instanced = false;
    geometry_needs_recreation = false;
    plot_data = {};
    deserialized_uniforms = {};
    type = "";

    constructor(scene, data) {
        this.plot_data = data;
        connect_plot(scene, this);
        this.deserialized_uniforms = deserialize_uniforms(scene, data.uniforms);
        this.name = data.name;
        this.uuid = data.uuid;
        this.parent = scene;
        data.updater.on((data) => {
            this.update(data);
        });
    }

    init_mesh() {
        // Give mesh a reference to the plot object.
        this.mesh.plot_uuid = this.plot_data.uuid;
        this.mesh.frustumCulled = false;
        this.mesh.matrixAutoUpdate = false;
        this.mesh.renderOrder = this.plot_data.zvalue;
        this.mesh.plot_object = this;
        this.mesh.visible = this.plot_data.visible;
    }

    dispose() {
        delete plot_cache[this.uuid];
        this.parent.remove(this.mesh);
        this.mesh.geometry.dispose();
        this.mesh.material.dispose();
        this.mesh = undefined;
        this.parent = undefined;
        // this.uuid = "";
        // this.name = "";
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
        if (!mesh) {
            console.log(`Updating plot ${this.name} (${this.uuid}) with data:`);
        }
        const { geometry } = mesh;
        const { attributes, interleaved_attributes } = geometry;
        const { uniforms } = mesh.material;
        data.forEach(([key, value]) => {
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

    update_buffer(name, input_data) {
        const new_data = expand_compressed(input_data);
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
            if (this instanceof Lines) {
                const is_segments = this.is_segments === true;
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
                this.is_segments === true
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


export class Lines extends Plot {
    constructor(scene, data) {
        super(scene, data);

        if (data.plot_type !== "Lines") {
            throw new Error(
                `Lines class must be initialized with plot_type 'Lines' found ${data.plot_type}`
            );
        }
        this.is_segments = data.is_segments === true;
        this.is_instanced = true;
        // this will be filled with the ndims of the arrays in create_line (more specifically add_line_attributes)
        this.ndims = {};
        this.scene = scene;
        this.mesh = create_line(this);
        this.init_mesh();
    }

    update(data_key_value_array) {
        const dict = Object.fromEntries(data_key_value_array.map(([k, v]) => [k, expand_compressed(v)]));
        const line_attr = Object.entries(add_line_attributes(this, dict));
        super.update(line_attr);
    }
    dispose() {
        this.scene.wgl_camera.on_update.delete(this.uuid);
        super.dispose();
    }
}

export class Mesh extends Plot {
    constructor(scene, data) {
        super(scene, data);
        if ("instance_attributes" in data) {
            this.is_instanced = true;
            this.mesh = create_instanced_mesh(this);
        } else {
            this.mesh = create_mesh(this);
        }
        this.init_mesh();
    }
}


/**
 * Returns x[i] if x is an array, otherwise returns x.
 * @param {*} x - Either an array or a scalar value
 * @param {number} i - Index to access if x is an array
 * @returns {*} - The indexed value or x itself
 */
function broadcast_getindex(a, x, i) {
    if (a.length == (x.length / 2)) {
        return new THREE.Vector2(x[i * 2], x[i * 2 + 1]);
    } else if (x.length == 2) {
        return new THREE.Vector2(x[0], x[1]);
    } else {
        throw new Error(
            `broadcast_getindex: x has length ${x.length}, but a has length ${a.length}`
        );
    }
}

function per_glyph_data(glyph_hashes, scales) {
    const atlas = get_texture_atlas();
    const uv_offset_width = new Float32Array(glyph_hashes.length * 4);
    const markersize = new Float32Array(glyph_hashes.length * 2);
    const quad_offsets = new Float32Array(glyph_hashes.length * 2);
    for (let i = 0; i < glyph_hashes.length; i++) {
        const hash = glyph_hashes[i];
        const data = atlas.get_glyph_data(
            hash,
            broadcast_getindex(glyph_hashes, scales, i),
        );
        const [uv, c_width, q_offset] = data ?? [
            new THREE.Vector4(0, 0, 0, 0),
            new THREE.Vector2(0, 0),
            new THREE.Vector2(0, 0),
        ];
        uv_offset_width.set(uv.toArray(), i * 4);
        markersize.set(c_width.toArray(), i * 2);
        quad_offsets.set(q_offset.toArray(), i * 2);

    }
    return [uv_offset_width, markersize, quad_offsets];
}

function get_glyph_data_attributes(atlas, glyph_data) {
    if (glyph_data == null) {
        return {}
    }
    const { glyph_hashes, atlas_updates, scales } = glyph_data;
    atlas.insert_glyphs(atlas_updates);
    if (glyph_hashes) {
        const [sdf_uv, quad_scale, quad_offset] = per_glyph_data(
            glyph_hashes,
            scales
        );
        return { sdf_uv, quad_scale, quad_offset };
    }
    return {}
}

export class Scatter extends Plot {

    constructor(scene, data) {
        const atlas = get_texture_atlas();
        const lengths = { sdf_uv: 4 };
        if ("glyph_data" in data) {
            const gdata = get_glyph_data_attributes(atlas, data.glyph_data);
            delete data.glyph_data;
            for (const name in gdata) {
                const buff = gdata[name];
                const len = lengths[name] || 2;
                data.instance_attributes[name] = {
                    flat: buff,
                    type_length: len,
                };
            }
        }
        super(scene, data);
        this.is_instanced = true;
        this.atlas = atlas;
        this.mesh = create_instanced_mesh(this);
        this.init_mesh();
    }

    update(data_key_value_array) {
        const dict = Object.fromEntries(data_key_value_array);
        if ("glyph_data" in dict) {
            const data = get_glyph_data_attributes(this.atlas, dict.glyph_data);
            delete dict.glyph_data;
            for (const [key, value] of Object.entries(data)) {
                dict[key] = value;
            }
        }
        super.update(Object.entries(dict));
    }
}
