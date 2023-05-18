{{GLSL_VERSION}}
{{GLSL_EXTENSIONS}}
{{SUPPORTED_EXTENSIONS}}

struct Nothing{ //Nothing type, to encode if some variable doesn't contain any data
    bool _; //empty structs are not allowed
};

struct WorldAxisLimits{
    vec3 min, max;
};

{{define_fast_path}}

layout(lines_adjacency) in;
layout(triangle_strip, max_vertices = 11) out;

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

out vec3 o_view_pos;
out vec3 o_normal;

uniform vec2 resolution;
uniform float pattern_length;
uniform sampler1D pattern_sections;
{{clip_planes_type}} clip_planes;

float px2uv = 0.5 / pattern_length;

// Constants
#define MITER_LIMIT -0.4
#define AA_THICKNESS 4

vec3 screen_space(vec4 vertex)
{
    return vec3(vertex.xy * resolution, vertex.z) / vertex.w;
}

void set_clip(Nothing planes, int idx){ return; };
void set_clip(WorldAxisLimits planes, int idx){
    gl_ClipDistance[0] = gl_in[idx].gl_ClipDistance[0];
    gl_ClipDistance[1] = gl_in[idx].gl_ClipDistance[1];
    gl_ClipDistance[2] = gl_in[idx].gl_ClipDistance[2];
    gl_ClipDistance[3] = gl_in[idx].gl_ClipDistance[3];
    gl_ClipDistance[4] = gl_in[idx].gl_ClipDistance[4];
    gl_ClipDistance[5] = gl_in[idx].gl_ClipDistance[5];
};



////////////////////////////////////////////////////////////////////////////////
/// Emit Vertex Methods
////////////////////////////////////////////////////////////////////////////////


// Manual uv calculation
// - position in screen space (double resolution as generally used)
// - uv with uv.u normalized (0..1), uv.v unnormalized (0..pattern_length)
void emit_vertex(vec3 position, vec2 uv, int index)
{
    f_uv        = uv;
    f_color     = g_color[index];
    gl_Position = vec4((position.xy / resolution), position.z, 1.0);
    f_id        = g_id[index];
    f_thickness = g_thickness[index];
    set_clip(clip_planes, index);
    EmitVertex();
}

// For center point
void emit_vertex(vec3 position, vec2 uv)
{
    f_uv        = uv;
    f_color     = 0.5 * (g_color[1] + g_color[2]);
    gl_Position = vec4((position.xy / resolution), position.z, 1.0);
    f_id        = g_id[1];
    f_thickness = 0.5 * (g_thickness[1] + g_thickness[2]);
    EmitVertex();
}

// Debug
void emit_vertex(vec3 position, vec2 uv, int index, vec4 color)
{
    f_uv        = uv;
    f_color     = color;
    gl_Position = vec4((position.xy / resolution), position.z, 1.0);
    f_id        = g_id[index];
    f_thickness = g_thickness[index];
    EmitVertex();
}
void emit_vertex(vec3 position, vec2 uv, vec4 color)
{
    f_uv        = uv;
    f_color     = color;
    gl_Position = vec4((position.xy / resolution), position.z, 1.0);
    f_id        = g_id[1];
    f_thickness = 0.5 * (g_thickness[1] + g_thickness[2]);
    EmitVertex();
}


// With offset calculations for core line segment
void emit_vertex(vec3 position, vec2 offset, vec2 line_dir, vec2 uv, int index)
{
    emit_vertex(
        position + vec3(offset, 0),
        vec2(uv.x + px2uv * dot(line_dir, offset), uv.y),
        index
    );
}

void emit_vertex(vec3 position, vec2 offset, vec2 line_dir, vec2 uv)
{
    emit_vertex(
        position + vec3(offset, 0),
        vec2(uv.x + px2uv * dot(line_dir, offset), uv.y)
    );
}


////////////////////////////////////////////////////////////////////////////////
/// Draw full line segment
////////////////////////////////////////////////////////////////////////////////


