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

out vec4 f_color;
out vec4 f_quad_sdf; // smooth edges (along length and width)
out vec4 f_joint_cutoff; // xy = hard cutoff, zw = smooth cutoff
out vec2 f_uv;
flat out vec4 f_pattern_overwrite;
flat out uvec2 f_id;

out vec3 o_view_pos;
out vec3 o_view_normal;

{{pattern_type}} pattern;
uniform float pattern_length;
uniform vec2 resolution;

// Constants
#define MITER_LIMIT -0.4
#define AA_THICKNESS 4

vec3 screen_space(vec4 vertex) {
    return vec3((0.5 * vertex.xy + 0.5) * resolution, vertex.z) / vertex.w;
}

////////////////////////////////////////////////////////////////////////////////
/// new version
////////////////////////////////////////////////////////////////////////////////

/*
How it works:
1. geom shader generates a large enough quad:
    - width: max(linewidth) + AA pad
    - length: line segment length + join pad + AA pad
2. fragment shader generates SDF and takes care of AA, clean line joins
    - generate rect sdf matching line segment w/o truncation but with join extension
    - adjust sdf to truncate join without AA
*/

struct LineData {
    vec3 p1, p2, v;
    float segment_length, extrusion_a, extrusion_b;
    vec2 n, n0, n2, miter_v_a, miter_n_a, miter_v_b, miter_n_b;
    float miter_offset_a, miter_offset_b;
    bool is_start, is_end;
};

void process_pattern(Nothing pattern, LineData line) {
    // do not adjust stuff
    f_pattern_overwrite = vec4(1e5, 1.0, -1e5, 1.0);
}
void process_pattern(sampler2D pattern, LineData line) {
    // TODO
    // This is not a case that's used at all yet. Maybe consider it in the future...
    f_pattern_overwrite = vec4(1e5, 1.0, -1e5, 1.0);
}

void process_pattern(sampler1D pattern, LineData line) {
    float pattern_sample;

    // line segment start
    if (line.is_start) {
        // get sample slightly further along
        pattern_sample = texture(pattern, (g_lastlen[1] + AA_THICKNESS) / pattern_length).x;
        // extend this value into the AA gap
        f_pattern_overwrite.x = (g_lastlen[1] + AA_THICKNESS) / pattern_length;
        f_pattern_overwrite.y = sign(pattern_sample);
    } else {
        // sample at "center" of corner/joint
        pattern_sample = texture(pattern, g_lastlen[1] / pattern_length).x;
        // overwrite until one AA gap past the corner/joint
        f_pattern_overwrite.x = (g_lastlen[1] + abs(line.extrusion_a) + AA_THICKNESS) / pattern_length;
        // using the sign of the sample to decide between drawing or not drawing
        f_pattern_overwrite.y = sign(pattern_sample);
    }

    // and again for the end of the segment
    if (line.is_end) {
        pattern_sample = texture(pattern, (g_lastlen[2] - AA_THICKNESS) / pattern_length).x;
        f_pattern_overwrite.z = (g_lastlen[2] - AA_THICKNESS) / pattern_length;
        f_pattern_overwrite.w = sign(pattern_sample);
    } else {
        pattern_sample = texture(pattern, g_lastlen[2] / pattern_length).x;
        f_pattern_overwrite.z = (g_lastlen[2] - abs(line.extrusion_b) - AA_THICKNESS) / pattern_length;
        f_pattern_overwrite.w = sign(pattern_sample);
    }
}

