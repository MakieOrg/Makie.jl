{{GLSL_VERSION}}

// Sets which shading procedures to use
// Options:
// NO_SHADING           - skip shading calculation, handled outside
// FAST_SHADING         - single point light (forward rendering)
// MULTI_LIGHT_SHADING  - simple shading with multiple lights (forward rendering)
{{shading}}

// Writes "#define ENABLE_DEPTH" if the attribute is initialized as true
// Otherwise writes nothing
{{ENABLE_DEPTH}}

bool is_clipped(vec4 pos) { return !((-pos.w < pos.z) && (pos.z < pos.w)); }

// We will need to renormalize this to the 0..1 range OpenGL defaults to
float clip_depth = 0.0;

struct Nothing{ //Nothing type, to encode if some variable doesn't contain any data
    bool _; //empty structs are not allowed
};
in vec3 frag_vert;

{{color_map_type}} color_map;
{{color_type}} color;
{{color_norm_type}} color_norm;

uniform vec3 eyeposition;
uniform mat4 modelinv;

uniform mat4 model, projectionview;
uniform int _num_clip_planes;
uniform vec4 clip_planes[8];
uniform float depth_shift;

uniform sampler1D marker_mode; // 1 UInt8
// probably worth squashing into one 2D texture?
uniform sampler1D position; // float vec3
uniform sampler1D markersize; // float vec3
uniform sampler1D rotation; // float vec4
uniform sampler1D smudge_range; // float

const float max_distance = 1.3;

const int num_samples = 200;
const float step_size = max_distance / float(num_samples);

uniform uint objectid;

void write2framebuffer(vec4 color, uvec2 id);

float _normalize(float val, float from, float to) { return (val-from) / (to - from);}

vec4 color_lookup(float intensity, Nothing color_map, Nothing norm, vec4 color) {
    return color;
}
vec4 color_lookup(float intensity, samplerBuffer color_ramp, vec2 norm, Nothing color) {
    return texelFetch(color_ramp, int(_normalize(intensity, norm.x, norm.y)*textureSize(color_ramp)));
}
vec4 color_lookup(float intensity, samplerBuffer color_ramp, Nothing norm, Nothing color) {
    return vec4(0);  // stub method
}
vec4 color_lookup(float intensity, sampler1D color_ramp, vec2 norm, Nothing color) {
    return texture(color_ramp, _normalize(intensity, norm.x, norm.y));
}
vec4 color_lookup(vec4 data_color, Nothing color_ramp, Nothing norm, Nothing color) {
    return data_color;  // stub method
}
vec4 color_lookup(float intensity, Nothing color_ramp, Nothing norm, Nothing color) {
    return vec4(0);  // stub method
}

vec4 color_lookup(samplerBuffer colormap, int index) { return texelFetch(colormap, index); }
vec4 color_lookup(sampler1D colormap, int index) { return texelFetch(colormap, index, 0); }
vec4 color_lookup(Nothing colormap, int index) { return vec4(0); }

#ifndef NO_SHADING
vec3 illuminate(vec3 world_pos, vec3 camdir, vec3 normal, vec3 base_color);
#endif

#ifdef NO_SHADING
vec3 illuminate(vec3 world_pos, vec3 camdir, vec3 normal, vec3 base_color) {
    return normal;
}
#endif

const float typemax = 100000000000000000000000000000000000000.0;

////////////////////////////////////////////////////////////////////////////////
/// Operations
////////////////////////////////////////////////////////////////////////////////



////////////////////////////////////////////////////////////////////////////////
/// Distance Functions
////////////////////////////////////////////////////////////////////////////////

// These are all assumed to be centered around 0. `ray_pos` may be translated
// externally to translate the sdf.

float sphere_dist(vec3 ray_pos, vec3 scale) { return length(ray_pos) - scale.x; }

float ellipsoid_dist(vec3 ray_pos, vec3 scale)
{
    // See Inigo Quilez https://iquilezles.org/articles/ellipsoids/
    float k0 = length(ray_pos / scale);
    float k1 = length(ray_pos / (scale * scale));
    return k0 * (k0 - 1.0) / max(0.000001, k1);
}