// Generate line segment with 3 triangles
// - p1, p2 are the line start and end points in pixel space
// - miter_a and miter_b are the offsets from p1 and p2 respectively that 
//   generate the line segment quad. This should include thickness and AA
// - u1, u2 are the u values at p1 and p2. These should be in uv scale (px2uv applied)
// - thickness_aa1, thickness_aa2 are linewidth at p1 and p2 with AA added. They
//   double as uv.y values, which are in pixel space
// - v1 is the line direction of this segment (xy component)
void generate_line_segment(
        vec3 p1, vec2 miter_a, float u1, float thickness_aa1,
        vec3 p2, vec2 miter_b, float u2, float thickness_aa2,
        vec2 v1, float segment_length
    )
{
    float line_offset_a = dot(miter_a, v1);
    float line_offset_b = dot(miter_b, v1);

    if (abs(line_offset_a) + abs(line_offset_b) < segment_length+1){
        //  _________
        //  \       /
        //   \_____/
        //    <--->
        // Line segment is extensive (minimum width positive)

        emit_vertex(p1, +miter_a, v1, vec2(u1, -thickness_aa1), 1);
        emit_vertex(p1, -miter_a, v1, vec2(u1,  thickness_aa1), 1);
        emit_vertex(p2, +miter_b, v1, vec2(u2, -thickness_aa2), 2);
        emit_vertex(p2, -miter_b, v1, vec2(u2,  thickness_aa2), 2);
    } else {
        //  ____
        //  \  /
        //   \/
        //   /\
        //  >--<  
        // Line segment has zero or negative width on short side

        // Pulled apart, we draw these two triangles (vertical lines added)
        // ___      ___
        // \  |    |  /
        //  X |    | X
        //   \|    |/
        //
        // where X is u1/p1 (left) and u2/p2 (right) respectively. To avoid 
        // drawing outside the line segment due to AA padding, we cut off the 
        // left triangle on the right side at u2 via f_uv_minmax.y, and 
        // analogously the right triangle at u1 via f_uv_minmax.x.
        // These triangles will still draw over each other like this.

        // incoming side
        float old = f_uv_minmax.y;
        f_uv_minmax.y = u2;

        emit_vertex(p1, -miter_a, v1, vec2(u1, -thickness_aa1), 1);
        emit_vertex(p1, +miter_a, v1, vec2(u1, +thickness_aa1), 1);
        if (line_offset_a > 0){ // finish triangle on -miter_a side
            emit_vertex(p1, 2 * line_offset_a * v1 - miter_a, v1, vec2(u1, -thickness_aa1));
        } else {
            emit_vertex(p1, -2 * line_offset_a * v1 + miter_a, v1, vec2(u1, +thickness_aa1));
        }

        EndPrimitive();

        // outgoing side
        f_uv_minmax.x = u1;
        f_uv_minmax.y = old;
        
        emit_vertex(p2, -miter_b, v1, vec2(u2, -thickness_aa2), 2);
        emit_vertex(p2, +miter_b, v1, vec2(u2, +thickness_aa2), 2);
        if (line_offset_b < 0){ // finish triangle on -miter_b side
            emit_vertex(p2, 2 * line_offset_b * v1 - miter_b, v1, vec2(u2, -thickness_aa2));
        } else {
            emit_vertex(p2, -2 * line_offset_b * v1 + miter_b, v1, vec2(u2, +thickness_aa2));
        }
    }
}

