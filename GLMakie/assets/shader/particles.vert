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

uniform vec3 lightposition;
uniform mat4 view, model, projection;
uniform uint objectid;
uniform int len;

flat out uvec2 o_id;
out vec4 o_color;
out vec2 o_uv;

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

{{color_type}}      color;
{{color_map_type}}  color_map;
{{intensity_type}}  intensity;
{{color_norm_type}} color_norm;
{{vertex_color_type}} vertex_color;
vec4 to_color(Nothing c){return vec4(1, 1, 1, 1);}
vec4 to_color(vec3 c){return vec4(c, 1);}
vec4 to_color(vec4 c){return c;}

// constant color!
vec4 _color(vec4 color, Nothing intensity, Nothing color_map, Nothing color_norm, int index, int len);
vec4 _color(vec3 color, Nothing intensity, Nothing color_map, Nothing color_norm, int index, int len);
// only a samplerBuffer, this means we have a color per particle
vec4 _color(samplerBuffer color, Nothing intensity, Nothing color_map, Nothing color_norm, int index, int len);
// no color, but intensities a color map and color norm. Color will be based on intensity!
vec4 _color(Nothing color, sampler1D intensity, sampler1D color_map, vec2 color_norm, int index, int len);
vec4 _color(Nothing color, samplerBuffer intensity, sampler1D color_map, vec2 color_norm, int index, int len);
// no color, no intensities a color map and color norm. Color will be based on z_position or rotation!
vec4 _color(Nothing color, Nothing intensity, sampler1D color_map, vec2 color_norm, int index, int len);

vec4 color_lookup(float intensity, sampler1D color_ramp, vec2 norm);

vec4 _color(sampler2D color, Nothing intensity, Nothing color_map, Nothing color_norm, int index, int len){
    return vec4(0);
}

void render(vec4 position_world, vec3 normal, mat4 view, mat4 projection, vec3 lightposition);

vec2 get_uv(Nothing x){return vec2(0.0);}
vec2 get_uv(vec2 x){return vec2(1.0 - x.y, x.x);}

void main(){
    int index = gl_InstanceID;
    o_id = uvec2(objectid, index+1);
    vec3 s = _scale(scale, index);
    vec3 V = vertices * s;
    vec3 N = normals;
    vec3 pos;
    {{position_calc}}
    o_color = _color(color, intensity, color_map, color_norm, index, len);
    o_color = o_color * to_color(vertex_color);
    o_uv = get_uv(texturecoordinates);
    rotate(rotation, index, V, N);
    render(model * vec4(pos + V, 1), N, view, projection, lightposition);
}
