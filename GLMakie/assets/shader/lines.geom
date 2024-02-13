{{GLSL_VERSION}}
{{GLSL_EXTENSIONS}}
{{SUPPORTED_EXTENSIONS}}

struct Nothing{ //Nothing type, to encode if some variable doesn't contain any data
    bool _; //empty structs are not allowed
};

{{define_fast_path}}

layout(lines_adjacency) in;
layout(triangle_strip, max_vertices = 4) out;

in vec4 g_color[];
in float g_lastlen[];
in uvec2 g_id[];
in int g_valid_vertex[];
in float g_thickness[];

out highp float f_quad_sdf0;
out highp vec3 f_quad_sdf1;
out highp float f_quad_sdf2;
out vec2 f_truncation;
out float f_linestart;
out float f_linelength;

flat out vec2 f_extrusion;
flat out float f_linewidth;
flat out vec4 f_pattern_overwrite;
flat out vec2 f_discard_limit;
flat out uvec2 f_id;
flat out vec4 f_color1;
flat out vec4 f_color2;
flat out float f_cumulative_length;

out vec3 o_view_pos;
out vec3 o_view_normal;

{{pattern_type}} pattern;
uniform float pattern_length;
uniform vec2 resolution;

// Constants
const float MITER_LIMIT = -0.4;
const float AA_RADIUS = 0.8;
const float AA_THICKNESS = 4.0 * AA_RADIUS;
// NOTE: if MITER_LIMIT becomes a variable AA_THICKNESS needs to scale with the joint extrusion

vec3 screen_space(vec4 vertex) {
    return vec3((0.5 * vertex.xy / vertex.w + 0.5) * resolution, vertex.z / vertex.w);
}

struct LineVertex {
    vec3 position;
    int index;

    float quad_sdf0;
    vec3 quad_sdf1;
    float quad_sdf2;
    vec2 truncation;

    float linestart;
    float linelength;
};

void emit_vertex(LineVertex vertex) {
    gl_Position    = vec4((2.0 * vertex.position.xy / resolution) - 1.0, vertex.position.z, 1.0);
    f_quad_sdf0    = vertex.quad_sdf0;
    f_quad_sdf1    = vertex.quad_sdf1;
    f_quad_sdf2    = vertex.quad_sdf2;
    f_truncation   = vertex.truncation;
    f_linestart    = vertex.linestart;
    f_linelength   = vertex.linelength;
    f_id           = g_id[vertex.index];
    EmitVertex();
}

vec2 normal_vector(in vec2 v) { return vec2(-v.y, v.x); }
vec2 normal_vector(in vec3 v) { return vec2(-v.y, v.x); }


////////////////////////////////////////////////////////////////////////////////
//                              Linestyle Support                             //
////////////////////////////////////////////////////////////////////////////////


vec2 process_pattern(Nothing pattern, bool[4] isvalid, mat2 extrusion, float halfwidth) {
    // do not adjust stuff
    f_pattern_overwrite = vec4(-1e12, 1.0, 1e12, 1.0);
    return vec2(0);
}
vec2 process_pattern(sampler2D pattern, bool[4] isvalid, mat2 extrusion, float halfwidth) {
    // TODO
    // This is not a case that's used at all yet. Maybe consider it in the future...
    f_pattern_overwrite = vec4(-1e12, 1.0, 1e12, 1.0);
    return vec2(0);
}

