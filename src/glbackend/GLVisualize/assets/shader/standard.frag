{{GLSL_VERSION}}

struct Nothing{ //Nothing type, to encode if some variable doesn't contain any data
    bool _; //empty structs are not allowed
};

in vec3 o_normal;
in vec3 o_lightdir;
in vec3 o_vertex;
in vec4 o_color;
in vec2 o_uv;
flat in uvec2 o_id;

{{color_type}} color;

vec4 get_color(vec3 color, vec2 uv){
    return vec4(color, 1.0 + (0.0 * uv)); // we must prohibit uv from getting into dead variable removal
}

vec4 get_color(vec4 color, vec2 uv){
    return color + uv.x * 0.0; // we must prohibit uv from getting into dead variable removal
}

vec4 get_color(Nothing color, vec2 uv){
    return o_color + uv.x * 0.0;
}
vec4 get_color(samplerBuffer color, vec2 uv){
    return o_color + uv.x * 0.0;
}

vec4 get_color(sampler2D color, vec2 uv){
    return texture(color, uv);
}

vec3 blinnphong(vec3 N, vec3 V, vec3 L, vec3 color){
    float diff_coeff = max(dot(L, N), 0.0);

    // specular coefficient
    vec3 H = normalize(L+V);

    float spec_coeff = pow(max(dot(H, N), 0.0), 8.0);
    if (diff_coeff <= 0.0)
        spec_coeff = 0.0;

    // final lighting model
    return vec3(
        vec3(0.1) * vec3(0.3)  +
        vec3(0.9) * color * diff_coeff +
        vec3(0.3) * spec_coeff
    );
}

void write2framebuffer(vec4 color, uvec2 id);

void main(){
    vec4 color = get_color(color, o_uv);
    {{light_calc}}
    write2framebuffer(
        color,
        o_id
    );
}
