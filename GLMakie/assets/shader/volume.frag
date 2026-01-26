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

{{volumedata_type}} volumedata;
{{indexmap_type}} indexmap;
{{bricks_type}} bricks;
{{brick_colors_type}} brick_colors;

{{color_map_type}} color_map;
{{color_type}} color;
{{color_norm_type}} color_norm;

uniform float absorption = 1.0;
uniform vec3 eyeposition, view_direction;
uniform bool is_orthographic;

uniform mat4 modelinv;
uniform int algorithm;
uniform float isovalue;
uniform float isorange;
uniform int bricksize;

uniform mat4 model, projectionview;
uniform int _num_clip_planes;
uniform vec4 clip_planes[8];
uniform float depth_shift;

const float max_distance = 1.3;

// const int num_samples = 200;
const int num_samples = 1000;
const float step_size = max_distance / float(num_samples);

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

vec4 get_volume_sample(sampler3D volumedata, Nothing indexmap, Nothing bricks, vec3 uvw)
{
    return texture(volumedata, uvw);
}

int tracker = 0;
vec4 get_volume_sample(Nothing volumedata, usampler3D indexmap, sampler3D bricks, vec3 uvw)
{
    // no half bins on the edges
    // | 0 | 1 | 2 |  index
    // 0  1/3 2/3  1  uv
    // 0   1   2   3  uv * size
    uvec3 isize = textureSize(indexmap, 0);
    ivec3 indexmap_ijk = min(ivec3(uvw * isize), ivec3(isize) - 1);
    uint index = texelFetch(indexmap, indexmap_ijk, 0).x; // check

    vec3 istep = 1 / vec3(isize - 1); // uvw distance to next brick

    // no brick here, move to next spot (half a cellsize is allowed)
    if (index == 0)
    {
        // when debug-drawing index we need to use smaller steps here so ray
        // marching can actually find the start of a brick here
        tracker = -1;
        // return vec4(0.5 * length(istep), 0, 0, 0); // too large
        return vec4(0.5 * istep.x, 0, 0, 0); // this seems fine
        // return vec4(0.05 * length(istep), 0, 0, 0);
        // return vec4(0.002, 0, 0, 0);
    }
    tracker = 1;

    index--; // index = 0 is implied, not part of bricks

    // test index
    // return vec4(
    //     float((index) % 7) / float(7),
    //     float((index) % 17) / float(17),
    //     float((index) % 23) / float(23),
    //     1.0
    // );

    ivec3 size = ivec3(textureSize(bricks, 0)) / bricksize;

    uint size_xy = size.x * size.y;
    uint k = index / size_xy;
    index = index - size_xy * k;
    uint j = index / size.x;
    uint i = index - size.x * j;

    // meh, not much to learn from that
    // return vec4(
    //     float(i) / float(size.x - 1),
    //     float(j) / float(size.y - 1),
    //     float(k) / float(size.z - 1),
    //     1
    // );

    // index.dim < size.dim
    // return vec4(size.x - i, size.y - j, size.z - k, 1);

    //////////////////////////////////////////////////////////////////////////// ^check

    // index of brick -> uvw in brickmap
    vec3 brickmap_uvw_origin = (vec3(i, j, k) + 0.5 / bricksize) / vec3(size);

    // effective size of the volume data
    // for each index in indexmap, we have a brick
    // each brick shares its shell with neighboring bricks -> (bricksize - 1)
    uvec3 world_size = isize * (bricksize - 1);

    // how far from the origin of the brick are we?
    vec3 offset_index = uvw * vec3(world_size) - indexmap_ijk * (bricksize - 1);

    // how far are we from the brick origin in the brickmaps uvw space?
    vec3 brickmap_uvw_offset = offset_index / vec3(textureSize(bricks, 0));

    // what's the full uvw position in the brickmap?
    vec3 brickmap_uvw = brickmap_uvw_origin + brickmap_uvw_offset;

    // in-brick offset
    // return vec4(offset_index / vec3(bricksize-1), 1);

    // origin of brick in brickmap
    // return vec4(brickmap_uvw_origin, 1);

    // offset in brickmap
    // return vec4(brickmap_uvw_offset * size, 1);

    // convert UInt8 to a float
    float cellsize = length(istep / bricksize); // distance to next point within a brick
    float compressed_sample = texture(bricks, brickmap_uvw).x;
    return vec4(
        compressed_sample * 2.0 * cellsize - cellsize,
        0, 0, 0
    );
}

