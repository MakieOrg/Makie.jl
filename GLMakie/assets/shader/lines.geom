{{GLSL_VERSION}}
{{GLSL_EXTENSIONS}}
{{SUPPORTED_EXTENSIONS}}

struct Nothing{ //Nothing type, to encode if some variable doesn't contain any data
    bool _; //empty structs are not allowed
};

{{define_fast_path}}

layout(lines_adjacency) in;
layout(triangle_strip, max_vertices = 9) out;

in vec4 g_color[];
in float g_lastlen[];
in uvec2 g_id[];
in int g_valid_vertex[];
in float g_thickness[];

out vec4 f_color;
out vec2 f_uv;
out float f_thickness;

flat out uvec2 f_id;
out vec4 f_uv_minmax;

uniform vec2 resolution;
uniform float pattern_length;
{{pattern_type}} pattern;

float px2uv = 0.5 / pattern_length;

#define MITER_LIMIT -0.4
#define AA_THICKNESS 4

vec2 screen_space(vec4 vertex)
{
    return vec2(vertex.xy / vertex.w) * resolution;
}

// detect pattern edges in [u - 0.5w, u + 0.5w] range (u, w pixels):
// 0.0 no edge in section
// +1 rising edge in section
// -1 falling edge in section 
float pattern_edge(Nothing _, float u, float w){return 0.0;}

float pattern_edge(sampler1D pattern, float u, float w){
    float left   = texture(pattern, u - w * px2uv).x;
    float center = texture(pattern, u).x;
    float right  = texture(pattern, u + w * px2uv).x;
    // 4 if same sign right and same sign left, 0 else
    float noedge = (1 + sign(left) * sign(center)) * (1 + sign(center) * sign(right));
    return 0.25 * (4 - noedge) * sign(right - left);
}

// Get pattern values
float fetch(Nothing _, float u){return 10.0;}
float fetch(sampler1D pattern, float u){return texture(pattern, u).x;}

// For manual usage
void emit_vertex(vec2 position, vec2 uv, int index)
{
    vec4 inpos  = gl_in[index].gl_Position;
    f_uv        = uv;
    f_color     = g_color[index];
    gl_Position = vec4((position / resolution) * inpos.w, inpos.z, inpos.w);
    f_id        = g_id[index];
    f_thickness = g_thickness[index];
    EmitVertex();
}

// for line sections
void emit_vertex(vec2 position, float v, int index, vec2 line_unit, vec2 p1)
{
    vec4 inpos = gl_in[index].gl_Position;
    // calculate distance between this vertex and line start p1 in line direction
    // Do not rely on g_lastlen[2] here, as it is not the correct distance for 
    // solid lines.
    float vertex_offset = dot(position - p1, line_unit);
    f_uv        = vec2((g_lastlen[1] + vertex_offset) * px2uv, v);
    f_color     = g_color[index];
    gl_Position = vec4((position / resolution) * inpos.w, inpos.z, inpos.w);
    f_id        = g_id[index];
    f_thickness = g_thickness[index];
    EmitVertex();
}

out vec3 o_view_pos;
out vec3 o_normal;

void main(void)
{
    // These need to be set but don't have reasonable values here 
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

    // get the four vertices passed to the shader: (screen/pixel space)
    #ifdef FAST_PATH
        vec2 p0 = screen_space(gl_in[0].gl_Position);
        vec2 p1 = screen_space(gl_in[1].gl_Position);
        vec2 p2 = screen_space(gl_in[2].gl_Position);
        vec2 p3 = screen_space(gl_in[3].gl_Position);
    #else
        vec2 p0 = gl_in[0].gl_Position.xy; // start of previous segment
        vec2 p1 = gl_in[1].gl_Position.xy; // end of previous segment, start of current segment
        vec2 p2 = gl_in[2].gl_Position.xy; // end of current segment, start of next segment
        vec2 p3 = gl_in[3].gl_Position.xy; // end of next segment
    #endif

    // linewidth with padding for anti aliasing
    float thickness_aa1 = g_thickness[1] + AA_THICKNESS;
    float thickness_aa2 = g_thickness[2] + AA_THICKNESS;

    // determine the direction of each of the 3 segments (previous, current, next)
    vec2 v1 = p2 - p1;
    float segment_length = length(v1);
    v1 /= segment_length;
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

    f_uv_minmax = vec4(-1000000.0, g_lastlen[1], 1000000.0, g_lastlen[2]); 

    // harcoded for dots
    #ifndef FAST_PATH
        float start = 2 * float(int(0.5 * g_lastlen[1] + 0.833333333333 * pattern_length) / int(pattern_length));
        float stop  = 2 * float(int(0.5 * g_lastlen[2] + 0.833333333333 * pattern_length) / int(pattern_length));
        stop -= 1.333333333;

        if (stop > start){
            // consider AA
            start -= AA_THICKNESS / pattern_length;
            stop  += AA_THICKNESS / pattern_length;
        
            p1 += (start  * pattern_length - g_lastlen[1]) * v1;
            p2 += (stop   * pattern_length - g_lastlen[2]) * v1;

            emit_vertex(p1 + thickness_aa1 * n1, vec2(0.5 * start, -thickness_aa1), 1);
            emit_vertex(p1 - thickness_aa1 * n1, vec2(0.5 * start,  thickness_aa1), 1);
            emit_vertex(p2 + thickness_aa2 * n1, vec2(0.5 * stop,  -thickness_aa2), 2);
            emit_vertex(p2 - thickness_aa2 * n1, vec2(0.5 * stop,   thickness_aa2), 2);
            EndPrimitive();
        }
    #else
        emit_vertex(p1 + thickness_aa1 * n1, -thickness_aa1, 1, v1, p1);
        emit_vertex(p1 - thickness_aa1 * n1,  thickness_aa1, 1, v1, p1);
        emit_vertex(p2 + thickness_aa2 * n1, -thickness_aa2, 2, v1, p1);
        emit_vertex(p2 - thickness_aa2 * n1,  thickness_aa2, 2, v1, p1);
        EndPrimitive();
    #endif

    // reset shifting
    // f_uv_minmax = vec4(-999999, g_lastlen[1], 999999, g_lastlen[2]); 
}
