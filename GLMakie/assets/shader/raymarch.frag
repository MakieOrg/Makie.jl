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

// {{color_map_type}} color_map;
// {{color_type}} color;
// {{color_norm_type}} color_norm;

uniform vec3 eyeposition;
uniform mat4 modelinv;

uniform mat4 model, projectionview;
uniform int _num_clip_planes;
uniform vec4 clip_planes[8];
uniform float depth_shift;

uniform usampler1D id_buffer;
uniform sampler1D data_buffer;

const float max_distance = 1.3;

const int num_samples = 200;
const float step_size = max_distance / float(num_samples);

uniform uint objectid;

void write2framebuffer(vec4 color, uvec2 id);

#ifndef NO_SHADING
vec3 illuminate(vec3 world_pos, vec3 camdir, vec3 normal, vec3 base_color);
#endif

#ifdef NO_SHADING
vec3 illuminate(vec3 world_pos, vec3 camdir, vec3 normal, vec3 base_color) {
    return normal;
}
#endif

const float typemax = 100000000000000000000000000000000000000.0;

vec3 qmul(vec4 quat, vec3 vec)
{
    // using inverse of quat, which means -xyz, instead of xyz
    float num = -quat.x * 2.0;
    float num2 = -quat.y * 2.0;
    float num3 = -quat.z * 2.0;
    float num4 = -quat.x * num;
    float num5 = -quat.y * num2;
    float num6 = -quat.z * num3;
    float num7 = -quat.x * num2;
    float num8 = -quat.x * num3;
    float num9 = -quat.y * num3;
    float num10 = quat.w * num;
    float num11 = quat.w * num2;
    float num12 = quat.w * num3;
    return vec3(
        (1.0 - (num5 + num6)) * vec.x + (num7 - num12) * vec.y + (num8 + num11) * vec.z,
        (num7 + num12) * vec.x + (1.0 - (num4 + num6)) * vec.y + (num9 - num10) * vec.z,
        (num8 - num11) * vec.x + (num9 + num10) * vec.y + (1.0 - (num4 + num5)) * vec.z
    );
}

////////////////////////////////////////////////////////////////////////////////
/// Distance Functions
////////////////////////////////////////////////////////////////////////////////

// These are all assumed to be centered around 0. `ray_pos` may be translated
// externally to translate the sdf.

float sphere_dist(vec3 ray_pos, float radius) { return length(ray_pos) - radius; }

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
    // TODO: underestimates distance when we're diagonally below/above the cylinder
    //  |    |
    //..|____|.. OK
    //  : OK : wrong
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
/// ray marching
////////////////////////////////////////////////////////////////////////////////

{{operation_enum}}

int data_idx = 0;

float read_float()
{
    float data = texelFetch(data_buffer, data_idx, 0).x;
    data_idx++;
    return data;
}

vec2 read_vec2()
{
    vec2 data = vec2(
        texelFetch(data_buffer, data_idx + 0, 0).x,
        texelFetch(data_buffer, data_idx + 1, 0).x
    );
    data_idx += 2;
    return data;
}

vec3 read_vec3()
{
    vec3 data = vec3(
        texelFetch(data_buffer, data_idx + 0, 0).x,
        texelFetch(data_buffer, data_idx + 1, 0).x,
        texelFetch(data_buffer, data_idx + 2, 0).x
    );
    data_idx += 3;
    return data;
}

vec4 read_vec4()
{
    vec4 data = vec4(
        texelFetch(data_buffer, data_idx + 0, 0).x,
        texelFetch(data_buffer, data_idx + 1, 0).x,
        texelFetch(data_buffer, data_idx + 2, 0).x,
        texelFetch(data_buffer, data_idx + 3, 0).x
    );
    data_idx += 4;
    return data;
}

