{{GLSL_VERSION}}
{{GLSL_EXTENSIONS}}
{{SUPPORTED_EXTENSIONS}}

struct Nothing{ //Nothing type, to encode if some variable doesn't contain any data
    bool _; //empty structs are not allowed
};

{{image_type}} image;
{{pattern_type}} pattern;
{{matcap_type}} matcap;
{{color_map_type}}  color_map;
{{color_norm_type}} color_norm; 

uniform vec4 highclip;
uniform vec4 lowclip;
uniform vec4 nan_color;
uniform vec2 uv_scale;


////////////////////////////////////////////////////////////////////////////////
/// fragment shader functions
////////////////////////////////////////////////////////////////////////////////


// implementations 
vec4 _texture_color(sampler1D t, float u){return texture(t, u);}
vec4 _texture_color(sampler2D t, vec2 uv){return texture(t, uv);}
vec4 _texture_color(samplerBuffer t, int i){return texelFetch(t, i);}
// assumes 0..1 normalization
vec4 _texture_color(samplerBuffer t, float u){return texelFetch(t, int(u * textureSize(t)));}
vec4 _texture_color(sampler2DArray t, vec2 uv, float i){return texture(t, vec3(uv, i));}

vec4 _texture_color(Nothing t, float i){return vec4(1);}
vec4 _texture_color(Nothing t, int i){return vec4(1);}
vec4 _texture_color(Nothing t, vec2 uv){return vec4(1);}
vec4 _texture_color(Nothing t, vec2 uv, float i){return vec4(1);}

vec4 _texture_color(sampler2D t, ivec2 uv){
    ivec2 size = textureSize(t, 0);
    return texelFetch(t, ivec2(mod(uv.x, size.x), mod(uv.y, size.y)), 0);
}


vec4 _color(Nothing c){return vec4(1);}
vec4 _color(vec3 c){return vec4(c, 1);}
vec4 _color(vec4 c){return c;}



ivec2 pattern_uv(){return ivec2(gl_FragCoord.xy * uv_scale);}
ivec2 pos2uv(){return ivec2(gl_FragCoord.xy * uv_scale);}
vec2 normal2uv(vec3 normal){
    // -1..1 range -> 0..1 range and (x, y) -> (1-y, x)
    return normal.yx * vec2(-0.5, 0.5) + vec2(0.5, 0.5);
}


float _normalize(float val, float from, float to){
    return (val-from) / (to - from);
}
vec4 _get_colormap_color(Nothing cm, Nothing cr, float i){return vec4(1);}
vec4 _get_colormap_color(sampler1D cm, vec2 colorrange, float cm_index){
    vec4 color = texture(cm, _normalize(cm_index, colorrange.x, colorrange.y));
    if (isnan(cm_index)) {
        color = nan_color;
    } else if (cm_index < colorrange.x) {
        color = lowclip;
    } else if (cm_index > colorrange.y) {
        color = highclip;
    }
    return color;
}

vec4 get_colormap_color(float cm_index){
    return _get_colormap_color(color_map, color_norm, cm_index);
}
vec4 get_texture_color(vec2 uv){return _texture_color(image, uv);}
vec4 get_pattern_color(){return _texture_color(pattern, pattern_uv());}
vec4 get_matcap_color(vec3 normal){
    return _texture_color(matcap, normal2uv(normal));
}

vec4 get_color(vec4 color, vec2 uv, vec3 normal){
    return 
        color *
        get_texture_color(uv) *
        get_pattern_color() *
        get_matcap_color(normal);
}
vec4 get_color(vec4 color, vec3 normal){
    return color * get_pattern_color() * get_matcap_color(normal);
}
vec4 get_color(vec4 color, float cm_index){
    return color * get_colormap_color(cm_index);
}
vec4 get_color(vec4 color, float cm_index, vec2 uv, vec3 normal){
    return 
        color *
        get_colormap_color(cm_index) *
        get_texture_color(uv) *
        get_pattern_color() *
        get_matcap_color(normal);
}

/*
Vertex:
a) dots.vert           |
b) line_segments.vert  |
c) lines.vert          |
d) particles.vert      |
e) standard.vert       |
f) surface.vert        |
g) util.vert           | 
*) no vert stuff

Fragment:
1) distance_shape.frag  | g
2) intensity.frag       | *
3) standard.frag        | gc, gd, gf
4) texture.frag         | *
5) volume.frag          | g, g
0) no frag stuff

Plots:
- image?         *1
- heatmap?       *2
- volume-float   g5
- volume-RGBA    g5
- lines          gc0 <-
- linesegments   gc0 <-
- mesh           ge3 <-
- meshscatter    gd3 <-
- fastpixel      a0
- scatter        g1
- surface        gf3 <-
*/
