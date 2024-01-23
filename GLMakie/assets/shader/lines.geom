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
out float f_quad_sdf0;
out vec3 f_quad_sdf1;
out float f_quad_sdf2;
out vec2 f_truncation;
out vec2 f_uv;

flat out float f_linewidth;
flat out vec4 f_pattern_overwrite;
flat out uvec2 f_id;
flat out vec2 f_extrusion12;
flat out vec2 f_linelength;

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

struct LineVertex {
    vec3 position;
    int index;

    float quad_sdf0;
    vec3 quad_sdf1;
    float quad_sdf2;
    vec2 truncation;

    vec2 uv;
};

// Default constructor
LineVertex LV(vec3 position, int index) {
    LineVertex vertex;
    vertex.position = position;        // p1 or p2, will be modified further
    vertex.index = index;              // index will remain
    return vertex;
}

void emit_vertex(LineVertex vertex) {
    gl_Position    = vec4((2.0 * vertex.position.xy / resolution) - 1.0, vertex.position.z, 1.0);
    f_color        = g_color[vertex.index];

    f_quad_sdf0    = vertex.quad_sdf0;
    f_quad_sdf1    = vertex.quad_sdf1;
    f_quad_sdf2    = vertex.quad_sdf2;
    f_truncation   = vertex.truncation;

    f_uv           = vertex.uv;
    f_id           = g_id[vertex.index];
    EmitVertex();
}

vec2 normal_vector(in vec2 v) { return vec2(-v.y, v.x); }
vec2 normal_vector(in vec3 v) { return vec2(-v.y, v.x); }


////////////////////////////////////////////////////////////////////////////////
//                              Linestyle Support                             //
////////////////////////////////////////////////////////////////////////////////


bool has_pattern(Nothing pattern)   { return false; }
bool has_pattern(sampler1D pattern) { return true; }
bool has_pattern(sampler2D pattern) { return true; }

void process_pattern(Nothing pattern, bool[4] isvalid, float[2] extrusion) {
    // do not adjust stuff
    f_pattern_overwrite = vec4(1e5, 1.0, -1e5, 1.0);
}
void process_pattern(sampler2D pattern, bool[4] isvalid, float[2] extrusion) {
    // TODO
    // This is not a case that's used at all yet. Maybe consider it in the future...
    f_pattern_overwrite = vec4(1e5, 1.0, -1e5, 1.0);
}

