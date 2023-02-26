{{GLSL_VERSION}}
{{GLSL_EXTENSIONS}}
{{SUPPORTED_EXTENSIONS}}

struct Nothing{ //Nothing type, to encode if some variable doesn't contain any data
    bool _; //empty structs are not allowed
};

in vec4 f_color;
in vec2 f_uv;
in float f_thickness;
flat in uvec2 f_id;
flat in vec2 f_uv_minmax;
{{pattern_type}} pattern;

uniform float pattern_length;

// Half width of antialiasing smoothstep
#define ANTIALIAS_RADIUS 0.8

float aastep(float threshold1, float dist) {
    return smoothstep(threshold1-ANTIALIAS_RADIUS, threshold1+ANTIALIAS_RADIUS, dist);
}

float aastep(float threshold1, float threshold2, float dist) {
    // We use 2x pixel space in the geometry shaders which passes through
    // in uv.y, so we need to treat it here by using 2 * ANTIALIAS_RADIUS
    float AA = 2 * ANTIALIAS_RADIUS;
    return smoothstep(threshold1 - AA, threshold1 + AA, dist) -
           smoothstep(threshold2 - AA, threshold2 + AA, dist);
}

float aastep_scaled(float threshold1, float threshold2, float dist) {
    float AA = ANTIALIAS_RADIUS / pattern_length;
    return smoothstep(threshold1 - AA, threshold1 + AA, dist) -
           smoothstep(threshold2 - AA, threshold2 + AA, dist);
}


void write2framebuffer(vec4 color, uvec2 id);

// Signed distance fields for lines
// x/y pattern
float get_sd(sampler2D pattern, vec2 uv){
    return texture(pattern, uv).x;
}

// x pattern
vec2 get_sd(sampler1D pattern, vec2 uv){
    return vec2(texture(pattern, uv.x).x, uv.y);
}

// normal line type
// Note that this just returns uv, so get full manual control in geom shader
vec2 get_sd(Nothing _, vec2 uv){
    return uv;
}

float ifelse(bool condition, float true_val, float false_val){
    return float(condition) * (true_val - false_val) + false_val;
}

void main(){
    vec4 color = vec4(f_color.rgb, 0.0);
    vec2 xy = get_sd(pattern, f_uv);

    float alpha = aastep(0.0, xy.x);
    float alpha2 = aastep(-f_thickness, f_thickness, xy.y);
    float alpha3 = aastep_scaled(f_uv_minmax.x, f_uv_minmax.y, f_uv.x);

    color = vec4(f_color.rgb, f_color.a * alpha * alpha2 * alpha3);

    // Debug: Show uv values in line direction (repeating)
    // color = vec4(mod(f_uv.x, 1.0), 0, 0, 1);
    
    // Debug: Show uv values in line direction with pattern
    // color.r = 0.5;
    // color.g = mod(f_uv.x, 1.0);
    // color.b = mod(f_uv.x, 1.0);
    // color.a = 0.2 + 0.8 * color.a;

    
    write2framebuffer(color, f_id);
}