void apply_prefix(inout vec3 sample_pos, in uint operation, in vec3 ray_pos)
{
    if (operation == op_revolution)
        // TODO: arbitrary rotation around vec3? Or just force use of op_rotation...
        // float moves the 2d object away from th center of rotation
        // TODO: What should 2D shapes do with the third coordinate? What's neutral? Inf?
        sample_pos = vec3(length(sample_pos.xy) - read_float(), sample_pos.z, 0.0);
    else if (operation == op_elongate)
    {
        vec3 dir = read_vec3();
        sample_pos = sample_pos - clamp(sample_pos, -dir, dir);
    }
    else if (operation == op_rotation)
        sample_pos = qmul(read_vec4(), sample_pos);
    else if (operation == op_mirror)
        // vec3 input is 1 (true) if the axis should be mirrored, 0 (false) otherwise
        sample_pos = mix(sample_pos, abs(sample_pos), read_vec3());
    else if (operation == op_infinite_repetition)
    {
        vec3 rep_dist = read_vec3();
        sample_pos = sample_pos - rep_dist * round(sample_pos / rep_dist);
    }
    else if (operation == op_limited_repetition)
    {
        vec3 rep_dist = read_vec3();
        vec3 limit = read_vec3();
        sample_pos = sample_pos - rep_dist * clamp(round(sample_pos / rep_dist), -limit, limit);
    }
    else if (operation == op_twist)
    {
        float k = read_float();
        float c = cos(k * sample_pos.z);
        float s = sin(k * sample_pos.z);
        mat2 T = mat2(c, -s, s, c);
        sample_pos = vec3(T * sample_pos.xy, sample_pos.z); // Quilez has this reorder (T*xz, y)
    }
    else if (operation == op_bend)
    {
        float k = read_float();
        float c = cos(k * sample_pos.z);
        float s = sin(k * sample_pos.z);
        mat2 T = mat2(c, -s, s, c);
        sample_pos = vec3(T * sample_pos.xz, sample_pos.y).xzy; // Quilez has this not reorder (T*xy, z)
    }
    else if (operation == op_translation)
        sample_pos -= read_vec3();
    else if (operation == _reset)
        sample_pos = ray_pos;
}

float sample_sdf(in vec3 sample_pos, in uint operation)
{
    switch (operation)
    {
        // case shape2D_vesica:
        // case shape2D_plane:
        // case shape2D_rhombus:
        // case shape2D_hexagonal_prism:
        // case shape2D_triangular_prism:
        case shape3D_sphere:
            return sphere_dist(sample_pos, read_float());
        case shape3D_octahedron:
            return octahedron_dist(sample_pos, read_float());
        case shape3D_pyramid:
            return pyramid_dist(sample_pos, read_float(), read_float());
        case shape3D_torus:
            return torus_dist(sample_pos, read_float(), read_float());
        case shape3D_capsule:
            return capsule_dist(sample_pos, read_float(), read_float());
        case shape3D_cylinder: // TODO: rename?
            return cylinder_dist(sample_pos, read_float(), read_float());
        case shape3D_ellipsoid:
            return ellipsoid_dist(sample_pos, read_vec3());
        case shape3D_rect:
            return rect_dist(sample_pos, read_vec3());
        case shape3D_link:
            return link_dist(sample_pos, read_float(), read_float(), read_float());
        case shape3D_cone:
            return cone_dist(sample_pos, read_float(), read_float());
        case shape3D_capped_cone:
            return capped_cone_dist(sample_pos, read_float(), read_float(), read_float());
        // case shape3D_solid_angle:
            // TODO
        case shape3D_box_frame:
            return rect_frame_dist(sample_pos, read_vec3(), read_float());
        case shape3D_capped_torus:
            return capped_torus_dist(sample_pos, read_float(), read_float(), read_float());
        default:
            return 10000.0;
    }
}