float rect_dist(vec3 ray_pos, vec3 scale)
{
    vec3 q = abs(ray_pos) - scale;
    // outside and inside distance?
    return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
}

float rect_frame_dist(vec3 ray_pos, vec3 scale, float width)
{
    vec3 p = abs(ray_pos) - scale;
    vec3 q = abs(p + width) - width;
    // signed distance for x/y/z frame rects
    float a = length(max(vec3(p.x, q.y, q.z), 0.0)) + min(max(p.x, max(q.y, q.z)), 0.0);
    float b = length(max(vec3(q.x, p.y, q.z), 0.0)) + min(max(q.x, max(p.y, q.z)), 0.0);
    float c = length(max(vec3(q.x, q.y, p.z), 0.0)) + min(max(q.x, max(q.y, p.z)), 0.0);
    return min(min(a, b), c);
}

float torus_dist(vec3 ray_pos, float r_outer, float r_inner)
{
    vec2 q = vec2(length(ray_pos.xy) - r_outer, ray_pos.z);
    return length(q) - r_inner;
}

// opening angle extending in both directions from 0
float capped_torus_dist(vec3 ray_pos, float opening_angle, float r_outer, float r_inner)
{
    vec2 sincos = vec2(sin(opening_angle), cos(opening_angle));
    vec3 p = vec3(abs(ray_pos.x), ray_pos.yz);
    float k = (sincos.y * p.x > sincos.x * p.y) ? dot(p.xy, sincos) : length(p.xy);
    return sqrt(dot(p, p) + r_outer * r_outer - 2.0 * r_outer * k) - r_inner;
}

float link_dist(vec3 ray_pos, float len, float r_outer, float r_inner)
{
    vec3 q = vec3(ray_pos.x, max(abs(ray_pos.y) - len, 0.0), ray_pos.z);
    return length(vec2(length(q.xy) - r_outer, q.z)) - r_inner;
}

float cylinder_dist(vec3 ray_pos, float radius, float height)
{
    // homebrew, probably incorrect inside?
    return max(length(ray_pos.xy) - radius, abs(ray_pos.z) - height);
}

// or rounded cylinder
float capsule_dist(vec3 ray_pos, float radius, float height)
{
    vec3 pos = vec3(ray_pos.x, ray_pos.y, max(0.0, abs(ray_pos.z) - height));
    return length(pos) - radius;
}

float cone_dist(vec3 ray_pos, float radius, float height)
{
    // vector from top of cone to ray in (radius, height) coordinates
    vec2 ray_rh = vec2(length(ray_pos.xy), height - ray_pos.z);
    // vector from top along mantle
    vec2 mantle_dir = vec2(radius, 2 * height);
    float mantle_length = length(mantle_dir);
    mantle_dir /= mantle_length;
    // get vector from mantle to ray_pos, calculate length
    float d = length(ray_rh - mantle_dir * clamp(dot(ray_rh, mantle_dir), 0.0, mantle_length));
    // inside vs outside mantle
    float _sign = sign(ray_rh.x * mantle_dir.y - ray_rh.y * mantle_dir.x);
    // always positive if we are below
    _sign = max(_sign, 2.0 * float(ray_pos.z < -height) - 1.0);
    return d * _sign;
}

float capped_cone_dist(vec3 ray_pos, float height, float radius1, float radius2)
{
    vec2 ray_rh = vec2(length(ray_pos.xy), ray_pos.z);
    vec2 limits = vec2(radius2, height);
    vec2 delta = vec2(radius2 - radius1, 2.0 * height);
    vec2 ca = vec2(ray_rh.x - min(ray_rh.x, ray_rh.y < 0.0 ? radius1 : radius2), abs(ray_rh.y) - height);
    vec2 cb = ray_rh - limits + delta * clamp(dot(limits - ray_rh, delta) / dot(delta, delta), 0.0, 1.0);
    float s = (cb.x < 0.0 && ca.y < 0.0) ? -1.0 : 1.0;
    return s * sqrt(min(dot(ca, ca), dot(cb, cb)));
}

