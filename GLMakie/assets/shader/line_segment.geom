{{GLSL_VERSION}}
{{GLSL_EXTENSIONS}}

layout(lines) in;
layout(triangle_strip, max_vertices = 12) out;

uniform vec2 resolution;
uniform float maxlength;
uniform float pattern_length;
uniform int linecap;

in vec4 g_color[];
in uvec2 g_id[];
in float g_thickness[];
in float g_linecap_length[];

out float f_thickness;
out vec4 f_color;
out vec2 f_uv;
flat out uvec2 f_id;
flat out int f_type;

#define AA_THICKNESS 4.0

vec2 screen_space(vec4 vertex)
{
    return vec2(vertex.xy / vertex.w)*resolution;
}

void emit_vertex(vec2 position, vec2 uv, int index)
{
    vec4 inpos = gl_in[index].gl_Position;
    f_uv = uv;
    f_color = vec4(0,1,0,0.5); //g_color[index];
    gl_Position = vec4((position / resolution) * inpos.w, inpos.z, inpos.w);
    f_id = g_id[index];
    f_thickness = g_thickness[index] + AA_THICKNESS;
    f_type = 0;
    EmitVertex();
}

// for linecaps
void emit_vertex(vec2 position, vec2 uv, int index, int type)
{
    vec4 inpos  = gl_in[index].gl_Position;
    f_uv        = uv;
    f_color     = vec4(1,0,1,1);
    gl_Position = vec4((position/resolution)*inpos.w, inpos.z, inpos.w);
    f_id        = g_id[index];
    f_thickness = g_thickness[index];
    f_type      = type; // some cap style
    EmitVertex();
}

uniform int max_primtives;

out vec3 o_view_pos;
out vec3 o_normal;

void main(void)
{
    o_view_pos = vec3(0);
    o_normal = vec3(0);
    // get the four vertices passed to the shader:
    vec2 p0 = screen_space(gl_in[0].gl_Position); // start of previous segment
    vec2 p1 = screen_space(gl_in[1].gl_Position); // end of previous segment, start of current segment

    float thickness_aa0 = g_thickness[0]+AA_THICKNESS;
    float thickness_aa1 = g_thickness[1]+AA_THICKNESS;
    // determine the direction of each of the 3 segments (previous, current, next)
    vec2 vun0 = p1 - p0;
    vec2 v0 = normalize(vun0);
    // determine the normal of each of the 3 segments (previous, current, next)
    vec2 n0 = vec2(-v0.y, v0.x);
    float l = length(p1-p0);
    l /= (pattern_length*10);

    float uv0 = thickness_aa0/g_thickness[0];
    float uv1 = thickness_aa1/g_thickness[1];

    // shortens line if g_linecap_length is negative and the line terminates
    vec2 linecap_gap0 = -min(g_linecap_length[0], 0) * v0;
    vec2 linecap_gap1 = -min(g_linecap_length[1], 0) * v0;

    emit_vertex(p0 + linecap_gap0 + thickness_aa0 * n0, vec2(0, -uv0), 0);
    emit_vertex(p0 + linecap_gap0 - thickness_aa0 * n0, vec2(0,  uv0), 0);
    emit_vertex(p1 - linecap_gap1 + thickness_aa1 * n0, vec2(l, -uv1), 1);
    emit_vertex(p1 - linecap_gap1 - thickness_aa1 * n0, vec2(l,  uv1), 1);

    // generate quad for line cap
    if (linecap != 0) { // 0 doubles as no line cap
        /*
        Following the order of emit_vertex below

          cap      line      cap
        A-----C----    ----A-----C ^
        |     |            |     | | off_n
        |     p1---    ---p2     | '
        |     |            |     |
        B-----D----    ----B-----D
                            ----> off_l

        The size of the liencap quad is increase slightly to give space for 
        antialiasing. du and dv correct this scaling
        */

        vec2 off_n, off_l;
        float du, dv;

        // start of line segment
        off_n = thickness_aa0 * n0;
        off_l = sign(g_linecap_length[0]) * (abs(g_linecap_length[0]) + AA_THICKNESS) * v0;
        du = 0.5 * AA_THICKNESS / abs(g_linecap_length[0]);
        dv = 0.5 * AA_THICKNESS / g_thickness[0];

        EndPrimitive();
        emit_vertex(p0 + off_n - off_l, vec2(-du, -dv),  0, linecap);
        emit_vertex(p0 - off_n - off_l, vec2(-du, 1+dv), 0, linecap);
        emit_vertex(p0 + off_n,         vec2(0.5, -dv),  0, linecap);
        emit_vertex(p0 - off_n,         vec2(0.5, 1+dv), 0, linecap);

        // end of line segment
        off_n = thickness_aa1 * n0;
        off_l = sign(g_linecap_length[1]) * (abs(g_linecap_length[1]) + AA_THICKNESS) * v0;
        du = 0.5 * AA_THICKNESS / abs(g_linecap_length[1]);
        dv = 0.5 * AA_THICKNESS / g_thickness[1];

        EndPrimitive();
        emit_vertex(p1 + off_n,         vec2(0.5,   -dv), 1, linecap);
        emit_vertex(p1 - off_n,         vec2(0.5,  1+dv), 1, linecap);
        emit_vertex(p1 + off_n + off_l, vec2(1+dv,  -dv), 1, linecap);
        emit_vertex(p1 - off_n + off_l, vec2(1+dv, 1+dv), 1, linecap);
    }
}
