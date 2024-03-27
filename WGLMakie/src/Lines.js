import {
    attributes_to_type_declaration,
    uniforms_to_type_declaration,
    uniform_type,
    attribute_type,
} from "./Shaders.js";

import { deserialize_uniforms } from "./Serialization.js";

function filter_by_key(dict, keys, default_value = false) {
    const result = {};
    keys.forEach((key) => {
        const val = dict[key];
        if (val) {
            result[key] = val;
        } else {
            result[key] = default_value;
        }
    });
    return result;
}

// https://github.com/glslify/glsl-aastep
// https://wwwtyro.net/2019/11/18/instanced-lines.html
// https://github.com/mrdoob/three.js/blob/dev/examples/jsm/lines/LineMaterial.js
// https://www.khronos.org/assets/uploads/developers/presentations/Crazy_Panda_How_to_draw_lines_in_WebGL.pdf
// https://github.com/gameofbombs/pixi-candles/tree/master/src
// https://github.com/wwwtyro/instanced-lines-demos/tree/master
function linesegments_vertex_shader(uniforms, attributes) {
    const attribute_decl = attributes_to_type_declaration(attributes);
    const uniform_decl = uniforms_to_type_declaration(uniforms);
    const color =
        attribute_type(attributes.color_start) ||
        uniform_type(uniforms.color_start);

    return `precision mediump int;
        precision highp float;

        ${attribute_decl}
        ${uniform_decl}
        uniform int is_segments_multi;

        out vec2 f_uv;
        out ${color} f_color;
        flat out uint frag_instance_id;

        vec2 get_resolution() {
            // 2 * px_per_unit doesn't make any sense, but works
            // TODO, figure out what's going on!
            return resolution / 2.0 * px_per_unit;
        }

        vec3 screen_space(vec3 point) {
            vec4 vertex = projectionview * model * vec4(point, 1);
            return vec3(vertex.xy * get_resolution(), vertex.z + vertex.w * depth_shift) / vertex.w;
        }

        vec3 screen_space(vec2 point) {
            return screen_space(vec3(point, 0));
        }

        void main() {
            vec3 p_a = screen_space(linepoint_start);
            vec3 p_b = screen_space(linepoint_end);
            float width = (px_per_unit * (position.x == 1.0 ? linewidth_end : linewidth_start));
            f_color = position.x == 1.0 ? color_end : color_start;
            f_uv = vec2(position.x, position.y + 0.5);

            vec2 pointA = p_a.xy;
            vec2 pointB = p_b.xy;

            vec2 xBasis = pointB - pointA;
            vec2 yBasis = normalize(vec2(-xBasis.y, xBasis.x));
            vec2 point = pointA + xBasis * position.x + yBasis * width * position.y;

            gl_Position = vec4(point.xy / get_resolution(), position.x == 1.0 ? p_b.z : p_a.z, 1.0);
            frag_instance_id = uint((gl_InstanceID * is_segments_multi) + int(position.x == 1.0));
        }
        `;
}

function lines_fragment_shader(uniforms, attributes) {
    const color =
        attribute_type(attributes.color_start) ||
        uniform_type(uniforms.color_start);
    const color_uniforms = filter_by_key(uniforms, [
        "colorrange",
        "colormap",
        "nan_color",
        "highclip",
        "lowclip",
        "picking",
    ]);
    const uniform_decl = uniforms_to_type_declaration(color_uniforms);

    return `#extension GL_OES_standard_derivatives : enable

    precision mediump int;
    precision highp float;
    precision mediump sampler2D;
    precision mediump sampler3D;

    in vec2 f_uv;
    in ${color} f_color;
    ${uniform_decl}

    out vec4 fragment_color;

    // Half width of antialiasing smoothstep
    #define ANTIALIAS_RADIUS 0.7071067811865476

    vec4 get_color_from_cmap(float value, sampler2D colormap, vec2 colorrange) {
        float cmin = colorrange.x;
        float cmax = colorrange.y;
        if (value <= cmax && value >= cmin) {
            // in value range, continue!
        } else if (value < cmin) {
            return lowclip;
        } else if (value > cmax) {
            return highclip;
        } else {
            // isnan CAN be broken (of course) -.-
            // so if outside value range and not smaller/bigger min/max we assume NaN
            return nan_color;
        }
        float i01 = clamp((value - cmin) / (cmax - cmin), 0.0, 1.0);
        // 1/0 corresponds to the corner of the colormap, so to properly interpolate
        // between the colors, we need to scale it, so that the ends are at 1 - (stepsize/2) and 0+(stepsize/2).
        float stepsize = 1.0 / float(textureSize(colormap, 0));
        i01 = (1.0 - stepsize) * i01 + 0.5 * stepsize;
        return texture(colormap, vec2(i01, 0.0));
    }

    vec4 get_color(float color, sampler2D colormap, vec2 colorrange) {
        return get_color_from_cmap(color, colormap, colorrange);
    }

    vec4 get_color(vec4 color, bool colormap, bool colorrange) {
        return color;
    }
    vec4 get_color(vec3 color, bool colormap, bool colorrange) {
        return vec4(color, 1.0);
    }

    float aastep(float threshold, float value) {
        float afwidth = length(vec2(dFdx(value), dFdy(value))) * ANTIALIAS_RADIUS;
        return smoothstep(threshold-afwidth, threshold+afwidth, value);
    }

    float aastep(float threshold1, float threshold2, float dist) {
        return aastep(threshold1, dist) * aastep(threshold2, 1.0 - dist);
    }

    flat in uint frag_instance_id;
    uniform uint object_id;

    vec4 pack_int(uint id, uint index) {
        vec4 unpack;
        unpack.x = float((id & uint(0xff00)) >> 8) / 255.0;
        unpack.y = float((id & uint(0x00ff)) >> 0) / 255.0;
        unpack.z = float((index & uint(0xff00)) >> 8) / 255.0;
        unpack.w = float((index & uint(0x00ff)) >> 0) / 255.0;
        return unpack;
    }
    void main(){

        float xalpha = aastep(0.0, 0.0, f_uv.x);
        float yalpha = aastep(0.0, 0.0, f_uv.y);
        vec4 color = get_color(f_color, colormap, colorrange);
        if (picking) {
            if (color.a > 0.1) {
                fragment_color = pack_int(object_id, frag_instance_id);
            }
            return;
        }
        fragment_color = vec4(color.rgb, color.a);
    }
    `;
}

