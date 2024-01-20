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

struct LineVertex {
    vec3 position;
    int index;
    vec4 quad_sdf;
    vec4 joint_cutoff;
    vec2 uv;
};

// Default constructor
LineVertex LV(vec3 position, int index) {
    LineVertex vertex;
    vertex.position = position;        // p1 or p2, will be modified further
    vertex.index = index;              // index will remain
    vertex.quad_sdf = vec4(-10.0);     // defaults to always draw
    vertex.joint_cutoff = vec4(-10.0); // defaults to always draw/never cut away
    // vertex.uv                       // only relevant with uv
    return vertex;
}

void process_pattern(Nothing pattern, bool[4] isvalid, float extrusion_a, float extrusion_b) {
    // do not adjust stuff
    f_pattern_overwrite = vec4(1e5, 1.0, -1e5, 1.0);
}
void process_pattern(sampler2D pattern, bool[4] isvalid, float extrusion_a, float extrusion_b) {
    // TODO
    // This is not a case that's used at all yet. Maybe consider it in the future...
    f_pattern_overwrite = vec4(1e5, 1.0, -1e5, 1.0);
}

void process_pattern(sampler1D pattern, bool[4] isvalid, float extrusion_a, float extrusion_b) {
    float pattern_sample;

    // line segment start
    if (!isvalid[0]) {
        // get sample slightly further along
        pattern_sample = texture(pattern, (g_lastlen[1] + AA_THICKNESS) / pattern_length).x;
        // extend this value into the AA gap
        f_pattern_overwrite.x = (g_lastlen[1] + AA_THICKNESS) / pattern_length;
        f_pattern_overwrite.y = sign(pattern_sample);
    } else {
        // sample at "center" of corner/joint
        pattern_sample = texture(pattern, g_lastlen[1] / pattern_length).x;
        // overwrite until one AA gap past the corner/joint
        f_pattern_overwrite.x = (g_lastlen[1] + abs(extrusion_a) + AA_THICKNESS) / pattern_length;
        // using the sign of the sample to decide between drawing or not drawing
        f_pattern_overwrite.y = sign(pattern_sample);
    }

    // and again for the end of the segment
    if (!isvalid[3]) {
        pattern_sample = texture(pattern, (g_lastlen[2] - AA_THICKNESS) / pattern_length).x;
        f_pattern_overwrite.z = (g_lastlen[2] - AA_THICKNESS) / pattern_length;
        f_pattern_overwrite.w = sign(pattern_sample);
    } else {
        pattern_sample = texture(pattern, g_lastlen[2] / pattern_length).x;
        f_pattern_overwrite.z = (g_lastlen[2] - abs(extrusion_b) - AA_THICKNESS) / pattern_length;
        f_pattern_overwrite.w = sign(pattern_sample);
    }
}

// If we don't have a pattern we don't need uv's
void generate_uv(Nothing pattern, inout LineVertex vertex, int index, float extrusion, float linewidth) {}
// If we have a 1D pattern we don't need uv.y
void generate_uv(sampler1D pattern, inout LineVertex vertex, int index, float extrusion, float linewidth) {
    vertex.uv = vec2((g_lastlen[index] + extrusion) / pattern_length, 0.0);
}
void generate_uv(sampler2D pattern, inout LineVertex vertex, int index, float extrusion, float linewidth) {
    vertex.uv = vec2(
        (g_lastlen[index] + extrusion) / pattern_length,
        0.5 + linewidth / g_thickness[index]
    );
}

void generate_uvs(inout LineVertex[4] vertices, float extrusion_a, float extrusion_b, float geom_linewidth) {
    float extrusion, linewidth = geom_linewidth + AA_THICKNESS;

    // start of line segment
    extrusion = - (abs(extrusion_a) + AA_THICKNESS);
    generate_uv(pattern, vertices[0], 1, extrusion, -linewidth);
    generate_uv(pattern, vertices[1], 1, extrusion, +linewidth);

    // end of line segment
    extrusion = abs(extrusion_b) + AA_THICKNESS;
    generate_uv(pattern, vertices[2], 2, extrusion, -linewidth);
    generate_uv(pattern, vertices[3], 2, extrusion, +linewidth);
}

