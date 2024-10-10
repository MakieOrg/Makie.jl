{{GLSL_VERSION}}

struct Nothing{ //Nothing type, to encode if some variable doesn't contain any data
    bool _; //empty structs are not allowed
};

in vec2 o_uv;
flat in uvec2 o_objectid;

{{intensity_type}} intensity;
{{color_map_type}} color_map;
{{color_norm_type}} color_norm;

uniform vec4 highclip;
uniform vec4 lowclip;
uniform vec4 nan_color;

vec4 getindex(sampler2D image, vec2 uv){return texture(image, vec2(uv.x, 1-uv.y));}
vec4 getindex(sampler1D image, vec2 uv){return texture(image, uv.y);}

#define ALIASING_CONST 0.70710678118654757
#define M_PI 3.1415926535897932384626433832795

void write2framebuffer(vec4 color, uvec2 id);

vec4 get_color_from_cmap(float value, sampler1D color_map, vec2 colorrange) {
    float cmin = colorrange.x;
    float cmax = colorrange.y;
    float i01 = clamp((value - cmin) / (cmax - cmin), 0.0, 1.0);
    // 1/0 corresponds to the corner of the colormap, so to properly interpolate
    // between the colors, we need to scale it, so that the ends are at 1 - (stepsize/2) and 0+(stepsize/2).
    float stepsize = 1.0 / float(textureSize(color_map, 0));
    i01 = (1.0 - stepsize) * i01 + 0.5 * stepsize;
    return texture(color_map, i01);
}

vec4 get_color(sampler2D intensity, vec2 uv, Nothing color_norm, Nothing color_map){
    return getindex(intensity, uv);
}

vec4 get_color(sampler2D intensity, vec2 uv, vec2 color_norm, sampler1D color_map){
    float i = float(getindex(intensity, uv).x);
    if (isnan(i)) {
        return nan_color;
    } else if (i < color_norm.x) {
        return lowclip;
    } else if (i > color_norm.y) {
        return highclip;
    }
    return get_color_from_cmap(i, color_map, color_norm);
}

void main(){
    vec4 color = get_color(intensity, o_uv, color_norm, color_map);
    write2framebuffer(color, uvec2(o_objectid.x, o_objectid.y));
}
