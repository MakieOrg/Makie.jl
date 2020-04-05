
vec3 blinnphong(vec3 N, vec3 V, vec3 L, vec3 color){
    float diff_coeff = max(dot(L, N), 0.0);

    // specular coefficient
    vec3 H = normalize(L + V);

    float spec_coeff = pow(max(dot(H, N), 0.0), shininess);

    // final lighting model
    return vec3(
        get_ambient() * color +
        get_diffuse() * diff_coeff * color +
        get_specular() * spec_coeff
    );
}

void main() {
    vec4 real_color = get_color();
    vec3 shaded_color = real_color.xyz;

    if(get_shading()){
        shaded_color = blinnphong(get_normal(), get_position(), get_lightposition(), real_color.xyz);
    }

    fragment_color = vec4(shaded_color, real_color.a);
}
