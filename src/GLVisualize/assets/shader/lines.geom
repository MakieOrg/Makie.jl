// ------------------ Geometry Shader --------------------------------
// This version of the line shader simply cuts off the corners and
// draws the line with no overdraw on neighboring segments at all
{{GLSL_VERSION}}
{{GLSL_EXTENSIONS}}

layout(lines_adjacency) in;
layout(triangle_strip, max_vertices = 5) out;

in vec4 g_color[];
in float g_lastlen[];
in uvec2 g_id[];
in uint g_line_connections[];
in int g_valid_vertex[];
//in float g_thickness[];

out vec4 f_color;
out vec2 f_uv;
out float f_thickness;

flat out uvec2 f_id;

uniform vec2 resolution;
uniform float maxlength;
uniform float thickness;
uniform float pattern_length;


#define MITER_LIMIT -0.75

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

vec2 compute_miter(vec2 normal_a, vec2 normal_b)
{
    vec2 miter = normalize(normal_a + normal_b);
    if(miter.x < 0.000001 && miter.y < 0.000001)
    {
        return vec2(-normal_a.y, normal_a.x);
    }
    return miter;
}

uniform int max_primtives;
const float infinity = 1.0 / 0.0;

void main(void)
{
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

    if(g_line_connections[1] != g_line_connections[2] || !isvalid[1] || !isvalid[2]){
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


    // perform naive culling
    //vec2 area = resolution * 1.2;
    //if( p1.x < -area.x || p1.x > area.x ) return;
    //if( p1.y < -area.y || p1.y > area.y ) return;
    //if( p2.x < -area.x || p2.x > area.x ) return;
    //if( p2.y < -area.y || p2.y > area.y ) return;

    // determine the direction of each of the 3 segments (previous, current, next)
    vec2 v1 =              normalize(p2 - p1);
    vec2 v0 = isvalid[0] ? normalize(p1 - p0) : v1;
    vec2 v2 = isvalid[3] ? normalize(p3 - p2) : v1;

    // determine the normal of each of the 3 segments (previous, current, next)
    vec2 n0 = vec2(-v0.y, v0.x);
    vec2 n1 = vec2(-v1.y, v1.x);
    vec2 n2 = vec2(-v2.y, v2.x);

    // The goal here is to make wide line segments join cleanly. For most
    // joints, it's enough to extend/contract the buffered lines into the
    // "normal miter" shape below by emitting the vertices ABCD to form two
    // triangles. However, this can get really spiky if the lines are almost
    // anti-parallel, in which case we want to adjust C and emit an extra
    // vertex E to form a truncated miter with the triangle CDE.
    //
    //      normal miter                   truncated miter
    //  --A---------------------C      --A--------------C
    //    |  current       _-' /         |            .' '.
    //    |  segment  _.-*'   /          |          .'  * '.
    //  --B---------D'       /         --B---------D--------E
    //             /        /                     /        /
    //            /        /                     /        /
    //             next
    //            segment

    // determine miter lines by averaging the normals of the 2 segments
    vec2 miter_a = normalize(n0 + n1);    // miter at start of current segment
    vec2 miter_b = normalize(n1 + n2);    // miter at end of current segment

    // Determine the length of the miter by projecting it onto normal and then
    // inverting.
    float length_a = thickness_aa / dot(miter_a, n1);
    float length_b = thickness_aa / dot(miter_b, n1);
    // Clamp lengths of the miters to avoid problem with short lines and wide
    // line widths where the length of the miter can get longer than the line
    // itself.
    float length0 = length(p1 - p0);
    float length1 = length(p2 - p1);
    float length2 = length(p3 - p2);
    float maxlen_a = min(abs(length1/dot(miter_a, v1)), abs(length0/dot(miter_a, v0)));
    float maxlen_b = min(abs(length1/dot(miter_b, v1)), abs(length2/dot(miter_b, v2)));
    length_a = clamp(length_a, -maxlen_a, maxlen_a);
    length_b = clamp(length_b, -maxlen_b, maxlen_b);

    float xstart = g_lastlen[1];
    float xend   = g_lastlen[2];
    float ratio = length1 / (xend - xstart);
    float uvy = thickness_aa/thickness;

    vec2 vA =  length_a * miter_a;
    vec2 vB = -length_a * miter_a;
    if(dot( v0, v1 ) < MITER_LIMIT){
        if (dot(n1,v0) > 0)
            vA =  thickness_aa*n1;
        else
            vB = -thickness_aa*n1;
    }

    float Eside = 0;
    vec2 pE;
    vec2 vC =  length_b * miter_b;
    vec2 vD = -length_b * miter_b;
    if(dot( v1, v2 ) < MITER_LIMIT) {
        if (dot(n1,v2) < 0) {
            vC = thickness_aa*n1;
            Eside = 1.0;
        }
        else {
            vD = -thickness_aa*n1;
            Eside = -1.0;
        }
    }

    // generate the triangle strip

    emit_vertex(p1 + vA, vec2( 0, -uvy), 1, ratio);
    emit_vertex(p1 + vB, vec2( 0, uvy), 1, ratio);

    emit_vertex(p2 + vC, vec2( 0, -uvy ), 2, ratio);
    emit_vertex(p2 + vD, vec2( 0, uvy), 2, ratio);

    if(Eside != 0)
        emit_vertex(p2 + (Eside*thickness_aa)*n2, vec2(1, -Eside*uvy), 2, ratio);
}
