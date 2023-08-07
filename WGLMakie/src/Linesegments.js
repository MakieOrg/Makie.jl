import {
    attributes_to_type_declaration,
    uniforms_to_type_declaration,
} from "./Shaders.js";
import { deserialize_uniforms } from "./Serialization.js";

function lines_shader(uniforms, attributes) {
    const attribute_decl = attributes_to_type_declaration(attributes);
    const uniform_decl = uniforms_to_type_declaration(uniforms);

    return `#version 300 es
        precision mediump int;
        precision highp float;

        ${attribute_decl}
        ${uniform_decl}

        out vec2 f_uv;
        out vec4 f_color;

        vec3 screen_space(vec2 point) {
            vec4 vertex = projectionview * model * vec4(point, 0, 1);
            return vec3(vertex.xy * resolution, vertex.z) / vertex.w;
        }

        void main() {
            vec3 p_a = screen_space(linepoint_start);
            vec3 p_b = screen_space(linepoint_end);
            // vec3 p_c = screen_space(linepoint_next);
            float width = linewidth_start;

            vec2 pointA = p_a.xy;
            vec2 pointB = p_b.xy;
            // vec2 pointC = p_c.xy;

            vec2 xBasis = pointB - pointA;
            vec2 yBasis = normalize(vec2(-xBasis.y, xBasis.x));
            vec2 point = pointA + xBasis * position.x + yBasis * width * position.y;

            gl_Position = vec4((point.xy / resolution), p_a.z, 1.0);
            f_color = color_start;
        }
        `;
}

const LINES_FRAG = `#version 300 es
precision mediump int;
precision highp float;
precision mediump sampler2D;
precision mediump sampler3D;

flat in vec2 f_uv_minmax;
in vec2 f_uv;
in vec4 f_color;

out vec4 fragment_color;

// Half width of antialiasing smoothstep
#define ANTIALIAS_RADIUS 0.8

float aastep(float threshold1, float dist) {
    return smoothstep(threshold1-ANTIALIAS_RADIUS, threshold1+ANTIALIAS_RADIUS, dist);
}

float aastep(float threshold1, float threshold2, float dist) {
    // We use 2x pixel space in the geometry shaders which passes through
    // in uv.y, so we need to treat it here by using 2 * ANTIALIAS_RADIUS
    float AA = 2.0 * ANTIALIAS_RADIUS;
    return smoothstep(threshold1 - AA, threshold1 + AA, dist) -
           smoothstep(threshold2 - AA, threshold2 + AA, dist);
}

void main(){
    fragment_color = f_color;
}
`;

function create_line_material(uniforms, attributes) {
    const uniforms_des = deserialize_uniforms(uniforms);
    return new THREE.RawShaderMaterial({
        uniforms: uniforms_des,
        vertexShader: lines_shader(uniforms_des, attributes),
        fragmentShader: LINES_FRAG,
        transparent: true,
    });
}

function attach_interleaved_line_buffer(
    attr_name,
    geometry,
    points,
    ndim,
) {
    const buffer = new THREE.InstancedInterleavedBuffer(points, 2*ndim, 1);
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
                    ndims,
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
