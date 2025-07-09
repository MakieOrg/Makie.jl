import * as THREE from "https://cdn.esm.sh/v66/three@0.173/es2021/three.js";
import { get_texture_atlas } from "./TextureAtlas.js";

function first(x) {
    return x[Object.keys(x)[0]];
}

function is_three_fixed_array(value) {
    return (
        value instanceof THREE.Vector2 ||
        value instanceof THREE.Vector3 ||
        value instanceof THREE.Vector4 ||
        value instanceof THREE.Matrix4
    );
}

export function to_three_vector(data) {
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

function typedarray_to_vectype(typedArray, ndim) {
    if (typedArray instanceof Float32Array) {
        if (ndim === 1) {
            return "float";
        } else {
            return "vec" + ndim;
        }
    } else if (typedArray instanceof Int32Array) {
        if (ndim === 1) {
            return "int";
        } else {
            return "ivec" + ndim;
        }
    } else if (typedArray instanceof Uint32Array) {
        if (ndim === 1) {
            return "uint";
        } else {
            return "uvec" + ndim;
        }
    } else {
        return;
    }
}

export function attribute_type(attribute) {
    if (attribute) {
        return typedarray_to_vectype(attribute.array, attribute.itemSize);
    } else {
        return;
    }
}

export function uniform_type(obj) {
    if (obj instanceof THREE.Uniform) {
        return uniform_type(obj.value);
    } else if (typeof obj === "number") {
        return "float";
    } else if (typeof obj === "boolean") {
        return "bool";
    } else if (obj instanceof THREE.Vector2) {
        return "vec2";
    } else if (obj instanceof THREE.Vector3) {
        return "vec3";
    } else if (obj instanceof THREE.Vector4) {
        return "vec4";
    } else if (obj instanceof THREE.Color) {
        return "vec4";
    } else if (obj instanceof THREE.Matrix3) {
        return "mat3";
    } else if (obj instanceof THREE.Matrix4) {
        return "mat4";
    } else if (obj instanceof THREE.Texture) {
        return "sampler2D";
    } else {
        return "invalid";
    }
}

export function uniforms_to_type_declaration(uniform_dict) {
    let result = "";
    for (const name in uniform_dict) {
        const uniform = uniform_dict[name];
        const type = uniform_type(uniform);
        if (type != "invalid")
            result += `uniform ${type} ${name};\n`;
    }
    return result;
}

export function attributes_to_type_declaration(attributes_dict) {
    let result = "";
    for (const name in attributes_dict) {
        const attribute = attributes_dict[name];
        const type = attribute_type(attribute);
        result += `in ${type} ${name};\n`;
    }
    return result;
}

/**
 * Updates the value of a given uniform with a new value.
 *
 * @param {THREE.Uniform} uniform - The uniform to update.
 * @param {Object|Array} new_value - The new value to set for the uniform. If the uniform is a texture, this should be an array containing the size and texture data.
 */
export function update_uniform(uniform, new_value) {
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

export function re_create_geometry(geometry, is_segments) {
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

export function find_interleaved_attribute(geometry, buffer) {
    for (const [name, attribute] of Object.entries(geometry.attributes)) {
        if (attribute.data === buffer) {

            return attribute;
        }
    }
    return null; // Return null if no matching attribute is found
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


function convert_RGB_to_RGBA(rgbArray) {
    const length = rgbArray.length;
    const rgbaArray = new rgbArray.constructor((length / 3) * 4);
    const a = rgbArray instanceof Uint8Array ? 255 : 1.0;

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

export function create_texture(scene, data) {
    const buffer = data.data;
    if (buffer === "texture_atlas") {
        const { texture_atlas, renderer } = scene.screen;
        if (!texture_atlas) {
            const atlas = get_texture_atlas();
            scene.screen.texture_atlas = atlas.get_texture(renderer);
        }
        return scene.screen.texture_atlas;
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

export function attach_geometry(buffer_geometry, vertexarrays, faces) {
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

export function attach_instanced_geometry(
    buffer_geometry,
    instance_attributes
) {
    for (const name in instance_attributes) {
        const buffer = InstanceBufferAttribute(instance_attributes[name]);
        buffer_geometry.setAttribute(name, buffer);
    }
}

export function recreate_geometry(mesh, vertexarrays, faces) {
    const buffer_geometry = new THREE.BufferGeometry();
    attach_geometry(buffer_geometry, vertexarrays, faces);
    mesh.geometry.dispose();
    mesh.geometry = buffer_geometry;
    mesh.needsUpdate = true;
}

export function create_material(plot) {
    const is_volume = "isovalue" in plot.deserialized_uniforms;
    return new THREE.RawShaderMaterial({
        uniforms: plot.deserialized_uniforms,
        vertexShader: plot.plot_data.vertex_source,
        fragmentShader: plot.plot_data.fragment_source,
        side: is_volume ? THREE.BackSide : THREE.DoubleSide,
        transparent: true,
        glslVersion: THREE.GLSL3,
        depthTest: !plot.plot_data.overdraw,
        depthWrite: !plot.plot_data.transparency,
    });
}

export function create_mesh(plot) {
    const buffer_geometry = new THREE.BufferGeometry();
    const {plot_data} = plot;
    const faces = new THREE.BufferAttribute(plot_data.faces, 1);
    attach_geometry(buffer_geometry, plot_data.vertexarrays, faces);
    const material = create_material(plot);
    const mesh = new THREE.Mesh(buffer_geometry, material);
    return mesh;
}

export function create_instanced_mesh(plot) {
    const {plot_data} = plot;
    const buffer_geometry = new THREE.InstancedBufferGeometry();
    const faces = new THREE.BufferAttribute(plot_data.faces, 1);
    attach_geometry(buffer_geometry, plot_data.vertexarrays, faces);
    attach_instanced_geometry(buffer_geometry, plot_data.instance_attributes);
    const material = create_material(plot);
    const mesh = new THREE.Mesh(buffer_geometry, material);
    return mesh;
}

export function connect_attributes(mesh, updater) {
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