void emit_vertex(vec3 origin, vec2 center, LineData line, int index, vec2 geom_offset) {

    vec3 position = origin + geom_offset.x * line.v + vec3(geom_offset.y * line.n, 0);

    // sdf generation

    bool is_a_truncated_joint = line.miter_offset_a < 0.5;
    bool is_b_truncated_joint = line.miter_offset_b < 0.5;

    vec2 VP1 = position.xy - line.p1.xy;
    vec2 VP2 = position.xy - line.p2.xy;

    // by default joint cutoffs do nothing
    f_joint_cutoff = vec4(-10.0);

    // sharp joints use sharp (pixelated) cut offs to avoid self-overlap
    if (!line.is_start && !is_a_truncated_joint)
        f_joint_cutoff.x = dot(VP1, -line.miter_v_a);
    if (!line.is_end && !is_b_truncated_joint)
        f_joint_cutoff.y = dot(VP2, line.miter_v_b);

    // truncated joints use smooth cutoff for corners that are outside the other segment
    // TODO: this slightly degrades AA quality due to two AA edges overlapping
    if (is_a_truncated_joint)
        f_joint_cutoff.z = dot(VP1, -sign(dot(line.v.xy, line.n0)) * line.n0) - 0.5 * g_thickness[1];
    if (is_b_truncated_joint)
        f_joint_cutoff.w = dot(VP2,  sign(dot(line.v.xy, line.n2)) * line.n2) - 0.5 * g_thickness[2];


    // SDF of quad

    // In line direction
    if (line.is_start) // flat line end
        f_quad_sdf.x = dot(VP1, -line.v.xy);
    else if (is_a_truncated_joint)
        f_quad_sdf.x = dot(VP1, line.miter_n_a) - 0.5 * g_thickness[1] * line.miter_offset_a;

    if (line.is_end) // flat line end
        f_quad_sdf.y = dot(VP2, line.v.xy);
    else if (is_b_truncated_joint)
        f_quad_sdf.y = dot(VP2, line.miter_n_b) - 0.5 * g_thickness[2] * line.miter_offset_b;


    // In line normal direction (linewidth)
    // This mostly works
    // TODO: integrate better
    // TODO Problem: you can get concave shapes with very different linewidths + zooming
    // we want to adjust v direction on respective side to dodge both edge normals...

    // start/end/truncated joint: use g_thickness[i] at point i
    // sharp joint: use g_thickness[i] at point i +- joint offset to avoid different
    //              linewidth between this and the previous/next segment
    // TODO: can we calculate this more efficiently?
    // top
    float offset_a = !is_a_truncated_joint && !line.is_start ? line.extrusion_a : 0.0;
    float offset_b = !is_b_truncated_joint && !line.is_end   ? line.extrusion_b : 0.0;

    vec2 corner1 = line.p1.xy + offset_a * line.v.xy + 0.5 * g_thickness[1] * line.n;
    vec2 corner2 = line.p2.xy + offset_b * line.v.xy + 0.5 * g_thickness[2] * line.n;
    vec2 edge_vector = normalize(corner2 - corner1);
    vec2 edge_normal = vec2(-edge_vector.y, edge_vector.x);
    f_quad_sdf.z = dot(position.xy - corner1, edge_normal);

    // bottom
    corner1 = line.p1.xy - offset_a * line.v.xy - 0.5 * g_thickness[1] * line.n;
    corner2 = line.p2.xy - offset_b * line.v.xy - 0.5 * g_thickness[2] * line.n;
    edge_vector = normalize(corner2 - corner1);
    edge_normal = vec2(-edge_vector.y, edge_vector.x);
    f_quad_sdf.w = dot(position.xy - corner1, -edge_normal);

    // And the simpler things...
    f_color     = g_color[index];
    gl_Position = vec4((2.0 * position.xy / resolution) - 1.0, position.z, 1.0);
    f_id        = g_id[index];
    // index into pattern
    f_uv = vec2(
        (g_lastlen[index] + geom_offset.x) / pattern_length,
        0.5 + geom_offset.y / g_thickness[index]
    );
    EmitVertex();
}

