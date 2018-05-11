{{GLSL_VERSION}}

in vec2 o_uv;
flat in uvec2 o_objectid;

{{intensity_type}} intensity;
uniform sampler1D color_map;
uniform vec2 color_norm;
uniform float stroke_width;
uniform vec4 stroke_color;
uniform float levels;

vec4 getindex(sampler2D image, vec2 uv){return texture(image, uv);}
vec4 getindex(sampler1D image, vec2 uv){return texture(image, uv.y);}
float _normalize(float val, float from, float to){return (val-from) / (to - from);}

vec4 color_lookup(float intensity, sampler1D color_ramp, vec2 norm){
    return texture(color_ramp, _normalize(intensity, norm.x, norm.y));
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
    float i = float(getindex(intensity, vec2(o_uv.x, o_uv.y)).x);
    vec4 color;
    if(isnan(i)){
        color = vec4(0);
    }else{
        i = _normalize(i, color_norm.x, color_norm.y);
        float lines = i*levels;
        lines = abs(fract(lines-0.5));
        float half_stroke = stroke_width*0.5;
        lines = aastep(0.5 - half_stroke, 0.5 + half_stroke, lines);
        color = mix(texture(color_map, i), stroke_color, lines);
    }
    write2framebuffer(color, uvec2(o_objectid.x, 0));
}