void merge(inout float sdf1, inout vec4 color1, in float sdf2, in vec4 color2, in uint operation)
{
    if (operation < op_smooth_union) // not smoothed
    {
        bool use_left; // 0 = use left value

        if (operation == op_union)
            use_left = sdf1 < sdf2;
        else if (operation == op_subtraction)
            use_left = -sdf1 > sdf2;
        else if (operation == op_intersection)
            use_left = sdf1 > sdf2;
        else if (operation == op_xor)
            use_left = min(sdf1, sdf2) > -max(sdf1, sdf2);

        // equivalent to ifelse(mixing == 0.0, sdf1, sdf2)
        sdf1 = use_left ? sdf1 : sdf2;
        color1 = use_left ? color1 : color2;
    }
    else // smoothed
    {
        // quadratic smoothing
        float smoothing = read_float();
        float _sign = -1.0;

        if (operation == op_smooth_union)
            _sign = 1.0;
        else if (operation == op_smooth_subtraction)
            sdf2 = -sdf2;
        else if (operation == op_smooth_intersection){
            sdf1 = -sdf1;
            sdf2 = -sdf2;
        } else if (operation == op_smooth_xor) {
            float temp = min(sdf1, sdf2);
            sdf2 = -max(sdf1, sdf2);
            sdf1 = temp;
        }

        // color
        float h = 1.0 - min(0.25 * abs(sdf1 - sdf2) / smoothing, 1.0);
        float w = h * h;
        float m = 0.5 * w;
        float s = w * smoothing;
        vec2 factors = (sdf1 < sdf2) ? vec2(sdf1 - s, m) : vec2(sdf2 - s, 1.0 - m);
        sdf1 = _sign * factors.x;
        color1 = mix(color1, color2, factors.y);
    }
}

void merge(inout float sdf1, in float sdf2, in uint operation)
{
    if (operation < op_smooth_union) // not smoothed
    {
        bool use_left; // 0 = use left value

        if (operation == op_union)
            sdf1 = min(sdf1, sdf2);
        else if (operation == op_subtraction)
            sdf1 = max(-sdf1, sdf2);
        else if (operation == op_intersection)
            sdf1 = max(sdf1, sdf2);
        else if (operation == op_xor)
            sdf1 = max(min(sdf1, sdf2), -max(sdf1, sdf2));
    }
    else // smoothed
    {
        // quadratic smoothing
        float smoothing = read_float();
        float _sign = -1.0;

        if (operation == op_smooth_union)
            _sign = 1.0;
        else if (operation == op_smooth_subtraction)
            sdf2 = -sdf2;
        else if (operation == op_smooth_intersection){
            sdf1 = -sdf1;
            sdf2 = -sdf2;
        } else if (operation == op_smooth_xor) {
            float temp = min(sdf1, sdf2);
            sdf2 = -max(sdf1, sdf2);
            sdf1 = temp;
        }

        float h = max(smoothing - 0.25 * abs(sdf1 - sdf2), 0.0 ) / smoothing;
        sdf1 = _sign * (min(sdf1, sdf2) - h * h * smoothing);
    }
}

void apply_postfix(inout vec3 sample_pos, in float sdf, in uint operation)
{
    if (operation == op_extrusion)
    {
        vec3 dir = read_vec3();
        vec2 vec = vec2(sdf, length(abs(sample_pos) - dir));
        sdf = min(max(vec.x, vec.y), 0.0) + length(max(vec, 0.0));
    }
    else if (operation == op_rounding)
        sdf = sdf - read_float();
    else if (operation == op_onion)
        sdf = abs(sdf) - read_float();
}

