struct Nothing{ //Nothing type, to encode if some variable doesn't contain any data
    bool _; //empty structs are not allowed
};
in vec3 frag_vert;
in vec3 o_light_dir;

const float max_distance = 1.3;

const int num_samples = 200;
const float step_size = max_distance / float(num_samples);

float _normalize(float val, float from, float to)
{
    return (val-from) / (to - from);
}

vec4 color_lookup(float intensity, sampler2D color_ramp, vec2 norm)
{
    return texture(color_ramp, vec2(_normalize(intensity, norm.x, norm.y), 0.0));
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

    a.x = texture(volumedata, uvw - vec3(d,0.0,0.0)).r;
    b.x = texture(volumedata, uvw + vec3(d,0.0,0.0)).r;

    a.y = texture(volumedata, uvw - vec3(0.0,d,0.0)).r;
    b.y = texture(volumedata, uvw + vec3(0.0,d,0.0)).r;

    a.z = texture(volumedata, uvw - vec3(0.0,0.0,d)).r;
    b.z = texture(volumedata, uvw + vec3(0.0,0.0,d)).r;
    return normalize(a-b);
}

vec3 blinnphong(vec3 N, vec3 V, vec3 L, vec3 color){
    float diff_coeff = max(dot(L, N), 0.0);
    // specular coefficient
    vec3 H = normalize(L + V);
    float spec_coeff = pow(max(dot(H, N), 0.0), shininess);
    // final lighting model
    return vec3(
        ambient * color +
        diffuse * diff_coeff * color +
        specular * spec_coeff
    );
}

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
        float intensity = texture(volumedata, pos).x;
        vec4 density = color_lookup(intensity, colormap, colorrange);
        float opacity = step_size * density.a * absorption;
        T *= 1.0 - opacity;
        if (T <= 0.01)
            break;

        Lo += (T*opacity)*density.rgb;
        pos += dir;
    }
    return vec4(Lo, 1.0 - T);
}


vec4 volumergba(vec3 front, vec3 dir)
{
    vec3  pos = front;
    float T = 1.0;
    vec3 Lo = vec3(0.0);
    int i = 0;
    for (i; i < num_samples ; ++i) {
        vec4 density = texture(volumedata, pos);
        float opacity = step_size * density.a;
        T *= 1.0 - opacity;
        if (T <= 0.01)
            break;

        Lo += (T*opacity)*density.rgb;
        pos += dir;
    }
    return vec4(Lo, 1.0 - T);
}

// vec4 volumeindexedrgba(vec3 front, vec3 dir)
// {
//     vec3 pos = front;
//     float T = 1.0;
//     vec3 Lo = vec3(0.0);
//     int i = 0;
//     for (i; i < num_samples; ++i) {
//         int index = int(texture(volumedata, pos).x) - 1;
//         vec4 density = color_lookup(colormap, index);
//         float opacity = step_size*density.a;
//         Lo += (T*opacity)*density.rgb;
//         T *= 1.0 - opacity;
//         if (T <= 0.01)
//             break;
//         pos += dir;
//     }
//     return vec4(Lo, 1-T);
// }

vec4 contours(vec3 front, vec3 dir)
{
    vec3 pos = front;
    float T = 1.0;
    vec3 Lo = vec3(0.0);
    int i = 0;
    vec3 camdir = normalize(-dir);
    for (i; i < num_samples; ++i) {
        float intensity = texture(volumedata, pos).x;
        vec4 density = color_lookup(intensity, colormap, colorrange);
        float opacity = density.a;
        if(opacity > 0.0){
            vec3 N = gennormal(pos, step_size);
            vec3 L = normalize(o_light_dir - pos);
            vec3 opaque = blinnphong(N, camdir, L, density.rgb);
            Lo += (T * opacity) * opaque;
            T *= 1.0 - opacity;
            if (T <= 0.01)
                break;
        }
        pos += dir;
    }
    return vec4(Lo, 1.0 - T);
}

vec4 isosurface(vec3 front, vec3 dir)
{
    vec3 pos = front;
    vec4 c = vec4(0.0);
    int i = 0;
    vec4 diffuse_color = color_lookup(isovalue, colormap, colorrange);
    vec3 camdir = normalize(-dir);
    for (i; i < num_samples; ++i){
        float density = texture(volumedata, pos).x;
        if(abs(density - isovalue) < isorange){
            vec3 N = gennormal(pos, step_size);
            vec3 L = normalize(o_light_dir - pos);
            // back & frontface...
            vec3 c1 = blinnphong(N, camdir, L, diffuse_color.rgb);
            vec3 c2 = blinnphong(-N, camdir, L, diffuse_color.rgb);
            c = vec4(0.5*c1 + 0.5*c2, diffuse_color.a);
            break;
        }
        pos += dir;
    }
    return c;
}

vec4 mip(vec3 front, vec3 dir)
{
    vec3 pos = front;
    int i = 0;
    float maximum = 0.0;
    for (i; i < num_samples; ++i, pos += dir){
        float density = texture(volumedata, pos).x;
        if(maximum < density)
            maximum = density;
    }
    return color_lookup(maximum, colormap, colorrange);
}

uniform uint objectid;

void write2framebuffer(vec4 color, uvec2 id);

const float typemax = 100000000000000000000000000000000000000.0;

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
    vec4 color;
    vec3 eye_unit = vec3(modelinv * vec4(eyeposition, 1));
    vec3 back_position = vec3(modelinv * vec4(frag_vert, 1));
    vec3 dir = normalize(eye_unit - back_position);
    // solve back_position + distance * dir == 1
    // solve back_position + distance * dir == 0
    // to see where it first hits unit cube!
    vec3 solution_1 = (1.0 - back_position) / dir;
    vec3 solution_0 = (0.0 - back_position) / dir;
    float solution = min_bigger_0(solution_1, solution_0);

    vec3 start = back_position + solution * dir;
    vec3 step_in_dir = (back_position - start) / float(num_samples);

    float steps = 0.1;
    if(algorithm == uint(0))
        color = isosurface(start, step_in_dir);
    else if(algorithm == uint(1))
        color = volume(start, step_in_dir);
    else if(algorithm == uint(2))
        color = mip(start, step_in_dir);
    else if(algorithm == uint(3))
        color = volumergba(start, step_in_dir);
    else if(algorithm == uint(4))
        color = vec4(0.0);
        // color = volumeindexedrgba(start, step_in_dir);
    else
        color = contours(start, step_in_dir);

    fragment_color = color;
}
