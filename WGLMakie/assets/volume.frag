precision highp float;
precision highp int;

struct Nothing{ //Nothing type, to encode if some variable doesn't contain any data
    bool _; //empty structs are not allowed
};
in vec3 frag_vert;

uniform vec4 uniform_clip_planes[8];
uniform int uniform_num_clip_planes;
uniform vec3 light_color;
uniform vec3 ambient;
uniform vec3 light_direction;

uniform mat4 projection, view;

float _normalize(float val, float from, float to) { return (val-from) / (to - from); }

vec4 get_color_from_cmap(float value, sampler2D color_map, vec2 colorrange) {
    float cmin = colorrange.x;
    float cmax = colorrange.y;
    if (value <= cmax && value >= cmin) {
        // in value range, continue!
    } else if (value < cmin) {
        return get_lowclip_color();
    } else if (value > cmax) {
        return get_highclip_color();
    } else {
        // isnan is broken (of course) -.-
        // so if outside value range and not smaller/bigger min/max we assume NaN
        return get_nan_color();
    }
    float i01 = clamp((value - cmin) / (cmax - cmin), 0.0, 1.0);
    // 1/0 corresponds to the corner of the colormap, so to properly interpolate
    // between the colors, we need to scale it, so that the ends are at 1 - (stepsize/2) and 0+(stepsize/2).
    float stepsize = 1.0 / float(textureSize(color_map, 0));
    i01 = (1.0 - stepsize) * i01 + 0.5 * stepsize;
    return texture(color_map, vec2(i01, 0.0));
}

vec4 color_lookup(float intensity, sampler2D color_ramp, vec2 norm) {
    return get_color_from_cmap(intensity, color_ramp, norm);
}
vec4 color_lookup(vec4 color, bool color_ramp, bool norm) {
    return color; // stub method
}
vec4 color_lookup(float intensity, bool color_ramp, bool norm) {
    return vec4(0); // stub method
}

vec4 color_lookup(sampler2D uniform_colormap, int index) {
    return texelFetch(uniform_colormap, ivec2(index, 0), 0);
}
vec4 color_lookup(bool uniform_colormap, vec4 color) {
    return color; // stub method
}
vec4 color_lookup(bool uniform_colormap, int index) {
    return vec4(0); // stub method
}

vec3 gennormal(vec3 uvw, float d)
{
    vec3 a, b;
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

    a.x = texture(uniform_color, uvw - vec3(d,0.0,0.0)).r;
    b.x = texture(uniform_color, uvw + vec3(d,0.0,0.0)).r;

    a.y = texture(uniform_color, uvw - vec3(0.0,d,0.0)).r;
    b.y = texture(uniform_color, uvw + vec3(0.0,d,0.0)).r;

    a.z = texture(uniform_color, uvw - vec3(0.0,0.0,d)).r;
    b.z = texture(uniform_color, uvw + vec3(0.0,0.0,d)).r;
    return normalize(a-b);
}

// Smoothes out edge around 0 light intensity, see GLMakie
float smooth_zero_max(float x) {
    const float c = 0.00390625, xswap = 0.6406707120152759, yswap = 0.20508383900190955;
    const float shift = 1.0 + xswap - yswap;
    float pow8 = x + shift;
    pow8 = pow8 * pow8; pow8 = pow8 * pow8; pow8 = pow8 * pow8;
    return x < yswap ? c * pow8 : x;
}

vec3 blinnphong(vec3 N, vec3 V, vec3 L, vec3 color){
    // TODO use backlight here too?
    float diff_coeff = smooth_zero_max(dot(L, -N)) + smooth_zero_max(dot(L, N));
    // specular coefficient
    vec3 H = normalize(L + V);
    float spec_coeff = pow(max(dot(H, -N), 0.0) + max(dot(H, N), 0.0), shininess);
    // final lighting model
    return ambient * color + light_color * vec3(
        get_diffuse() * diff_coeff * color +
        get_specular() * spec_coeff
    );
}

