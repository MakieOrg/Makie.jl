{{GLSL_VERSION}}

struct Nothing{ //Nothing type, to encode if some variable doesn't contain any data
    bool _; //empty structs are not allowed
};

// 9 texels per triangle. First 3: corner positions (pre model transform) with the width
// multiplier of the edge from this corner to the next in w. Then per corner 2 "wing"
// texels: endpoint of a stroked edge that is incident to the corner but not part of this
// triangle, with its width multiplier in w (0 = unused slot). Wings let stroke bands
// continue across triangulation edges instead of being cut off at them.
{{stroke_data_type}} stroke_data;

uniform float strokewidth;
uniform vec4 strokecolor;
uniform vec2 resolution;
uniform float px_per_unit;
uniform mat4 projection, view, model;

// interpolates to the fragment's own normalized device coordinates (pre depth_shift)
noperspective in vec3 o_ndc;

// meshes render non-instanced (o_InstanceID = 0), so their stroke data is indexed by
// gl_PrimitiveID alone; instanced surfaces store two triangles per grid cell instance
flat in int o_InstanceID;

// screen position in physical pixels with NDC depth in z
vec3 stroke_screen_space(vec3 position)
{
    vec4 clip = projection * view * model * vec4(position, 1);
    vec3 ndc = clip.xyz / clip.w;
    return vec3((0.5 * ndc.xy + 0.5) * px_per_unit * resolution, ndc.z);
}

float distance_to_segment(vec2 p, vec2 a, vec2 b)
{
    vec2 ab = b - a;
    float len2 = dot(ab, ab);
    if (len2 < 1e-20)
        return length(p - a);
    float t = clamp(dot(p - a, ab) / len2, 0.0, 1.0);
    return length(p - a - t * ab);
}

float edge_face_factor(vec2 frag, vec2 a, vec2 b, float width_multiplier)
{
    if (width_multiplier <= 0.0)
        return 1.0;
    float aa_radius = 0.7 * px_per_unit;
    float width = width_multiplier * strokewidth * px_per_unit;
    return smoothstep(-aa_radius, aa_radius, distance_to_segment(frag, a, b) - width);
}

// A wing band may only paint fragments whose surface plane the wing edge actually
// touches. A wing that merely projects nearby in screen space (the surface folding
// back on itself, the far side of a curved shape) lies at a different depth than the
// fragment's plane extrapolated to the same screen position, so it is rejected here.
float wing_face_factor(vec2 frag, vec3 a, vec3 b, float width_multiplier, float frag_z, vec2 z_gradient)
{
    if (width_multiplier <= 0.0)
        return 1.0;

    vec2 ab = b.xy - a.xy;
    float len2 = dot(ab, ab);
    float t = len2 < 1e-20 ? 0.0 : clamp(dot(frag - a.xy, ab) / len2, 0.0, 1.0);
    vec2 closest = a.xy + t * ab;
    float dist = length(frag - closest);

    float wing_z = mix(a.z, b.z, t);
    float plane_z = frag_z + dot(z_gradient, closest - frag);
    float z_tolerance = (abs(z_gradient.x) + abs(z_gradient.y)) * (dist + 1.0) + 1e-4;
    if (abs(wing_z - plane_z) > z_tolerance)
        return 1.0;

    float aa_radius = 0.7 * px_per_unit;
    float width = width_multiplier * strokewidth * px_per_unit;
    return smoothstep(-aa_radius, aa_radius, dist - width);
}

vec4 apply_stroke(Nothing data, vec4 color) { return color; }

vec4 apply_stroke(samplerBuffer data, vec4 color)
{
    if (strokewidth <= 0.0)
        return color;

    int base = 9 * (2 * o_InstanceID + gl_PrimitiveID);
    vec4 c0 = texelFetch(data, base + 0);
    vec4 c1 = texelFetch(data, base + 1);
    vec4 c2 = texelFetch(data, base + 2);
    vec3 corners[3] = vec3[3](
        stroke_screen_space(c0.xyz),
        stroke_screen_space(c1.xyz),
        stroke_screen_space(c2.xyz)
    );
    vec2 frag = (0.5 * o_ndc.xy + 0.5) * px_per_unit * resolution;
    vec2 z_gradient = vec2(dFdx(o_ndc.z), dFdy(o_ndc.z));

    float face_factor = 1.0;
    face_factor = min(face_factor, edge_face_factor(frag, corners[0].xy, corners[1].xy, c0.w));
    face_factor = min(face_factor, edge_face_factor(frag, corners[1].xy, corners[2].xy, c1.w));
    face_factor = min(face_factor, edge_face_factor(frag, corners[2].xy, corners[0].xy, c2.w));

    for (int i = 0; i < 3; i++) {
        for (int k = 0; k < 2; k++) {
            vec4 wing = texelFetch(data, base + 3 + 2 * i + k);
            if (wing.w > 0.0) {
                vec3 endpoint = stroke_screen_space(wing.xyz);
                face_factor = min(face_factor, wing_face_factor(frag, corners[i], endpoint, wing.w, o_ndc.z, z_gradient));
            }
        }
    }

    return mix(strokecolor, color, face_factor);
}

vec4 apply_stroke(vec4 color)
{
    return apply_stroke(stroke_data, color);
}
