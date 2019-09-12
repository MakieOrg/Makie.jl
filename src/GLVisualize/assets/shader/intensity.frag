{{GLSL_VERSION}}

in vec2 o_uv;
flat in uvec2 o_objectid;

{{intensity_type}} intensity;
uniform sampler1D color_map;
uniform vec2 color_norm;
uniform float stroke_width;
uniform vec4 stroke_color;
uniform float levels;

vec4 getindex(sampler2D image, vec2 uv){return texture(image, vec2(uv.x, 1-uv.y));}
vec4 getindex(sampler1D image, vec2 uv){return texture(image, uv.y);}
float clamp_01(float val, float from, float to){
    return clamp((val - from) / (to - from), 0.0, 1.0);
}

vec4 color_lookup(float intensity, sampler1D color_ramp, vec2 norm){
    return texture(color_ramp, clamp_01(intensity, norm.x, norm.y));
}

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
    i = clamp_01(i, color_norm.x, color_norm.y);
    vec4 color = vec4(0);
    if(!isnan(i)){
        color = texture(color_map, i);
        if(stroke_width > 0.0){
            float lines = i * levels;
            lines = abs(fract(lines - 0.5));
            float half_stroke = stroke_width * 0.5;
            lines = aastep(0.5 - half_stroke, 0.5 + half_stroke, lines);
            color = mix(color, stroke_color, lines);
        }
    }
    write2framebuffer(color, uvec2(o_objectid.x, 0));
}