float octahedron_dist(vec3 ray_pos, float size)
{
    vec3 p = abs(ray_pos);
    float boundary_dist = p.x + p.y + p.z - size; // unnormalized

    vec3 q;
    if (3.0 * p.x < boundary_dist)
        q = p.xyz;
    else if (3.0 * p.y < boundary_dist)
        q = p.yzx;
    else if (3.0 * p.z < boundary_dist)
        q = p.zxy;
    else
        return boundary_dist * 0.57735027; // normalized

    float k = clamp(0.5 * (q.z - q.y + size), 0.0, size);
    return length(vec3(q.x, q.y - size + k, q.z - k));
}

float pyramid_dist(vec3 ray_pos, float radius, float height)
{
    // use xy symmetry
    vec3 pos = vec3(abs(ray_pos.xy), height - ray_pos.z);

    // project ray_pos onto the side surfaces where side_dir is the vector going
    // from the tip of the pyramid down one of the sides
    vec2 side_dir = vec2(radius, 2.0 * height);
    float side_length2 = dot(side_dir, side_dir);

    // and also the edge between side surfaces
    vec3 edge_dir = vec3(radius, radius, 2.0 * height);
    float edge_length2 = dot(edge_dir, edge_dir);

    // use projection ray_pos = a * side_dir + b * some_vec
    vec2 x_proj = side_dir * clamp(dot(pos.xz, side_dir), 0.0, side_length2) / side_length2;
    vec2 y_proj = side_dir * clamp(dot(pos.yz, side_dir), 0.0, side_length2) / side_length2;
    vec3 xy_proj = edge_dir * clamp(dot(pos, edge_dir), 0.0, edge_length2) / edge_length2;

    // We can further disassemble some_vec = c * side_normal + d * perp_vec
    // where perp_vec = u_y for the x surface. If d < width of the surface
    // at x_proj, c is the closest distance. Check if this is the case:
    // If it's not the case for the x or y surface, the edge must be closer(1)
    float in_x_range = float(pos.y * height < 0.5 * radius * x_proj.y);
    float in_y_range = float(pos.x * height < 0.5 * radius * y_proj.y);

    float mantle_dist = length(
        in_x_range * vec3(pos.xz - x_proj, 0) +
        in_y_range * vec3(pos.yz - y_proj, 0) +
        (1.0 - in_x_range) * (1.0 - in_y_range) * (pos - xy_proj)
    );

    // (1) ... except if the bottom face is closer
    // directly calculate the distance here, treating anything from -radius .. radius
    // as zero distance (or 0 .. radius with symmetry)
    float base_dist = length(vec3(max(pos.xy - radius, 0.0), pos.z - 2.0 * height));

    // figure out if we're inside tbe pyramid by checking if x, y < the width
    // of the pyramid at the closest point, and if we're not below the pyramid
    float local_radius = in_x_range * x_proj.x + in_y_range * y_proj.x +
        (1.0 - in_x_range) * (1.0 - in_y_range) * xy_proj.x;
    bool is_inside = (pos.x < local_radius) && (pos.y < local_radius) && (abs(ray_pos.z) < height);
    float _sign = 1.0 - 2.0 * float(is_inside);

    return _sign * min(mantle_dist, base_dist);
}

////////////////////////////////////////////////////////////////////////////////
/// Normals
////////////////////////////////////////////////////////////////////////////////

// TODO:
// These are not going to work with sdf transformations
// getting normals from the sdf is actually necessary there...

vec3 sphere_normal(vec3 ray_pos, vec3 scale) { return normalize(ray_pos); }
vec3 ellipsoid_normal(vec3 ray_pos, vec3 scale) { return normalize(ray_pos / scale); }

vec3 rect_normal(vec3 ray_pos, vec3 scale)
{
    vec3 face_dist = abs(abs(ray_pos) - scale);
    vec3 is_point_on_face = vec3(
        face_dist.x < face_dist.y && face_dist.x < face_dist.z,
        face_dist.y < face_dist.z && face_dist.y < face_dist.x,
        face_dist.z < face_dist.x && face_dist.z < face_dist.y
    );
    vec3 normal = is_point_on_face * sign(ray_pos);
    return normal;
}