vec3 brick_debug_color(usampler3D indexmap, vec3 uvw)
{
    uvec3 isize = textureSize(indexmap, 0) * bricksize;
    ivec3 indexmap_ijk = min(ivec3(uvw * isize), ivec3(isize) - bricksize);
    vec3 brick_color = 0.25 + 0.5 * mod(indexmap_ijk / bricksize, 2);
    // small differences in blue are harder to see
    vec3 cell_color = -vec3(0.05, 0.05, 0.1) + vec3(0.1, 0.1, 0.2) * mod(mod(indexmap_ijk, bricksize), 2);
    return brick_color + cell_color;
}

vec3 get_brick_color(usampler3D indexmap, sampler1D brick_colors, vec3 uvw)
{
    ivec3 isize = ivec3(textureSize(indexmap, 0));
    vec3 ijk = uvw * isize;
    ivec3 mini = ivec3(ijk);

    vec3 color = vec3(0);
    float summed_weight = 0.0;

    for (int i = 0; i < 2; i++)
    {
        for (int j = 0; j < 2; j++)
        {
            for (int k = 0; k < 2; k++)
            {
                ivec3 picked = min(mini + ivec3(i, j, k), isize-1);
                uint idx = texelFetch(indexmap, picked, 0).x;
                if (idx != 0)
                {
                    vec3 c = texelFetch(brick_colors, int(idx) - 1, 0).rgb;
                    vec3 w = 1 - abs(ijk - picked);
                    color += w.x * w.y * w.z * c;
                    summed_weight += w.x * w.y * w.z;
                }
            }
        }
    }

    return color / summed_weight;
}
vec3 get_brick_color(vec3 uvw) { return get_brick_color(indexmap, brick_colors, uvw); }

float get_eps(sampler3D volumedata, Nothing indexmap)
{
    vec3 step = 1.0 / vec3(textureSize(volumedata, 0));
    return max(max(step.x, step.y), step.z);
}
float get_eps(Nothing volumedata, usampler3D indexmap)
{
    // Moving out of a brick may cause us to sample a constant, larger brick,
    // resulting in a worse normal approximation. So keep the step smaller than
    // 1 interpolation cell to avoid it
    vec3 step = 0.1 / vec3(textureSize(indexmap, 0) * (bricksize - 1));
    return max(max(step.x, step.y), step.z);
}
float get_eps() { return get_eps(volumedata, indexmap); }

vec4 get_volume_sample(vec3 uvw)
{
    return get_volume_sample(volumedata, indexmap, bricks, uvw);
}

uvec3 get_volume_size(sampler3D volumedata, Nothing indexmap)
{
    return textureSize(volumedata, 0);
}
uvec3 get_volume_size(Nothing volumedata, usampler3D indexmap)
{
    return textureSize(indexmap, 0) * 8; // TODO: pass bricksize
}
uvec3 get_volume_size()
{
    return get_volume_size(volumedata, indexmap);
}