void emit_vertex(LineVertex vertex) {
    gl_Position    = vec4((2.0 * vertex.position.xy / resolution) - 1.0, vertex.position.z, 1.0);
    f_color        = g_color[vertex.index];
    f_quad_sdf     = vertex.quad_sdf;
    f_joint_cutoff = vertex.joint_cutoff;
    f_uv           = vertex.uv;
    f_id           = g_id[vertex.index];
    EmitVertex();
}

// TODO isn't this wrong?
vec2 normal_vector(in vec2 v) { return vec2(-v.y, v.x); }
vec2 normal_vector(in vec3 v) { return vec2(-v.y, v.x); }

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

    // determine the normal of each of the 3 segments (previous, current, next)
    vec2 n0 = normal_vector(v0);
    vec2 n1 = normal_vector(v1);
    vec2 n2 = normal_vector(v2);

    // Miter normals (normal of truncated edge / vector to sharp corner)
    vec2 miter_n_a = normalize(n0 + n1);
    vec2 miter_n_b = normalize(n1 + n2);

    // miter vectors (line vector matching miter normal)
    vec2 miter_v_a = -normal_vector(miter_n_a);
    vec2 miter_v_b = -normal_vector(miter_n_b);

    // distance between p1/2 and respective sharp corner
    float miter_offset_a = dot(miter_n_a, n1);
    float miter_offset_b = dot(miter_n_b, n1);

    // Are we truncating the joint?
    bool is_a_truncated_joint = dot(v0, v1) < MITER_LIMIT;
    bool is_b_truncated_joint = dot(v1, v2) < MITER_LIMIT;

    // How far the line needs to extend to accomodate the joint
    // Note that the sign flips between + and - depending on the orientation
    // of the joint.
    float extrusion_a, extrusion_b;

    if (is_a_truncated_joint) {
        // need to extend segment to include previous segments corners for truncated join
        extrusion_a = 0.5 * g_thickness[1] * dot(v1.xy, n0);
    } else {
        // shallow/spike join needs to include point where miter normal meets outer line edge
        extrusion_a = 0.5 * g_thickness[1] * dot(miter_n_a, v1.xy) / miter_offset_a;
    }
    if (is_b_truncated_joint) {
        extrusion_b = 0.5 * g_thickness[2] * dot(-v1.xy, n2);
    } else {
        extrusion_b = 0.5 * g_thickness[2] * dot(miter_n_b, v1.xy) / max(0.5, miter_offset_b);
    }

    LineVertex[4] vertices = LineVertex[4](LV(p1, 1), LV(p1, 1), LV(p2, 2), LV(p2, 2));

    // vertex positions

    // Note: We cut off lines at g_thickness[1/2] so we never go beyond those values
    float geom_linewidth = 0.5 * max(g_thickness[1], g_thickness[2]);

    // Position
    // TODO: Consider trapezoidal shapes (using AA-padded linewidths as is, not max)
    //        SDF's should be fine, uv's not
    vertices[0].position += (-(abs(extrusion_a) + AA_THICKNESS)) * v1 + vec3(-(geom_linewidth + AA_THICKNESS) * n1, 0);
    vertices[1].position += (-(abs(extrusion_a) + AA_THICKNESS)) * v1 + vec3(+(geom_linewidth + AA_THICKNESS) * n1, 0);
    vertices[2].position += (+(abs(extrusion_b) + AA_THICKNESS)) * v1 + vec3(-(geom_linewidth + AA_THICKNESS) * n1, 0);
    vertices[3].position += (+(abs(extrusion_b) + AA_THICKNESS)) * v1 + vec3(+(geom_linewidth + AA_THICKNESS) * n1, 0);

    // Set up pattern overwrites at joints if patterns are used
    process_pattern(pattern, isvalid, extrusion_a, extrusion_b);

    // Set up uvs if patterns are used
    generate_uvs(vertices, extrusion_a, extrusion_b, geom_linewidth);

    // ^ Clean
    ////////////////////////////////////////
    // v TODO

    // Do linewidth sdfs interfere with edge cleanup due to strongly varying linewidths?
    bool is_a_critical =
        (max(segment_length0 - 2 * sqrt(0.7), 0.0) < -(g_thickness[1] - g_thickness[0]) * sqrt(0.7)) ||
        (max(segment_length1 - 2 * sqrt(0.7), 0.0) < +(g_thickness[2] - g_thickness[1]) * sqrt(0.7));
    bool is_b_critical =
        (max(segment_length1 - 2 * sqrt(0.7), 0.0) < -(g_thickness[2] - g_thickness[1]) * sqrt(0.7)) ||
        (max(segment_length2 - 2 * sqrt(0.7), 0.0) < +(g_thickness[3] - g_thickness[2]) * sqrt(0.7));

    // Compute variables for line joints

    // Options:
    // valid    truncated
    // false -> false
    // true     false
    // true     true

    // joint cutoff
    // (f, f) -> do nothin
    // (t, f) -> miter_v
    // (t, t) -> v1, n0 or n2, index

    // quad (v)
    // (f, f) -> (+-) v1
    // (t, f) -> nothing? TODO shouldn't this move cutoff out?
    // (t, t) -> miter_n, index, miter_offset

    // quad (n)
    // always: extrusion_a + b, v1, n1
    // (f, f) -> dot(VP1, +-n1) - linewidth[index]
    // (t, f) -> use linewidth at translated corners
    // (t, t) -> dot(VP1, +-n1) - linewidth[index]

    // simpler var linewidth:
    // the sdf tells us the linewidth at the vertices of the generated quad
    // so we can do the following:
    // 1. calculate linewidth at vertex
    // 2. compute distance between vertex and p1 in normal direction.
    //    This is unaffected by extrusion as extrusion \perp normal
    // 3. modify like usual to get sdf (result - target)

    // // normal case
    // float linewidth_scale = (g_thickness[2] - g_thickness[1]) / segment_length;
    // float linewidth_a = g_thickness[1] - linewidth_scale * (abs(extrusion_a) + AA_THICKNESS);
    // float linewidth_b = g_thickness[2] + linewidth_scale * (abs(extrusion_b) + AA_THICKNESS);
    // quad_sdf.z = dot(VP1, -n1) - 0.5 * linewidth_a; // or b if index == 2
    // quad_sdf.w = dot(VP1, +n1) - 0.5 * linewidth_a; // or b if index == 2

    // // special case - sharp join
    // float linewidth_scale = (g_thickness[2] - g_thickness[1]) / (segment_length + abs(extrusion_a) + abs(extrusion_b));
    // float linewidth_a = g_thickness[1] - linewidth_scale * AA_THICKNESS;
    // float linewidth_b = g_thickness[2] + linewidth_scale * AA_THICKNESS;
    // quad_sdf.z = dot(VP1, -n1) - 0.5 * linewidth_a; // or b if index == 2
    // quad_sdf.w = dot(VP1, +n1) - 0.5 * linewidth_a; // or b if index == 2

    // sdf generation

    for (int i = 0; i < 4; i++) {
        vec2 VP1 = vertices[i].position.xy - p1.xy;
        vec2 VP2 = vertices[i].position.xy - p2.xy;

        // joint cutoff
        // (isvalid, is_truncated), miter_v
        // (is_truncated), v1, n0 or n2, index

        // sharp joints use sharp (pixelated) cut offs to avoid self-overlap
        if (isvalid[0] && !is_a_truncated_joint && !is_a_critical)
            vertices[i].joint_cutoff.x = dot(VP1, -miter_v_a);
        if (isvalid[3] && !is_b_truncated_joint && !is_b_critical)
            vertices[i].joint_cutoff.y = dot(VP2, +miter_v_b);

        // truncated joints use smooth cutoff for corners that are outside the other segment
        // TODO: this slightly degrades AA quality due to two AA edges overlapping
        if (is_a_truncated_joint && !is_a_critical)
            vertices[i].joint_cutoff.z = dot(VP1, -sign(dot(v1.xy, n0)) * n0) - 0.5 * g_thickness[1];
        if (is_b_truncated_joint && !is_b_critical)
            vertices[i].joint_cutoff.w = dot(VP2,  sign(dot(v1.xy, n2)) * n2) - 0.5 * g_thickness[2];

        // main sdf

        // SDF of quad
        // !isvalid -> v1
        // isvalid && truncated -> miter_n_a

        // In line direction
        if (!isvalid[0]) // flat line end
            vertices[i].quad_sdf.x = dot(VP1, -v1.xy);
        else if (is_a_truncated_joint)
            vertices[i].quad_sdf.x = dot(VP1, miter_n_a) - 0.5 * g_thickness[1] * miter_offset_a;

        if (!isvalid[3]) // flat line end
            vertices[i].quad_sdf.y = dot(VP2, v1.xy);
        else if (is_b_truncated_joint)
            vertices[i].quad_sdf.y = dot(VP2, miter_n_b) - 0.5 * g_thickness[2] * miter_offset_b;


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
        // TODO: a lot of this doesn't need to be in a loop
        float offset_a = !is_a_critical && !is_a_truncated_joint && isvalid[0] ? extrusion_a : 0.0;
        float offset_b = !is_b_critical && !is_b_truncated_joint && isvalid[3] ? extrusion_b : 0.0;

        vec2 corner1 = p1.xy + offset_a * v1.xy + 0.5 * g_thickness[1] * n1;
        vec2 corner2 = p2.xy + offset_b * v1.xy + 0.5 * g_thickness[2] * n1;
        vec2 edge_vector = normalize(corner2 - corner1);
        vec2 edge_normal = vec2(-edge_vector.y, edge_vector.x);
        vertices[i].quad_sdf.z = dot(vertices[i].position.xy - corner1, edge_normal);

        // bottom
        corner1 = p1.xy - offset_a * v1.xy - 0.5 * g_thickness[1] * n1;
        corner2 = p2.xy - offset_b * v1.xy - 0.5 * g_thickness[2] * n1;
        edge_vector = normalize(corner2 - corner1);
        edge_normal = vec2(-edge_vector.y, edge_vector.x);
        vertices[i].quad_sdf.w = dot(vertices[i].position.xy - corner1, -edge_normal);
    }

    for (int i = 0; i < 4; i++)
        emit_vertex(vertices[i]);

    EndPrimitive();

    return;
}


/*

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

    vec2 center = 0.5 * (line.p1.xy + line.p2.xy);
    float geom_linewidth = 0.5 * max(g_thickness[1], g_thickness[2]) + AA_THICKNESS;

    // set up pattern overwrites at joints
    process_pattern(pattern, line);

    LineVertex[4] vertices = LineVertex[4](LV(line.p1, 1), LV(line.p1, 1), LV(line.p2, 2), LV(line.p2, 2));

    calc_vertex(vertices[0], center, line, vec2(- (abs(line.extrusion_a) + AA_THICKNESS), -geom_linewidth));
    calc_vertex(vertices[1], center, line, vec2(- (abs(line.extrusion_a) + AA_THICKNESS), +geom_linewidth));
    calc_vertex(vertices[2], center, line, vec2(+ (abs(line.extrusion_b) + AA_THICKNESS), -geom_linewidth));
    calc_vertex(vertices[3], center, line, vec2(+ (abs(line.extrusion_b) + AA_THICKNESS), +geom_linewidth));

    for (int i = 0; i < 4; i++)
        emit_vertex(vertices[i]);

    // -geom_linewidth means -n offset means -miter_n offset

    EndPrimitive();

    return;
}

*/