vec2 process_pattern(sampler1D pattern, bool[4] isvalid, mat2 extrusion, float halfwidth) {
    // samples:
    //   -ext1  p1 ext1    -ext2 p2 ext2
    //      1   2   3        4   5   6
    // prev | joint |  this  | joint | next

    // default to no overwrite
    f_pattern_overwrite.x = -1e12;
    f_pattern_overwrite.z = +1e12;
    vec2 adjust = vec2(0);
    float width = 2.0 * halfwidth;
    float uv_scale = 1.0 / (width * pattern_length);
    float left, center, right;

    if (isvalid[0]) {
        // using this would allow dots to never bend across a joint but currently
        // results in artifacts in dense patterned lines (e.g. bracket tests)
        // float offset = max(abs(extrusion[0][0]), halfwidth);
        float offset = abs(extrusion[0][0]);
        left   = width * texture(pattern, uv_scale * (g_lastlen[1] - offset)).x;
        center = width * texture(pattern, uv_scale * (g_lastlen[1]         )).x;
        right  = width * texture(pattern, uv_scale * (g_lastlen[1] + offset)).x;

        // cases:
        // ++-, +--, +-+ => elongate backwards
        // -++, --+      => shrink forward
        // +++, ---, -+- => freeze around joint

        if ((left > 0 && center > 0 && right > 0) || (left < 0 && right < 0)) {
            // default/freeze
            // overwrite until one AA gap past the corner/joint
            f_pattern_overwrite.x = uv_scale * (g_lastlen[1] + abs(extrusion[0][0]) + AA_RADIUS);
            // using the sign of the center to decide between drawing or not drawing
            f_pattern_overwrite.y = sign(center);
        } else if (left > 0) {
            // elongate backwards
            adjust.x = -1.0;
        } else if (right > 0) {
            // shorten forward
            adjust.x = 1.0;
        } else {
            // default - see above
            f_pattern_overwrite.x = uv_scale * (g_lastlen[1] + abs(extrusion[0][0]) + AA_RADIUS);
            f_pattern_overwrite.y = sign(center);
        }

    } // else there is no left segment, no left join, so no overwrite

    if (isvalid[3]) {
        // float offset = max(abs(extrusion[1][0]), halfwidth + AA_RADIUS);
        float offset = abs(extrusion[1][0]);
        left   = width * texture(pattern, uv_scale * (g_lastlen[2] - offset)).x;
        center = width * texture(pattern, uv_scale * (g_lastlen[2]         )).x;
        right  = width * texture(pattern, uv_scale * (g_lastlen[2] + offset)).x;

        if ((left > 0 && center > 0 && right > 0) || (left < 0 && right < 0)) {
            // default/freeze
            f_pattern_overwrite.z = uv_scale * (g_lastlen[2] - abs(extrusion[1][0]) - AA_RADIUS);
            f_pattern_overwrite.w = sign(center);
        } else if (left > 0) {
            // shrink backwards
            adjust.y = -1.0;
        } else if (right > 0) {
            // elongate forward
            adjust.y = 1.0;
        } else {
            // default - see above
            f_pattern_overwrite.z = uv_scale * (g_lastlen[2] - abs(extrusion[1][0]) - AA_RADIUS);
            f_pattern_overwrite.w = sign(center);
        }
    }

    return adjust;
}


////////////////////////////////////////////////////////////////////////////////
//                                    Main                                    //
////////////////////////////////////////////////////////////////////////////////


