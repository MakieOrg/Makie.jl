{{GLSL_VERSION}}
{{GLSL_EXTENSIONS}}
{{SUPPORTED_EXTENSIONS}}

// This only handles flat colors and colormap lookups.
// See color.frag for details.

struct Nothing{ //Nothing type, to encode if some variable doesn't contain any data
    bool _; //empty structs are not allowed
};

// {{color_type}} color;
{{color_map_type}}  color_map;
{{color_norm_type}} color_norm; 
{{intensity_type}}  intensity;

uniform vec4 highclip;
uniform vec4 lowclip;
uniform vec4 nan_color;

// 1D index -> 2D
ivec2 ind2sub(ivec2 dim, int linearindex){
    return ivec2(linearindex % dim.x, linearindex / dim.x);
}

// lines can have float intensities indexed by vertexID's
float get_intensity(Nothing intensity){return 0.0;}
float get_intensity(float intensity){return intensity;}
float get_intensity(){return get_intensity(intensity);}

float get_intensity(float intensity, int idx, int len){return intensity;}
float get_intensity(Nothing intensity, int idx, int len){return 0.0;}
float get_intensity(sampler1D intensity, int idx, int len){
    return texture(intensity, float(idx) / float(len-1)).x;
}
float get_intensity(int idx, int len){return get_intensity(intensity, idx, len);}


// texture color implementations (general)
vec4 get_color(sampler1D t, float u){return texture(t, u);}
// assumes 0..1 normalization
vec4 get_color(samplerBuffer t, float u){return texelFetch(t, int(u * textureSize(t)));}
vec4 get_color(sampler2DArray t, vec2 uv, float i){return texture(t, vec3(uv, i));}

// integer version for gl_VertexID (linesegments)
vec4 get_color(sampler1D t, int i){return texelFetch(t, i, 0);}
vec4 get_color(sampler2D t, int i){
    return texelFetch(t, ind2sub(textureSize(t, 0), i), 0);
}
// vec4 get_color(samplerBuffer t, int i){return texelFetch(t, i);}

// fallbacks for `nothing` 
vec4 get_color(Nothing t, float i){return vec4(1);}
vec4 get_color(Nothing t, int i){return vec4(1);}
// vec4 get_color(Nothing t, vec2 uv, float i){return vec4(1);}

// with color
vec4 get_color(vec3 color){return vec4(color, 1);}
vec4 get_color(vec3 color, int i){return vec4(color, 1);}
// vec4 get_color(vec3 color, float i){return vec4(color, 1);}
// vec4 get_color(vec3 color, vec2 uv, float i){return vec4(color, 1);}

vec4 get_color(vec4 color){return color;}
vec4 get_color(vec4 color, int i){return color;}
// vec4 get_color(vec4 color, float i){return color;}
// vec4 get_color(vec4 color, vec2 uv, float i){return color;}



float _normalize(float val, float from, float to){
    return (val - from) / (to - from);
}
vec4 _get_colormap_color(Nothing cm, Nothing cr, Nothing i){return vec4(1);}
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
vec4 get_colormap_color(Nothing cm_index){
    return vec4(1);
}
vec4 get_colormap_color(){
    return _get_colormap_color(color_map, color_norm, intensity);
}
