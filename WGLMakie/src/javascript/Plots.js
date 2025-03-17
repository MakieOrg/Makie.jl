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
        this.mesh.visible = this.plot_data.visible.value;
        this.plot_data.visible.on((v) => {
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
        this.mesh = create_line(this);
        this.init_mesh();
    }

    update(data_key_value_array) {
        const dict = Object.fromEntries(data_key_value_array);
        const line_attr = Object.entries(add_line_attributes(this, dict));
        super.update(line_attr);
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
