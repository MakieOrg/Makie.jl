{{GLSL_VERSION}}
{{GLSL_EXTENSIONS}}
{{SUPPORTED_EXTENSIONS}}

struct Nothing{ //Nothing type, to encode if some variable doesn't contain any data
    bool _; //empty structs are not allowed
};

{{define_fast_path}}

layout(lines_adjacency) in;
layout(triangle_strip, max_vertices = 4) out;

in {{stripped_color_type}} g_color[];
in float g_lastlen[];
in uvec2 g_id[];
in int g_valid_vertex[];
in float g_thickness[];

out highp vec3 f_quad_sdf;
out vec2 f_truncation;
out float f_linestart;
out float f_linelength;

flat out vec2 f_extrusion;
flat out float f_linewidth;
flat out vec4 f_pattern_overwrite;
flat out vec2 f_discard_limit;
flat out uvec2 f_id;
flat out {{stripped_color_type}} f_color1;
flat out {{stripped_color_type}} f_color2;
flat out float f_alpha_weight;
flat out float f_cumulative_length;
flat out ivec2 f_capmode;
flat out vec4 f_linepoints;
flat out vec4 f_miter_vecs;
out float gl_ClipDistance[8];

out vec3 o_view_pos;
out vec3 o_view_normal;

{{pattern_type}} pattern;
uniform float pattern_length;
uniform vec2 resolution;
uniform vec2 scene_origin;
uniform float px_per_unit;

uniform int linecap;
uniform int joinstyle;
uniform float miter_limit;

uniform mat4 view, projection, projectionview;
uniform int _num_clip_planes;
uniform vec4 clip_planes[8];

// Constants
const float AA_RADIUS = 0.8;
const float AA_THICKNESS = 4.0 * AA_RADIUS;
// NOTE: if MITER_LIMIT becomes a variable AA_THICKNESS needs to scale with the joint extrusion
const int BUTT   = 0;
const int SQUARE = 1;
const int ROUND  = 2;
const int MITER  = 0;
const int BEVEL  = 3;

vec3 screen_space(vec4 vertex) {
    return vec3((0.5 * vertex.xy / vertex.w + 0.5) * px_per_unit * resolution, vertex.z / vertex.w);
}

struct LineVertex {
    vec3 position;
    int index;

    vec3 quad_sdf;
    vec2 truncation;

    float linestart;
    float linelength;
};

void emit_vertex(LineVertex vertex) {
    gl_Position    = vec4(2.0 * vertex.position.xy / (px_per_unit * resolution) - 1.0, vertex.position.z, 1.0);
    f_quad_sdf    = vertex.quad_sdf;
    f_truncation   = vertex.truncation;
    f_linestart    = vertex.linestart;
    f_linelength   = vertex.linelength;
    f_id           = g_id[vertex.index];
    EmitVertex();
}

vec2 normal_vector(in vec2 v) { return vec2(-v.y, v.x); }
vec2 normal_vector(in vec3 v) { return vec2(-v.y, v.x); }
float sign_no_zero(float value) { return value >= 0.0 ? 1.0 : -1.0; }

bool process_clip_planes(inout vec4 p1, inout vec4 p2, inout bool[4] isvalid)
{
    float d1, d2;
    for(int i = 0; i < _num_clip_planes; i++)
    {
        // distance from clip planes with negative clipped
        d1 = dot(p1.xyz, clip_planes[i].xyz) - clip_planes[i].w * p1.w;
        d2 = dot(p2.xyz, clip_planes[i].xyz) - clip_planes[i].w * p2.w;

        // both outside - clip everything
        if (d1 < 0.0 && d2 < 0.0) {
            p2 = p1;
            isvalid[1] = false;
            isvalid[2] = false;
            return true;
        // one outside - shorten segment
        } else if (d1 < 0.0) {
            // solve 0 = m * t + b = (d2 - d1) * t + d1 with t in (0, 1)
            p1       = p1       - d1 * (p2 - p1)             / (d2 - d1);
            f_color1 = f_color1 - d1 * (f_color2 - f_color1) / (d2 - d1);
            isvalid[0] = false;
        } else if (d2 < 0.0) {
            p2       = p2       - d2 * (p1 - p2)             / (d1 - d2);
            f_color2 = f_color2 - d2 * (f_color1 - f_color2) / (d1 - d2);
            isvalid[3] = false;
        }
    }

    return false;
}


