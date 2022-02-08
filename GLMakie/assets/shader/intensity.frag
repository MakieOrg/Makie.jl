{{GLSL_VERSION}}

struct Nothing{ //Nothing type, to encode if some variable doesn't contain any data
    bool _; //empty structs are not allowed
};

in vec2 o_uv;
in vec3 o_normal;
flat in uvec2 o_objectid;

{{intensity_type}} intensity;
// uniform sampler1D color_map;
// uniform vec2 color_norm;

uniform float stroke_width;
// {{color_type}} color;
uniform vec4 stroke_color;
uniform float levels;
uniform vec2 uv_scale;

// uniform vec4 highclip;
// uniform vec4 lowclip;
// uniform vec4 nan_color;

vec4 getindex(sampler2D image, vec2 uv){return texture(image, vec2(uv.x, 1-uv.y));}
vec4 getindex(sampler1D image, vec2 uv){return texture(image, uv.y);}
float range_01(float val, float from, float to){
    return (val - from) / (to - from);
}
vec4 _color(Nothing c);
vec4 _color(vec3 c);
vec4 _color(vec4 c);
vec4 get_color(vec4 color, float cm_index, vec2 uv, vec3 normal);

#define ALIASING_CONST 0.70710678118654757
#define M_PI 3.1415926535897932384626433832795

float aastep(float threshold1, float threshold2, float value) {
    float afwidth = length(vec2(dFdx(value), dFdy(value))) * ALIASING_CONST;
    return smoothstep(threshold1-afwidth, threshold1+afwidth, value)-smoothstep(threshold2-afwidth, threshold2+afwidth, value);
}
float aastep(float threshold1, float value) {
    float afwidth = length(vec2(dFdx(value), dFdy(value))) * ALIASING_CONST;
    return smoothstep(threshold1-afwidth, threshold1+afwidth, value);
}
void write2framebuffer(vec4 color, uvec2 id);

void main(){
    float i = float(getindex(intensity, o_uv).x);
    vec2 uv = mod(uv_scale * o_uv, 1);
    vec4 c = get_color(vec4(1,1,1,1), i, uv.yx, o_normal);
    // vec4 c = get_color(_color(color), i, o_uv, o_normal);
    if(stroke_width > 0.0){
        float lines = i * levels;
        lines = abs(fract(lines - 0.5));
        float half_stroke = stroke_width * 0.5;
        lines = aastep(0.5 - half_stroke, 0.5 + half_stroke, lines);
        c = mix(c, stroke_color, lines);
    }
    // i = range_01(i, color_norm.x, color_norm.y);
    // vec4 color = texture(color_map, clamp(i, 0.0, 1.0));
    // if (isnan(i)) {
    //     color = nan_color;
    // } else if (i < 0.0) {
    //     color = lowclip;
    // } else if (i > 1.0) {
    //     color = highclip;
    // } else {
    //     if(stroke_width > 0.0){
    //         float lines = i * levels;
    //         lines = abs(fract(lines - 0.5));
    //         float half_stroke = stroke_width * 0.5;
    //         lines = aastep(0.5 - half_stroke, 0.5 + half_stroke, lines);
    //         color = mix(color, stroke_color, lines);
    //     }
    // }
    write2framebuffer(c, uvec2(o_objectid.x, 0));
}
