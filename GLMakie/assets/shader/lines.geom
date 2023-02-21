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
flat out vec2 f_uv_minmax;

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

// should be noticably faster than branching if true_val and false_val are
// easy to calculate
float ifelse(bool condition, float true_val, float false_val){
    return float(condition) * (true_val - false_val) + false_val;
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
    // This sets a min and max value foir uv.u at which anti-aliasing is forced.
    // With this setting it's never triggered.
    f_uv_minmax = vec2(-1000000000.0, 1000000000.0);

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

    // get the four vertices passed to the shader
    // without FAST_PATH the conversions happen on the CPU
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


    // Figure out the pattern-aware size of the line segment. 
    // g_lastlen[1]                        g_lastlen[2]
    //     |-----------------------------------|
    //     |   :                           :   |
    //     |   :                           :   |
    //     |   :                           :   |
    //     '---:---------------------------:---'
    //       edge1                       edge2
    //
    // start and stop are both cumulative length normalized by pattern_length
    // start is the off-to-on (left) transition of the first pattern that still 
    // draws after edge1
    // stop is the on-to-off (right) transition of the last pattern that still
    // draws before edge2
    float start, stop, left, right, edge1, edge2, inv_pl;

    inv_pl = 1.0 / pattern_length;
    start = g_lastlen[2] * inv_pl;
    stop  = g_lastlen[1] * inv_pl;
    edge1 = 0.5 * (g_lastlen[1] + g_thickness[1]);
    edge2 = 0.5 * (g_lastlen[2] - g_thickness[2]);

    for (int i = 0; i < textureSize(pattern_sections, 0).x - 1; i = i + 2)
    {
        left  = texelFetch(pattern_sections, i,   0).x;
        right = texelFetch(pattern_sections, i+1, 0).x;

        start = min(start, 2 * (ceil((edge1 - right) * inv_pl) + left * inv_pl));
        stop  = max(stop, 2 * (floor((edge2 - left) * inv_pl) + right * inv_pl));
    }
    // Technically start and stop should be offset by another 
    // 1 / (2 * textureSize(pattern)) so the line segment is normalized to
    // pattern texel centers rather than the left edge, but we have enough
    // AA_THICKNESS for it to be irrelevant.

    // if there is something to draw...
    if (stop > start){
        // init corner/linewidth handling (truncated miter join)
        vec2 miter_a = n1;
        vec2 miter_b = n1;

        float length_a = thickness_aa1;
        float length_b = thickness_aa2;

        // if start goes beyond one thickness outside this segment we need to
        // treat the join
        //               g_lastlen[1]                
        //               . - |--------------
        //               :   |              
        //               :   |              
        //               :   |              
        //               : - '--------------
        //  g_lastlen[1] - g_thickness[1]
        if (start * pattern_length < g_lastlen[1] - g_thickness[1] && isvalid[0]) {
            
            // setup for sharp corners
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
            miter_a = normalize(n0 + n1);
            length_a = thickness_aa1 / dot(miter_a, n1);

            // if the corner is too sharp, do a truncated miter join instead
            //        ----------c.
            //        ----------a.'.
            //                  | '.'.
            //                  x_ '.'.
            //        ------.     '--b d
            //             /        / /
            //            /        / /
            //
            // x is the point the two line segments meet (here p1)
            // a, b are the outer corners of the line segments
            // a, b, x define the triangle we need to fill to make the line continuous
            // c, d are a, b with padding for AA included
            // Note that the padding generated by c, d is reduced on the triangle
            // so we need to add another rectangle there to ensure enough padding
            if( dot( v0, v1 ) < MITER_LIMIT ){

                bool gap = dot( v0, n1 ) > 0;

                /*
                Another view of a truncated join (with lines joining like a V). 

                        uv.y = 0 in line segment
                         /
                        .  -- uv.x = u0 in truncated join 
                      .' '.     uv.y = thickness in line segment
                    .'     '.  /   uv.y = thickness + AA_THICKNESS in line segment
                  .'_________'.   /_ uv.x = start in truncated join (constraint for AA)
                .'_____________'.  _ uv.x = -proj_AA in truncated join (derived from line segment + constraint)
                |               |  
                |_______________|  _ uv.x = -proj_AA - AA_THICKNESS in truncated join

                Here the / annotations come from the connecting line segment and are to
                be viewed on the diagonal. The -- and _ annotations are relevant to the
                truncated join and viewed vertically.
                Note that `start` marks off-to-on edge in the pattern. So values
                greater than `start` will be drawn and smaller will be discarded.
                With how we pick start and get in this branch u0 will always be
                in a solidly drawn region of the pattern.
                */
                float u0      = 0.5 * start + thickness_aa1 * abs(dot(miter_a, n1)) * px2uv;
                float proj_AA = 0.5 * start - AA_THICKNESS  * abs(dot(miter_a, n1)) * px2uv;

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
            // We don't need to treat the join, so resize the line segment to
            // the drawn region. (This may extend the line too)
            start -= AA_THICKNESS * inv_pl;
            p1 += (start * pattern_length - g_lastlen[1]) * v1;
        }

        // Same as above for a line end. 
        if (stop * pattern_length >= g_lastlen[2] + g_thickness[2] && isvalid[3]) {
            // generate sharp corner at end
            if( dot( v1, v2 ) >= MITER_LIMIT ){
                miter_b = normalize(n1 + n2);
                length_b = thickness_aa2 / dot(miter_b, n1);
            }
            // for truncated miter join just leave it flat

            stop = g_lastlen[2] * inv_pl;
        } else {
            // resize to new limits
            stop += AA_THICKNESS * inv_pl;
            p2 += (stop * pattern_length - g_lastlen[2]) * v1;
        }

        // to save some space
        miter_a *= length_a;
        miter_b *= length_b;

        // If this segment starts or ends a line we force anti-aliasing to
        // happen at the respective edge.
        f_uv_minmax.x = ifelse(isvalid[0], f_uv_minmax.x, g_lastlen[1] * px2uv);
        f_uv_minmax.y = ifelse(isvalid[3], f_uv_minmax.y, g_lastlen[2] * px2uv);
        
        // generate rectangle for this segment
        emit_vertex(p1 + miter_a, vec2(0.5 * start + dot(v1, miter_a) * px2uv, -thickness_aa1), 1);
        emit_vertex(p1 - miter_a, vec2(0.5 * start - dot(v1, miter_a) * px2uv,  thickness_aa1), 1);
        emit_vertex(p2 + miter_b, vec2(0.5 * stop  + dot(v1, miter_b) * px2uv, -thickness_aa2), 2);
        emit_vertex(p2 - miter_b, vec2(0.5 * stop  - dot(v1, miter_b) * px2uv,  thickness_aa2), 2);
    }

    return;


    ////////////////////////////////////////////////////////////////////////////
    ///  solid lines
    ////////////////////////////////////////////////////////////////////////////

    #else


    // Setup for sharp corners (see above)
    vec2 miter_a = normalize(n0 + n1);
    vec2 miter_b = normalize(n1 + n2);
    float length_a = thickness_aa1 / dot(miter_a, n1);
    float length_b = thickness_aa2 / dot(miter_b, n1);

    // truncated miter join (see above)
    if( dot( v0, v1 ) < MITER_LIMIT ){
        bool gap = dot( v0, n1 ) > 0;
        // In this case uv's are used as signed distance field values, so we
        // want 0 where we had start before. 
        float u0      = thickness_aa1 * abs(dot(miter_a, n1)) * px2uv;
        float proj_AA = AA_THICKNESS  * abs(dot(miter_a, n1)) * px2uv;

        // to save some space
        vec2 off0   = thickness_aa1 * n0;
        vec2 off1   = thickness_aa1 * n1;
        vec2 off_AA = AA_THICKNESS * miter_a;
        float u_AA  = AA_THICKNESS * px2uv;

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
    if( dot( v1, v2 ) <= MITER_LIMIT ){
        miter_b = n1;
        length_b = thickness_aa2;
    }


    // Without a pattern (linestyle) we use uv.u directly as a signed 
    // distance field. If the line doesn't start or end with this line segment
    // we keep uv.u > 0 (draw w/o AA). 
    float u0 = 10.0 * (abs(g_thickness[1] + g_thickness[2])) * pattern_length;
    float u1 = u0 + segment_length * px2uv;

    // If we are at an edge we need to treat AA
    if (!isvalid[0] && !isvalid[3]){
        // start and end are part of this line segment

        // pad line to have space for AA
        p1 -= AA_THICKNESS * v1;
        p2 += AA_THICKNESS * v1;

        // set the cut off points and add uv padding to uv.u values
        f_uv_minmax = vec2(u0, u1);
        u0 -= AA_THICKNESS * px2uv;
        u1 -= AA_THICKNESS * px2uv;

        // TODO indices, half thickness
        emit_vertex(p1 + thickness_aa1 * n1, vec2(u0, -thickness_aa1), 1);
        emit_vertex(p1 - thickness_aa1 * n1, vec2(u0,  thickness_aa1), 1);
        emit_vertex(p2 + thickness_aa2 * n1, vec2(u1, -thickness_aa2), 2);
        emit_vertex(p2 - thickness_aa2 * n1, vec2(u1,  thickness_aa2), 2);
        EndPrimitive();
        return;

    // line starts or ends with this segment. Add space for AA and add an
    // edge (0 crossover) in uv.u (This works without f_uv_minmax)
    } else if (!isvalid[0]){
        p1 -= AA_THICKNESS * v1;
        u0 = -AA_THICKNESS;
        u1 = segment_length;
    } else if (!isvalid[3]){
        p2 += AA_THICKNESS * v1;
        u0 = segment_length;
        u1 = -AA_THICKNESS;
    }

    // if there is no start or end in the segment we can just leave things.
    // The offset in u0 is big enough to work with a factor px2uv

    // to save some space
    miter_a *= length_a;
    miter_b *= length_b;

    // Generate line segment (with uv.u being signed distance field values)
    emit_vertex(p1 + miter_a, vec2(px2uv * (u0 + dot(v1, miter_a)), -thickness_aa1), 1);
    emit_vertex(p1 - miter_a, vec2(px2uv * (u0 - dot(v1, miter_a)),  thickness_aa1), 1);
    emit_vertex(p2 + miter_b, vec2(px2uv * (u1 + dot(v1, miter_b)), -thickness_aa2), 2);
    emit_vertex(p2 - miter_b, vec2(px2uv * (u1 - dot(v1, miter_b)),  thickness_aa2), 2);


    #endif
}
