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


////////////////////////////////////////////////////////////////////////////////
/// Emit Vertex Methods
////////////////////////////////////////////////////////////////////////////////


// Manual uv calculation
// - position in screen space (double resolution as generally used)
// - uv with uv.u normalized (0..1), uv.v unnormalized (0..pattern_length)
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

// for vertices in the center of a line segment
// - position in screen space, half point applied
// - uv unnormalized (since this is used for solid lines)
void emit_mid_vertex(vec2 position, vec2 uv)
{
    vec4 inpos  = 0.5 * (gl_in[1].gl_Position + gl_in[2].gl_Position);
    f_uv        = uv;
    f_color     = 0.5 * (g_color[1] + g_color[2]);
    gl_Position = vec4((position / resolution) * inpos.w, inpos.z, inpos.w);
    f_id        = g_id[1];
    f_thickness = 0.5 * (g_thickness[1] + g_thickness[2]);
    EmitVertex();
}


////////////////////////////////////////////////////////////////////////////////
/// Main
////////////////////////////////////////////////////////////////////////////////


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


    ////////////////////////////////////////////////////////////////////////////
    ///  patterned lines
    ////////////////////////////////////////////////////////////////////////////

    #ifndef FAST_PATH


    float start, stop, left, right, edge1, edge2, inv_pl;

    inv_pl = 1.0 / pattern_length;
    start = g_lastlen[2] * inv_pl;
    stop  = g_lastlen[1] * inv_pl;
    edge1 = 0.5 * (g_lastlen[1] + g_thickness[1]);
    edge2 = 0.5 * (g_lastlen[2] - g_thickness[2]);

    // figure out where on sections of the pattern start and stop
    for (int i = 0; i < textureSize(pattern_sections, 0).x - 1; i = i + 2)
    {
        left  = texelFetch(pattern_sections, i,   0).x;
        right = texelFetch(pattern_sections, i+1, 0).x;

        start = min(start, 2 * (ceil((edge1 - right) * inv_pl) + left * inv_pl));
        if (isvalid[3])
            stop  = max(stop, 2 * (floor((edge2 - left) * inv_pl) + right * inv_pl));
        else
            stop  = max(stop, 2 * (floor((0.5 * g_lastlen[2] - right) * inv_pl) + right * inv_pl));
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
                // There is an edge at start
                float u0      = start + thickness_aa1 * abs(dot(miter_a, n1)) * px2uv;
                float proj_AA = start - AA_THICKNESS  * abs(dot(miter_a, n1)) * px2uv;

                // to save some space
                vec2 off0   = thickness_aa1 * n0;
                vec2 off1   = thickness_aa1 * n1;
                vec2 off_AA = AA_THICKNESS * miter_a;
                float u_AA  = AA_THICKNESS * px2uv;

                if(gap){
                    emit_vertex(p1,                 vec2(u0,                          0), 1);
                    emit_vertex(p1 + off0,          vec2(proj_AA,        +thickness_aa1), 1);
                    emit_vertex(p1 + off1,          vec2(proj_AA,        -thickness_aa1), 1);
                    emit_vertex(p1 + off0 + off_AA, vec2(proj_AA - u_AA, +thickness_aa1), 1);
                    emit_vertex(p1 + off1 + off_AA, vec2(proj_AA - u_AA, -thickness_aa1), 1);
                    EndPrimitive();
                }else{
                    emit_vertex(p1,                 vec2(u0,                          0), 1);
                    emit_vertex(p1 - off1,          vec2(proj_AA,        +thickness_aa1), 1);
                    emit_vertex(p1 - off0,          vec2(proj_AA,        -thickness_aa1), 1);
                    emit_vertex(p1 - off1 - off_AA, vec2(proj_AA - u_AA, +thickness_aa1), 1);
                    emit_vertex(p1 - off0 - off_AA, vec2(proj_AA - u_AA, -thickness_aa1), 1);
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
        if (stop * pattern_length >= g_lastlen[2] + g_thickness[2] && isvalid[3]) {
            // generate sharp corner at end
            if( dot( v1, v2 ) >= MITER_LIMIT ){
                miter_b = normalize(n1 + n2);
                length_b = thickness_aa2 / dot(miter_b, n1);
            }

            stop = g_lastlen[2] * inv_pl;
        } else {
            stop += AA_THICKNESS * inv_pl;
            p2 += (stop * pattern_length - g_lastlen[2]) * v1;
        }

        // to save some space
        miter_a *= length_a;
        miter_b *= length_b;
        
        // generate rectangle for this segment
        emit_vertex(p1 + miter_a, vec2(0.5 * start + dot(v1, miter_a) * px2uv, -thickness_aa1), 1);
        emit_vertex(p1 - miter_a, vec2(0.5 * start - dot(v1, miter_a) * px2uv,  thickness_aa1), 1);
        emit_vertex(p2 + miter_b, vec2(0.5 * stop  + dot(v1, miter_b) * px2uv, -thickness_aa2), 2);
        emit_vertex(p2 - miter_b, vec2(0.5 * stop  - dot(v1, miter_b) * px2uv,  thickness_aa2), 2);
        EndPrimitive();
    }

    return;


    ////////////////////////////////////////////////////////////////////////////
    ///  solid lines
    ////////////////////////////////////////////////////////////////////////////

    #else


    // generate sharp corner on both line ends
    //
    //     2 length_b
    //      |-----|    
    //  -----------  
    //          .'        ___
    //        .'     .'|   |
    //  -----'     .'  |   | 2 length_a
    //           .'    |  _|_
    //          |      |
    //
    vec2 miter_a = normalize(n0 + n1);
    vec2 miter_b = normalize(n1 + n2);
    float length_a = thickness_aa1 / dot(miter_a, n1);
    float length_b = thickness_aa2 / dot(miter_b, n1);

    // truncated miter join
    //      .-----------
    //    .'|
    //   '--|
    //      |
    //      '-----------
    if( dot( v0, v1 ) < MITER_LIMIT ){
        bool gap = dot( v0, n1 ) > 0;
        float u0      = thickness_aa1 * abs(dot(miter_a, n1)) * 0.5;
        float proj_AA = AA_THICKNESS  * abs(dot(miter_a, n1)) * 0.5;

        // to save some space
        vec2 off0   = thickness_aa1 * n0;
        vec2 off1   = thickness_aa1 * n1;
        vec2 off_AA = AA_THICKNESS * miter_a;
        float u_AA  = AA_THICKNESS * 0.5;

        if(gap){
            emit_vertex(p1,                 vec2(+ u0,                          0), 1);
            emit_vertex(p1 + off0,          vec2(- proj_AA,        +thickness_aa1), 1);
            emit_vertex(p1 + off1,          vec2(- proj_AA,        -thickness_aa1), 1);
            emit_vertex(p1 + off0 + off_AA, vec2(- proj_AA - u_AA, +thickness_aa1), 1);
            emit_vertex(p1 + off1 + off_AA, vec2(- proj_AA - u_AA, -thickness_aa1), 1);
            EndPrimitive();
        }else{
            emit_vertex(p1,                 vec2(+ u0,                          0), 1);
            emit_vertex(p1 - off1,          vec2(- proj_AA,        +thickness_aa1), 1);
            emit_vertex(p1 - off0,          vec2(- proj_AA,        -thickness_aa1), 1);
            emit_vertex(p1 - off1 - off_AA, vec2(- proj_AA - u_AA, +thickness_aa1), 1);
            emit_vertex(p1 - off0 - off_AA, vec2(- proj_AA - u_AA, -thickness_aa1), 1);
            EndPrimitive();
        }

        miter_a = n1;
        length_a = thickness_aa1;
    }

    // we have miter join on next segment, do normal line cut off
    //  ---------.
    //           |
    //           |
    //  ---------'
    if( dot( v1, v2 ) <= MITER_LIMIT ){
        miter_b = n1;
        length_b = thickness_aa2;
    }


    // Without a pattern (linestyle) we use uv.u directly as a signed 
    // distance field. If we don't have an edge uv.u should be consistently
    // > 0 (no AA edge). Since we extrude some lines it should be greater
    // than 1 / MITER_LIMIT.
    float u0 = 10.0 * g_thickness[1];
    float u1 = 10.0 * g_thickness[2];

    // If we are at an edge we make add an edge (0 crossing) in our uv.u
    // to get anti-aliasing.
    if (!isvalid[0] && !isvalid[3]){
        // line segments is cut off on both ends.
        // We need to add a mid point here to get AA on both sides.
        //
        //  |-------- l + 2AA --------|    total length
        //  .------------.------------.
        //  |            |            |
        //  p1    0.5 * (p1 + p2)    p2    points
        //  |            |            |
        //  '------------'------------'
        // -AA          l/2          -AA   uv.u values

        // pad line to have space for AA
        p1 -= AA_THICKNESS * v1;
        p2 += AA_THICKNESS * v1;

        // uv values (0.5 for double pixel space -> normalized space)
        u0 = -0.5 * AA_THICKNESS;
        u1 = 0.25 * segment_length;

        // TODO indices, half thickness
        emit_vertex(p1 + thickness_aa1 * n1,                  vec2(u0, -thickness_aa1), 1);
        emit_vertex(p1 - thickness_aa1 * n1,                  vec2(u0,  thickness_aa1), 1);
        emit_mid_vertex(0.5 * (p1 + p2) + thickness_aa1 * n1, vec2(u1, -thickness_aa1));
        emit_mid_vertex(0.5 * (p1 + p2) - thickness_aa1 * n1, vec2(u1,  thickness_aa1));
        emit_vertex(p2 + thickness_aa2 * n1,                  vec2(u0, -thickness_aa2), 2);
        emit_vertex(p2 - thickness_aa2 * n1,                  vec2(u0,  thickness_aa2), 2);
        EndPrimitive();
        return;

    // line starts or ends with this segment. Add space for AA and add an
    // edge (0 crossover) in uv.u
    } else if (!isvalid[0]){
        p1 -= AA_THICKNESS * v1;
        u0 = -AA_THICKNESS;
        u1 = segment_length;
    } else if (!isvalid[3]){
        p2 += AA_THICKNESS * v1;
        u0 = segment_length;
        u1 = -AA_THICKNESS;
    }

    // to save some space
    miter_a *= length_a;
    miter_b *= length_b;

    emit_vertex(p1 + miter_a, vec2(0.5 * (u0 + dot(v1, miter_a)), -thickness_aa1), 1);
    emit_vertex(p1 - miter_a, vec2(0.5 * (u0 - dot(v1, miter_a)),  thickness_aa1), 1);
    emit_vertex(p2 + miter_b, vec2(0.5 * (u1 + dot(v1, miter_b)), -thickness_aa2), 2);
    emit_vertex(p2 - miter_b, vec2(0.5 * (u1 - dot(v1, miter_b)),  thickness_aa2), 2);
    EndPrimitive();


    #endif
}