// Simple random generator found:
// http://stackoverflow.com/questions/4200224/random-noise-functions-for-glsl
float rand(){
    return fract(sin(gl_FragCoord.x * 12.9898 + gl_FragCoord.y * 78.233) * 43758.5453);
}

vec4 volume(vec3 front, vec3 dir)
{
    // The per-voxel alpha channel is specified in units of opacity/length.
    // If our voxels are not isotropic, then the distance that we trace through
    // depends on the direction.
    vec3  pos = front;
    float transmittance = 1.0;
    vec3 color_sum = vec3(0.0);
    int i = 0;
    float step_size = length(dir);

    for (i; i < samples; ++i) {
        float intensity = texture(uniform_color, pos).x;
        vec4 color_sample = color_lookup(intensity, uniform_colormap, uniform_colorrange);

        float opacity = clamp(step_size * color_sample.a * absorption, 0.0, 1.0);
        color_sum += (opacity * transmittance) * color_sample.rgb;
        transmittance *= 1.0 - opacity;

        if (transmittance <= 0.01)
            break;

        pos += dir;
    }
    return vec4(color_sum / (1.0 - transmittance), 1.0 - transmittance);
}


vec4 absorptionrgba(vec3 front, vec3 dir)
{
    vec3  pos = front;
    float transmittance = 1.0;
    vec3 color_sum = vec3(0.0);
    int i = 0;
    float step_size = length(dir);

    for (i; i < samples ; ++i) {
        vec4 color_sample = texture(uniform_color, pos);

        float opacity = clamp(step_size * color_sample.a * absorption, 0.0, 1.0);
        color_sum += (transmittance * opacity) * color_sample.rgb;
        transmittance *= 1.0 - opacity;

        if (transmittance <= 0.01)
            break;

        pos += dir;
    }
    return vec4(color_sum / (1.0 - transmittance), 1.0 - transmittance);
}

vec4 contours(vec3 front, vec3 dir)
{
    vec3 pos = front;
    float transmittance = 1.0;
    vec3 color_sum = vec3(0.0);
    int i = 0;
    vec3 camdir = normalize(dir);
    float step_size = length(dir);

    for (i; i < samples; ++i) {
        float intensity = texture(uniform_color, pos).x;
        vec4 color_sample = color_lookup(intensity, uniform_colormap, uniform_colorrange);

        float opacity = color_sample.a;
        if(opacity > 0.0){
            vec3 N = gennormal(pos, step_size);
            vec3 L = light_direction;
            vec3 opaque = blinnphong(N, camdir, L, color_sample.rgb);
            color_sum += (transmittance * opacity) * opaque;
            transmittance *= 1.0 - opacity;

            if (transmittance <= 0.01)
                break;
        }
        pos += dir;
    }
    return vec4(color_sum / (1.0 - transmittance), 1.0 - transmittance);
}

vec4 isosurface(vec3 front, vec3 dir)
{
    vec3 pos = front;
    vec4 c = vec4(0.0);
    int i = 0;
    vec4 diffuse_color = color_lookup(isovalue, uniform_colormap, uniform_colorrange);
    vec3 camdir = normalize(dir);
    float step_size = length(dir);

    for (i; i < samples; ++i){
        float density = texture(uniform_color, pos).x;
        if(abs(density - isovalue) < isorange){
            vec3 N = gennormal(pos, step_size);
            vec3 L = light_direction;
            c = vec4(
                blinnphong(N, camdir, L, diffuse_color.rgb),
                diffuse_color.a
            );
            break;
        }
        pos += dir;
    }
    return c;
}

bool less_than_max(float val, Nothing range) { return true; }
bool less_than_max(float val, vec2 range) { return (val < range.y); }