vec3 gennormal(vec3 uvw, float d, vec3 o)
{
    // uvw samples positions (0..1 values)
    // d is the sampling step. Could be any small value here
    // o is half the uvw distance between two voxels. A distance smaller than
    // that will result in equal positions when sampling on the edge of the
    // volume, generating broken normals.
    vec3 a, b;

    float eps = 0.001;

    // handle normals at edges!
    if(uvw.x + d >= 1.0){
        return vec3(1, 0, 0);
    }
    if(uvw.y + d >= 1.0){
        return vec3(0, 1, 0);
    }
    if(uvw.z + d >= 1.0){
        return vec3(0, 0, 1);
    }

    if(uvw.x - d <= 0.0){
        return vec3(-1, 0, 0);
    }
    if(uvw.y - d <= 0.0){
        return vec3(0, -1, 0);
    }
    if(uvw.z - d <= 0.0){
        return vec3(0, 0, -1);
    }

    a.x = get_volume_sample(uvw - vec3(o.x, 0.0, 0.0)).r;
    b.x = get_volume_sample(uvw + vec3(o.x, 0.0, 0.0)).r;

    a.y = get_volume_sample(uvw - vec3(0.0, o.y, 0.0)).r;
    b.y = get_volume_sample(uvw + vec3(0.0, o.y, 0.0)).r;

    a.z = get_volume_sample(uvw - vec3(0.0, 0.0, o.z)).r;
    b.z = get_volume_sample(uvw + vec3(0.0, 0.0, o.z)).r;

    vec3 diff = a - b;
    float n = length(diff);

    if (n < 0.000000000001) // 1e-12
        return diff;

    return diff / n;
}

#ifndef NO_SHADING
vec3 illuminate(vec3 world_pos, vec3 camdir, vec3 normal, vec3 base_color);
#endif

#ifdef NO_SHADING
vec3 illuminate(vec3 world_pos, vec3 camdir, vec3 normal, vec3 base_color) {
    return normal;
}
#endif

// Simple random generator found: http://stackoverflow.com/questions/4200224/random-noise-functions-for-glsl
float rand(){
    return fract(sin(gl_FragCoord.x * 12.9898 + gl_FragCoord.y * 78.233) * 43758.5453);
}

vec4 volume(vec3 front, vec3 dir)
{
    // The per-voxel alpha channel is specified in units of opacity/length.
    // If our voxels are not isotropic, then the distance that we trace through
    // depends on the direction.
    vec3  pos = front;
    float T = 1.0;
    vec3 Lo = vec3(0.0);
    int i = 0;
    for (i; i < num_samples; ++i) {
        float intensity = get_volume_sample(pos).x;
        vec4 density = color_lookup(intensity, color_map, color_norm, color);
        float opacity = step_size * density.a * absorption;
        T *= 1.0-opacity;
        if (T <= 0.01)
            break;

        Lo += (T*opacity)*density.rgb;
        pos += dir;
    }
    return vec4(Lo, 1-T);
}

vec4 additivergba(vec3 front, vec3 dir)
{
    vec3 pos = front;
    vec4 integrated_color = vec4(0., 0., 0., 0.);
    int i = 0;
    for (i; i < num_samples ; ++i) {
        vec4 density = get_volume_sample(pos);
        integrated_color = 1.0 - (1.0 - integrated_color) * (1.0 - density);
        pos += dir;
    }
    return integrated_color;
}

vec4 absorptionrgba(vec3 front, vec3 dir)
{
    vec3  pos = front;
    float T = 1.0;
    vec3 Lo = vec3(0.0);
    int i = 0;
    for (i; i < num_samples ; ++i) {
        vec4 density = get_volume_sample(pos);
        float opacity = step_size * density.a * absorption;
        T *= 1.0-opacity;
        if (T <= 0.01)
            break;

        Lo += (T*opacity)*density.rgb;
        pos += dir;
    }
    return vec4(Lo, 1-T);
}

vec4 volumeindexedrgba(vec3 front, vec3 dir)
{
    vec3 pos = front;
    float T = 1.0;
    vec3 Lo = vec3(0.0);
    int i = 0;
    for (i; i < num_samples; ++i) {
        int index = int(get_volume_sample(pos).x) - 1;
        vec4 density = color_lookup(color_map, index);
        float opacity = step_size*density.a * absorption;
        Lo += (T*opacity)*density.rgb;
        T *= 1.0 - opacity;
        if (T <= 0.01)
            break;
        pos += dir;
    }
    return vec4(Lo, 1-T);
}

