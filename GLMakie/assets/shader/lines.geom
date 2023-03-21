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

out vec3 o_view_pos;
out vec3 o_normal;

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
float ifelse(float condition, float true_val, float false_val){
    return condition * (true_val - false_val) + false_val;
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
/// Patterned line
////////////////////////////////////////////////////////////////////////////////



void draw_patterned_line(bool isvalid[4])
{
    // This sets a min and max value foir uv.u at which anti-aliasing is forced.
    // With this setting it's never triggered.
    f_uv_minmax = vec2(-1.0e12, 1.0e12);

    // get the four vertices passed to the shader
    // without FAST_PATH the conversions happen on the CPU
    vec2 p0 = gl_in[0].gl_Position.xy; // start of previous segment
    vec2 p1 = gl_in[1].gl_Position.xy; // end of previous segment, start of current segment
    vec2 p2 = gl_in[2].gl_Position.xy; // end of current segment, start of next segment
    vec2 p3 = gl_in[3].gl_Position.xy; // end of next segment

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
        start_width = ifelse(temp < start, right - left, start_width);
        start = min(start, temp);

        // update right side
        temp = floor((edge2 - left) * inv_pl) + right * inv_pl;
        stop_width = ifelse(temp > stop, right - left, stop_width);
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
        left_offset  = g_thickness[1] * max(1.0, float(dot(v0, v1) >= MITER_LIMIT) * abs(dot(miter_a, v1)) * length_a);
        right_offset = g_thickness[2] * max(1.0, float(dot(v1, v2) >= MITER_LIMIT) * abs(dot(miter_b, v1)) * length_b);

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
            ) {

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
            if( dot( v0, v1 ) < MITER_LIMIT ){

                bool gap = dot( v0, n1 ) > 0;

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
            start = ifelse(
                !isvalid[0] || (start > (g_lastlen[1] - start_width) * px2uv),
                start - AA_THICKNESS * px2uv,
                start + (start_width + 0.5 * AA_THICKNESS) * inv_pl
            );
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
            ) {
            if( dot( v1, v2 ) < MITER_LIMIT ){
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
            stop = ifelse(
                isvalid[3] && (stop > (g_lastlen[2] + stop_width) * px2uv),
                stop - (stop_width + 0.5 * AA_THICKNESS) * inv_pl,
                stop + AA_THICKNESS * px2uv
            );
            p2 += (2 * stop * pattern_length - g_lastlen[2]) * v1;
        }

        // to save some space
        miter_a *= length_a;
        miter_b *= length_b;

        // If this segment starts or ends a line we force anti-aliasing to
        // happen at the respective edge.
        f_uv_minmax.x = ifelse(isvalid[0], f_uv_minmax.x, g_lastlen[1] * px2uv);
        f_uv_minmax.y = ifelse(isvalid[3], f_uv_minmax.y, g_lastlen[2] * px2uv);

        // generate rectangle for this segment
        emit_vertex(p1 + miter_a, vec2(start + dot(v1, miter_a) * px2uv, -thickness_aa1), 1);
        emit_vertex(p1 - miter_a, vec2(start - dot(v1, miter_a) * px2uv,  thickness_aa1), 1);
        emit_vertex(p2 + miter_b, vec2(stop  + dot(v1, miter_b) * px2uv, -thickness_aa2), 2);
        emit_vertex(p2 - miter_b, vec2(stop  - dot(v1, miter_b) * px2uv,  thickness_aa2), 2);
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
    vec2 p0 = screen_space(gl_in[0].gl_Position); // start of previous segment
    vec2 p1 = screen_space(gl_in[1].gl_Position); // end of previous segment, start of current segment
    vec2 p2 = screen_space(gl_in[2].gl_Position); // end of current segment, start of next segment
    vec2 p3 = screen_space(gl_in[3].gl_Position); // end of next segment

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


    // Without a pattern (linestyle) we use uv.u directly as a signed distance
    // field. We only care about u1 - u0 being the correct distance and
    // u0 > AA_THICHKNESS at all times.
    float u1 = 10.0 * AA_THICKNESS + thickness_aa1 + thickness_aa2;
    float u2 = u1 + segment_length;

    // Fix #1129
    // When points are very close together the AA padding propagated through
    // shallow miter joins in v1 direction can draw outside the lines region.
    //
    //         | | <- extrusion in v1 direction from AA padding
    // .----------
    // | .--------
    // | |'.    ##  <- potentially draws outside
    // | |  '.  ##  <- the current line segment
    // | |    '.--
    // | |     | .
    // | |     | |
    //
    // Here we treat this by adding an artificial AA boundary at the line start
    // and end. Note that always doing this will introduce AA where lines should
    // smoothly connect.
    f_uv_minmax.x = ifelse(
        segment_length < abs(length_a * dot(miter_a, v1)),
        (u1 - g_thickness[1] * abs(dot(miter_a, v1) / dot(miter_a, n1))) * px2uv,
        f_uv_minmax.x
    );
    f_uv_minmax.y = ifelse(
        segment_length < abs(length_b * dot(miter_b, v1)),
        (u2 + g_thickness[2] * abs(dot(miter_b, v1) / dot(miter_b, n1))) * px2uv,
        f_uv_minmax.y
    );

    // To treat line starts and ends we elongate the line in the respective
    // direction and enforce an AA border at the original start/end position
    // with f_uv_minmax.
    float is_start = float(!isvalid[0]);
    f_uv_minmax.x = ifelse(is_start, px2uv * u1, f_uv_minmax.x);
    p1 -= is_start * AA_THICKNESS * v1;
    u1 -= is_start * AA_THICKNESS;

    float is_end = float(!isvalid[3]);
    f_uv_minmax.y = ifelse(is_end, px2uv * u2, f_uv_minmax.y);
    u2 += is_end * AA_THICKNESS;
    p2 += is_end * AA_THICKNESS * v1;

    // to save some space
    miter_a *= length_a;
    miter_b *= length_b;

    // Generate line segment (with uv.u being signed distance field values)
    emit_vertex(p1 + miter_a, vec2(px2uv * (u1 + dot(v1, miter_a)), -thickness_aa1), 1);
    emit_vertex(p1 - miter_a, vec2(px2uv * (u1 - dot(v1, miter_a)),  thickness_aa1), 1);
    emit_vertex(p2 + miter_b, vec2(px2uv * (u2 + dot(v1, miter_b)), -thickness_aa2), 2);
    emit_vertex(p2 - miter_b, vec2(px2uv * (u2 - dot(v1, miter_b)),  thickness_aa2), 2);

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

    // We mark each of the four vertices as valid or not. Vertices can be
    // marked invalid on input (eg, if they contain NaN). We also mark them
    // invalid if they repeat in the index buffer. This allows us to render to
    // the very ends of a polyline without clumsy buffering the position data on the
    // CPU side by repeating the first and last points via the index buffer. It
    // just requires a little care further down to avoid degenerate normals.
    bool isvalid[4] = bool[](
        g_valid_vertex[0] == 1,
        g_valid_vertex[1] == 1,
        g_valid_vertex[2] == 1,
        g_valid_vertex[3] == 1
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
