{{GLSL_VERSION}}
{{GLSL_EXTENSIONS}}

#define MAX_LIGHTS 64

// differentiating different light sources
const int UNDEFINED        = 0;
const int Ambient          = 1;
const int PointLight       = 2;
const int DirectionalLight = 3;
const int SpotLight        = 4;

// light parameters (maybe invalid depending on light type)
uniform int light_types[MAX_LIGHTS];
uniform vec3 light_colors[MAX_LIGHTS];
uniform vec3 light_positions[MAX_LIGHTS];
uniform vec3 light_directions[MAX_LIGHTS];
uniform vec3 light_parameters[MAX_LIGHTS];
uniform int lights_length;

// Material parameters
uniform vec3 diffuse;
uniform vec3 specular;
uniform float shininess;

// TODO: we don't want to do this here...
// maybe pre-calc on cpu?
uniform mat4 view;

// in vec3 o_light_directions[MAX_LIGHTS];
in vec3 o_camdir;
in vec3 o_view_pos;

vec3 illuminate_pointlight(int idx, vec3 normal, vec3 camera_direction, vec3 color) {
    // calculate light direction and distance
    vec3 light_vec = (view * vec4(light_positions[idx], 1)).xyz - o_view_pos;
    float dist = length(light_vec);
    vec3 light_dir = normalize(light_vec);

    // diffuse coefficient (how directly does light hit the surface)
    float diff_coeff = max(dot(light_dir, normal), 0.0);

    // specular coefficient (does reflected light bounce into camera)
    vec3 H = normalize(light_dir + camera_direction);
    float spec_coeff = pow(max(dot(H, normal), 0.0), shininess);
    if (diff_coeff <= 0.0 || isnan(spec_coeff))
        spec_coeff = 0.0;

    // How weak has the light gotten due to distance
    float attentuation = 1.0;
    // float attentuation = 1.0 / (
    //     light_parameters[idx].x +
    //     light_parameters[idx].y * dist +
    //     light_parameters[idx].z * dist * dist
    // );

    // final lighting model

    return attentuation * light_colors[idx] * vec3(
        diffuse * diff_coeff * color +
        specular * spec_coeff
    );
}

// vec3 illuminate_directionallight(Light light, vec3 normal, vec3 light_direction, vec3 camera_direction, vec3 color) {
//     // light coming down (0, -1, 0) should reflect off of normals (0, 1, 0) the strongest
//     float diff_coeff = max(dot(-light.direction, normal), 0.0);
//     return diffuse * diff_coeff * light.color * color;
// }

vec3 illuminate(vec3 normal, vec3 base_color) {
    vec3 final_color = vec3(0);
    for (int i = 0; i < min(lights_length, MAX_LIGHTS); i++) {
        switch (light_types[i]) {
        case Ambient:
            final_color += light_colors[i] * base_color;
            break;
        case PointLight:
            final_color += illuminate_pointlight(i, normal, o_camdir, base_color);
            break;
        // case DirectionalLight:
        //     return illuminate_directionallight(light, normal, light_direction, camera_direction, base_color);
        default:
            final_color += vec3(1,0,1); // debug magenta
        }
    }
    return final_color;
}

