in vec4 frag_color;
in vec3 frag_normal;
in vec3 frag_position;
in vec3 o_camdir;

// Smoothes out edge around 0 light intensity, see GLMakie
float smooth_zero_max(float x) {
    const float c = 0.00390625, xswap = 0.6406707120152759, yswap = 0.20508383900190955;
    const float shift = 1.0 + xswap - yswap;
    float pow8 = x + shift;
    pow8 = pow8 * pow8; pow8 = pow8 * pow8; pow8 = pow8 * pow8;
    return x < yswap ? c * pow8 : x;
}

vec3 blinnphong(vec3 N, vec3 V, vec3 L, vec3 color){
    float backlight = get_backlight();
    float diff_coeff = smooth_zero_max(dot(L, -N)) +
        backlight * smooth_zero_max(dot(L, N));

    // specular coefficient
    vec3 H = normalize(L + V);

    float spec_coeff = pow(max(dot(H, -N), 0.0), get_shininess()) +
        backlight * pow(max(dot(H, N), 0.0), get_shininess());
    if (diff_coeff <= 0.0)
        spec_coeff = 0.0;

    // final lighting model
    return get_light_color() * vec3(
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
    vec3 L, N, light, color;
    if (get_shading()) {
        L = get_light_direction();
        N = normalize(frag_normal);
        light = blinnphong(N, normalize(o_camdir), L, frag_color.rgb);
        color = get_ambient() * frag_color.rgb + light;
    } else {
        color = frag_color.rgb;
    }


    if (picking) {
        if (frag_color.a > 0.1) {
            fragment_color = pack_int(object_id, frag_instance_id);
        }
        return;
    }

    if (frag_color.a <= 0.0){
        discard;
    }
    fragment_color = vec4(color, frag_color.a);
}