// Debug Version
// Generates more triangles and colors them individually so they can be differentiated
void generate_line_segment_debug(
        vec3 p1, vec2 miter_a, float u1, float thickness_aa1,
        vec3 p2, vec2 miter_b, float u2, float thickness_aa2,
        vec2 v1, float segment_length
    )
{
    float line_offset_a = dot(miter_a, v1);
    float line_offset_b = dot(miter_b, v1);

    if (abs(line_offset_a) + abs(line_offset_b) < segment_length + 1 ){
        emit_vertex(p1 - vec3(miter_a, 0), vec2(u1 - px2uv * dot(v1, miter_a),  thickness_aa1), 1, vec4(1, 0, 0, 0.5));
        emit_vertex(p1 + vec3(miter_a, 0), vec2(u1 + px2uv * dot(v1, miter_a), -thickness_aa1), 1, vec4(1, 0, 0, 0.5));
        emit_vertex(p2 - vec3(miter_b, 0), vec2(u2 - px2uv * dot(v1, miter_b),  thickness_aa2), 2, vec4(1, 0, 0, 0.5));
            
        EndPrimitive();
            
        emit_vertex(p1 + vec3(miter_a, 0), vec2(u1 + px2uv * dot(v1, miter_a), -thickness_aa1), 1, vec4(0, 0, 1, 0.5));
        emit_vertex(p2 - vec3(miter_b, 0), vec2(u2 - px2uv * dot(v1, miter_b),  thickness_aa2), 2, vec4(0, 0, 1, 0.5));
        emit_vertex(p2 + vec3(miter_b, 0), vec2(u2 + px2uv * dot(v1, miter_b), -thickness_aa2), 2, vec4(0, 0, 1, 0.5));

        // Mid point version
        /*
        vec3 pc = 0.5 * (p1 + p2);
        vec2 miter_c = 0.5 * (miter_a + miter_b);
        float uc = 0.5 * (u1 + u2);
        float thickness_aac = 0.5 * (thickness_aa1 + thickness_aa2);

        if (dot(miter_a, v1) < dot(miter_b, v1)){
            emit_vertex(p1 + vec3(miter_a, 0), vec2(u1 + px2uv * dot(v1, miter_a), -thickness_aa1), 1, vec4(1, 0, 0, 0.5));
            emit_vertex(p1 - vec3(miter_a, 0), vec2(u1 - px2uv * dot(v1, miter_a),  thickness_aa1), 1, vec4(1, 0, 0, 0.5));
            emit_vertex(pc + vec3(miter_c, 0), vec2(uc + px2uv * dot(v1, miter_c), -thickness_aac), vec4(1, 0, 0, 0.5));
            
            EndPrimitive();
            
            emit_vertex(p1 - vec3(miter_a, 0), vec2(u1 - px2uv * dot(v1, miter_a),  thickness_aa1), 1, vec4(0, 1, 0, 0.5));
            emit_vertex(pc + vec3(miter_c, 0), vec2(uc + px2uv * dot(v1, miter_c), -thickness_aac), vec4(0, 1, 0, 0.5));
            emit_vertex(p2 - vec3(miter_b, 0), vec2(u2 - px2uv * dot(v1, miter_b),  thickness_aa2), 2, vec4(0, 1, 0, 0.5));
            
            EndPrimitive();

            emit_vertex(pc + vec3(miter_c, 0), vec2(uc + px2uv * dot(v1, miter_c), -thickness_aac), vec4(0, 0, 1, 0.5));
            emit_vertex(p2 - vec3(miter_b, 0), vec2(u2 - px2uv * dot(v1, miter_b),  thickness_aa2), 2, vec4(0, 0, 1, 0.5));
            emit_vertex(p2 + vec3(miter_b, 0), vec2(u2 + px2uv * dot(v1, miter_b), -thickness_aa2), 2, vec4(0, 0, 1, 0.5));

        } else {
            // subtractive side has more space
            emit_vertex(p1 - vec3(miter_a, 0), vec2(u1 - px2uv * dot(v1, miter_a), -thickness_aa1), 1, vec4(1, 0, 0, 0.5));
            emit_vertex(p1 + vec3(miter_a, 0), vec2(u1 + px2uv * dot(v1, miter_a),  thickness_aa1), 1, vec4(1, 0, 0, 0.5));
            emit_vertex(pc - vec3(miter_c, 0), vec2(uc - px2uv * dot(v1, miter_c), -thickness_aac), vec4(1, 0, 0, 0.5));
            
            EndPrimitive();
            
            emit_vertex(p1 + vec3(miter_a, 0), vec2(u1 + px2uv * dot(v1, miter_a),  thickness_aa1), 1, vec4(0, 1, 0, 0.5));
            emit_vertex(pc - vec3(miter_c, 0), vec2(uc - px2uv * dot(v1, miter_c), -thickness_aac), vec4(0, 1, 0, 0.5));
            emit_vertex(p2 + vec3(miter_b, 0), vec2(u2 + px2uv * dot(v1, miter_b),  thickness_aa2), 2, vec4(0, 1, 0, 0.5));
            
            EndPrimitive();

            emit_vertex(pc - vec3(miter_c, 0), vec2(uc - px2uv * dot(v1, miter_c), -thickness_aac), vec4(0, 0, 1, 0.5));
            emit_vertex(p2 + vec3(miter_b, 0), vec2(u2 + px2uv * dot(v1, miter_b),  thickness_aa2), 2, vec4(0, 0, 1, 0.5));
            emit_vertex(p2 - vec3(miter_b, 0), vec2(u2 - px2uv * dot(v1, miter_b), -thickness_aa2), 2, vec4(0, 0, 1, 0.5));
        }
        */
    } else {
        // incoming side
        float old = f_uv_minmax.y;
        f_uv_minmax.y = u2;

        emit_vertex(p1 - vec3(miter_a, 0), vec2(u1 - px2uv * dot(v1, miter_a), -thickness_aa1), 1, vec4(1, 0, 0, 0.5));
        emit_vertex(p1 + vec3(miter_a, 0), vec2(u1 + px2uv * dot(v1, miter_a),  thickness_aa1), 1, vec4(1, 0, 0, 0.5));
        if (line_offset_a > 0){ // finish triangle on -miter_a side
            emit_vertex(
                p1 + vec3(2 * line_offset_a * v1 - miter_a, 0), 
                vec2(u1 + px2uv * (2 * line_offset_a - dot(v1, miter_a)), -thickness_aa1), 
                1, vec4(1, 0, 0, 0.5)
            );
        } else {
            emit_vertex(
                p1 + vec3(-2 * line_offset_a * v1 + miter_a, 0), 
                vec2(u1 + px2uv * (-2 * line_offset_a + dot(v1, miter_a)), thickness_aa1), 
                1, vec4(1, 0, 0, 0.5)
            );
        }

        EndPrimitive();
        f_uv_minmax.x = u1;
        f_uv_minmax.y = old;

        // outgoing side
        emit_vertex(p2 - vec3(miter_b, 0), vec2(u2 - px2uv * dot(v1, miter_b), -thickness_aa2), 2, vec4(0, 0, 1, 0.5));
        emit_vertex(p2 + vec3(miter_b, 0), vec2(u2 + px2uv * dot(v1, miter_b),  thickness_aa2), 2, vec4(0, 0, 1, 0.5));
        if (line_offset_b < 0){ // finish triangle on -miter_b side
            emit_vertex(
                p2 + vec3(2 * line_offset_b * v1 - miter_b, 0), 
                vec2(u2 + px2uv * (2 * line_offset_b - dot(v1, miter_b)), -thickness_aa2), 
                2, vec4(0, 0, 1, 0.5)
            );
        } else {
            emit_vertex(
                p2 + vec3(-2 * line_offset_b * v1 + miter_b, 0), 
                vec2(u2 + px2uv * (-2 * line_offset_b + dot(v1, miter_b)), thickness_aa2), 
                2, vec4(0, 0, 1, 0.5)
            );
        }
    }
}