vec4 contours(vec3 front, vec3 dir)
{
    vec3 pos = front;
    float T = 1.0;
    vec3 Lo = vec3(0.0);
    int i = 0;
    vec3 camdir = normalize(dir);
    vec3 edge_gap = 0.5 / get_volume_size(); // see gennormal
#ifdef ENABLE_DEPTH
    float depth = 100000.0;
#endif
    for (i; i < num_samples; ++i) {
        float intensity = get_volume_sample(pos).x;
        vec4 density = color_lookup(intensity, color_map, color_norm, color);
        float opacity = density.a;
        if(opacity > 0.0)
        {

#ifdef ENABLE_DEPTH
            vec4 frag_coord = projectionview * model * vec4(pos, 1);
            if (is_clipped(frag_coord))
            {
                pos += dir;
                continue;
            }
            else
                depth = min(depth, frag_coord.z / frag_coord.w);
#endif

            vec3 N = gennormal(pos, step_size, edge_gap);
            vec4 world_pos = model * vec4(pos, 1);
            vec3 opaque = illuminate(world_pos.xyz / world_pos.w, camdir, N, density.rgb);
            Lo += (T * opacity) * opaque;
            T *= 1.0 - opacity;
            if (T <= 0.01)
                break;
        }
        pos += dir;
    }
#ifdef ENABLE_DEPTH
    clip_depth = depth == 100000.0 ? clip_depth : depth;
#endif
    return vec4(Lo, 1-T);
}

vec4 isosurface(vec3 front, vec3 dir)
{
    vec3 pos = front;
    vec4 c = vec4(0.0);
    int i = 0;
    vec4 diffuse_color = color_lookup(isovalue, color_map, color_norm, color);
    vec3 camdir = normalize(dir);
    vec3 edge_gap = 0.5 / get_volume_size(); // see gennormal
#ifdef ENABLE_DEPTH
    float depth = 100000.0;
#endif
    for (i; i < num_samples; ++i){
        float density = get_volume_sample(pos).x;
        if(abs(density - isovalue) < isorange)
        {

#ifdef ENABLE_DEPTH
            vec4 frag_coord = projectionview * model * vec4(pos, 1);
            if (is_clipped(frag_coord))
            {
                pos += dir;
                continue;
            }
            else
                depth = min(depth, frag_coord.z / frag_coord.w);
#endif

            vec3 N = gennormal(pos, step_size, edge_gap);
            vec4 world_pos = model * vec4(pos, 1);
            c = vec4(
                illuminate(world_pos.xyz / world_pos.w, camdir, N, diffuse_color.rgb),
                diffuse_color.a
            );
            break;
        }
        pos += dir;
    }
#ifdef ENABLE_DEPTH
    clip_depth = depth == 100000.0 ? clip_depth : depth;
#endif
    return c;
}

vec3 generate_sdf_normal(vec3 uvw)
{
    const vec2 k = vec2(1, -1) * 0.5773;
    const float eps = get_eps();
    float sdf1 = get_volume_sample(uvw + k.xyy * eps).x;
    float sdf2 = get_volume_sample(uvw + k.yyx * eps).x;
    float sdf3 = get_volume_sample(uvw + k.yxy * eps).x;
    float sdf4 = get_volume_sample(uvw + k.xxx * eps).x;
    return normalize(k.xyy * sdf1 + k.yyx * sdf2 + k.yxy * sdf3 + k.xxx * sdf4);
}

vec4 raymarch_sdf(vec3 front, vec3 dir)
{
    vec3 pos = front;
    vec4 c = vec4(0.0);
    float max_distance = length(dir);
    vec3 camdir = dir / max_distance;

    float min_step = isorange;
    float cumulative_distance = 0.0;
    int i = 0;

    for (i; i < num_samples; ++i)
    {
        vec4 temp = get_volume_sample(pos);
        float signed_distance = temp.x;

        // if (tracker == 1)
        //     return temp;
            // return vec4(signed_distance / 0.007, -signed_distance / 0.007, 0, 1);

        // we still want to trigger this when we get into min_step range to
        // make one last improvement
        // if we get a negative distance (inside the shape) we want to be able
        // to move back outside
        pos = pos + sign(signed_distance) * max(abs(signed_distance), min_step) * camdir;
        cumulative_distance += signed_distance;

        if (abs(signed_distance) < min_step)
            break;
        else if (cumulative_distance > max_distance)
        {
            discard;
            return vec4(0, 0, 0, 0);
        }
    }

    vec4 world_pos = model * vec4(pos, 1);

#ifdef ENABLE_DEPTH
    vec4 frag_coord = projectionview * world_pos;
    clip_depth = frag_coord.z / frag_coord.w;
#endif

    float cost = i / num_samples;
    // vec3 color = vec3(cost * cost, (1 - cost) * (1 - cost), 0.1);
    // vec3 color = vec3(3 * cost - 2, 1 - 3 * cost, 1 - abs(3 * cost - 1.5));
    // vec3 color = brick_debug_color(indexmap, pos);
    vec3 color = get_brick_color(pos);
    // return vec4(color, 1);

    vec3 normal = generate_sdf_normal(pos);
    vec4 shaded_color = vec4(
        illuminate(world_pos.xyz / world_pos.w, camdir, normal, color), 1.0
    );
    return shaded_color;
}

