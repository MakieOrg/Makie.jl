// ------------------ Geometry Shader --------------------------------
// This version of the line shader simply cuts off the corners and
// draws the line with no overdraw on neighboring segments at all
{{GLSL_VERSION}}
{{GLSL_EXTENSIONS}}

layout(lines_adjacency) in;
layout(triangle_strip, max_vertices = 15) out;

in vec4 g_color[];
in float g_lastlen[];
in uvec2 g_id[];
in int g_valid_vertex[];
in float g_thickness[];
in float g_linecap_length[];

out vec4 f_color;
out vec2 f_uv;
out float f_thickness;

flat out uvec2 f_id;
flat out int f_type;

uniform vec2 resolution;
uniform float maxlength;
uniform float pattern_length;
uniform int linecap;


#define MITER_LIMIT -0.4
#define AA_THICKNESS 4


vec2 screen_space(vec4 vertex)
{
    return vec2(vertex.xy / vertex.w) * resolution;
}

// for line sections
void emit_vertex(vec2 position, float v, int index, float ratio)
{
    vec4 inpos  = gl_in[index].gl_Position;
    f_uv        = vec2(0.5 * g_lastlen[index] * ratio / pattern_length, v);
    f_color     = g_color[index];
    gl_Position = vec4((position/resolution)*inpos.w, inpos.z, inpos.w);
    f_id        = g_id[index];
    f_thickness = g_thickness[index];
    f_type      = 0; // line 
    EmitVertex();
}

// for linecaps
void emit_vertex(vec2 position, vec2 uv, int index, int type)
{
    vec4 inpos  = gl_in[index].gl_Position;
    f_uv        = uv;
    f_color     = g_color[index];
    gl_Position = vec4((position/resolution)*inpos.w, inpos.z, inpos.w);
    f_id        = g_id[index];
    f_thickness = g_thickness[index];
    f_type      = type; // some cap style
    EmitVertex();
}

uniform int max_primtives;
const float infinity = 1.0 / 0.0;

out vec3 o_view_pos;
out vec3 o_normal;