vec3 rect_frame_normal(vec3 ray_pos, vec3 scale, float width)
{
    const float h = 0.0001;
    const vec2 k = vec2(1, -1);
    return normalize(
        k.xyy * rect_frame_dist(ray_pos + k.xyy * h, scale, width) +
        k.yyx * rect_frame_dist(ray_pos + k.yyx * h, scale, width) +
        k.yxy * rect_frame_dist(ray_pos + k.yxy * h, scale, width) +
        k.xxx * rect_frame_dist(ray_pos + k.xxx * h, scale, width)
    );
}

vec3 torus_normal(vec3 ray_pos, float r_outer, float r_inner)
{
    vec2 ring_pos = r_outer * normalize(ray_pos.xy);
    vec3 normal = normalize(ray_pos - vec3(ring_pos, 0.0));
    return normal;
}

vec3 capped_torus_normal(vec3 ray_pos, float opening_angle, float r_outer, float r_inner)
{
    vec2 ring_pos = normalize(ray_pos.xy);
    ring_pos.y = max(ring_pos.y, cos(opening_angle));
    ring_pos = r_outer * normalize(ring_pos);
    vec3 normal = normalize(ray_pos - vec3(ring_pos, 0.0));
    return normal;
}

vec3 link_normal(vec3 ray_pos, float len, float r_outer, float r_inner)
{
    vec2 link_pos;
    if (abs(ray_pos.y) < len)
        link_pos = vec2(sign(ray_pos.x) * r_outer, ray_pos.y);
    else
    {
        // compute position on link with len = r_inner = 0
        float s = sign(ray_pos.y);
        float ring_y = s * (abs(ray_pos.y) - len);
        vec2 ring_pos = r_outer * normalize(vec2(ray_pos.x, ring_y));
        // then add length back
        link_pos = ring_pos + s * vec2(0, len);
    }

    vec3 normal = normalize(ray_pos - vec3(link_pos, 0.0));
    return normal;
}

vec3 cylinder_normal(vec3 ray_pos, float radius, float height) {
    float norm = length(ray_pos.xy);
    if (abs(ray_pos.z) - height < norm - radius)
        return vec3(ray_pos.xy / norm, 0.0);
    else
        return vec3(0, 0, sign(ray_pos.z));
}

vec3 capsule_normal(vec3 ray_pos, float radius, float height) {
    float norm = length(ray_pos.xy);
    if (abs(ray_pos.z) - height < norm - radius)
        return vec3(ray_pos.xy / norm, 0.0);
    else
        return normalize(ray_pos - vec3(0, 0, sign(ray_pos.z) * height));
}

vec3 cone_normal(vec3 ray_pos, float radius, float height) {
    float norm = length(ray_pos.xy);
    float mantle_radius = radius * (height - ray_pos.z) / (2.0 * height);
    if (abs(ray_pos.z + height) > abs(norm - mantle_radius))
        return vec3(ray_pos.xy / norm, 0.0);
    else
        return vec3(0.0, 0.0, -1.0);
}

vec3 capped_cone_normal(vec3 ray_pos, float height, float radius1, float radius2) {
    float norm = length(ray_pos.xy);
    float mantle_radius = mix(radius1, radius2, (ray_pos.z + height) / (2.0 * height));
    if (height - abs(ray_pos.z) > abs(norm - mantle_radius))
        return vec3(ray_pos.xy / norm, 0.0);
    else
        return vec3(0.0, 0.0, sign(ray_pos.z));
}

vec3 octahedron_normal(vec3 ray_pos, float size) {
    return normalize(vec3(sign(ray_pos)));
}


////////////////////////////////////////////////////////////////////////////////
/// ray marching
////////////////////////////////////////////////////////////////////////////////