vec4 mip(vec3 front, vec3 dir)
{
    vec3 pos = front + dir;
    int i = 1;
    float maximum = get_volume_sample(front).x;
    for (i; i < num_samples; ++i, pos += dir){
        float density = get_volume_sample(pos).x;
        if(maximum < density)
            maximum = density;
    }
    return color_lookup(maximum, color_map, color_norm, color);
}

uniform uint objectid;

void write2framebuffer(vec4 color, uvec2 id);

const float typemax = 100000000000000000000000000000000000000.0;


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
    vec3 dir;
    if (is_orthographic)
        dir = mat3(modelinv) * -view_direction; // is this correct for a direction?
    else
        dir = normalize(eye_unit - back_position);

    // In model space (pre model application) the volume is defined in a const
    // 0..1 box. If the camera is inside the box we start our rays from the
    // camera position (eyeposition).
    // TODO: Should we consider near here?

    bool is_outside_box = (eye_unit.x < 0.0 || eye_unit.y < 0.0 || eye_unit.z < 0.0
            || eye_unit.x > 1.0 || eye_unit.y > 1.0 || eye_unit.z > 1.0);

    vec3 start = eye_unit;
    vec3 stop = back_position;

    // Otherwise we find the box - ray intersection so we can skip the empty
    // space between the camera and the volume

    if (is_outside_box) {
        // only trace inside the box:
        // solve back_position + distance * dir == 1
        // solve back_position + distance * dir == 0
        // to see where it first hits unit cube!
        vec3 solution_1 = (1.0 - back_position) / dir;
        vec3 solution_0 = (0.0 - back_position) / dir;
        float solution = min_bigger_0(solution_1, solution_0);
        start = back_position + solution * dir;
    }

#ifdef ENABLE_DEPTH
    vec4 frag_coord = projectionview * model * vec4(start, 1);
    clip_depth = frag_coord.z / frag_coord.w;
#endif

    // if completely clipped discard this ray tracing attempt
    // TODO: this should discard samples too
    if (process_clip_planes(start, stop))
        discard;

    vec3 full_dir = (stop - start);
    vec3 step_in_dir = full_dir / num_samples;

    // the algorithm numbers correspond to the order in the
    // RaymarchAlgorithm enum defined in Makie types.jl
    if(algorithm == 0)
        color = isosurface(start, step_in_dir);
    else if(algorithm == 1)
        color = volume(start, step_in_dir);
    else if(algorithm == 2)
        color = mip(start, step_in_dir);
    else if(algorithm == 3)
        color = absorptionrgba(start, step_in_dir);
    else if(algorithm == 4)
        color = additivergba(start, step_in_dir);
    else if(algorithm == 5)
        color = volumeindexedrgba(start, step_in_dir);
    else if(algorithm == 6)
        color = raymarch_sdf(start, full_dir);
    else
        color = contours(start, step_in_dir);

#ifdef ENABLE_DEPTH
    // By default OpenGL renormalizes depth to a 0..1 range. We need to do this
    // manually here. (Should be generalizable with gl_DepthRange...)
    gl_FragDepth = 0.5 * (clip_depth + depth_shift + 1);
#endif

    write2framebuffer(color, uvec2(objectid, 0));
}
