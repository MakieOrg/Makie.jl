in vec4 frag_color;
in vec3 o_normal;
in vec3 o_camdir;
in vec3 o_lightdir;

vec3 blinnphong(vec3 N, vec3 V, vec3 L, vec3 color){
    float diff_coeff = max(dot(L, N), 0.0);

    // specular coefficient
    vec3 H = normalize(L + V);

    float spec_coeff = pow(max(dot(H, N), 0.0), get_shininess());
    if (diff_coeff <= 0.0)
        spec_coeff = 0.0;
    // final lighting model
    return vec3(
        get_diffuse() * diff_coeff * color +
        get_specular() * spec_coeff
    );
}

flat in uint frag_instance_id;
vec4 pack_int(uint id, uint index) {
    vec4 unpack;
    unpack.x = float((id & uint(0xff00)) >> 8) / 255.0;
    unpack.y = float((id & uint(0x00ff)) >> 0) / 255.0;
    unpack.z = float((index & uint(0xff00)) >> 8) / 255.0;
    unpack.w = float((index & uint(0x00ff)) >> 0) / 255.0;
    return unpack;
}

void main() {
    vec3 L = normalize(o_lightdir);
    vec3 N = normalize(o_normal);
    vec3 light1 = blinnphong(N, o_camdir, L, frag_color.rgb);
    vec3 light2 = blinnphong(N, o_camdir, -L, frag_color.rgb);
    vec3 color = get_ambient() * frag_color.rgb + light1 + get_backlight() * light2;
    if (frag_color.a <= 0.01){
        discard;
    }
    if (picking) {
        fragment_color = pack_int(object_id, frag_instance_id);
        return;
    }

    fragment_color = vec4(color, frag_color.a);
}
