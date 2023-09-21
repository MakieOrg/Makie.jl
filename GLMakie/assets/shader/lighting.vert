{{GLSL_VERSION}}
{{GLSL_EXTENSIONS}}

#define MAX_LIGHTS 8

const int UNDEFINED        = 0;
const int Ambient          = 1;
const int PointLight       = 2;
const int DirectionalLight = 3;
const int SpotLight        = 4;

uniform int light_types[MAX_LIGHTS];
uniform vec3 light_colors[MAX_LIGHTS];
uniform vec3 light_positions[MAX_LIGHTS];
uniform vec3 light_directions[MAX_LIGHTS];
uniform vec3 light_attenuation_parameters[MAX_LIGHTS];
uniform int lights_length;

uniform mat4 view;

out vec3 o_light_directions[MAX_LIGHTS];

void prepare_lights(vec4 view_pos) {
    for (int i = 0; i < lights_length; i++) {
        if (light_types[i] == PointLight || light_types[i] == SpotLight) {
            o_light_directions[i] = (view * vec4(light_positions[i], 1) - view_pos).xyz;
        } else {
            o_light_directions[i] = normalize((view * vec4(light_directions[i], 1)).xyz);
        }
    }
}