function create_line_material(scene, uniforms, attributes) {
    const uniforms_des = deserialize_uniforms(scene, uniforms);
    const mat = new THREE.RawShaderMaterial({
        uniforms: uniforms_des,
        glslVersion: THREE.GLSL3,
        vertexShader: linesegments_vertex_shader(uniforms_des, attributes),
        fragmentShader: lines_fragment_shader(uniforms_des, attributes),
        transparent: true,
    });
    mat.uniforms.object_id = { value: 1 };
    return mat;
}

function attach_interleaved_line_buffer(attr_name, geometry, points, ndim, is_segments) {
    const skip_elems = is_segments ? 2 * ndim : ndim;
    const buffer = new THREE.InstancedInterleavedBuffer(points, skip_elems, 1);
    geometry.setAttribute(
        attr_name + "_start",
        new THREE.InterleavedBufferAttribute(buffer, ndim, 0)
    ); // xyz1
    geometry.setAttribute(
        attr_name + "_end",
        new THREE.InterleavedBufferAttribute(buffer, ndim, ndim)
    ); // xyz1
    return buffer;
}

function create_line_instance_geometry() {
    const geometry = new THREE.InstancedBufferGeometry();
    const instance_positions = [
        0, -0.5, 1, -0.5, 1, 0.5,

        0, -0.5, 1, 0.5, 0, 0.5,
    ];
    geometry.setAttribute(
        "position",
        new THREE.Float32BufferAttribute(instance_positions, 2)
    );
    geometry.boundingSphere = new THREE.Sphere();
    // don't use intersection / culling
    geometry.boundingSphere.radius = 10000000000000;
    geometry.frustumCulled = false;
    return geometry;
}

function create_line_buffer(geometry, buffers, name, attr, is_segments) {
    const flat_buffer = attr.value.flat;
    const ndims = attr.value.type_length;
    const linebuffer = attach_interleaved_line_buffer(
        name,
        geometry,
        flat_buffer,
        ndims,
        is_segments
    );
    buffers[name] = linebuffer;
    return flat_buffer;
}

function create_line_buffers(geometry, buffers, attributes, is_segments) {
    for (let name in attributes) {
        const attr = attributes[name];
        create_line_buffer(geometry, buffers, name, attr, is_segments);
    }
}

function attach_updates(mesh, buffers, attributes, is_segments) {
    let geometry = mesh.geometry;
    for (let name in attributes) {
        const attr = attributes[name];
        attr.on((new_points) => {
            let buff = buffers[name];
            const ndims = new_points.type_length;
            const new_line_points = new_points.flat;
            const old_count = buff.array.length;
            const new_count = new_line_points.length / ndims;
            if (old_count < new_line_points.length) {
                mesh.geometry.dispose();
                geometry = create_line_instance_geometry();
                buff = attach_interleaved_line_buffer(
                    name,
                    geometry,
                    new_line_points,
                    ndims,
                    is_segments
                );
                mesh.geometry = geometry;
                buffers[name] = buff;
            } else {
                buff.set(new_line_points);
            }
            const ls_factor = is_segments ? 2 : 1;
            const offset = is_segments ? 0 : 1;
            mesh.geometry.instanceCount = Math.max(0, (new_count / ls_factor) - offset);
            buff.needsUpdate = true;
            mesh.needsUpdate = true;
        });
    }
}

export function _create_line(scene, line_data, is_segments) {
    const geometry = create_line_instance_geometry();
    const buffers = {};
    create_line_buffers(
        geometry,
        buffers,
        line_data.attributes,
        is_segments
    );
    const material = create_line_material(
        scene,
        line_data.uniforms,
        geometry.attributes
    );

    material.uniforms.is_segments_multi = {value: is_segments ? 2 : 1};
    const mesh = new THREE.Mesh(geometry, material);
    const offset = is_segments ? 0 : 1;
    const new_count = geometry.attributes.linepoint_start.count;
    mesh.geometry.instanceCount = Math.max(0, new_count - offset);
    attach_updates(mesh, buffers, line_data.attributes, is_segments);
    return mesh;
}

export function create_line(scene, line_data) {
    return _create_line(scene, line_data, false)
}

export function create_linesegments(scene, line_data) {
    return _create_line(scene, line_data, true)
}
