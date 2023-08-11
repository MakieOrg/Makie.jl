precision mediump int;
precision mediump float;
precision mediump sampler2D;
precision mediump sampler3D;

flat in vec2 f_uv_minmax;
in vec2 f_uv;
in vec4 f_color;
in float f_thickness;

uniform float pattern_length;

out vec4 fragment_color;

// Half width of antialiasing smoothstep
#define ANTIALIAS_RADIUS 0.8

float aastep(float threshold1, float dist) {
    return smoothstep(threshold1 - ANTIALIAS_RADIUS, threshold1 + ANTIALIAS_RADIUS, dist);
}

float aastep(float threshold1, float threshold2, float dist) {
    // We use 2x pixel space in the geometry shaders which passes through
    // in uv.y, so we need to treat it here by using 2 * ANTIALIAS_RADIUS
    float AA = 2.0f * ANTIALIAS_RADIUS;
    return smoothstep(threshold1 - AA, threshold1 + AA, dist) -
        smoothstep(threshold2 - AA, threshold2 + AA, dist);
}

float aastep_scaled(float threshold1, float threshold2, float dist) {
    float AA = ANTIALIAS_RADIUS / pattern_length;
    return smoothstep(threshold1 - AA, threshold1 + AA, dist) -
        smoothstep(threshold2 - AA, threshold2 + AA, dist);
}

void main() {
    vec4 color = vec4(f_color.rgb, 0.0f);
    vec2 xy = f_uv;

    float alpha = aastep(0.0f, xy.x);
    float alpha2 = aastep(-f_thickness, f_thickness, xy.y);
    float alpha3 = aastep_scaled(f_uv_minmax.x, f_uv_minmax.y, f_uv.x);

    color = vec4(f_color.rgb, f_color.a * alpha * alpha2 * alpha3);

    fragment_color = color;
}