////////////////////////////////////////////////////////////////////////////////
/// Patterned line
////////////////////////////////////////////////////////////////////////////////



void draw_patterned_line(bool isvalid[4])
{
    // This sets a min and max value foir uv.u at which anti-aliasing is forced.
    // With this setting it's never triggered.
    f_uv_minmax = vec2(-1.0e12, 1.0e12);

    // get the four vertices passed to the shader
    // without FAST_PATH the conversions happen on the CPU
    vec3 p0 = screen_space(gl_in[0].gl_Position); // start of previous segment
    vec3 p1 = screen_space(gl_in[1].gl_Position); // end of previous segment, start of current segment
    vec3 p2 = screen_space(gl_in[2].gl_Position); // end of current segment, start of next segment
    vec3 p3 = screen_space(gl_in[3].gl_Position); // end of next segment

    // linewidth with padding for anti aliasing
    float thickness_aa1 = g_thickness[1] + AA_THICKNESS;
    float thickness_aa2 = g_thickness[2] + AA_THICKNESS;

    // determine the direction of each of the 3 segments (previous, current, next)
    vec3 v1 = p2 - p1;
    float segment_length = length(v1.xy);
    v1 /= segment_length;
    vec3 v0 = v1;
    vec3 v2 = v1;

    if (p1 != p0 && isvalid[0]) {
        v0 = (p1 - p0) / length((p1 - p0).xy);
    }
    if (p3 != p2 && isvalid[3]) {
        v2 = (p3 - p2) / length((p3 - p2).xy);
    }

    // determine the normal of each of the 3 segments (previous, current, next)
    vec2 n0 = vec2(-v0.y, v0.x);
    vec2 n1 = vec2(-v1.y, v1.x);
    vec2 n2 = vec2(-v2.y, v2.x);

    // The pattern may look like this:
    //
    //      pattern_sections index
    //     0        1        2    3
    //     |########|        |####|    |(repeat)
    //   left     right    left right
    //        variable in loop
    //
    // We first figure out the extended size of this line segment, starting
    // from the left end of the first relevant pattern section and ending at the
    // right end of the last relevant pattern section. E.g.:
    //
    //           g_lastlen[1]                  g_lastlen[2]       (2x pixel coords)
    //             edge1                         edge2            (1x pixel coords)
    //               |                             |
    //  |####|    |########|        |####|    |########|        |####|    |########|
    //            | first  |                  | last   |
    //            | pattern|                  | pattern|
    //            | section|                  | section|
    //          start                                 stop        (pattern coords (normalized))
    //
    // start_width and stop_width are the widths of the start and stop sections.
    float start, stop, start_width, stop_width, temp;
    float left, right, edge1, edge2, inv_pl, left_offset, right_offset;

    // normalized single pixel scale
    start = g_lastlen[2] * px2uv;
    stop  = g_lastlen[1] * px2uv;
    start_width = 0.0;
    stop_width  = 0.0;

    inv_pl = 1.0 / pattern_length;
    edge1 = 0.5 * g_lastlen[1];
    edge2 = 0.5 * g_lastlen[2];

    int pattern_texsize = textureSize(pattern_sections, 0);

    for (int i = 0; i < pattern_texsize - 1; i = i + 2)
    {
        left  = texelFetch(pattern_sections, i,   0).x;
        right = texelFetch(pattern_sections, i+1, 0).x;

        // update left side
        temp = ceil((edge1 - right) * inv_pl) + left * inv_pl;
        if (temp < start)
            start_width = right - left;
        start = min(start, temp);

        // update right side
        temp = floor((edge2 - left) * inv_pl) + right * inv_pl;
        if (temp > stop)
            stop_width = right - left;
        stop = max(stop, temp);
    }
    // Technically start and stop should be offset by another
    // 1 / (2 * textureSize(pattern)) so the line segment is normalized to
    // pattern texel centers rather than the left edge, but we have enough
    // AA_THICKNESS for it to be irrelevant.

    // if there is something to draw...
    if (stop > start){

        // setup for sharp corners
        //               miter_a / miter_b
        //           ___         ↑      ___
        //            |         .|.      |
        // length_a  _|_      .' | '.   _|_  length_b
        //                  .'   |   '.
        //                .'     |     '.
        //              .'     .' '.     '.
        //                   .'     '.
        //
        vec2 miter_a = normalize(n0 + n1);
        vec2 miter_b = normalize(n1 + n2);
        float length_a = 1.0 / dot(miter_a, n1);
        float length_b = 1.0 / dot(miter_b, n1);

        // if we have a sharp corner:
        //   max(g_thickness[1], proj(length_a * miter_a, v1)) without AA padding
        // otherwise just g_thickness[1]
        left_offset  = g_thickness[1] * max(1.0, float(dot(v0.xy, v1.xy) >= MITER_LIMIT) * abs(dot(miter_a, v1.xy)) * length_a);
        right_offset = g_thickness[2] * max(1.0, float(dot(v1.xy, v2.xy) >= MITER_LIMIT) * abs(dot(miter_b, v1.xy)) * length_b);

        // Finish length_a/b
        length_a *= thickness_aa1;
        length_b *= thickness_aa2;

        // if the "on" section of the pattern at start extends over the whole
        // potential corner we draw the corner. If not we extend the line.
        //
        //               g_lastlen[1]
        //               . - |---.----------
        //               :   |   :
        //               :   |   :
        //               :   |   :
        //               : - '---:----------
        //             start     :
        //               start + start_width
        //
        // Equivalent to
        // (start * pattern_length                   < g_lastlen[1] - left_offset) &&
        // (start * pattern_length + 2 * start_width > g_lastlen[1] + left_offset)
        if (
            isvalid[0] &&
            abs(2 * start * pattern_length - g_lastlen[1] + start_width) < (start_width - left_offset)
            )
        {
            // if the corner is too sharp, we do a truncated miter join
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
            if( dot( v0.xy, v1.xy ) < MITER_LIMIT ){

                bool gap = dot( v0.xy, n1 ) > 0;

                // Another view of a truncated join (with lines joining like a V).
                //
                //         uv.y = 0 in line segment
                //          /
                //         .  -- uv.x = u0 in truncated join
                //       .' '.     uv.y = thickness in line segment
                //     .'     '.  /   uv.y = thickness + AA_THICKNESS in line segment
                //   .'_________'.   /_ uv.x = start in truncated join (constraint for AA)
                // .'_____________'.  _ uv.x = -proj_AA in truncated join (derived from line segment + constraint)
                // |               |
                // |_______________|  _ uv.x = -proj_AA - AA_THICKNESS in truncated join
                //
                // Here the / annotations come from the connecting line segment and are to
                // be viewed on the diagonal. The -- and _ annotations are relevant to the
                // truncated join and viewed vertically.
                // Note that `start` marks off-to-on edge in the pattern. So values
                // greater than `start` will be drawn and smaller will be discarded.
                // With how we pick start and get in this branch u0 will always be
                // in a solidly drawn region of the pattern.
                float u0      = start + thickness_aa1 * abs(dot(miter_a, n1)) * px2uv;
                float proj_AA = start - AA_THICKNESS  * abs(dot(miter_a, n1)) * px2uv;

                // to save some space
                vec2 off0   = thickness_aa1 * n0;
                vec2 off1   = thickness_aa1 * n1;
                vec2 off_AA = AA_THICKNESS * miter_a;
                float u_AA  = AA_THICKNESS * px2uv;

                if(gap){
                    emit_vertex(p1,                          vec2(u0,                          0), 1);
                    emit_vertex(p1 + vec3(off0, 0),          vec2(proj_AA,        +thickness_aa1), 1);
                    emit_vertex(p1 + vec3(off1, 0),          vec2(proj_AA,        -thickness_aa1), 1);
                    emit_vertex(p1 + vec3(off0 + off_AA, 0), vec2(proj_AA - u_AA, +thickness_aa1), 1);
                    emit_vertex(p1 + vec3(off1 + off_AA, 0), vec2(proj_AA - u_AA, -thickness_aa1), 1);
                    EndPrimitive();
                }else{
                    emit_vertex(p1,                          vec2(u0,                          0), 1);
                    emit_vertex(p1 - vec3(off1, 0),          vec2(proj_AA,        +thickness_aa1), 1);
                    emit_vertex(p1 - vec3(off0, 0),          vec2(proj_AA,        -thickness_aa1), 1);
                    emit_vertex(p1 - vec3(off1 + off_AA, 0), vec2(proj_AA - u_AA, +thickness_aa1), 1);
                    emit_vertex(p1 - vec3(off0 + off_AA, 0), vec2(proj_AA - u_AA, -thickness_aa1), 1);
                    EndPrimitive();
                }

                miter_a = n1;
                length_a = thickness_aa1;
                start = g_lastlen[1] * px2uv;

            } else { // otherwise we do a sharp join
                start = g_lastlen[1] * px2uv;
            }
        } else {
            // We don't need to treat the join, so resize the line segment to
            // the drawn region. (This may extend the line too)
            miter_a = n1;
            length_a = thickness_aa1;
            // If the line starts with this segment or the center of the "on"
            // section of the pattern is in this segment, we draw it, else
            // we skip past the first "on" section.
            if (!isvalid[0] || (start > (g_lastlen[1] - start_width) * px2uv))
                start = start - AA_THICKNESS * px2uv;
            else
                start = start + (start_width + 0.5 * AA_THICKNESS) * inv_pl;
            p1 += (2 * start * pattern_length - g_lastlen[1]) * v1;
        }


        // The other end of the line is analogous
        // (stop * pattern_length - 2 * stop_width < g_lastlen[2] - right_offset) &&
        // (stop * pattern_length                  > g_lastlen[2] + right_offset)
        // (stop * pattern_length - stop_width - g_lastlen[2] <  (stop_width - right_offset)) &&
        // (stop * pattern_length - stop_width - g_lastlen[2] > -(stop_width - right_offset))
        if (
            isvalid[3] &&
            abs(2*stop * pattern_length - g_lastlen[2] - stop_width) < (stop_width - right_offset)
            )
        {
            if( dot( v1.xy, v2.xy ) < MITER_LIMIT ){
                // setup for truncated join (flat line end)
                miter_b = n1;
                length_b = thickness_aa2;
                stop = g_lastlen[2] * px2uv;
            } else {
                // setup for sharp join
                stop = g_lastlen[2] * px2uv;
            }
        } else {
            miter_b = n1;
            length_b = thickness_aa2;
            if (isvalid[3] && (stop > (g_lastlen[2] + stop_width) * px2uv))
                stop = stop - (stop_width + 0.5 * AA_THICKNESS) * inv_pl;
            else
                stop = stop + AA_THICKNESS * px2uv;
            p2 += (2 * stop * pattern_length - g_lastlen[2]) * v1;
        }

        // to save some space
        miter_a *= length_a;
        miter_b *= length_b;

        // If this segment starts or ends a line we force anti-aliasing to
        // happen at the respective edge.
        if (!isvalid[0])
            f_uv_minmax.x = g_lastlen[1] * px2uv;
        if (!isvalid[3])
            f_uv_minmax.y = g_lastlen[2] * px2uv;

        // generate rectangle for this segment

        // Normal Version
        generate_line_segment(
            p1, miter_a, start, thickness_aa1,
            p2, miter_b, stop, thickness_aa2,
            v1.xy, segment_length
        );

        // Debug - show each triangle
        // generate_line_segment_debug(
        //     p1, miter_a, start, thickness_aa1, 
        //     p2, miter_b, stop, thickness_aa2, 
        //     v1.xy, segment_length
        // );

    }

    return;
}