vec4 raymarch(vec3 start, vec3 dir)
{
    int N_objects = textureSize(marker_mode, 0).x;
    vec3 ray_pos = start;
    vec3 ray_dir = normalize(dir);
    float max_dist = length(dir);
    float min_step = 0.1 * max_dist / float(num_samples);

    int picked_index = -1;
    float picked_distance = 0.0;
    float total_distance = 0.0;
    int iter_counter = 0;

    for (int iter = 0; iter < 10 * num_samples; iter++)
    {
        iter_counter = iter;
        float min_dist = 1000000.0;
        int min_idx = 0;
        for (int i = 0; i < N_objects; i++)
        {
            // TODO: extract sdf from marker_mode
            vec3 sdf_pos = texelFetch(position, i, 0).xyz;
            vec3 scale = texelFetch(markersize, i, 0).xyz;
            // vec3 rot = texelFetch(rotation, i, 0);

            // float dist = ellipsoid_dist(ray_pos, sdf_pos, scale);
            // float dist = rect_frame_dist(ray_pos - sdf_pos, scale, 0.05);
            // float dist = torus_dist(ray_pos - sdf_pos, scale.x, scale.y);
            // float dist = capped_torus_dist(ray_pos - sdf_pos, 1.5708, 0.5, 0.2);
            // float dist = link_dist(ray_pos - sdf_pos, 0.5, 0.3, 0.1);
            // float dist = cylinder_dist(ray_pos - sdf_pos, 0.2, 0.5);
            // float dist = capsule_dist(ray_pos - sdf_pos, 0.2, 0.5);
            // float dist = cone_dist(ray_pos - sdf_pos, 0.2, 0.5);
            // float dist = octahedron_dist(ray_pos - sdf_pos, 0.5);
            float dist = pyramid_dist(ray_pos - sdf_pos, 0.3, 0.5);

            if (dist < min_dist)
            {
                min_dist = dist;
                min_idx = i;
            }
        }

        float move_by = clamp(min_dist, 0.1 * min_step, 10 * min_step);

        if (min_dist < 0.0)
        {
            picked_index = min_idx;
            picked_distance = min_dist;
            break;
        }
        else if (total_distance + move_by > max_dist)
        {
            break;
        }
        else
        {
            ray_pos += move_by * ray_dir;
            total_distance += move_by;
        }
    }

    if (picked_index != -1)
    {
        vec3 sdf_pos = texelFetch(position, picked_index, 0).xyz;
        vec3 base_color = texelFetch(color, picked_index, 0).xyz; // TODO: cases
        vec3 scale = texelFetch(markersize, picked_index, 0).xyz;

        // vec3 normal = ellipsoid_normal(ray_pos, sdf_pos, scale);
        // vec3 normal = rect_normal(ray_pos - sdf_pos, scale);
        // vec3 normal = rect_frame_normal(ray_pos - sdf_pos, scale, 0.05);
        // vec3 normal = capped_torus_normal(ray_pos - sdf_pos, 1.5708, 0.5, 0.2);
        // vec3 normal = link_normal(ray_pos - sdf_pos, 0.5, 0.3, 0.1);
        // vec3 normal = cylinder_normal(ray_pos - sdf_pos, 0.2, 0.5);
        // vec3 normal = capsule_normal(ray_pos - sdf_pos, 0.2, 0.5);
        // vec3 normal = cone_normal(ray_pos - sdf_pos, 0.2, 0.5);
        // vec3 normal = octahedron_normal(ray_pos - sdf_pos, 0.5);

        vec3 normal;
        {
            const float h = 0.01 * min_step;
            const vec2 k = vec2(1, -1) * 0.5773;
            normal = normalize(
                k.xyy * (pyramid_dist(ray_pos + k.xyy * h, 0.3, 0.5)) +
                k.yyx * (pyramid_dist(ray_pos + k.yyx * h, 0.3, 0.5)) +
                k.yxy * (pyramid_dist(ray_pos + k.yxy * h, 0.3, 0.5)) +
                k.xxx * (pyramid_dist(ray_pos + k.xxx * h, 0.3, 0.5))
            );
        }

        vec3 color = illuminate(ray_pos, ray_dir, normal, base_color);

        // // if we're inside the shape we hit a solid part, if we're outside we
        // // probably scratched an edge?
        // float alpha = 1.0 - max(0.0, 2.0 * dist / min_step);

        // OK, no, but specifically spheres can check normals...
        // float alpha = 10 * abs(dot(normal, ray_dir));

        return vec4(color, 1);
    }
    else
    {
        discard;
        return vec4(0, 0, 0, 0);
    }
}

// prefix Operations
const uint op_revolution = 0;
const uint op_elongate = 1;
const uint op_rotation = 2;
const uint op_mirror = 3; // enable dims in data
const uint op_infinite_repetition = 4;
const uint op_limited_repetition = 5;
const uint op_twist = 6;
const uint op_bend = 7;
const uint op_translation = 10;

