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
out vec2 f_uv;
out float f_linestart;
out float f_linelength;

flat out float f_linewidth;
flat out vec4 f_pattern_overwrite;
flat out uvec2 f_id;
flat out vec2 f_extrusion12;
flat out vec2 f_discard_limit;
flat out vec4 f_color1;
flat out vec4 f_color2;

out vec3 o_view_pos;
out vec3 o_view_normal;

{{pattern_type}} pattern;
uniform float pattern_length;
uniform vec2 resolution;

// Constants
const float MITER_LIMIT = -0.4;
const float AA_RADIUS = 0.8;
const float AA_THICKNESS = 2.0 * AA_RADIUS;

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

    vec2 uv;
    float linestart;
    float linelength;
};

void emit_vertex(LineVertex vertex) {
    gl_Position    = vec4((2.0 * vertex.position.xy / resolution) - 1.0, vertex.position.z, 1.0);
    f_quad_sdf0    = vertex.quad_sdf0;
    f_quad_sdf1    = vertex.quad_sdf1;
    f_quad_sdf2    = vertex.quad_sdf2;
    f_truncation   = vertex.truncation;
    f_uv           = vertex.uv;
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


vec2 process_pattern(Nothing pattern, bool[4] isvalid, float[2] extrusion) {
    // do not adjust stuff
    f_pattern_overwrite = vec4(1e5, 1.0, -1e5, 1.0);
    return vec2(0);
}
vec2 process_pattern(sampler2D pattern, bool[4] isvalid, float[2] extrusion) {
    // TODO
    // This is not a case that's used at all yet. Maybe consider it in the future...
    f_pattern_overwrite = vec4(1e5, 1.0, -1e5, 1.0);
    return vec2(0);
}

vec2 process_pattern(sampler1D pattern, bool[4] isvalid, float[2] extrusion) {
    // samples:
    //   -ext1  p1 ext1    -ext2 p2 ext2
    //      1   2   3        4   5   6
    // prev | joint |  this  | joint | next

    // default to no overwrite
    f_pattern_overwrite.x = -1e12;
    f_pattern_overwrite.z = +1e12;
    vec2 adjust = vec2(0);
    float left, center, right;

    if (isvalid[0]) {
        float offset = max(abs(extrusion[0]), 0.5 * g_thickness[1]);
        left   = texture(pattern, (g_lastlen[1] - offset) / pattern_length).x;
        center = texture(pattern, g_lastlen[1] / pattern_length).x;
        right  = texture(pattern, (g_lastlen[1] + offset) / pattern_length).x;

        // cases:
        // ++-, +--, +-+ => elongate backwards
        // -++, --+      => shrink forward
        // +++, ---, -+- => freeze around joint

        if ((left > 0 && center > 0 && right > 0) || (left < 0 && right < 0)) {
            // default/freeze
            // overwrite until one AA gap past the corner/joint
            f_pattern_overwrite.x = (g_lastlen[1] + abs(extrusion[0]) + AA_RADIUS) / pattern_length;
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
            f_pattern_overwrite.x = (g_lastlen[1] + abs(extrusion[0]) + AA_RADIUS) / pattern_length;
            f_pattern_overwrite.y = sign(center);
        }

    } // else there is no left segment, no left join, so no overwrite

    if (isvalid[3]) {
        float offset = max(abs(extrusion[1]), 0.5 * g_thickness[2]);
        left   = texture(pattern, (g_lastlen[2] - offset) / pattern_length).x;
        center = texture(pattern, g_lastlen[2] / pattern_length).x;
        right  = texture(pattern, (g_lastlen[2] + offset) / pattern_length).x;

        if ((left > 0 && center > 0 && right > 0) || (left < 0 && right < 0)) {
            // default/freeze
            f_pattern_overwrite.z = (g_lastlen[2] - abs(extrusion[1]) - AA_RADIUS) / pattern_length;
            f_pattern_overwrite.w = sign(center);
        } else if (left > 0) {
            // shrink backwards
            adjust.y = -1.0;
        } else if (right > 0) {
            // elongate forward
            adjust.y = 1.0;
        } else {
            // default - see above
            f_pattern_overwrite.z = (g_lastlen[2] - abs(extrusion[1]) - AA_RADIUS) / pattern_length;
            f_pattern_overwrite.w = sign(center);
        }
    }

    return adjust;
}

// If we don't have a pattern we don't need uv's
vec2 generate_uv(Nothing pattern, int index, float extrusion, float linewidth) { return vec2(0); }
// If we have a 1D pattern we don't need uv.y
vec2 generate_uv(sampler1D pattern, int index, float extrusion, float linewidth) {
    return vec2((g_lastlen[index] + extrusion) / pattern_length, 0.0);
}
vec2 generate_uv(sampler2D pattern, int index, float extrusion, float linewidth) {
    return vec2(
        (g_lastlen[index] + extrusion) / pattern_length,
        0.5 + linewidth / g_thickness[index]
    );
}


////////////////////////////////////////////////////////////////////////////////
//                                    Main                                    //
////////////////////////////////////////////////////////////////////////////////


void main(void)
{
    // These need to be set but don't have reasonable values here
    o_view_pos = vec3(0);
    o_view_normal = vec3(0);

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

    // determine the direction of each of the 3 segments (previous, current, next)
    vec3 v1 = (p2 - p1);
    float segment_length1 = length(v1.xy);
    v1 /= segment_length1;
    vec3 v0 = v1;
    vec3 v2 = v1;
    float segment_length0 = 0.0, segment_length2 = 0.0;
    if (p1 != p0 && isvalid[0]) {
        v0 = (p1 - p0);
        segment_length0 = length(p1.xy - p0.xy);
        v0 /= segment_length0;
    }
    if (p3 != p2 && isvalid[3]) {
        v2 = (p3 - p2);
        segment_length2 = length(p3.xy - p2.xy);
        v2 /= segment_length2;
    }

    // Since we are measuring from the center of the line we will need half
    // the thickness/linewidth for most things.
    float halfwidth = 0.5 * g_thickness[1];

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
    bool[2] is_truncated = bool[2](
        dot(v0.xy, v1.xy) < MITER_LIMIT,
        dot(v1.xy, v2.xy) < MITER_LIMIT
    );

    // How far the line needs to extend to accomodate the joint
    // These are calulated in n1 direction, as prefactors of v1. I.e the rect
    // uses:    p1 + extrusion[0] * v1  -----  p2 + extrusion[1] * v1
    //                    |                             |
    //          p1 - extrusion[0] * v1  -----  p2 - extrusion[1] * v1
    float[2] extrusion;

    if (is_truncated[0]) {
        // need to extend segment to include previous segments corners for truncated join
        extrusion[0] = -halfwidth * miter_offset1 / dot(miter_v1, n1);
    } else {
        // shallow/spike join needs to include point where miter normal meets outer line edge
        extrusion[0] = -halfwidth * dot(miter_n1, v1.xy) / miter_offset1;
    }
    if (is_truncated[1]) {
        extrusion[1] = halfwidth * miter_offset2 / dot(miter_v2, n1);
    } else {
        extrusion[1] = halfwidth * dot(miter_n2, v1.xy) / miter_offset2;
    }

    // Generate static/flat outputs

    // Set up pattern overwrites at joints if patterns are used. This "freezes"
    // the pattern in either the on state (draw) or off state (no draw) to avoid
    // fragmenting it around a corner.
    vec2 adjustment = process_pattern(pattern, isvalid, extrusion);

    // limit range of distance sampled in prev/next segment
    // this makes overlapping segments draw over each other when reaching the limit
    // Maxiumum overlap in sharp joint is halfwidth / dot(miter_n, n) ~ 1.83 halfwidth
    // So 2 halfwidth = g_thickness[1] will avoid overdraw in sharp joints
    f_discard_limit = vec2(
        is_truncated[0] ? 0.0 : g_thickness[1],
        is_truncated[1] ? 0.0 : g_thickness[1]
    );

    // color scaling to match colors where segments connect, not where vertices are
    vec4[2] col_m = vec4[2](
        (g_color[2] - g_color[1]) / max(0.01, segment_length1 - extrusion[0] + extrusion[1]),
        (g_color[2] - g_color[1]) / max(0.01, segment_length1 + extrusion[0] - extrusion[1])
    );

    // used to elongate sdf to include joints
    // if start/end don't elongate
    // if joint skipped elongate to new length
    // if joint elongate a lot to let discard/truncation handle joint
    f_extrusion12 = vec2(
        !isvalid[0] ? 0.0 : (adjustment[0] == 0.0 ? 1e12 : max(abs(extrusion[0]), halfwidth)),
        !isvalid[3] ? 0.0 : (adjustment[1] == 0.0 ? 1e12 : max(abs(extrusion[1]), halfwidth))
    );

    // used to compute width sdf
    f_linewidth = halfwidth;

    // for color sampling
    f_color1 = g_color[1];
    f_color2 = g_color[2];

    // Generate interpolated/varying outputs:

    LineVertex vertex;

    for (int x = 0; x < 2; x++) {
        // Get offset in line direction
        float v_offset;
        if (adjustment[x] == 0.0)
            v_offset = (2 * x - 1) * (abs(extrusion[x]) + AA_THICKNESS);
        else
            v_offset = adjustment[x] * (max(abs(extrusion[x]), halfwidth) + AA_THICKNESS);
        vertex.index = x+1;

        for (int y = 0; y < 2; y++) {
            // Get offset in y direction & compute vertex position
            float n_offset = (2 * y - 1) * (halfwidth + AA_THICKNESS);
            vertex.position = vec3[2](p1, p2)[x] + v_offset * v1 + n_offset * vec3(n1, 0);

            // generate uv coordinate
            vertex.uv = generate_uv(pattern, vertex.index, v_offset, n_offset);

            // Generate SDF's

            // distance from quad vertex to line control points
            vec2 VP1 = vertex.position.xy - p1.xy;
            vec2 VP2 = vertex.position.xy - p2.xy;

            // Note: Adding an offset of -0.5 to all SDF's in v direction
            // fixes most issues with picking which segment renders a fragment
            // of a joint.

            // signed distance of previous segment at shared control point in line
            // direction. Used decide which segments renders which joint fragment.
            // If the left joint is adjusted this sdf is disabled.
            vertex.quad_sdf0 = isvalid[0] ? dot(VP1, v0.xy) - 0.5 + abs(adjustment[0]) * 1e12 : 2 * AA_THICKNESS;

            // sdf of this segment
            vertex.quad_sdf1.x = dot(VP1, -v1.xy) - 0.5;
            vertex.quad_sdf1.y = dot(VP2,  v1.xy) - 0.5;
            vertex.quad_sdf1.z = n_offset;

            // SDF for next segment, see quad_sdf0
            vertex.quad_sdf2 = isvalid[3] ? dot(VP2, -v2.xy) - 0.5 + abs(adjustment[1]) * 1e12 : 2 * AA_THICKNESS;

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
            vertex.linestart = (1 - 2 * y) * extrusion[0];
            vertex.linelength = segment_length1 - (1 - 2 * y) * (extrusion[0] + extrusion[1]);

            // finalize vertex
            emit_vertex(vertex);
        }
    }

    // finalize primitive
    EndPrimitive();

    return;
}