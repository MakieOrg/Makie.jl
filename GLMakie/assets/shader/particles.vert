{{GLSL_VERSION}}
{{GLSL_EXTENSIONS}}

struct Nothing{ //Nothing type, to encode if some variable doesn't contain any data
    bool _; //empty structs are not allowed
};
struct Grid1D{
    int lendiv;
    float start;
    float stop;
    int dims;
};
struct Grid2D{
    ivec2 lendiv;
    vec2 start;
    vec2 stop;
    ivec2 dims;

};
struct Grid3D{
    ivec3 lendiv;
    vec3 start;
    vec3 stop;
    ivec3 dims;
};

in vec3 vertices;
in vec3 normals;
{{texturecoordinates_type}} texturecoordinates;

uniform mat4 view, model, projection;
uniform bool scale_primitive;
uniform uint objectid;
uniform int len;

flat out uvec2 o_id;
flat out int o_InstanceID;
out vec4 o_color;
out vec3 o_uv;

{{position_type}} position;

ivec2 ind2sub(ivec2 dim, int linearindex);
ivec3 ind2sub(ivec3 dim, int linearindex);


{{rotation_type}}   rotation;
void rotate(Nothing       vectors, int index, inout vec3 vertices, inout vec3 normal);
void rotate(samplerBuffer vectors, int index, inout vec3 V, inout vec3 N);
void rotate(vec4          vectors, int index, inout vec3 vertices, inout vec3 normal);
vec4 get_rotation(samplerBuffer rotation, int index){
    return texelFetch(rotation, index);
}
vec4 get_rotation(Nothing rotation, int index){
    return vec4(0,0,0,1);
}
vec4 get_rotation(vec4 rotation, int index){
    return rotation;
}

{{scale_type}}   scale;
vec3 _scale(samplerBuffer scale, int index);
vec3 _scale(vec3          scale, int index);
vec3 _scale(vec2          scale, int index);

uniform vec3 f32c_scale;

{{color_type}} color;
{{color_map_type}} color_map;
{{intensity_type}} intensity;
{{color_norm_type}} color_norm;
{{vertex_color_type}} vertex_color;
vec4 to_color(Nothing c){return vec4(1, 1, 1, 1);}
vec4 to_color(vec3 c){return vec4(c, 1);}
vec4 to_color(vec4 c){return c;}

vec4 get_color_from_cmap(float value, sampler1D color_map, vec2 colorrange);

// constant color!
vec4 get_particle_color(vec4 color, Nothing intensity, Nothing color_map, Nothing color_norm, int index, int len){
    return color;
}
// only a samplerBuffer, this means we have one color per particle
vec4 get_particle_color(samplerBuffer color, Nothing intensity, Nothing color_map, Nothing color_norm, int index, int len){
    return texelFetch(color, index);
}
// only a samplerBuffer, this means we have one color (as float) per particle
vec4 get_particle_color(Nothing color, samplerBuffer intensity, sampler1D color_map, vec2 color_norm, int index, int len){
    // always look up color in vertex_shader (mesh.frag can switch)
    return get_color_from_cmap(texelFetch(intensity, index).x, color_map, color_norm);
}
// image should be defined instead
vec4 get_particle_color(Nothing color, Nothing intensity, Nothing color_map, Nothing color_norm, int index, int len){
    return vec4(0);
}

void render(vec4 position_world, vec3 normal, mat4 view, mat4 projection);

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

vec3 get_uv(int index, Nothing uv){ return vec3(0.0); }
vec3 get_uv(int index, vec2 uv){
    return vec3(apply_uv_transform(uv_transform, index, uv), 0.0);
}
vec3 get_uv(int index, vec3 uv) {
    return uv;
}


void main(){
    int index = gl_InstanceID;
    o_id = uvec2(objectid, index+1);
    vec3 s = _scale(scale, index);
    vec3 V = s * vertices;
    vec3 N = normals / s; // see issue #3702
    vec3 pos;
    {{position_calc}}
    o_color = get_particle_color(color, intensity, color_map, color_norm, index, len);
    o_color = o_color * to_color(vertex_color);
    o_uv = get_uv(index, texturecoordinates);
    o_InstanceID = index;
    rotate(rotation, index, V, N);
    V = f32c_scale * V;
    N = N / f32c_scale;
    if (scale_primitive)
        render(model * vec4(pos + V, 1), N, view, projection);
    else
        render(model * vec4(pos, 1) +  vec4(V, 0), N, view, projection);
}
