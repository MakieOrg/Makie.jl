{{GLSL_VERSION}}

struct Nothing{ //Nothing type, to encode if some variable doesn't contain any data
    bool _; //empty structs are not allowed
};

{{vertices_type}} vertices;
{{vertex_color_type}} vertex_color;
{{texturecoordinates_type}} texturecoordinates;

{{color_map_type}} color_map;
{{color_norm_type}} color_norm;
uniform bool interpolate_in_fragment_shader = false;

in vec3 normals;

uniform mat4 projection, view, model;

uniform int num_clip_planes;
uniform vec4 clip_planes[8];

void render(vec4 position_world, vec3 normal, mat4 view, mat4 projection);
vec4 get_color_from_cmap(float value, sampler1D color_map, vec2 colorrange);

uniform uint objectid;

flat out uvec2 o_id;
flat out int o_InstanceID;
out vec3 o_uv;
out vec4 o_color;


vec3 to_3d(vec2 v){return vec3(v, 0);}
vec3 to_3d(vec3 v){return v;}

vec2 to_2d(float v){return vec2(v, 0);}
vec2 to_2d(vec2 v){return v;}

{{uv_transform_type}} uv_transform;

vec3 apply_uv_transform(Nothing t1, vec2 uv){
    return vec3(uv, 0.0);
}
vec3 apply_uv_transform(Nothing t1, vec3 uv) {
    return uv;
}
vec3 apply_uv_transform(mat3x2 transform, vec3 uv){
    return uv;
}
vec3 apply_uv_transform(mat3x2 transform, vec2 uv) {
    return vec3(transform * vec3(uv, 1.0), 0.0);
}

vec4 to_color(vec3 c, Nothing color_map, Nothing color_norm){
    return vec4(c, 1);
}

vec4 to_color(vec4 c, Nothing color_map, Nothing color_norm){
    return c;
}

vec4 to_color(float c, sampler1D color_map, vec2 color_norm){
    if (interpolate_in_fragment_shader) {
        return vec4(c, 0.0, 0.0, 0.0);
    } else {
        return get_color_from_cmap(c, color_map, color_norm);
    }
}

vec4 to_color(Nothing c, sampler1D color_map, vec2 color_norm){
    return vec4(0.0);
}

vec4 to_color(Nothing c, Nothing cm, Nothing cn) {
    return vec4(0.0);
}


void main()
{
    o_id = uvec2(objectid, gl_VertexID+1);
    o_uv = apply_uv_transform(uv_transform, texturecoordinates);
    o_color = to_color(vertex_color, color_map, color_norm);
    o_InstanceID = 0;
    vec3 v = to_3d(vertices);
    render(model * vec4(v, 1), normals, view, projection);
}
