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
// out vec4 f_uv_minmax;

uniform vec2 resolution;
uniform float pattern_length;
{{pattern_type}} pattern;
uniform sampler1D pattern_sections;

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


    // harcoded for dots
    #ifndef FAST_PATH
        float start, stop, left, right, edge1, edge2, inv_pl;

        inv_pl = 1.0 / pattern_length;
        start = g_lastlen[2] * inv_pl;
        stop  = g_lastlen[1] * inv_pl;
        edge1 = 0.5 * (g_lastlen[1] + g_thickness[1]);
        edge2 = 0.5 * (g_lastlen[2] - g_thickness[2]);

        // figure out where on sections of the pattern start and stop
        for (int i = 0; i < textureSize(pattern_sections, 0).x; i = i + 2)
        {
            left  = texelFetch(pattern_sections, i,   0).x;
            right = texelFetch(pattern_sections, i+1, 0).x;

            start = min(start, 2 * (ceil((edge1 - right) * inv_pl) + left * inv_pl));
            stop  = max(stop,  2 * (floor((edge2 - left) * inv_pl) + right * inv_pl));
        }



        if (stop > start){
            // init corner/linewidth handling
            vec2 miter_a = n1;
            vec2 miter_b = n1;

            float length_a = thickness_aa1;
            float length_b = thickness_aa2;

            // does left corner underflow?
            if (start * pattern_length < g_lastlen[1] - g_thickness[1]) {
                // generate sharp corner at start
                miter_a = normalize(n0 + n1);
                length_a = thickness_aa1 / dot(miter_a, n1);

                // truncated miter join
                if( dot( v0, v1 ) < MITER_LIMIT ){
                    bool gap = dot( v0, n1 ) > 0;
                    float u0      = thickness_aa1 * abs(dot(miter_a, n1)) * px2uv;
                    float proj_AA = AA_THICKNESS  * abs(dot(miter_a, n1)) * px2uv;

                    if(gap){
                        emit_vertex(p1,                                               vec2(start + u0,                      0),              1);
                        emit_vertex(p1 + thickness_aa1 * n0,                          vec2(start - proj_AA,                +thickness_aa1), 1);
                        emit_vertex(p1 + thickness_aa1 * n1,                          vec2(start - proj_AA,                -thickness_aa1), 1);
                        emit_vertex(p1 + thickness_aa1 * n0 + AA_THICKNESS * miter_a, vec2(start - proj_AA - AA_THICKNESS * px2uv, +thickness_aa1), 1);
                        emit_vertex(p1 + thickness_aa1 * n1 + AA_THICKNESS * miter_a, vec2(start - proj_AA - AA_THICKNESS * px2uv, -thickness_aa1), 1);
                        EndPrimitive();
                    }else{
                        emit_vertex(p1,                                               vec2(start + u0,                      0),              1);
                        emit_vertex(p1 - thickness_aa1 * n1,                          vec2(start - proj_AA,                +thickness_aa1), 1);
                        emit_vertex(p1 - thickness_aa1 * n0,                          vec2(start - proj_AA,                -thickness_aa1), 1);
                        emit_vertex(p1 - thickness_aa1 * n1 - AA_THICKNESS * miter_a, vec2(start - proj_AA - AA_THICKNESS * px2uv, +thickness_aa1), 1);
                        emit_vertex(p1 - thickness_aa1 * n0 - AA_THICKNESS * miter_a, vec2(start - proj_AA - AA_THICKNESS * px2uv, -thickness_aa1), 1);
                        EndPrimitive();
                    }

                    miter_a = n1;
                    length_a = thickness_aa1;
                }
                    
                start = g_lastlen[1] * inv_pl;
            } else {
                start -= AA_THICKNESS * inv_pl;
                p1 += (start * pattern_length - g_lastlen[1]) * v1;
            }

            // does right corner overflow?
            if (stop * pattern_length >= g_lastlen[2] + g_thickness[2]) {
                // generate sharp corner at end
                if( dot( v1, v2 ) >= MITER_LIMIT ){
                    miter_b = normalize(n1 + n2);
                    length_b = thickness_aa2 / dot(miter_b, n1);
                }

                stop = g_lastlen[2] * inv_pl;
            } else {
                stop += AA_THICKNESS * inv_pl;
                p2 += (stop  * pattern_length - g_lastlen[2]) * v1;
            }
        
            // generate rectangle for this segment
            emit_vertex(p1 + length_a * miter_a, vec2(0.5 * start + dot(v1, miter_a) * length_a * px2uv, -thickness_aa1), 1);
            emit_vertex(p1 - length_a * miter_a, vec2(0.5 * start - dot(v1, miter_a) * length_a * px2uv,  thickness_aa1), 1);
            emit_vertex(p2 + length_b * miter_b, vec2(0.5 * stop  + dot(v1, miter_b) * length_b * px2uv,  -thickness_aa2), 2);
            emit_vertex(p2 - length_b * miter_b, vec2(0.5 * stop  - dot(v1, miter_b) * length_b * px2uv,   thickness_aa2), 2);
            EndPrimitive();
        }
    #else
        // generate sharp corner at start
        vec2 miter_a = normalize(n0 + n1);
        vec2 miter_b = normalize(n1 + n2);
        float length_a = thickness_aa1 / dot(miter_a, n1);
        float length_b = thickness_aa2 / dot(miter_b, n1);

        // truncated miter join
        if( dot( v0, v1 ) < MITER_LIMIT ){
            bool gap = dot( v0, n1 ) > 0;
            float u0      = thickness_aa1 * abs(dot(miter_a, n1)) * 0.5; //  * px2uv;
            float proj_AA = AA_THICKNESS  * abs(dot(miter_a, n1)) * 0.5; //  * px2uv;

            if(gap){
                emit_vertex(p1,                                               vec2(+ u0,                                        0), 1);
                emit_vertex(p1 + thickness_aa1 * n0,                          vec2(- proj_AA,                      +thickness_aa1), 1);
                emit_vertex(p1 + thickness_aa1 * n1,                          vec2(- proj_AA,                      -thickness_aa1), 1);
                emit_vertex(p1 + thickness_aa1 * n0 + AA_THICKNESS * miter_a, vec2(- proj_AA - AA_THICKNESS * 0.5, +thickness_aa1), 1);
                emit_vertex(p1 + thickness_aa1 * n1 + AA_THICKNESS * miter_a, vec2(- proj_AA - AA_THICKNESS * 0.5, -thickness_aa1), 1);
                EndPrimitive();
            }else{
                emit_vertex(p1,                                               vec2(+ u0,                                        0), 1);
                emit_vertex(p1 - thickness_aa1 * n1,                          vec2(- proj_AA,                      +thickness_aa1), 1);
                emit_vertex(p1 - thickness_aa1 * n0,                          vec2(- proj_AA,                      -thickness_aa1), 1);
                emit_vertex(p1 - thickness_aa1 * n1 - AA_THICKNESS * miter_a, vec2(- proj_AA - AA_THICKNESS * 0.5, +thickness_aa1), 1);
                emit_vertex(p1 - thickness_aa1 * n0 - AA_THICKNESS * miter_a, vec2(- proj_AA - AA_THICKNESS * 0.5, -thickness_aa1), 1);
                EndPrimitive();
            }

            miter_a = n1;
            length_a = thickness_aa1;
        }

        // generate sharp corner at end
        if( dot( v1, v2 ) <= MITER_LIMIT ){
            miter_b = n1;
            length_b = thickness_aa2;
        }

        // if we are not at the line start or end this should just be a big positive number
        float u0 = 10.0 * g_thickness[1];
        float u1 = 10.0 * g_thickness[2];
        if (!isvalid[0]){
            p1 -= AA_THICKNESS * v1;
            u0 = -AA_THICKNESS;
            u1 = segment_length;
        }
        if (!isvalid[3]){
            p2 += AA_THICKNESS * v1;
            u0 = segment_length;
            u1 = -AA_THICKNESS;
        }

        emit_vertex(p1 + length_a * miter_a, vec2((u0 + dot(v1, miter_a) * length_a) * 0.5, -thickness_aa1), 1);
        emit_vertex(p1 - length_a * miter_a, vec2((u0 - dot(v1, miter_a) * length_a) * 0.5,  thickness_aa1), 1);
        emit_vertex(p2 + length_b * miter_b, vec2((u1 + dot(v1, miter_b) * length_b) * 0.5, -thickness_aa2), 2);
        emit_vertex(p2 - length_b * miter_b, vec2((u1 - dot(v1, miter_b) * length_b) * 0.5,  thickness_aa2), 2);
        EndPrimitive();
    #endif
}

