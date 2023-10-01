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

uniform vec3 lightposition;
uniform mat4 projection, view, model;

void render(vec4 position_world, vec3 normal, mat4 view, mat4 projection, vec3 lightposition);
vec4 get_color_from_cmap(float value, sampler1D color_map, vec2 colorrange);

uniform uint objectid;
uniform vec2 uv_scale;

flat out uvec2 o_id;
out vec2 o_uv_scale;
out vec2 o_uv;
out vec4 o_color;

vec3 to_3d(vec2 v){return vec3(v, 0);}
vec3 to_3d(vec3 v){return v;}

vec2 to_2d(float v){return vec2(v, 0);}
vec2 to_2d(vec2 v){return v;}

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
    vec2 tex_uv = to_2d(texturecoordinates);
    o_uv_scale = uv_scale;
    o_uv = vec2(1.0 - tex_uv.y, tex_uv.x) * uv_scale;
    o_color = to_color(vertex_color, color_map, color_norm);
    vec3 v = to_3d(vertices);
    render(model * vec4(v, 1), normals, view, projection, lightposition);
}