vec4 mip(vec3 front, vec3 dir)
{
    vec3 pos = front + dir;
    int i = 0;
    float maximum = -10000000000000000.0;
    bool highclip_visible = get_highclip_color().a > 0.0;

    for (i; i < samples; ++i, pos += dir){
        float density = texture(uniform_color, pos).x;
        bool consider_sample = less_than_max(density, uniform_colorrange) || highclip_visible;
        if (consider_sample && (maximum < density))
            maximum = density;
    }
    if (maximum == -10000000000000000.0)
        maximum = 10000000000000000.0;
    return color_lookup(maximum, uniform_colormap, uniform_colorrange);
}

vec4 additivergba(vec3 front, vec3 dir)
{
    vec3 pos = front;
    vec4 integrated_color = vec4(0., 0., 0., 0.);
    int i = 0;
    for (i; i < samples ; ++i) {
        vec4 density = texture(uniform_color, pos);
        integrated_color = 1.0 - (1.0 - integrated_color) * (1.0 - density);
        pos += dir;
    }
    return integrated_color;
}

vec4 volumeindexedrgba(vec3 front, vec3 dir)
{
    vec3 pos = front;
    float transmittance = 1.0;
    vec3 color_sum = vec3(0.0);
    int i = 0;
    float step_size = length(dir);

    for (i; i < samples; ++i) {
        int index = int(texture(uniform_color, pos).x) - 1;
        vec4 color_sample = color_lookup(uniform_colormap, index);

        float opacity = clamp(step_size * color_sample.a * absorption, 0.0, 1.0);
        color_sum += (transmittance * opacity) * color_sample.rgb;
        transmittance *= 1.0 - opacity;

        if (transmittance <= 0.01)
            break;
        pos += dir;
    }
    return vec4(color_sum / (1.0 - transmittance), 1.0 - transmittance);
}

uniform uint objectid;

const float typemax = 100000000000000000000000000000000000000.0;

uniform int num_clip_planes;
bool process_clip_planes(inout vec3 p1, inout vec3 p2)
{
    float d1, d2;
    for (int i = 0; i < uniform_num_clip_planes; i++) {
        // distance from clip planes with negative clipped
        d1 = dot(p1.xyz, uniform_clip_planes[i].xyz) - uniform_clip_planes[i].w;
        d2 = dot(p2.xyz, uniform_clip_planes[i].xyz) - uniform_clip_planes[i].w;

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

vec2 encode_uint_to_float(uint value) {
    float lower = float(value & 0xFFFFu) / 65535.0;
    float upper = float(value >> 16u) / 65535.0;
    return vec2(lower, upper);
}

vec4 pack_int(uint id, uint index) {
    vec4 unpack;
    unpack.rg = encode_uint_to_float(id);
    unpack.ba = encode_uint_to_float(index);
    return unpack;
}

void main()
{
    vec4 color;
    vec3 eye_unit = vec3(modelinv * vec4(eyeposition, 1));
    vec3 back_position = frag_vert; // frag_vert is different from GLMakie here
    vec3 dir = normalize(eye_unit - back_position);

    bool is_outside_box = (eye_unit.x < 0.0 || eye_unit.y < 0.0 || eye_unit.z < 0.0
            || eye_unit.x > 1.0 || eye_unit.y > 1.0 || eye_unit.z > 1.0);

    vec3 start = eye_unit;
    vec3 stop = back_position;

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

    // if completely clipped discard this ray tracing attempt
    if (process_clip_planes(start, stop))
        discard;

    vec3 step_in_dir = (stop - start) / float(samples);

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
    else
        color = contours(start, step_in_dir);

    if (picking) {
        if (color.a > 0.1) {
            fragment_color = pack_int(object_id, uint(0));
        }
        return;
    }
    if (color.a <= 0.0){
        discard;
    }

    // use front face for depth, see GLMakie
    // TODO: depth calculation for contour, isosurface
    vec4 frag_coord = projection * view * model * vec4(start, 1.0);
    gl_FragDepth = 0.5 * (frag_coord.z / frag_coord.w + depth_shift + 1.0);

    fragment_color = color;
}