// include this with sdf
// maybe also include position
// both of them seem practically guaranteed to be set
// const uint op_scale = 49; // special, needs to apply before and after sdf...

// Shapes 2D (for extrusion, revolution)
const uint shape_Vesica = 50;
const uint shape_Plane = 51;
const uint shape_Rhombus = 52; // extrusion
const uint shape_Hexagonal_prism = 53; // extrusion
const uint shape_Triangular_prism = 54; // extrusion

// Shapes 3D
const uint shape_Sphere = 100;              // check
const uint shape_Octahedron = 101;          // check
const uint shape_Pyramid = 102;             // check
const uint shape_Torus = 103;               // check
const uint shape_Capsule = 104;             // check
const uint shape_Capped_Cylinder = 105;     // check
const uint shape_Ellipsoid = 106;           // check
const uint shape_Rect = 107;                // check
const uint shape_Link = 108;                // check
const uint shape_Capped_Cone = 109;         // check
const uint shape_Solid_Angle = 110;         //
const uint shape_BoxFrame = 111;            // check
const uint shape_Capped_Torus = 112;        // check

// probably not
// infinite Cone
// Hollow Sphere // subtraction
// Death Star // subtraction
// Cut Sphere // subtraction

const uint op_extrusion = 150;
const uint op_rounding = 151;
const uint op_onion = 152;

const uint op_union = 200;
const uint op_subtraction = 201;
const uint op_intersection = 202;
const uint op_xor = 203;
const uint op_smooth_union = 204;
const uint op_smooth_subtraction = 205;
const uint op_smooth_intersection = 206;
const uint op_smooth_xor = 207;


struct SampleData
{
    float dist;
    int index;
};

SampleData sample_at(vec3 ray_pos)
{
    int N_objects = textureSize(marker_mode, 0).x;

    float min_dist = 1000000.0;
    int min_idx = 0;

    for (int i = 0; i < N_objects; i++)
    {
        // uint operation = texelFetch(operation_buffer, i).x;

        // if (operation == )
        float dist = 0.0;

        if (dist < min_dist)
        {
            min_dist = dist;
            min_idx = i;
        }
    }
    return SampleData(min_dist, min_idx);
}

vec4 raymarch2(vec3 start, vec3 dir)
{
    vec3 ray_pos = start;
    vec3 ray_dir = normalize(dir);
    float max_dist = length(dir);
    float min_step = 0.1 * max_dist / float(num_samples);

    int picked_index = -1;
    float picked_distance = 0.0;
    float total_distance = 0.0;
    int iter_counter = 0;

    for (int iter = 0; iter < 10 * num_samples; iter++)
    {
        iter_counter = iter;
        float min_dist = 1000000.0;
        int min_idx = 0;
        SampleData _sample = sample_at(ray_pos);

        float move_by = clamp(min_dist, min_step, 10 * min_step);

        if (min_dist < 0.0)
        {
            picked_index = min_idx;
            picked_distance = min_dist;
            break;
        }
        else if (total_distance + move_by > max_dist)
        {
            break;
        }
        else
        {
            ray_pos += move_by * ray_dir;
            total_distance += move_by;
        }
    }

    if (picked_index != -1)
    {
        vec3 sdf_pos = texelFetch(position, picked_index, 0).xyz;
        vec3 base_color = texelFetch(color, picked_index, 0).xyz; // TODO: cases
        vec3 scale = texelFetch(markersize, picked_index, 0).xyz;

        // vec3 normal = ellipsoid_normal(ray_pos, sdf_pos, scale);
        // vec3 normal = rect_normal(ray_pos - sdf_pos, scale);
        // vec3 normal = rect_frame_normal(ray_pos - sdf_pos, scale, 0.05);
        // vec3 normal = capped_torus_normal(ray_pos - sdf_pos, 1.5708, 0.5, 0.2);
        // vec3 normal = link_normal(ray_pos - sdf_pos, 0.5, 0.3, 0.1);
        vec3 normal = cylinder_normal(ray_pos - sdf_pos, 0.2, 0.5);

        vec3 color = illuminate(ray_pos, ray_dir, normal, base_color);

        // // if we're inside the shape we hit a solid part, if we're outside we
        // // probably scratched an edge?
        // float alpha = 1.0 - max(0.0, 2.0 * dist / min_step);

        // OK, no, but specifically spheres can check normals...
        // float alpha = 10 * abs(dot(normal, ray_dir));

        return vec4(color, 1);
    }
    else
    {
        discard;
        return vec4(0, 0, 0, 0);
    }
}


