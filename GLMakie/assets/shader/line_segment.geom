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

out float f_thickness;
out vec4 f_color;
out vec2 f_uv;
flat out uvec2 f_id;
// out vec4 f_uv_minmax;

#define AA_THICKNESS 4.0

// Get pattern values
float fetch(Nothing _, float u){return 10000000.0;}
float fetch(sampler1D pattern, float u){return texture(pattern, u).x;}

vec2 screen_space(vec4 vertex)
{
    return vec2(vertex.xy / vertex.w) * resolution;
}

void emit_vertex(vec2 position, vec2 uv, int index)
{
    vec4 inpos = gl_in[index].gl_Position;
    f_uv = uv;
    f_color = g_color[index];
    gl_Position = vec4((position / resolution) * inpos.w, inpos.z, inpos.w);
    f_id = g_id[index];
    f_thickness = g_thickness[index];
    EmitVertex();
}

uniform int max_primtives;

out vec3 o_view_pos;
out vec3 o_normal;

void main(void)
{
    o_view_pos = vec3(0);
    o_normal = vec3(0);
    // f_uv_minmax = vec4(-1000000.0, 0, 1000000.0, 0); // never trigger changes

    // get the four vertices passed to the shader:
    vec2 p0 = screen_space(gl_in[0].gl_Position); // start of previous segment
    vec2 p1 = screen_space(gl_in[1].gl_Position); // end of previous segment, start of current segment

    float thickness_aa0 = g_thickness[0] + AA_THICKNESS;
    float thickness_aa1 = g_thickness[1] + AA_THICKNESS;
    // determine the direction of each of the 3 segments (previous, current, next)
    vec2 vun0 = p1 - p0;
    vec2 v0 = normalize(vun0);
    // determine the normal of each of the 3 segments (previous, current, next)
    vec2 n0 = vec2(-v0.y, v0.x);
    float l = length(p1 - p0);
    float px2u = 0.5 / pattern_length;
    float u = l * px2u;

    vec2 AA_offset = AA_THICKNESS * v0;

    /*                  0              v0              l 
                        |             -->              | 
     -thickness_aa0 - .----------------------------------. - -thickness_aa1
    -g_thickness[0] - | .------------------------------. | - -g_thickness[1]
                      | |                              | |
                n0 ↑  | |                              | |
                      | |                              | |
    +g_thickness[0] - | '------------------------------' | - +g_thickness[1]
     +thickness_aa0 - '----------------------------------' - +thickness_aa1
                      |                                  |
                -AA_THICKNESS                    l + AA_THICKNESS
    */

    // Force AA at line start/end 
    // This forces the signed distance field to be 0 at the start and end of a 
    // line, unless it is already negative due to a pattern.
    // float off_marker = float(fetch(pattern, 0).x < -1);
    // f_uv_minmax.x = AA_THICKNESS * px2u - 1000000.0 * off_marker;
    // f_uv_minmax.y = - 1000000.0 * off_marker;

    // off_marker = float(fetch(pattern, u).x < -1);
    // f_uv_minmax.z = u - AA_THICKNESS * px2u + 1000000.0 * off_marker;
    // f_uv_minmax.w = u - 1000000.0 * off_marker;

    emit_vertex(p0 + thickness_aa0 * n0 - AA_offset, vec2(  - AA_THICKNESS * px2u, -thickness_aa0), 0);
    emit_vertex(p0 - thickness_aa0 * n0 - AA_offset, vec2(  - AA_THICKNESS * px2u,  thickness_aa0), 0);
    emit_vertex(p1 + thickness_aa1 * n0 + AA_offset, vec2(u + AA_THICKNESS * px2u, -thickness_aa1), 1);
    emit_vertex(p1 - thickness_aa1 * n0 + AA_offset, vec2(u + AA_THICKNESS * px2u,  thickness_aa1), 1);
}
