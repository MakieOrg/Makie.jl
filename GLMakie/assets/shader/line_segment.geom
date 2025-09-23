{{GLSL_VERSION}}
{{GLSL_EXTENSIONS}}

struct Nothing{ //Nothing type, to encode if some variable doesn't contain any data
    bool _; //empty structs are not allowed
};

layout(lines) in;
layout(triangle_strip, max_vertices = 4) out;

uniform vec2 resolution;
uniform float px_per_unit;
uniform float pattern_length;
{{pattern_type}} pattern;
uniform int linecap;

in {{stripped_color_type}} g_color[];
in uvec2 g_id[];
in float g_thickness[];

out vec3 f_quad_sdf;
out vec2 f_truncation;
out float f_linestart;
out float f_linelength;
out vec3 o_view_pos;
out vec3 o_view_normal;

flat out float f_linewidth;
flat out vec4 f_pattern_overwrite;
flat out uvec2 f_id;
flat out vec2 f_extrusion;
flat out {{stripped_color_type}} f_color1;
flat out {{stripped_color_type}} f_color2;
flat out float f_alpha_weight;
flat out float f_cumulative_length;
flat out ivec2 f_capmode;
flat out vec4 f_linepoints;
flat out vec4 f_miter_vecs;

const float AA_RADIUS = 0.8;
const float AA_THICKNESS = 2.0 * AA_RADIUS;

uniform mat4 projectionview;
uniform float depth_shift;
uniform int _num_clip_planes;
uniform vec4 clip_planes[8];

bool process_clip_planes(inout vec4 p1, inout vec4 p2)
{
    float d1, d2;
    for (int i = 0; i < _num_clip_planes; i++) {
        // distance from clip planes with negative clipped
        d1 = dot(p1.xyz, clip_planes[i].xyz) - clip_planes[i].w * p1.w;
        d2 = dot(p2.xyz, clip_planes[i].xyz) - clip_planes[i].w * p2.w;

        // both outside - clip everything
        if (d1 < 0.0 && d2 < 0.0) {
            p2 = p1;
            return true;
        }

        // one outside - shorten segment
        else if (d1 < 0.0)
        {
            // solve 0 = m * t + b = (d2 - d1) * t + d1 with t in (0, 1)
            p1       = p1       - d1 * (p2 - p1)             / (d2 - d1);
            f_color1 = f_color1 - d1 * (f_color2 - f_color1) / (d2 - d1);
        }
        else if (d2 < 0.0)
        {
            p2       = p2       - d2 * (p1 - p2)             / (d1 - d2);
            f_color2 = f_color2 - d2 * (f_color1 - f_color2) / (d1 - d2);
        }
    }

    return false;
}


vec3 screen_space(vec4 vertex) {
    return vec3((0.5 * vertex.xy / vertex.w + 0.5) * px_per_unit * resolution, vertex.z / vertex.w);
}

vec2 normal_vector(in vec2 v) { return vec2(-v.y, v.x); }
vec2 normal_vector(in vec3 v) { return vec2(-v.y, v.x); }

void main(void)
{
    o_view_pos = vec3(0);
    o_view_normal = vec3(0);

    // we generate very thin lines for linewidth 0, so we manually skip them:
    if (g_thickness[0] == 0.0 && g_thickness[1] == 0.0) {
        return;
    }

    f_color1 = g_color[0];
    f_color2 = g_color[1];

    // get start and end point of line segment
    // restrict to visible area (see lines.geom)
    vec3 p1, p2;
    {
        vec4 _p1 = gl_in[0].gl_Position, _p2 = gl_in[1].gl_Position;

        // remaining world -> clip projection
        _p1 = projectionview * _p1;
        _p2 = projectionview * _p2;

        _p1.z += _p1.w * depth_shift;
        _p2.z += _p2.w * depth_shift;

        // Handle near/far clip planes
        vec4 v1 = _p2 - _p1;

        if (_p1.w < 0.0) {
            _p1      = _p1      + (-_p1.w - _p1.z) / (v1.z + v1.w) * v1;
            f_color1 = f_color1 + (-_p1.w - _p1.z) / (v1.z + v1.w) * (f_color2 - f_color1);
        }
        if (_p2.w < 0.0) {
            _p2      = _p2      + (-_p2.w - _p2.z) / (v1.z + v1.w) * v1;
            f_color2 = f_color2 + (-_p2.w - _p2.z) / (v1.z + v1.w) * (f_color2 - f_color1);
        }

        // Shorten segments to fit clip planes
        // returns true if segments are fully clipped
        if (process_clip_planes(_p1, _p2))
            return;

        // clip -> pixel/screen projection
        p1 = screen_space(_p1);
        p2 = screen_space(_p2);
    }

    // get vector in line direction and vector in linewidth direction
    vec3 v1 = (p2 - p1);
    float segment_length = length(p2.xy - p1.xy);
    v1 /= segment_length;
    vec2 n1 = normal_vector(v1);

    // Set invalid / ignored outputs
    f_truncation = vec2(-1e12);     // no truncated joint
    f_pattern_overwrite = vec4(-1e12, 1.0, 1e12, 1.0); // no joints to overwrite
    f_extrusion = vec2(0.0);        // no joints needing extrusion
    f_linepoints = vec4(-1e12);
    f_miter_vecs = vec4(-1);

    // constants
    f_alpha_weight = min(1.0, g_thickness[0] / AA_RADIUS);
    f_linestart = 0;                // no corners so no joint extrusion to consider
    f_linelength = segment_length;  // and also no changes in line length
    f_cumulative_length = 0.0;      // resets for each new segment

    // linecaps
    f_capmode = ivec2(linecap);

    // Generate vertices

    for (int x = 0; x < 2; x++) {
        // pass on linewidth and id (picking) for the current line vertex
        float halfwidth = 0.5 * max(AA_RADIUS, g_thickness[x]);
        // Get offset in line direction
        float v_offset = (2 * x - 1) * (halfwidth + AA_THICKNESS);
        // TODO: if we just make this a varying output we probably get var linewidths here
        f_linewidth = halfwidth;
        f_id = g_id[x];

        for (int y = 0; y < 2; y++) {
            // Get offset in y direction & compute vertex position
            float n_offset = (2 * y - 1) * (halfwidth + AA_THICKNESS);
            vec3 position = vec3[2](p1, p2)[x] + v_offset * v1 + n_offset * vec3(n1, 0);
            gl_Position = vec4(2.0 * position.xy / (px_per_unit * resolution) - 1.0, position.z, 1.0);

            // Generate SDF's

            // distance from quad vertex to line control points
            vec2 VP1 = position.xy - p1.xy;
            vec2 VP2 = position.xy - p2.xy;

            // sdf of this segment
            f_quad_sdf.x = dot(VP1, -v1.xy);
            f_quad_sdf.y = dot(VP2,  v1.xy);
            f_quad_sdf.z = n_offset;

            // finalize vertex
            EmitVertex();
        }
    }

    EndPrimitive();

    return;
}