bool process_clip_planes(inout vec3 p1, inout vec3 p2)
{
    float d1, d2;
    for (int i = 0; i < _num_clip_planes; i++) {
        // distance from clip planes with negative clipped
        d1 = dot(p1.xyz, clip_planes[i].xyz) - clip_planes[i].w;
        d2 = dot(p2.xyz, clip_planes[i].xyz) - clip_planes[i].w;

        // both outside - clip everything
        if (d1 < 0.0 && d2 < 0.0) {
            p2 = p1;
            return true;
        }

        // one outside - shorten segment
        else if (d1 < 0.0)
            // solve 0 = m * t + b = (d2 - d1) * t + d1 with t in (0, 1)
            p1 = p1 - d1 * (p2 - p1) / (d2 - d1);
        else if (d2 < 0.0)
            p2 = p2 - d2 * (p1 - p2) / (d1 - d2);
    }

    return false;
}

bool no_solution(float x){
    return x <= 0.0001 || isinf(x) || isnan(x);
}

float min_bigger_0(float a, float b){
    bool a_no = no_solution(a);
    bool b_no = no_solution(b);
    if(a_no && b_no){
        // no solution
        return typemax;
    }
    if(a_no){
        return b;
    }
    if(b_no){
        return a;
    }
    return min(a, b);
}

float min_bigger_0(vec3 v1, vec3 v2){
    float x = min_bigger_0(v1.x, v2.x);
    float y = min_bigger_0(v1.y, v2.y);
    float z = min_bigger_0(v1.z, v2.z);
    return min(x, min(y, z));
}

void main()
{
#ifdef ENABLE_DEPTH
    gl_FragDepth = gl_FragCoord.z;
#endif

    vec4 color;
    vec3 eye_unit = vec3(modelinv * vec4(eyeposition, 1));
    vec3 back_position = vec3(modelinv * vec4(frag_vert, 1));
    vec3 dir = normalize(eye_unit - back_position);

    // In model space (pre model application) the volume is defined in a const
    // 0..1 box. If the camera is inside the box we start our rays from the
    // camera position (eyeposition).
    // TODO: Should we consider near here?

    // bool is_outside_box = (eye_unit.x < 0.0 || eye_unit.y < 0.0 || eye_unit.z < 0.0
    //         || eye_unit.x > 1.0 || eye_unit.y > 1.0 || eye_unit.z > 1.0);
    bool is_outside_box = true;

    vec3 start = eye_unit;
    vec3 stop = back_position;

    // Otherwise we find the box - ray intersection so we can skip the empty
    // space between the camera and the volume

    // if (is_outside_box) {
    //     // only trace inside the box:
    //     // solve back_position + distance * dir == 1
    //     // solve back_position + distance * dir == 0
    //     // to see where it first hits unit cube!
    //     vec3 solution_1 = (1.0 - back_position) / dir;
    //     vec3 solution_0 = (0.0 - back_position) / dir;
    //     float solution = min_bigger_0(solution_1, solution_0);
    //     start = back_position + solution * dir;
    // }

#ifdef ENABLE_DEPTH
    vec4 frag_coord = projectionview * model * vec4(start, 1);
    clip_depth = frag_coord.z / frag_coord.w;
#endif

    // if completely clipped discard this ray tracing attempt
    // TODO: this should discard samples too
    if (process_clip_planes(start, stop))
        discard;

    // vec3 step_in_dir = (stop - start) / num_samples;

    color = raymarch(start, stop - start);

#ifdef ENABLE_DEPTH
    // By default OpenGL renormalizes depth to a 0..1 range. We need to do this
    // manually here. (Should be generalizable with gl_DepthRange...)
    gl_FragDepth = 0.5 * (clip_depth + depth_shift + 1);
#endif

    write2framebuffer(color, uvec2(objectid, 0));
}