////////////////////////////////////////////////////////////////////////////////
/// Solid lines
////////////////////////////////////////////////////////////////////////////////



void draw_solid_line(bool isvalid[4])
{
    // This sets a min and max value foir uv.u at which anti-aliasing is forced.
    // With this setting it's never triggered.
    f_uv_minmax = vec2(-1.0e12, 1.0e12);

    // get the four vertices passed to the shader
    // without FAST_PATH the conversions happen on the CPU
    vec3 p0 = screen_space(gl_in[0].gl_Position); // start of previous segment
    vec3 p1 = screen_space(gl_in[1].gl_Position); // end of previous segment, start of current segment
    vec3 p2 = screen_space(gl_in[2].gl_Position); // end of current segment, start of next segment
    vec3 p3 = screen_space(gl_in[3].gl_Position); // end of next segment

    // linewidth with padding for anti aliasing
    float thickness_aa1 = g_thickness[1] + AA_THICKNESS;
    float thickness_aa2 = g_thickness[2] + AA_THICKNESS;

    // determine the direction of each of the 3 segments (previous, current, next)
    vec3 v1 = p2 - p1;
    float segment_length = length(v1.xy);
    v1 /= segment_length;
    vec3 v0 = v1;
    vec3 v2 = v1;

    if (p1 != p0 && isvalid[0]) {
        v0 = (p1 - p0) / length((p1 - p0).xy);
    }
    if (p3 != p2 && isvalid[3]) {
        v2 = (p3 - p2) / length((p3 - p2).xy);
    }

    // determine the normal of each of the 3 segments (previous, current, next)
    vec2 n0 = vec2(-v0.y, v0.x);
    vec2 n1 = vec2(-v1.y, v1.x);
    vec2 n2 = vec2(-v2.y, v2.x);

    // Setup for sharp corners (see above)
    vec2 miter_a = normalize(n0 + n1);
    vec2 miter_b = normalize(n1 + n2);
    float length_a = thickness_aa1 / dot(miter_a, n1);
    float length_b = thickness_aa2 / dot(miter_b, n1);

    // truncated miter join (see above)
    if( dot( v0.xy, v1.xy ) < MITER_LIMIT ){
        bool gap = dot( v0.xy, n1 ) > 0;
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
            emit_vertex(p1,                          vec2(+ u0,                          0), 1);
            emit_vertex(p1 + vec3(off0, 0),          vec2(- proj_AA,        +thickness_aa1), 1);
            emit_vertex(p1 + vec3(off1, 0),          vec2(- proj_AA,        -thickness_aa1), 1);
            emit_vertex(p1 + vec3(off0 + off_AA, 0), vec2(- proj_AA - u_AA, +thickness_aa1), 1);
            emit_vertex(p1 + vec3(off1 + off_AA, 0), vec2(- proj_AA - u_AA, -thickness_aa1), 1);
            EndPrimitive();
        }else{
            emit_vertex(p1,                          vec2(+ u0,                          0), 1);
            emit_vertex(p1 - vec3(off1, 0),          vec2(- proj_AA,        +thickness_aa1), 1);
            emit_vertex(p1 - vec3(off0, 0),          vec2(- proj_AA,        -thickness_aa1), 1);
            emit_vertex(p1 - vec3(off1 + off_AA, 0), vec2(- proj_AA - u_AA, +thickness_aa1), 1);
            emit_vertex(p1 - vec3(off0 + off_AA, 0), vec2(- proj_AA - u_AA, -thickness_aa1), 1);
            EndPrimitive();
        }

        miter_a = n1;
        length_a = thickness_aa1;
    }

    // we have miter join on next segment, do normal line cut off
    if( dot( v1.xy, v2.xy ) <= MITER_LIMIT ){
        miter_b = n1;
        length_b = thickness_aa2;
    }

    // Without a pattern (linestyle) we use uv.u directly as a signed distance
    // field. We only care about u1 - u0 being the correct distance and
    // u0 > AA_THICHKNESS at all times.
    float u1 = 10000.0;
    float u2 = u1 + segment_length;

    miter_a *= length_a;
    miter_b *= length_b;

    // To treat line starts and ends we elongate the line in the respective
    // direction and enforce an AA border at the original start/end position
    // with f_uv_minmax.
    if (!isvalid[0])
    {
        float corner_offset = max(0, abs(dot(miter_b, v1.xy)) - segment_length);
        f_uv_minmax.x = px2uv * (u1 - corner_offset);
        p1 -= (corner_offset + AA_THICKNESS) * v1;
        u1 -= (corner_offset + AA_THICKNESS);
        segment_length += corner_offset;
    }

    if (!isvalid[3])
    {
        float corner_offset = max(0, abs(dot(miter_a, v1.xy)) - segment_length);
        f_uv_minmax.y = px2uv * (u2 + corner_offset);
        p2 += (corner_offset + AA_THICKNESS) * v1;
        u2 += (corner_offset + AA_THICKNESS);
        segment_length += corner_offset;
    }


    // Generate line segment
    u1 *= px2uv;
    u2 *= px2uv;

    // Normal Version
    generate_line_segment(
        p1, miter_a, u1, thickness_aa1,
        p2, miter_b, u2, thickness_aa2,
        v1.xy, segment_length
    );

    // Debug - show each triangle
    // generate_line_segment_debug(
    //     p1, miter_a, u1, thickness_aa1,
    //     p2, miter_b, u2, thickness_aa2,
    //     v1.xy, segment_length
    // );

    return;
}



////////////////////////////////////////////////////////////////////////////////
/// Main
////////////////////////////////////////////////////////////////////////////////



void main(void)
{
    // These need to be set but don't have reasonable values here
    o_view_pos = vec3(0);
    o_normal = vec3(0);

    // we generate very thin lines for linewidth 0, so we manually skip them:
    if (g_thickness[1] == 0.0 && g_thickness[2] == 0.0) {
        return;
    }


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
    draw_solid_line(isvalid);
#else
    draw_patterned_line(isvalid);
#endif

    return;
}
