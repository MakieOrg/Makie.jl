{{GLSL_VERSION}}

in vec2 o_uv;
flat in uvec2 o_objectid;

{{intensity_type}} intensity;
uniform sampler1D color_map;
uniform vec2 color_norm;

uniform float stroke_width;
uniform vec4 stroke_color;
uniform float levels;

uniform vec4 highclip;
uniform vec4 lowclip;
uniform vec4 nan_color;

vec4 getindex(sampler2D image, vec2 uv){return texture(image, vec2(uv.x, 1-uv.y));}
vec4 getindex(sampler1D image, vec2 uv){return texture(image, uv.y);}
float range_01(float val, float from, float to){
    return (val - from) / (to - from);
}

#define ALIASING_CONST 0.70710678118654757
#define M_PI 3.1415926535897932384626433832795

void write2framebuffer(vec4 color, uvec2 id);

// It seems texture(color_map, i0) doesn't actually correctly interpolate between the values.
// TODO, further investigate texture, since it's likely not broken, but rather not used correctly.
// Meanwhile, we interpolate manually from the colormap
vec4 get_color_from_cmap(float value, sampler1D color_map, vec2 colorrange) {
    float cmin = colorrange.x;
    float cmax = colorrange.y;
    float i01 = clamp((value - cmin) / (cmax - cmin), 0.0, 1.0);
    int len = textureSize(color_map, 0);

    float i1len = i01 * (len - 1);
    int down = int(floor(i1len));
    int up = int(ceil(i1len));
    if (down == up) {
        return texelFetch(color_map, up, 0);
    }
    float interp_val = i1len - down;
    vec4 downc = texelFetch(color_map, down, 0);
    vec4 upc = texelFetch(color_map, up, 0);
    return mix(downc, upc, interp_val);
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
    write2framebuffer(color, uvec2(o_objectid.x, 0));
}
