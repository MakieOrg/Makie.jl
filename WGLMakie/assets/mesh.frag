in vec2 frag_uv;
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

vec4 get_color(vec3 color, vec2 uv, bool colorrange, bool colormap){
    return vec4(color, 1.0); // we must prohibit uv from getting into dead variable removal
}

vec4 get_color(vec4 color, vec2 uv, bool colorrange, bool colormap){
    return color; // we must prohibit uv from getting into dead variable removal
}

vec4 get_color(bool color, vec2 uv, bool colorrange, bool colormap){
    return frag_color;  // color not in uniform
}

vec4 get_color(sampler2D color, vec2 uv, bool colorrange, bool colormap){
    return texture(color, uv);
}

float _normalize(float val, float from, float to){return (val-from) / (to - from);}

vec4 get_color(sampler2D color, vec2 uv, vec2 colorrange, sampler2D colormap){
    float value = texture(color, uv).x;
    float normed = _normalize(value, colorrange.x, colorrange.y);
    vec4 c = texture(colormap, vec2(normed, 0.0));

    if (isnan(value)) {
        c = get_nan_color();
    } else if (value < colorrange.x) {
        c = get_lowclip();
    } else if (value > colorrange.y) {
        c = get_highclip();
    }
    return c;
}

vec4 get_color(sampler2D color, vec2 uv, bool colorrange, sampler2D colormap){
    return texture(color, uv);
}

void main() {
    vec4 real_color = get_color(uniform_color, frag_uv, get_colorrange(), colormap);
    vec3 shaded_color = real_color.rgb;

    if(get_shading()){
        vec3 L = normalize(o_lightdir);
        vec3 N = normalize(o_normal);
        vec3 light1 = blinnphong(N, o_camdir, L, real_color.rgb);
        vec3 light2 = blinnphong(N, o_camdir, -L, real_color.rgb);
        shaded_color = get_ambient() * real_color.rgb + light1 + get_backlight() * light2;
    }
    fragment_color = vec4(shaded_color, real_color.a);
}