void emit_quad(LineData line) {
    vec2 center = 0.5 * (line.p1.xy + line.p2.xy);
    float geom_linewidth = 0.5 * max(g_thickness[1], g_thickness[2]) + AA_THICKNESS;

    // set up pattern overwrites at joints
    process_pattern(pattern, line);

    emit_vertex(line.p1, center, line, 1, vec2(- (abs(line.extrusion_a) + AA_THICKNESS), -geom_linewidth));
    emit_vertex(line.p1, center, line, 1, vec2(- (abs(line.extrusion_a) + AA_THICKNESS), +geom_linewidth));
    emit_vertex(line.p2, center, line, 2, vec2(+ (abs(line.extrusion_b) + AA_THICKNESS), -geom_linewidth));
    emit_vertex(line.p2, center, line, 2, vec2(+ (abs(line.extrusion_b) + AA_THICKNESS), +geom_linewidth));

    // -geom_linewidth means -n offset means -miter_n offset

    EndPrimitive();
}

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
    vec3 v1 = p2 - p1;
    float segment_length = length(v1.xy);
    v1 = v1 / segment_length;
    vec3 v0 = v1;
    vec3 v2 = v1;
    if (p1 != p0 && isvalid[0])
        v0 = (p1 - p0) / length(p1.xy - p0.xy);
    if (p3 != p2 && isvalid[3])
        v2 = (p3 - p2) / length(p3.xy - p2.xy);

    // determine the normal of each of the 3 segments (previous, current, next)
    vec2 n0 = vec2(-v0.y, v0.x);
    vec2 n1 = vec2(-v1.y, v1.x);
    vec2 n2 = vec2(-v2.y, v2.x);

    // Compute variables for line joints
    LineData line;
    line.p1 = p1;
    line.p2 = p2;
    line.v = v1;
    line.n = n1;
    line.n0 = n0;
    line.n2 = n2;
    line.segment_length = segment_length;
    line.is_start = !isvalid[0];
    line.is_end = !isvalid[3];

    // We create a second (imaginary line for each of the joins which averages the
    // directions of the previous lines. For the corner at P1 this line has
    // normal = miter_n_a = normalize(n0 + n1)
    // direction = miter_v_a = normalize(v0 + v1) = vec2(normal.y, -normal.x)
    line.miter_n_a = normalize(n0 + n1);
    line.miter_n_b = normalize(n1 + n2);
    line.miter_v_a = vec2(line.miter_n_a.y, -line.miter_n_a.x);
    line.miter_v_b = vec2(line.miter_n_b.y, -line.miter_n_b.x);

    // The normal of this new line defines the edge between two line segments
    // with a sharp join:
    //       _______________
    //      |'.              ^
    //    ^ |  '. miter_n_a  | n1
    // v0 | |    '._________
    //      |  n0 |      -->
    //      | <-- |      v1
    //      |     |
    //
    // From the triangle with unit vectors (miter_n_a, v1, n1) and the linewidth
    // g_thickness[1] along n1 direction follows the necessary extrusion for
    // sharp corners:
    //   dot(length_a * miter_n_a, n1) = g_thickness[1]
    //   extrusion = dot(length_a * miter_n_a, v1)
    //             = g_thickness[1] * dot(miter_n_a, v1) / dot(miter_n_a, n1)
    //
    // For truncated corners the extrusion will always be <= that of the sharp
    // corner, so we can just clamp the extrusion at the appropriate maximum
    // value. Truncation happens when the angle between v0 and v1 exceeds some
    // value, e.g. 120°, or half of that between miter_v_a and v1. We choose
    // truncation if
    //   dot(miter_v_a, v1) < 0.5   (120° between segments)
    // or equivalently
    //   dot(miter_n_a, n1) < 0.5
    // giving use the limit:
    line.miter_offset_a = dot(line.miter_n_a, n1);
    line.miter_offset_b = dot(line.miter_n_b, n1);

    // TODO: switch to this miter limit
    // if (dot(v0, v1) < MITER_LIMIT) {
    if (dot(line.miter_v_a, v1.xy) < 0.5) {
        // need to extend segment to include previous segments corners for truncated join
        line.extrusion_a = 0.5 * g_thickness[1] * dot(v1.xy, line.n0);
    } else {
        // shallow/spike join needs to include point where miter normal meets outer line edge
        line.extrusion_a = 0.5 * g_thickness[1] * dot(line.miter_n_a, v1.xy) / line.miter_offset_a;
    }
    // if (dot(v1, v2) < MITER_LIMIT) {
    if (dot(v1.xy, line.miter_v_b) < 0.5) {
        line.extrusion_b = 0.5 * g_thickness[2] * dot(-v1.xy, line.n2);
    } else {
        line.extrusion_b = 0.5 * g_thickness[2] * dot(line.miter_n_b, v1.xy) / max(0.5, line.miter_offset_b);
    }

    // For truncated joins we also need to know how far the edge of the joint
    // (between a and b) is from the center point which the line segments share
    // (x).
    //        ----------a.
    //                  | '.
    //                  x  '.
    //        ------.    '--_b
    //             /        /
    //            /        /
    //
    // This distance is given by linewidth * dot(miter_n_a, n1)
    // start/end case doesn't use this anymore

    emit_quad(line);

    return;
}