void main(void)
{
    o_view_pos = vec3(0);
    o_normal = vec3(0);
    // We mark each of the four vertices as valid or not. Vertices can be
    // marked invalid on input (eg, if they contain NaN). We also mark them
    // invalid if they repeat in the index buffer. This allows us to render to
    // the very ends of a polyline without clumsy buffering the position data on the
    // CPU side by repeating the first and last points via the index buffer. It
    // just requires a little care further down to avoid degenerate normals.
    bool isvalid[4] = bool[](
        g_valid_vertex[0] == 1 && g_id[0].y != g_id[1].y,
        g_valid_vertex[1] == 1,
        g_valid_vertex[2] == 1,
        g_valid_vertex[3] == 1 && g_id[2].y != g_id[3].y
    );

    if(!isvalid[1] || !isvalid[2]){
        // If one of the central vertices is invalid or there is a break in the
        // line, we don't emit anything.
        return;
    }
    // get the four vertices passed to the shader:
    vec2 p0 = screen_space(gl_in[0].gl_Position); // start of previous segment
    vec2 p1 = screen_space(gl_in[1].gl_Position); // end of previous segment, start of current segment
    vec2 p2 = screen_space(gl_in[2].gl_Position); // end of current segment, start of next segment
    vec2 p3 = screen_space(gl_in[3].gl_Position); // end of next segment

    float thickness_aa1 = g_thickness[1] + AA_THICKNESS;
    float thickness_aa2 = g_thickness[2] + AA_THICKNESS;

    // determine the direction of each of the 3 segments (previous, current, next)
    vec2 v1 = normalize(p2 - p1);
    vec2 v0 = v1;
    vec2 v2 = v1;

    if (p1 != p0 && isvalid[0]) {
        v0 = normalize(p1 - p0);
    }
    if (p3 != p2 && isvalid[3]) {
        v2 = normalize(p3 - p2);
    }

    // determine the normal of each of the 3 segments (previous, current, next)
    vec2 n0 = vec2(-v0.y, v0.x);
    vec2 n1 = vec2(-v1.y, v1.x);
    vec2 n2 = vec2(-v2.y, v2.x);


    // The goal here is to make wide line segments join cleanly. For most
    // joints, it's enough to extend/contract the buffered lines into the
    // "normal miter" shape below. However, this can get really spiky if the
    // lines are almost anti-parallel, in which case we want the truncated
    // mitre. For the truncated miter, we must emit the additional triangle
    // x-a-b.
    //
    //        normal miter               truncated miter
    //      ------------------*        ----------a.
    //                       /                   | '.
    //                 x    /                    x_ '.
    //      ------*        /           ------.     '--b
    //           /        /                 /        /
    //          /        /                 /        /
    //
    // Note that the way this is done below is fairly simple but results in
    // overdraw for semi transparent lines. Ideally would be nice to fix that
    // somehow.

    // determine miter lines by averaging the normals of the 2 segments
    vec2 miter_a = normalize(n0 + n1);    // miter at start of current segment
    vec2 miter_b = normalize(n1 + n2);    // miter at end of current segment

    // determine the length of the miter by projecting it onto normal and then inverse it
    float length_a = thickness_aa1 / dot(miter_a, n1);
    float length_b = thickness_aa2 / dot(miter_b, n1);

    float xstart = g_lastlen[1];
    float xend   = g_lastlen[2];
    float ratio = length(p2 - p1) / (xend - xstart);

    if( dot( v0, v1 ) < MITER_LIMIT ){
        /*
                 n1
        gap true  :  gap false
            v0    :
        . ------> :
        */
        bool gap = dot( v0, n1 ) > 0;
        // close the gap
        if(gap){
            emit_vertex(p1 + thickness_aa1 * n0, -thickness_aa1, 1, ratio);
            emit_vertex(p1 + thickness_aa1 * n1, -thickness_aa1, 1, ratio);
            emit_vertex(p1,                      0.0,            1, ratio);
            EndPrimitive();
        }else{
            emit_vertex(p1 - thickness_aa1 * n0, thickness_aa1, 1, ratio);
            emit_vertex(p1,                      0.0,           1, ratio);
            emit_vertex(p1 - thickness_aa1 * n1, thickness_aa1, 1, ratio);
            EndPrimitive();
        }
        miter_a = n1;
        length_a = thickness_aa1;
    }

    if( dot( v1, v2 ) < MITER_LIMIT ) {
        miter_b = n1;
        length_b = thickness_aa2;
    }

    // shortens line if g_linecap_length is negative and the line terminates
    vec2 linecap_gap1 = -min(g_linecap_length[1], 0) * float(!isvalid[0]) * v1;
    vec2 linecap_gap2 = -min(g_linecap_length[2], 0) * float(!isvalid[3]) * v1;

    emit_vertex(p1 + linecap_gap1 + length_a * miter_a, -thickness_aa1, 1, ratio);
    emit_vertex(p1 + linecap_gap1 - length_a * miter_a,  thickness_aa1, 1, ratio);
    emit_vertex(p2 - linecap_gap2 + length_b * miter_b, -thickness_aa2, 2, ratio);
    emit_vertex(p2 - linecap_gap2 - length_b * miter_b,  thickness_aa2, 2, ratio);

    // generate quads for line cap
    if (linecap != 0) { // 0 doubles as no line cap
        /*
        Line with line caps:

          cap      line      cap
        1-----3----    ----5-----7 ^
        |     |            |     | | off_n
        |     p1---    ---p2     | '
        |     |            |     |
        2-----4----    ----6-----8
                            ----> off_l

        1 .. 8 are the emit_vertex calls below
        */

        if (!isvalid[0]) {
            // there is no line before this
            vec2 off_n = thickness_aa1 * n1;
            vec2 off_l = sign(g_linecap_length[1]) * (abs(g_linecap_length[1]) + AA_THICKNESS) * v1;
            float du = 0.5 * AA_THICKNESS / abs(g_linecap_length[1]);
            float dv = 0.5 * AA_THICKNESS / g_thickness[1];

            EndPrimitive();
            emit_vertex(p1 + off_n - off_l, vec2(-du, -dv),  1, linecap);
            emit_vertex(p1 - off_n - off_l, vec2(-du, 1+dv), 1, linecap);
            emit_vertex(p1 + off_n,         vec2(0.5, -dv),  1, linecap);
            emit_vertex(p1 - off_n,         vec2(0.5, 1+dv), 1, linecap);
        }
        if (!isvalid[3]) {
            // there is no line after this
            vec2 off_n = thickness_aa2 * n1;
            vec2 off_l = sign(g_linecap_length[2]) * (abs(g_linecap_length[2]) + AA_THICKNESS) * v1;
            float du = 0.5 * AA_THICKNESS / abs(g_linecap_length[2]);
            float dv = 0.5 * AA_THICKNESS / g_thickness[2];

            EndPrimitive();
            emit_vertex(p2 + off_n,         vec2(0.5,   -dv), 2, linecap);
            emit_vertex(p2 - off_n,         vec2(0.5,  1+dv), 2, linecap);
            emit_vertex(p2 + off_n + off_l, vec2(1+dv,  -dv), 2, linecap);
            emit_vertex(p2 - off_n + off_l, vec2(1+dv, 1+dv), 2, linecap);
        }
    }
}
