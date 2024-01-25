{{GLSL_VERSION}}
{{GLSL_EXTENSIONS}}

struct Nothing{ //Nothing type, to encode if some variable doesn't contain any data
    bool _; //empty structs are not allowed
};

layout(lines) in;
layout(triangle_strip, max_vertices = 4) out;

uniform vec2 resolution;
uniform float pattern_length;
{{pattern_type}} pattern;

in vec4 g_color[];
in uvec2 g_id[];
in float g_thickness[];

out vec4 f_color;
out float f_quad_sdf0;
out vec3 f_quad_sdf1;
out float f_quad_sdf2;
out vec2 f_truncation;
out vec2 f_uv;

flat out float f_linewidth;
flat out vec4 f_pattern_overwrite;
flat out uvec2 f_id;
flat out vec2 f_extrusion12;
flat out vec2 f_linelength;

const float AA_RADIUS = 0.8;
const float AA_THICKNESS = 4.0 * AA_RADIUS;

vec3 screen_space(vec4 vertex) {
    return vec3((0.5 * vertex.xy / vertex.w + 0.5) * resolution, vertex.z / vertex.w);
}

vec2 normal_vector(in vec2 v) { return vec2(-v.y, v.x); }
vec2 normal_vector(in vec3 v) { return vec2(-v.y, v.x); }

out vec3 o_view_pos;
out vec3 o_view_normal;

void main(void)
{
    o_view_pos = vec3(0);
    o_view_normal = vec3(0);

    // we generate very thin lines for linewidth 0, so we manually skip them:
    if (g_thickness[0] == 0.0 && g_thickness[1] == 0.0) {
        return;
    }

    // get start and end point of line segment
    vec3 p1 = screen_space(gl_in[0].gl_Position);
    vec3 p2 = screen_space(gl_in[1].gl_Position);

    // get vector in line direction and vector in linewidth direction
    vec3 v1 = (p2 - p1) / length(p2.xy - p1.xy);
    vec2 n1 = normal_vector(v1);

    // Set invalid / ignored outputs
    f_quad_sdf0 = 10.0;         // no joint to previous segment
    f_quad_sdf2 = 10.0;         // not joint to next segment
    f_truncation = vec2(-10.0); // no truncated joint
    f_pattern_overwrite = vec4(-1e12, 1.0, 1e12, 1.0); // no joints to overwrite
    f_extrusion12 = vec2(0);    // no joints needing extrusion
    f_linelength = vec2(10.0);  // no joints needing discards

    // Generate vertices

    for (int x = 0; x < 2; x++) {
        // Get offset in line direction
        float v_offset = (2 * x - 1) * AA_THICKNESS;
        // pass on linewidth and id (picking) for the current line vertex
        float halfwidth = 0.5 * g_thickness[x];
        // TODO: if we just make this a varying output we probably get var linewidths here
        f_linewidth = halfwidth;
        f_id = g_id[x];
        f_color = g_color[x];

        for (int y = 0; y < 2; y++) {
            // Get offset in y direction & compute vertex position
            float n_offset = (2 * y - 1) * (halfwidth + AA_THICKNESS);
            vec3 position = vec3[2](p1, p2)[x] + v_offset * v1 + n_offset * vec3(n1, 0);
            gl_Position = vec4(2.0 * position.xy / resolution - 1.0, position.z, 1.0);

            // Generate SDF's

            // distance from quad vertex to line control points
            vec2 VP1 = position.xy - p1.xy;
            vec2 VP2 = position.xy - p2.xy;

            // sdf of this segment
            f_quad_sdf1.x = dot(VP1, -v1.xy);
            f_quad_sdf1.y = dot(VP2,  v1.xy);
            f_quad_sdf1.z = n_offset;

            // generate uv coordinate
            f_uv = vec2(
                -f_quad_sdf1.x / pattern_length,
                0.5 + halfwidth / g_thickness[x]
            );

            // finalize vertex
            EmitVertex();
        }
    }

    EndPrimitive();

    return;
}
