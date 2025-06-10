{{GLSL_VERSION}}

struct Nothing{ //Nothing type, to encode if some variable doesn't contain any data
    bool _; //empty structs are not allowed
};

// Sets which shading procedures to use
{{shading}}

// Selects what is used to calculate the picked index
{{picking_mode}}

in vec3 o_world_normal;
in vec3 o_view_normal;
in vec4 o_color;
in vec3 o_uv;
flat in uvec2 o_id;
flat in int o_InstanceID;

{{matcap_type}} matcap;
{{image_type}} image;
{{color_map_type}} color_map;
{{color_norm_type}} color_norm;

uniform bool interpolate_in_fragment_shader;

uniform vec4 highclip;
uniform vec4 lowclip;
uniform vec4 nan_color;

vec4 get_color_from_cmap(float value, sampler1D color_map, vec2 colorrange) {
    float cmin = colorrange.x;
    float cmax = colorrange.y;
    if (value <= cmax && value >= cmin) {
        // in value range, continue!
    } else if (value < cmin) {
        return lowclip;
    } else if (value > cmax) {
        return highclip;
    } else {
        // isnan CAN be broken (of course) -.-
        // so if outside value range and not smaller/bigger min/max we assume NaN
        return nan_color;
    }
    float i01 = clamp((value - cmin) / (cmax - cmin), 0.0, 1.0);
    // 1/0 corresponds to the corner of the colormap, so to properly interpolate
    // between the colors, we need to scale it, so that the ends are at 1 - (stepsize/2) and 0+(stepsize/2).
    float stepsize = 1.0 / float(textureSize(color_map, 0));
    i01 = (1.0 - stepsize) * i01 + 0.5 * stepsize;
    return texture(color_map, i01);
}

vec4 get_color(Nothing image, vec3 uv, Nothing color_norm, Nothing color_map, Nothing matcap){
    return o_color;
}
vec4 get_color(sampler2D color, vec3 uv, Nothing color_norm, Nothing color_map, Nothing matcap){
    return texture(color, uv.xy);
}
vec4 get_color(Nothing color, vec3 uv, vec2 color_norm, sampler1D color_map, Nothing matcap){
    if (interpolate_in_fragment_shader) {
        return get_color_from_cmap(o_color.x, color_map, color_norm);
    } else {
        return o_color;
    }
}

vec4 get_color(sampler2D intensity, vec3 uv, vec2 color_norm, sampler1D color_map, Nothing matcap){
    float i = texture(intensity, uv.xy).x;
    return get_color_from_cmap(i, color_map, color_norm);
}

vec4 get_color(sampler3D intensity, vec3 uv, vec2 color_norm, sampler1D color_map, Nothing matcap){
    float i = texture(intensity, uv).x;
    return get_color_from_cmap(i, color_map, color_norm);
}

vec4 matcap_color(sampler2D matcap){
    // TODO should matcaps use view space normals?
    vec2 muv = normalize(o_view_normal).xy * 0.5 + vec2(0.5, 0.5);
    return texture(matcap, vec2(1.0-muv.y, muv.x));
}
vec4 get_color(Nothing image, vec3 uv, Nothing color_norm, Nothing color_map, sampler2D matcap){
    return matcap_color(matcap);
}
vec4 get_color(sampler2D color, vec3 uv, Nothing color_norm, Nothing color_map, sampler2D matcap){
    return matcap_color(matcap);
}
vec4 get_color(sampler1D color, vec3 uv, vec2 color_norm, sampler1D color_map, sampler2D matcap){
    return matcap_color(matcap);
}
vec4 get_color(sampler2D color, vec3 uv, vec2 color_norm, sampler1D color_map, sampler2D matcap){
    return matcap_color(matcap);
}

uniform bool fetch_pixel;

{{uv_transform_type}} uv_transform;
vec2 apply_uv_transform(Nothing t1, int i, vec2 uv){ return uv; }
vec2 apply_uv_transform(mat3x2 transform, int i, vec2 uv){ return transform * vec3(uv, 1); }
vec2 apply_uv_transform(samplerBuffer transforms, int index, vec2 uv){
    // can't have matrices in a texture so we have 3x vec2 instead
    mat3x2 transform;
    transform[0] = texelFetch(transforms, 3 * index + 0).xy;
    transform[1] = texelFetch(transforms, 3 * index + 1).xy;
    transform[2] = texelFetch(transforms, 3 * index + 2).xy;
    return transform * vec3(uv, 1);
}

vec4 get_pattern_color(sampler2D color){
    vec2 pos = apply_uv_transform(uv_transform, o_InstanceID, gl_FragCoord.xy);
    return texture(color, pos);
}
vec4 get_pattern_color(sampler3D color){
    return vec4(0, 0, 0, 1);
}
// Needs to exist for opengl to be happy
vec4 get_pattern_color(Nothing color){return vec4(1,0,1,1);}

void write2framebuffer(vec4 color, uvec2 id);

#ifndef NO_SHADING
vec3 illuminate(vec3 normal, vec3 base_color);
#endif

void main(){
    vec4 color;
    // Should this be a mustache replace?
    if (fetch_pixel){
        color = get_pattern_color(image);
    }else{
        color = get_color(image, o_uv, color_norm, color_map, matcap);
    }
    #ifndef NO_SHADING
    color.rgb = illuminate(normalize(o_world_normal), color.rgb);
    #endif

#ifdef PICKING_INDEX_FROM_UV
    ivec2 size = textureSize(image, 0);
    ivec2 jl_idx = clamp(ivec2(vec2(o_uv) * size), ivec2(0), size-1);
    uint idx = uint(jl_idx.x + jl_idx.y * size.x);
    write2framebuffer(color, uvec2(o_id.x, uint(1) + idx));
#else
    write2framebuffer(color, o_id);
#endif
}