vec4 sample_color_at(in vec3 ray_pos)
{
    int N_objects = textureSize(id_buffer, 0);

    data_idx = 0; // reset global
    int stack_idx = 0;

    const int MAX_STACK_SIZE = 16;
    float sdf_stack[MAX_STACK_SIZE];
    vec4 color_stack[MAX_STACK_SIZE];

    vec3 sample_pos = ray_pos;
    uint operation;

    for (int i = 0; i < N_objects; i++)
    {
        operation = texelFetch(id_buffer, i, 0).x;

        if (operation < _start_of_shapes) // prefix
            apply_prefix(sample_pos, operation, ray_pos);

        else if (operation < _start_of_merge) // sdf
        {
            color_stack[stack_idx] = read_vec4();
            sdf_stack[stack_idx] = sample_sdf(sample_pos, operation);
            stack_idx++;
        }
        else if (operation < _start_of_postfix) // merge operation
        {
            merge(
                sdf_stack[stack_idx - 2],
                color_stack[stack_idx - 2],
                sdf_stack[stack_idx - 1],
                color_stack[stack_idx - 1],
                operation
            );

            stack_idx--;
        }
        else // postfix
            apply_postfix(sample_pos, sdf_stack[stack_idx - 1], operation);
    }

    // stack_idx should always be 0 here
    return color_stack[0];
}

float sample_sdf_at(in vec3 ray_pos)
{
    int N_objects = textureSize(id_buffer, 0);

    data_idx = 0; // reset global
    int stack_idx = 0;

    const int MAX_STACK_SIZE = 16;
    float sdf_stack[MAX_STACK_SIZE];

    vec3 sample_pos = ray_pos;
    uint operation;

    for (int i = 0; i < N_objects; i++)
    {
        operation = texelFetch(id_buffer, i, 0).x;

        if (operation < _start_of_shapes) // prefix
            apply_prefix(sample_pos, operation, ray_pos);

        else if (operation < _start_of_merge) // sdf
        {
            data_idx += 4; // skip over color;
            sdf_stack[stack_idx] = sample_sdf(sample_pos, operation);
            stack_idx++;
        }
        else if (operation < _start_of_postfix) // merge operation
        {
            merge(
                sdf_stack[stack_idx - 2],
                sdf_stack[stack_idx - 1],
                operation
            );

            stack_idx--;
        }
        else // postfix
        {
            apply_postfix(sample_pos, sdf_stack[stack_idx - 1], operation);
        }
    }

    // stack_idx should always be 0 here
    return sdf_stack[0];
}

vec3 generate_normal(vec3 sample_pos, float eps)
{
    const vec2 k = vec2(1, -1) * 0.5773;
    float sdf1 = sample_sdf_at(sample_pos + k.xyy * eps);
    float sdf2 = sample_sdf_at(sample_pos + k.yyx * eps);
    float sdf3 = sample_sdf_at(sample_pos + k.yxy * eps);
    float sdf4 = sample_sdf_at(sample_pos + k.xxx * eps);
    return normalize(k.xyy * sdf1 + k.yyx * sdf2 + k.yxy * sdf3 + k.xxx * sdf4);
}

vec4 raymarch(vec3 start, vec3 dir)
{
    vec3 ray_pos = start;
    vec3 ray_dir = normalize(dir);
    float max_dist = length(dir);
    float min_step = 0.01 * max_dist / float(num_samples);

    float picked_distance = 0.0;
    float total_distance = 0.0;

    for (int iter = 0; iter < num_samples; iter++)
    {
        picked_distance = sample_sdf_at(ray_pos);

        float move_by = max(picked_distance, min_step);

        if (picked_distance < 0.0)
        {
            ray_pos += picked_distance * ray_dir;
            break;
        }
        else if (total_distance + move_by > max_dist)
        {
            discard;
            // return vec4(float(iter) / float(num_samples), 0, 0, 1);
            return vec4(float(iter) / float(num_samples), 1, 0, 1);
        }
        else
        {
            ray_pos += move_by * ray_dir;
            total_distance += move_by;
        }
    }

    vec4 base_color = sample_color_at(ray_pos);
    vec3 normal = generate_normal(ray_pos, 0.1 * min_step);
    vec3 color = illuminate(ray_pos, ray_dir, normal, base_color.rgb);

    return vec4(color, 1);
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