////////////////////////////////////////////////////////////////////////////////
//                              Linestyle Support                             //
////////////////////////////////////////////////////////////////////////////////


vec2 process_pattern(Nothing pattern, bool[4] isvalid, mat2 extrusion, float segment_length, float halfwidth) {
    // do not adjust stuff
    f_pattern_overwrite = vec4(-1e12, 1.0, 1e12, 1.0);
    return vec2(0);
}
vec2 process_pattern(sampler2D pattern, bool[4] isvalid, mat2 extrusion, float segment_length, float halfwidth) {
    // TODO
    // This is not a case that's used at all yet. Maybe consider it in the future...
    f_pattern_overwrite = vec4(-1e12, 1.0, 1e12, 1.0);
    return vec2(0);
}

vec2 process_pattern(sampler1D pattern, bool[4] isvalid, mat2 extrusion, float segment_length, float halfwidth) {
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
        left   = width * texture(pattern, uv_scale * (g_lastlen[1] + segment_length - offset)).x;
        center = width * texture(pattern, uv_scale * (g_lastlen[1] + segment_length         )).x;
        right  = width * texture(pattern, uv_scale * (g_lastlen[1] + segment_length + offset)).x;

        if ((left > 0 && center > 0 && right > 0) || (left < 0 && right < 0)) {
            // default/freeze
            f_pattern_overwrite.z = uv_scale * (g_lastlen[1] + segment_length - abs(extrusion[1][0]) - AA_RADIUS);
            f_pattern_overwrite.w = sign(center);
        } else if (left > 0) {
            // shrink backwards
            adjust.y = -1.0;
        } else if (right > 0) {
            // elongate forward
            adjust.y = 1.0;
        } else {
            // default - see above
            f_pattern_overwrite.z = uv_scale * (g_lastlen[1] + segment_length - abs(extrusion[1][0]) - AA_RADIUS);
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

    // We mark vertices based on their role in a line segment:
    //  0: the vertex is skipped/invalid (i.e. NaN)
    //  1: the vertex is valid (part of a plain line segment)
    //  2: the vertex is either ..
    //       a loop target if the previous or next vertex is marked 0
    //       or a normal valid vertex otherwise
    // isvalid[0] and [3] are used to discern whether a line segment is part
    // of a continuing line (valid) or a line start/end (invalid). A line only
    // ends if the previous / next vertex is invalid
    // isvalid[1] and [2] are used to discern whether a line segment should be
    // discarded. This should happen if either vertex is invalid or if one of
    // the vertices is a loop target.
    // A loop target is an extra vertex placed before/after the shared vertex to
    // guide joint generation. Consider for example a closed triangle A B C A.
    // To cleanly close the loop both A's need to create a joint as if we had
    // c A B C A b, but without drawing the c-A and A-b segments. c and b would
    // be loop targets, matching C and B in position, but only being valid in
    // isvalid[0] and [3], not as a drawn segment in isvalid[1] and [2].
    bool isvalid[4] = bool[](
        (g_valid_vertex[0] > 0) && g_id[0].y != g_id[1].y,
        (g_valid_vertex[1] > 0) && !((g_valid_vertex[0] == 0) && (g_valid_vertex[1] == 2)),
        (g_valid_vertex[2] > 0) && !((g_valid_vertex[2] == 2) && (g_valid_vertex[3] == 0)),
        (g_valid_vertex[3] > 0) && g_id[2].y != g_id[3].y
    );

    if(!isvalid[1] || !isvalid[2]){
        return;
    }

    // line start/end colors for color sampling
    f_color1 = g_color[1];
    f_color2 = g_color[2];

    // Time to generate our quad. For this we need to find out how far a join
    // extends the line. First let's get some vectors we need.

    // Get the four vertices passed to the shader in pixel space.

    // To apply pixel space linewidths we transform line vertices to pixel space
    // here. This is dangerous with perspective projection as p.xyz / p.w sends
    // points from behind the camera to beyond far (clip z > 1), causing lines
    // to invert. To avoid this we translate points along the line direction,
    // moving them to the edge of the visible area.
    vec3 p0, p1, p2, p3;
    {
        // Not in clip
        vec4 clip_p0 = gl_in[0].gl_Position; // start of previous segment
        vec4 clip_p1 = gl_in[1].gl_Position; // end of previous segment, start of current segment
        vec4 clip_p2 = gl_in[2].gl_Position; // end of current segment, start of next segment
        vec4 clip_p3 = gl_in[3].gl_Position; // end of next segment

        vec4 v1 = clip_p2 - clip_p1;

        // With our perspective projection matrix clip.w = -view.z with
        // clip.w < 0.0 being behind the camera.
        // Note that if the signs in the projectionmatrix change, this may become wrong.
        if (clip_p1.w < 0.0) {
            // the line connects outside the visible area so we may consider it disconnected
            isvalid[0] = false;
            // A clip position is visible if -w <= z <= w. To move the line along
            // the line direction v to the start of the visible area, we solve:
            //   p.z + t * v.z = +-(p.w + t * v.w)
            // where (-) gives us the result for the near clipping plane as p.z
            // and p.w share the same sign and p.z/p.w = -1.0 is the near plane.
            clip_p1  = clip_p1  + (-clip_p1.w - clip_p1.z) / (v1.z + v1.w) * v1;
            f_color1 = f_color1 + (-clip_p1.w - clip_p1.z) / (v1.z + v1.w) * (f_color2 - f_color1);
        }
        if (clip_p2.w < 0.0) {
            isvalid[3] = false;
            clip_p2  = clip_p2  + (-clip_p2.w - clip_p2.z) / (v1.z + v1.w) * v1;
            f_color2 = f_color2 + (-clip_p2.w - clip_p2.z) / (v1.z + v1.w) * (f_color2 - f_color1);
        }

        // Shorten segments to fit clip planes
        // returns true if segments are fully clipped
        if (process_clip_planes(clip_p1, clip_p2, isvalid))
            return;

        // transform clip -> screen space, applying xyz / w normalization (which
        // is now save as all vertices are in front of the camera)
        p0 = screen_space(clip_p0); // start of previous segment
        p1 = screen_space(clip_p1); // end of previous segment, start of current segment
        p2 = screen_space(clip_p2); // end of current segment, start of next segment
        p3 = screen_space(clip_p3); // end of next segment
    }

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
    // Note: n0 + n1 = vec(0) for a 180° change in direction. +-(v0 - v1) is the
    //       same direction, but becomes vec(0) at 0°, so we can use it instead
    vec2 miter = vec2(dot(v0, v1.xy), dot(v1.xy, v2));
    vec2 miter_n1 = miter.x < 0.0 ?
        sign_no_zero(dot(v0.xy, n1)) * normalize(v0.xy - v1.xy) : normalize(n0 + n1);
    vec2 miter_n2 = miter.y < 0.0 ?
        sign_no_zero(dot(v1.xy, n2)) * normalize(v1.xy - v2.xy) : normalize(n1 + n2);

    // Are we truncating the joint based on miter limit or joinstyle?
    // bevel / always truncate doesn't work with v1 == v2 (v0) so we use allow
    // miter joints a when v1 ≈ v2 (v0)
    bvec2 is_truncated = bvec2(
        (joinstyle == BEVEL) ? miter.x < 0.99 : miter.x < miter_limit,
        (joinstyle == BEVEL) ? miter.y < 0.99 : miter.y < miter_limit
    );

    // miter vectors (line vector matching miter normal)
    vec2 miter_v1 = -normal_vector(miter_n1);
    vec2 miter_v2 = -normal_vector(miter_n2);

    // distance between p1/2 and respective sharp corner
    float miter_offset1 = dot(miter_n1, n1); // = dot(miter_v1, v1)
    float miter_offset2 = dot(miter_n2, n1); // = dot(miter_v2, v1)

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
    // TODO: skipping this for linestart/end avoid round and square being cut off
    //       but causes overlap...
    vec2 shape_factor = (isvalid[0] && isvalid[3]) || (linecap == BUTT) ? vec2(
        max(0.0, segment_length / max(segment_length, (halfwidth + AA_THICKNESS) * (extrusion[0][0] - extrusion[1][0]))), // -n
        max(0.0, segment_length / max(segment_length, (halfwidth + AA_THICKNESS) * (extrusion[0][1] - extrusion[1][1])))  // +n
    ) : vec2(1.0);

    // Generate static/flat outputs

    // If a pattern starts or stops drawing in a joint it will get
    // fractured across the joint. To avoid this we either:
    // - adjust the involved line segments so that the patterns ends
    //   on straight line quad (adjustment becomes +1.0 or -1.0)
    // - or adjust the pattern to start/stop outside of the joint
    //   (f_pattern_overwrite is set, adjustment is 0.0)
    vec2 adjustment = process_pattern(pattern, isvalid, halfwidth * extrusion, segment_length, halfwidth);

    // If adjustment != 0.0 we replace a joint by an extruded line, so we no longer
    // need to shrink the line for the joint to fit.
    if (adjustment[0] != 0.0 || adjustment[1] != 0.0)
        shape_factor = vec2(1.0);

    // For truncated miter joints we discard overlapping sections of the two
    // involved line segments. To identify which sections overlap we calculate
    // the signed distance in +- miter vector direction from the shared line
    // point in fragment shader. We pass the necessary data here. If we do not
    // have a truncated joint we adjust the data here to never discard.
    // Why not calculate the sdf here?
    // If we calculate the sdf here and pass it as an interpolated vertex output
    // the values we get between the two line segments will differ since the
    // the vertices each segment interpolates from differ. This causes the
    // discard check to rarely be true or false for both segments, resulting in
    // duplicated or missing pixel/fragment draw.
    // Passing the line point and miter vector instead should fix this issue,
    // because both of these values come from the same calculation between the
    // two segments. I.e. (previous segment).p2 == (next segment).p1 and
    // (previous segment).miter_v2 == (next segment).miter_v1 should be the case.
    if (isvalid[0] && is_truncated[0] && (adjustment[0] == 0.0)) {
        f_linepoints.xy = p1.xy + px_per_unit * scene_origin; // FragCoords are relative to the window
        f_miter_vecs.xy = -miter_v1.xy;         // but p1/p2 is relative to the scene origin
    } else {
        f_linepoints.xy = vec2(-1e12);          // FragCoord > 0
        f_miter_vecs.xy = normalize(vec2(-1));
    }
    if (isvalid[3] && is_truncated[1] && (adjustment[1] == 0.0)) {
        f_linepoints.zw = p2.xy + px_per_unit * scene_origin;
        f_miter_vecs.zw = miter_v2.xy;
    } else {
        f_linepoints.zw = vec2(-1e12);
        f_miter_vecs.zw = normalize(vec2(-1));
    }

    // used to elongate sdf to include joints
    // if start/end       elongate slightly so that there is no AA gap in loops
    // if joint skipped   elongate to new length
    // if normal joint    elongate a lot to let discard/truncation handle joint
    f_extrusion = vec2(
        !isvalid[0] ? 0.0 : (adjustment[0] == 0.0 ? 1e12 : halfwidth * abs(extrusion[0][0])),
        !isvalid[3] ? 0.0 : (adjustment[1] == 0.0 ? 1e12 : halfwidth * abs(extrusion[1][0]))
    );

    // used to compute width sdf
    f_linewidth = halfwidth;

    // handle very thin lines by adjusting alpha rather than linewidth/sdfs
    f_alpha_weight = min(1.0, g_thickness[1] / AA_RADIUS);

    // for uv's
    f_cumulative_length = g_lastlen[1];

    // 0 :butt/normal cap or joint | 1 :square cap | 2 rounded cap/joint
    f_capmode = ivec2(
        isvalid[0] ? joinstyle : linecap,
        isvalid[3] ? joinstyle : linecap
    );

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
                        (halfwidth * max(1.0, abs(extrusion[x][y])) + AA_THICKNESS) * (2 * x - 1) * v1 +
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

            // sdf of this segment
            vertex.quad_sdf.x = dot(VP1, -v1.xy);
            vertex.quad_sdf.y = dot(VP2,  v1.xy);
            vertex.quad_sdf.z = dot(VP1,  n1);

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