{{GLSL_VERSION}}
{{GLSL_EXTENSIONS}}

// Sets which shading procedures to use
// Options:
// NO_SHADING           - skip shading calculation, handled outside
// FAST_SHADING         - single point light (forward rendering)
// MULTI_LIGHT_SHADING  - simple shading with multiple lights (forward rendering)
{{shading}}


// Shared uniforms, inputs and functions
#if defined FAST_SHADING || defined MULTI_LIGHT_SHADING

// Generic uniforms
uniform vec3 diffuse;
uniform vec3 specular;
uniform float shininess;

uniform vec3 ambient;
uniform float backlight;

in vec3 o_camdir;
in vec3 o_world_pos;

float smooth_zero_max(float x) {
    // This is a smoothed version of max(value, 0.0) where -1 <= value <= 1
    // This comes from:
    // c = 2 ^ -a                                # normalizes power w/o swaps
    // xswap = (1 / c / a)^(1 / (a - 1)) - 1     # xval with derivative 1
    // yswap = c * (xswap+1) ^ a                 # yval with derivative 1
    // ifelse.(xs .< yswap, c .* (xs .+ 1 .+ xswap .- yswap) .^ a, xs)
    // a = 16 constants: (harder edge)
    // const float c = 0.0000152587890625, xswap = 0.7411011265922482, yswap = 0.10881882041201549;
    // a = 8 constants: (softer edge)
    const float c = 0.00390625, xswap = 0.6406707120152759, yswap = 0.20508383900190955;
    const float shift = 1.0 + xswap - yswap;
    return x < yswap ? c * pow(x + shift, 8) : x;
}

vec3 blinn_phong(vec3 light_color, vec3 light_dir, vec3 camdir, vec3 normal, vec3 color) {
    // diffuse coefficient (how directly does light hits the surface)
    float diff_coeff = smooth_zero_max(dot(light_dir, -normal)) +
        backlight * smooth_zero_max(dot(light_dir, normal));

    // DEBUG - visualize diff_coeff, i.e. the angle between light and normals
    // if (diff_coeff > 0.999)
    //     return vec3(0, 0, 1);
    // else
    //     return vec3(1 - diff_coeff,diff_coeff, 0.05);

    // specular coefficient (does reflected light bounce into camera?)
    vec3 H = normalize(light_dir + camdir);
    float spec_coeff = pow(max(dot(H, -normal), 0.0), shininess) +
        backlight * pow(max(dot(H, normal), 0.0), shininess);
    if (diff_coeff <= 0.0 || isnan(spec_coeff))
        spec_coeff = 0.0;

    return light_color * vec3(diffuse * diff_coeff * color + specular * spec_coeff);
}

#else // glsl fails to compile if the shader is just empty

vec3 illuminate(vec3 normal, vec3 base_color);

#endif


////////////////////////////////////////////////////////////////////////////////
//                                FAST_SHADING                                //
////////////////////////////////////////////////////////////////////////////////


#ifdef FAST_SHADING

uniform vec3 light_color;
uniform vec3 light_direction;

vec3 illuminate(vec3 world_pos, vec3 camdir, vec3 normal, vec3 base_color) {
    vec3 shaded_color = blinn_phong(light_color, light_direction, camdir, normal, base_color);
    return ambient * base_color + shaded_color;
}

vec3 illuminate(vec3 normal, vec3 base_color) {
    return illuminate(o_world_pos, normalize(o_camdir), normal, base_color);
}

#endif


////////////////////////////////////////////////////////////////////////////////
//                            MULTI_LIGHT_SHADING                             //
////////////////////////////////////////////////////////////////////////////////


#ifdef MULTI_LIGHT_SHADING

{{MAX_LIGHTS}}
{{MAX_LIGHT_PARAMETERS}}

// differentiating different light sources
const int UNDEFINED        = 0;
const int Ambient          = 1;
const int PointLight       = 2;
const int DirectionalLight = 3;
const int SpotLight        = 4;
const int RectLight        = 5;

// light parameters (maybe invalid depending on light type)
uniform int N_lights;
uniform int light_types[MAX_LIGHTS];
uniform vec3 light_colors[MAX_LIGHTS];
uniform float light_parameters[MAX_LIGHT_PARAMETERS];

