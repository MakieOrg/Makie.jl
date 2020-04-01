in vec2 frag_uv;
in vec4 frag_color;
in vec3 frag_normal;
in vec3 frag_position;
in vec3 frag_lightdir;

vec3 blinnphong(vec3 N, vec3 V, vec3 L, vec3 color){
    float diff_coeff = max(dot(L, N), 0.0);

    // specular coefficient
    vec3 H = normalize(L + V);

    float spec_coeff = pow(max(dot(H, N), 0.0), get_shininess());

    // final lighting model
    return vec3(
        get_ambient() * color +
        get_diffuse() * diff_coeff * color +
        get_specular() * spec_coeff
    );
}



vec4 get_color(vec3 color, vec2 uv){
    return vec4(color, 1.0); // we must prohibit uv from getting into dead variable removal
}

vec4 get_color(vec4 color, vec2 uv){
    return color; // we must prohibit uv from getting into dead variable removal
}

vec4 get_color(bool color, vec2 uv){
    return frag_color;  // color not in uniform
}

vec4 get_color(sampler2D color, vec2 uv){
    return texture(color, uv);
}


void main() {
    vec4 real_color = get_color(uniform_color, frag_uv);
    vec3 shaded_color = real_color.xyz;
    if(get_shading()){
        shaded_color = blinnphong(frag_normal, frag_position, frag_lightdir, real_color.xyz);
        shaded_color = shaded_color + blinnphong(frag_normal, frag_position, -frag_lightdir, real_color.xyz);
    }

    fragment_color = vec4(shaded_color, real_color.a);
}