void process_pattern(sampler1D pattern, bool[4] isvalid, float[2] extrusion) {
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
        f_pattern_overwrite.x = (g_lastlen[1] + abs(extrusion[0]) + AA_THICKNESS) / pattern_length;
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
        f_pattern_overwrite.z = (g_lastlen[2] - abs(extrusion[1]) - AA_THICKNESS) / pattern_length;
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

void generate_uvs(inout LineVertex[4] vertices, float[2] extrusion, float geom_linewidth) {
    float _extrusion, linewidth = geom_linewidth + AA_THICKNESS;

    // start of line segment
    _extrusion = - (abs(extrusion[0]) + AA_THICKNESS);
    generate_uv(pattern, vertices[0], 1, _extrusion, -linewidth);
    generate_uv(pattern, vertices[1], 1, _extrusion, +linewidth);

    // end of line segment
    _extrusion = abs(extrusion[1]) + AA_THICKNESS;
    generate_uv(pattern, vertices[2], 2, _extrusion, -linewidth);
    generate_uv(pattern, vertices[3], 2, _extrusion, +linewidth);
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
    float miter_offset1 = dot(miter_n1, n1);
    float miter_offset2 = dot(miter_n2, n1);

    // Are we truncating the joint?
    // 1. Based on real miter limits?
    bool[2] is_truncated = bool[2](
        dot(v0.xy, v1.xy) < MITER_LIMIT,
        dot(v1.xy, v2.xy) < MITER_LIMIT
    );

    // How far the line needs to extend to accomodate the joint
    // Note that the sign flips between + and - depending on the orientation
    // of the joint.
    float[2] extrusion;

    if (is_truncated[0]) {
        // need to extend segment to include previous segments corners for truncated join
        extrusion[0] = -0.5 * g_thickness[1] * miter_offset1 / dot(miter_n1, v1.xy);
    } else {
        // shallow/spike join needs to include point where miter normal meets outer line edge
        extrusion[0] = 0.5 * g_thickness[1] * dot(miter_n1, v1.xy) / miter_offset1;
    }
    if (is_truncated[1]) {
        extrusion[1] = -0.5 * g_thickness[2] * miter_offset2 / dot(miter_n2, v1.xy);
    } else {
        extrusion[1] = 0.5 * g_thickness[2] * dot(miter_n2, v1.xy) / miter_offset2;
    }

    LineVertex[4] vertices = LineVertex[4](LV(p1, 1), LV(p1, 1), LV(p2, 2), LV(p2, 2));

    // vertex positions

    // Note: We cut off lines at g_thickness[1/2] so we never go beyond those values
    float geom_linewidth = 0.5 * g_thickness[1];

    // Position
    // TODO: Consider trapezoidal shapes (using AA-padded linewidths as is, not max)
    //        SDF's should be fine, uv's not
    vertices[0].position += (-(abs(extrusion[0]) + AA_THICKNESS)) * v1 + vec3(-(geom_linewidth + AA_THICKNESS) * n1, 0);
    vertices[1].position += (-(abs(extrusion[0]) + AA_THICKNESS)) * v1 + vec3(+(geom_linewidth + AA_THICKNESS) * n1, 0);
    vertices[2].position += (+(abs(extrusion[1]) + AA_THICKNESS)) * v1 + vec3(-(geom_linewidth + AA_THICKNESS) * n1, 0);
    vertices[3].position += (+(abs(extrusion[1]) + AA_THICKNESS)) * v1 + vec3(+(geom_linewidth + AA_THICKNESS) * n1, 0);

    // Set up pattern overwrites at joints if patterns are used
    process_pattern(pattern, isvalid, extrusion);

    // Set up uvs if patterns are used
    generate_uvs(vertices, extrusion, geom_linewidth);

    // generate sdf
    // limit range of distance sampled in prev/next segment
    // this makes overlapping segments draw over each other rather than creating a gap
    // 1.5 is not an exact value, should technically be max length of 1 / dot(miter_n, n)
    f_linelength = vec2(
        0.5 * min(min(segment_length0, segment_length1), 1.83 * g_thickness[1]),
        0.5 * min(min(segment_length2, segment_length1), 1.83 * g_thickness[1])
    );
    f_extrusion12 = vec2(abs(extrusion[0]), abs(extrusion[1])); // used to elongate sdf to include joints
    f_linewidth = 0.5 * g_thickness[1];                         // used to compute width sdf

    for (int i = 0; i < 4; i++) {
        // distance from quad vertex to line control points
        vec2 VP1 = vertices[i].position.xy - p1.xy;
        vec2 VP2 = vertices[i].position.xy - p2.xy;

        // signed distance of previous segment at shared control point
        // used for line joints
        vertices[i].quad_sdf0 = isvalid[0] ? dot(VP1, v0.xy) : 2 * AA_THICKNESS;

        // sdf of this segment
        vertices[i].quad_sdf1.x = dot(VP1, -v1.xy);
        vertices[i].quad_sdf1.y = dot(VP2,  v1.xy);
        vertices[i].quad_sdf1.z = dot(VP1,  n1);

        // sdf of next segment at shared control point
        vertices[i].quad_sdf2 = isvalid[3] ? dot(VP2, -v2.xy) : 2 * AA_THICKNESS;

        // truncation edges
        vertices[i].truncation.x = !is_truncated[0] ? -1.0 :
            dot(VP1, sign(dot(miter_n1, -v1.xy)) * miter_n1) -
            0.5 * g_thickness[1] * abs(miter_offset1);
        vertices[i].truncation.y = !is_truncated[1] ? -1.0 :
            dot(VP2, sign(dot(miter_n2, +v1.xy)) * miter_n2) -
            0.5 * g_thickness[2] * abs(miter_offset2);
    }

    for (int i = 0; i < 4; i++)
        emit_vertex(vertices[i]);

    EndPrimitive();

    return;
}