vec3 calc_point_light(vec3 light_color, int idx, vec3 world_pos, vec3 camdir, vec3 normal, vec3 color) {
    // extract args
    vec3 position = vec3(light_parameters[idx], light_parameters[idx+1], light_parameters[idx+2]);
    vec2 param = vec2(light_parameters[idx+3], light_parameters[idx+4]);

    // calculate light direction and distance
    vec3 light_vec = world_pos - position;

    float dist = length(light_vec);
    vec3 light_dir = normalize(light_vec);

    // How weak has the light gotten due to distance
    // float attentuation = 1.0 / (1.0 + dist * dist * dist);
    float attentuation = 1.0 / (1.0 + param.x * dist + param.y * dist * dist);

    return attentuation * blinn_phong(light_color, light_dir, camdir, normal, color);
}

vec3 calc_directional_light(vec3 light_color, int idx, vec3 camdir, vec3 normal, vec3 color) {
    vec3 light_dir = vec3(light_parameters[idx], light_parameters[idx+1], light_parameters[idx+2]);
    return blinn_phong(light_color, light_dir, camdir, normal, color);
}

vec3 calc_spot_light(vec3 light_color, int idx, vec3 world_pos, vec3 camdir, vec3 normal, vec3 color) {
    // extract args
    vec3 position = vec3(light_parameters[idx], light_parameters[idx+1], light_parameters[idx+2]);
    vec3 spot_light_dir = normalize(vec3(light_parameters[idx+3], light_parameters[idx+4], light_parameters[idx+5]));
    float inner_angle = light_parameters[idx+6]; // cos applied
    float outer_angle = light_parameters[idx+7]; // cos applied

    vec3 light_dir = normalize(world_pos - position);
    float intensity = smoothstep(outer_angle, inner_angle, dot(light_dir, spot_light_dir));

    return intensity * blinn_phong(light_color, light_dir, camdir, normal, color);
}

vec3 calc_rect_light(vec3 light_color, int idx, vec3 world_pos, vec3 camdir, vec3 normal, vec3 color) {
    // extract args
    vec3 origin = vec3(light_parameters[idx], light_parameters[idx+1], light_parameters[idx+2]);
    vec3 u1 = vec3(light_parameters[idx+3], light_parameters[idx+4], light_parameters[idx+5]);
    vec3 u2 = vec3(light_parameters[idx+6], light_parameters[idx+7], light_parameters[idx+8]);
    vec3 light_dir = vec3(light_parameters[idx+9], light_parameters[idx+10], light_parameters[idx+11]);

    // Find t such that <world_pos + t * light_dir, light_dir> = <origin - world_pos, light_dir>
    // to find the point p = world_pos + t * light_dir = origin + w1 * u1 + w2 * u2 + 0 * light_dir.
    // Then check if p is inside the rectangle by computing w1 and w2.
    float t = dot(origin - world_pos, light_dir);
    vec3 dir = world_pos + t * light_dir - origin;
    float w1 = dot(dir, u1) / dot(u1, u1);
    float w2 = dot(dir, u2) / dot(u2, u2);

    // mask out light rays that do not come from inside the shape
    float intensity = smoothstep(0.45, 0.55, 1-abs(w1)) * smoothstep(0.45, 0.55, 1-abs(w2));

    // If we do not mask the plane we may want to consider light rays coming from
    // the closest edge.
    // vec3 position = origin + clamp(w1, -0.5, 0.5) * u1 + clamp(w2, -0.5, 0.5) * u2;
    // vec3 light_dir = normalize(world_pos - position);

    return intensity * blinn_phong(light_color, light_dir, camdir, normal, color);
}

vec3 illuminate(vec3 world_pos, vec3 camdir, vec3 normal, vec3 base_color) {
    vec3 final_color = ambient * base_color;
    int idx = 0;
    for (int i = 0; i < min(N_lights, MAX_LIGHTS); i++) {
        switch (light_types[i]) {
        case PointLight:
            final_color += calc_point_light(light_colors[i], idx, world_pos, camdir, normal, base_color);
            idx += 5; // 3 position, 2 attenuation params
            break;
        case DirectionalLight:
            final_color += calc_directional_light(light_colors[i], idx, camdir, normal, base_color);
            idx += 3; // 3 direction
            break;
        case SpotLight:
            final_color += calc_spot_light(light_colors[i], idx, world_pos, camdir, normal, base_color);
            idx += 8; // 3 position, 3 direction, 1 parameter
            break;
        case RectLight:
            final_color += calc_rect_light(light_colors[i], idx, world_pos, camdir, normal, base_color);
            idx += 12;
            break;
        default:
            return vec3(1,0,1); // debug magenta
        }
    }
    return final_color;
}

vec3 illuminate(vec3 normal, vec3 base_color) {
    return illuminate(o_world_pos, normalize(o_camdir), normal, base_color);
}

#endif
