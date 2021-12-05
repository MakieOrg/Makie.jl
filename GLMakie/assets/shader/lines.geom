// ------------------ Geometry Shader --------------------------------
// This version of the line shader simply cuts off the corners and
// draws the line with no overdraw on neighboring segments at all
{{GLSL_VERSION}}
{{GLSL_EXTENSIONS}}

layout(lines_adjacency) in;
layout(triangle_strip, max_vertices = 7) out;

in vec4 g_color[];
in float g_lastlen[];
in uvec2 g_id[];
in int g_valid_vertex[];

out vec4 f_color;
out vec2 f_uv;
out float f_thickness;

flat out uvec2 f_id;

uniform vec2 resolution;
uniform float maxlength;
uniform float thickness;
uniform float pattern_length;


#define MITER_LIMIT -0.4

vec2 screen_space(vec4 vertex)
{
    return vec2(vertex.xy / vertex.w) * resolution;
}
void emit_vertex(vec2 position, vec2 uv, int index, float ratio)
{
    vec4 inpos  = gl_in[index].gl_Position;
    f_uv        = vec2((g_lastlen[index] * ratio) / pattern_length / (thickness+4) / 2.0, uv.y);
    f_color     = g_color[index];
    gl_Position = vec4((position/resolution)*inpos.w, inpos.z, inpos.w);
    f_id        = g_id[index];
    f_thickness = thickness;
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

    float thickness_aa = thickness+4;

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
    float length_a = thickness_aa / dot(miter_a, n1);
    float length_b = thickness_aa / dot(miter_b, n1);

    float xstart = g_lastlen[1];
    float xend   = g_lastlen[2];
    float ratio = length(p2 - p1) / (xend - xstart);

    float uvy = thickness_aa/thickness;

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
            emit_vertex(p1 + thickness_aa * n0, vec2(1, -uvy), 1, ratio);
            emit_vertex(p1 + thickness_aa * n1, vec2(1, -uvy), 1, ratio);
            emit_vertex(p1,                     vec2(0, 0.0), 1, ratio);
            EndPrimitive();
        }else{
            emit_vertex(p1 - thickness_aa * n0, vec2(1, uvy), 1, ratio);
            emit_vertex(p1,                     vec2(0, 0.0), 1, ratio);
            emit_vertex(p1 - thickness_aa * n1, vec2(1, uvy), 1, ratio);
            EndPrimitive();
        }
        miter_a = n1;
        length_a = thickness_aa;
    }

    if( dot( v1, v2 ) < MITER_LIMIT ) {
        miter_b = n1;
        length_b = thickness_aa;
    }

    // generate the triangle strip

    emit_vertex(p1 + length_a * miter_a, vec2( 0, -uvy), 1, ratio);
    emit_vertex(p1 - length_a * miter_a, vec2( 0, uvy), 1, ratio);

    emit_vertex(p2 + length_b * miter_b, vec2( 0, -uvy ), 2, ratio);
    emit_vertex(p2 - length_b * miter_b, vec2( 0, uvy), 2, ratio);
}
