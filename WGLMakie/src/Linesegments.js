import {
    attributes_to_type_declaration,
    uniforms_to_type_declaration,
    uniform_type,
    attribute_type
} from "./Shaders.js";
import { deserialize_uniforms } from "./Serialization.js";


function filter_by_key(dict, keys, default_value=false) {
    const result = {};
    keys.forEach(key => {
        const val = dict[key];
        if (val) {
            result[key] = val;
        } else {
            result[key] = default_value;
        }
    })
    return result;
}

// https://github.com/glslify/glsl-aastep
// https://wwwtyro.net/2019/11/18/instanced-lines.html
// https://github.com/mrdoob/three.js/blob/dev/examples/jsm/lines/LineMaterial.js
// https://www.khronos.org/assets/uploads/developers/presentations/Crazy_Panda_How_to_draw_lines_in_WebGL.pdf
// https://github.com/gameofbombs/pixi-candles/tree/master/src
// https://github.com/wwwtyro/instanced-lines-demos/tree/master

function lines_vertex_shader(uniforms, attributes) {
    const attribute_decl = attributes_to_type_declaration(attributes);
    const uniform_decl = uniforms_to_type_declaration(uniforms);
    const color =
        attribute_type(attributes.color_start) ||
        uniform_type(uniforms.color_start);

    return `#version 300 es
        precision mediump int;
        precision highp float;

        ${attribute_decl}
        ${uniform_decl}

        out vec2 f_uv;
        out ${color} f_color;

        vec3 screen_space(vec3 point) {
            vec4 vertex = projectionview * model * vec4(point, 1);
            return vec3(vertex.xy * resolution, vertex.z) / vertex.w;
        }

        vec3 screen_space(vec2 point) {
            return screen_space(vec3(point, 0));
        }

        void main() {
            vec3 p_a = screen_space(linepoint_start);
            vec3 p_b = screen_space(linepoint_end);
            float width = position.x == 1.0 ? linewidth_end : linewidth_start ;

            vec2 pointA = p_a.xy;
            vec2 pointB = p_b.xy;

            vec2 xBasis = pointB - pointA;
            vec2 yBasis = normalize(vec2(-xBasis.y, xBasis.x));
            vec2 point = pointA + xBasis * position.x + yBasis * width * position.y;

            gl_Position = vec4((point.xy / resolution), p_a.z, 1.0);
            f_color = position.x == 1.0 ? color_end : color_start;
            f_uv = vec2(position.x, position.y + 0.5);
        }
        `;
}

function lines_fragment_shader(uniforms, attributes) {
    const color = attribute_type(attributes.color_start) || uniform_type(uniforms.color_start);
    const color_uniforms = filter_by_key(uniforms, ["colorrange", "colormap", "nan_color", "highclip", "lowclip"]);
    const uniform_decl = uniforms_to_type_declaration(color_uniforms);

    return `#version 300 es
    #extension GL_OES_standard_derivatives : enable

    precision mediump int;
    precision highp float;
    precision mediump sampler2D;
    precision mediump sampler3D;

    in vec2 f_uv;
    in ${color} f_color;
    ${uniform_decl}

    out vec4 fragment_color;

    // Half width of antialiasing smoothstep
    #define ANTIALIAS_RADIUS 1.0

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

    void main(){
        float xalpha = aastep(0.0, 0.0, f_uv.x);
        float yalpha = aastep(0.0, 0.0, f_uv.y);
        vec4 color = get_color(f_color, colormap, colorrange);
        fragment_color = vec4(color.rgb, color.a);
    }
    `;
}

function create_line_material(uniforms, attributes) {
    const uniforms_des = deserialize_uniforms(uniforms);
    const fragi = lines_fragment_shader(uniforms_des, attributes);
    return new THREE.RawShaderMaterial({
        uniforms: uniforms_des,
        vertexShader: lines_vertex_shader(uniforms_des, attributes),
        fragmentShader: fragi,
        transparent: true,
    });
}

function attach_interleaved_line_buffer(attr_name, geometry, points, ndim) {
    const buffer = new THREE.InstancedInterleavedBuffer(points, 2 * ndim, 1);
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

function create_linesegment_geometry(attributes) {
    function geometry_buffer() {
        const geometry = new THREE.InstancedBufferGeometry();
        const instance_positions = [
            0, -0.5, 1, -0.5, 1, 0.5, 0, -0.5, 1, 0.5, 0, 0.5,
        ];
        geometry.setAttribute(
            "position",
            new THREE.Float32BufferAttribute(instance_positions, 2)
        );
        return geometry;
    }

    const geometry = geometry_buffer();
    const buffers = {};
    function create_line_buffer(name, attr) {
        const flat_buffer = attr.value.flat;
        const ndims = attr.value.type_length;
        const buffer = flat_buffer;
        const linebuffer = attach_interleaved_line_buffer(
            name,
            geometry,
            buffer,
            ndims
        );
        buffers[name] = linebuffer;
        attr.on((new_points) => {
            const buff = buffers[name];
            const ndims = new_points.type_length;
            const new_line_points = new_points.flat;
            const old_count = buff.updateRange.count;
            if (old_count < new_line_points.length) {
                // instanceBuffer.dispose();
                buffers[name] = attach_interleaved_line_buffer(
                    name,
                    geometry,
                    new_line_points,
                    ndims
                );
            } else {
                buff.updateRange.count = new_line_points.length;
                buff.set(new_line_points, 0);
            }
            buffers[name].needsUpdate = true;
        });
        return buffer;
    }
    let points;
    for (let name in attributes) {
        const attr = attributes[name];
        points = create_line_buffer(name, attr);
    }
    geometry.boundingSphere = new THREE.Sphere();
    // don't use intersection / culling
    geometry.boundingSphere.radius = 10000000000000;
    geometry.frustumCulled = false;
    return geometry;
}

export function create_linesegments(line_data) {
    const geometry = create_linesegment_geometry(line_data.attributes);
    const material = create_line_material(
        line_data.uniforms,
        geometry.attributes
    );
    return new THREE.Mesh(geometry, material);
}

export function create_linesegments(line_data) {
    const geometry = create_linesegment_geometry(line_data.attributes);
    const material = create_line_material(
        line_data.uniforms,
        geometry.attributes
    );
    return new THREE.Mesh(geometry, material);
}