void main(void)
{
    // These need to be set but don't have reasonable values here
    o_view_pos = vec3(0);
    o_view_normal = vec3(0);

    // Shouldn't be necessary anymore but it may still be worth skipping work
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

    // Time to generate our quad. For this we need to find out how far a join
    // extends the line. First let's get some vectors we need.

    // Get the four vertices passed to the shader in pixel space.
    // Without FAST_PATH the conversions happen on the CPU
#ifdef FAST_PATH
    vec3 p0 = screen_space(gl_in[0].gl_Position); // start of previous segment
    vec3 p1 = screen_space(gl_in[1].gl_Position); // end of previous segment, start of current segment
    vec3 p2 = screen_space(gl_in[2].gl_Position); // end of current segment, start of next segment
    vec3 p3 = screen_space(gl_in[3].gl_Position); // end of next segment
#else
    vec3 p0 = gl_in[0].gl_Position.xyz; // start of previous segment
    vec3 p1 = gl_in[1].gl_Position.xyz; // end of previous segment, start of current segment
    vec3 p2 = gl_in[2].gl_Position.xyz; // end of current segment, start of next segment
    vec3 p3 = gl_in[3].gl_Position.xyz; // end of next segment
#endif

    // Since we are measuring from the center of the line we will need half
    // the thickness/linewidth for most things.
    // Note that if a line becomes very thin the alpha value generated by the
    // signed distance field (SDF) will be location dependent, causing the line
    // to flicker if it moves. It also becomes darker than it should be due to
    // the AA smoothstep becoming unbalanced (< AA_RADIUS inside, full AA_RADIUS
    // outside). To avoid these issues we reduce alpha directly rather than
    // shrinking the linewidth further at some point.
    float halfwidth = 0.5 * max(AA_RADIUS, g_thickness[1]);

    // determine the direction of each of the 3 segments (previous, current, next)
    vec3 v1 = (p2 - p1);
    float segment_length = length(v1.xy);
    v1 /= segment_length;

    // depth is irrelevant for these
    vec2 v0 = v1.xy;
    vec2 v2 = v1.xy;
    if (p1 != p0 && isvalid[0])
        v0 = normalize(p1.xy - p0.xy);
    if (p3 != p2 && isvalid[3])
        v2 = normalize(p3.xy - p2.xy);

    // determine the normal of each of the 3 segments (previous, current, next)
    vec2 n0 = normal_vector(v0);
    vec2 n1 = normal_vector(v1);
    vec2 n2 = normal_vector(v2);

    // Miter normals (normal of truncated edge / vector to sharp corner)
    vec2 miter_n1 = normalize(n0 + n1);
    vec2 miter_n2 = normalize(n1 + n2);

    // miter vectors (line vector matching miter normal)
    vec2 miter_v1 = -normal_vector(miter_n1);
    vec2 miter_v2 = -normal_vector(miter_n2);

    // distance between p1/2 and respective sharp corner
    float miter_offset1 = dot(miter_n1, n1); // = dot(miter_v1, v1)
    float miter_offset2 = dot(miter_n2, n1); // = dot(miter_v2, v1)

    // Are we truncating the joint?
    bvec2 is_truncated = bvec2(
        dot(v0, v1.xy) < MITER_LIMIT,
        dot(v1.xy, v2) < MITER_LIMIT
    );

    // How far the line needs to extend in v1 directionto accomodate the joint.
    // The line quad (w/o width) is given by:
    //          p1 + w * extrusion[0][1] * v1  -----  p2 + w * extrusion[1][1] * v1
    //                    |                                     |
    //          p1 + w * extrusion[0][0] * v1  -----  p2 + w * extrusion[1][0] * v1
    // where w = halfwidth for drawn corners and w = halfwidth + AA_THICKNESS
    // for the corners of quad.
    mat2 extrusion;

    if (is_truncated[0]) {
        // need to extend segment to include previous segments corners for truncated join
        extrusion[0][1] = -abs(miter_offset1 / dot(miter_v1, n1));
        extrusion[0][0] = extrusion[0][1];
    } else {
        // shallow/spike join needs to include point where miter normal meets outer line edge
        extrusion[0][1] = dot(miter_n1, v1.xy) / miter_offset1;
        extrusion[0][0] = -extrusion[0][1];
    }

    if (is_truncated[1]) {
        // extrusion[1] = halfwidth * miter_offset2 / dot(miter_v2, n1);
        extrusion[1][1] = abs(miter_offset2 / dot(miter_n2, v1.xy));
        extrusion[1][0] = extrusion[1][1];
    } else {
        extrusion[1][1] = dot(miter_n2, v1.xy) / miter_offset2;
        extrusion[1][0] = -extrusion[1][1];
    }


    // Miter joints can cause vertices to move past each other, e.g.
    //  _______
    //  '.   .'
    //     x
    //   '---'
    // To avoid drawing the "inverted" section we move the relevant
    // vertices to the crossing point (x) using this scaling factor.
    vec2 shape_factor = vec2(
        max(0.0, segment_length / max(segment_length, (halfwidth + AA_THICKNESS) * (extrusion[0][0] - extrusion[1][0]))), // -n
        max(0.0, segment_length / max(segment_length, (halfwidth + AA_THICKNESS) * (extrusion[0][1] - extrusion[1][1])))  // +n
    );

    // Generate static/flat outputs

    // If a pattern starts or stops drawing in a joint it will get
    // fractured across the joint. To avoid this we either:
    // - adjust the involved line segments so that the patterns ends
    //   on straight line quad (adjustment becomes +1.0 or -1.0)
    // - or adjust the pattern to start/stop outside of the joint
    //   (f_pattern_overwrite is set, adjustment is 0.0)
    vec2 adjustment = process_pattern(pattern, isvalid, halfwidth * extrusion, halfwidth);

    // If adjustment != 0.0 we replace a joint by an extruded line, so we no longer
    // need to shrink the line for the joint to fit.
    if (adjustment[0] != 0.0 || adjustment[1] != 0.0)
        shape_factor = vec2(1.0);

    // For truncated miter joints we discard overlapping sections of
    // the two involved line segments. To avoid discarding far into
    // the line segment we limit the range here. (Without this short
    // segments can cut holes into longer sections.)
    f_discard_limit = vec2(
        is_truncated[0] ? 0.0 : 1e12,
        is_truncated[1] ? 0.0 : 1e12
    );

    // used to elongate sdf to include joints
    // if start/end       elongate slightly so that there is no AA gap in loops
    // if joint skipped   elongate to new length
    // if normal joint    elongate a lot to let discard/truncation handle joint
    f_extrusion = vec2(
        !isvalid[0] ? min(AA_RADIUS, halfwidth) : (adjustment[0] == 0.0 ? 1e12 : halfwidth * abs(extrusion[0][0])),
        !isvalid[3] ? min(AA_RADIUS, halfwidth) : (adjustment[1] == 0.0 ? 1e12 : halfwidth * abs(extrusion[1][0]))
    );

    // used to compute width sdf
    f_linewidth = halfwidth;

    // for color sampling
    f_color1 = g_color[1];
    f_color2 = g_color[2];

    // handle very thin lines by adjusting alpha rather than linewidth/sdfs
    f_color1.a *= min(1.0, g_thickness[1] / AA_RADIUS);
    f_color2.a *= min(1.0, g_thickness[1] / AA_RADIUS);

    // for uv's
    f_cumulative_length = g_lastlen[1];

    // Generate interpolated/varying outputs:

    LineVertex vertex;

    for (int x = 0; x < 2; x++) {
        vertex.index = x+1;

        for (int y = 0; y < 2; y++) {
            // Calculate offset from p1/p2
            vec3 offset;
            if (adjustment[x] == 0.0) {
                if (is_truncated[x] || !isvalid[3*x]) {
                    // handle overlap in fragment shader via SDF comparison
                    offset = shape_factor[y] * (
                        (halfwidth * extrusion[x][y] + (2 * x - 1) * AA_THICKNESS) * v1 +
                        vec3((2 * y - 1) * (halfwidth + AA_THICKNESS) * n1, 0)
                    );
                } else {
                    // handle overlap by adjusting geometry
                    // TODO: should this include z in miter_n?
                    offset = (2 * y - 1) * shape_factor[y] *
                        (halfwidth + AA_THICKNESS) /
                        float[2](miter_offset1, miter_offset2)[x] *
                        vec3(vec2[2](miter_n1, miter_n2)[x], 0);
                }
            } else {
                // discard joint for cleaner pattern handling
                offset =
                    adjustment[x] * (halfwidth * abs(extrusion[x][1]) + AA_THICKNESS) * v1 +
                    vec3((2 * y - 1) * (halfwidth + AA_THICKNESS) * n1, 0);
            }

            vertex.position = vec3[2](p1, p2)[x] + offset;

            // Generate SDF's

            // distance from quad vertex to line control points
            vec2 VP1 = vertex.position.xy - p1.xy;
            vec2 VP2 = vertex.position.xy - p2.xy;

            // Signed distance of the previous segment from the shared point
            // p1 in line direction. Used decide which segments renders
            // which joint fragment/pixel for truncated joints.
            if (isvalid[0] && (adjustment[0] == 0) && is_truncated[0])
                vertex.quad_sdf0 = dot(VP1, v0.xy);
            else
                vertex.quad_sdf0 = 1e12;

            // sdf of this segment
            vertex.quad_sdf1.x = dot(VP1, -v1.xy);
            vertex.quad_sdf1.y = dot(VP2,  v1.xy);
            vertex.quad_sdf1.z = dot(VP1,  n1);

            // SDF for next segment, see quad_sdf0
            if (isvalid[3] && (adjustment[1] == 0) && is_truncated[1])
                vertex.quad_sdf2 = dot(VP2, -v2.xy);
            else
                vertex.quad_sdf2 = 1e12;

            // sdf for creating a flat cap on truncated joints
            // (sign(dot(...)) detects if line bends left or right)
            // left/right adjustments disable
            vertex.truncation.x = !is_truncated[0] ? -1.0 :
                dot(VP1, sign(dot(miter_n1, -v1.xy)) * miter_n1) - halfwidth * abs(miter_offset1)
                - abs(adjustment[0]) * 1e12;
            vertex.truncation.y = !is_truncated[1] ? -1.0 :
                dot(VP2, sign(dot(miter_n2, +v1.xy)) * miter_n2) - halfwidth * abs(miter_offset2)
                - abs(adjustment[1]) * 1e12;

            // colors should be sampled based on the normalized distance from the
            // extruded edge (varies with offset in n direction)
            // - correcting for this with per-vertex colors results visible face border
            // - calculating normalized distance here will cause div 0/negative
            //   issues as (linelength +- (extrusion[0] + extrusion[1])) <= 0 is possible
            // So defer color interpolation to fragment shader
            vertex.linestart = shape_factor[y] * halfwidth * extrusion[0][y];
            vertex.linelength = max(1, segment_length - shape_factor[y] * halfwidth * (extrusion[0][y] - extrusion[1][y]));

            // finalize vertex
            emit_vertex(vertex);
        }
    }

    // finalize primitive
    EndPrimitive();

    return;
}