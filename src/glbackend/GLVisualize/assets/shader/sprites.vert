{{GLSL_VERSION}}
{{GLSL_EXTENSIONS}}

struct Nothing{ //Nothing type, to encode if some variable doesn't contain any data
    bool _; //empty structs are not allowed
};
struct Grid1D{
    float ref;
    float offset;
    float _step;
    int dims;
};
struct Grid2D{
    vec2 ref;
    vec2 offset;
    vec2 _step;
    ivec2 dims;
};
struct Grid3D{
    vec3 ref;
    vec3 offset;
    vec3 _step;
    ivec3 dims;
};

{{uv_offset_width_type}} uv_offset_width;
//{{uv_x_type}} uv_width;
{{position_type}} position;
{{position_x_type}} position_x;
{{position_y_type}} position_y;
{{position_z_type}} position_z;
//Assembling functions for creating the right position from the above inputs. They also indicate the type combinations allowed for the above inputs
ivec2 ind2sub(ivec2 dim, int linearindex);
ivec3 ind2sub(ivec3 dim, int linearindex);

{{scale_type}}   scale; // so in the case of distinct x,y,z, there's no chance to unify them under one variable
{{scale_x_type}} scale_x;
{{scale_y_type}} scale_y;
{{scale_z_type}} scale_z;
vec3 _scale(Nothing scale, Nothing scale_x, Nothing scale_y, Nothing scale_z, int index);
vec3 _scale(vec3    scale, Nothing scale_x, Nothing scale_y, Nothing scale_z, int index);
vec3 _scale(vec2    scale, Nothing scale_x, Nothing scale_y, Nothing scale_z, int index);
vec3 _scale(Nothing scale, float   scale_x, float   scale_y, float   scale_z, int index);
vec3 _scale(vec3    scale, float   scale_x, float   scale_y, float   scale_z, int index);
vec3 _scale(vec2    scale, float   scale_x, float   scale_y, float   scale_z, int index);



{{offset_type}} offset;

{{rotation_type}} rotation;

vec4 _rotation(Nothing r){return vec4(0,0,0,1);}
vec4 _rotation(vec2 r){return vec4(r, 0, 1);}
vec4 _rotation(vec3 r){return vec4(r, 1);}
vec4 _rotation(vec4 r){return r;}

float get_rotation_len(Nothing rotation){
    return 1.0;
}

float get_rotation_len(vec4 rotation){
    return 1.0;
}

vec3 _scale(Nothing scale, float scale_x, float scale_y, Nothing scale_z, int index){
    float len = get_rotation_len(rotation);
    return vec3(scale_x,scale_y, len);
}
vec3 _scale(vec3 scale, Nothing scale_x, Nothing scale_y, Nothing scale_z, int index){
    float len = get_rotation_len(rotation);
    return vec3(scale.xy, scale.z*len);
}

{{color_type}}        color;
{{color_map_type}}    color_map;
{{intensity_type}}    intensity;
{{color_norm_type}}   color_norm;

float get_intensity(vec4 rotation, Nothing position_z, int index){return length(rotation);}
float get_intensity(vec3 rotation, Nothing position_z, int index){return length(rotation);}
float get_intensity(vec2 rotation, Nothing position_z, int index){return length(rotation);}
float get_intensity(Nothing rotation, float position_z, int index){return position_z;}
float get_intensity(vec3 rotation, float position_z, int index){return position_z;}
vec4 color_lookup(float intensity, sampler1D color_ramp, vec2 norm);

vec4 _color(vec3 color, Nothing intensity, Nothing color_map, Nothing color_norm, int index, int len);
vec4 _color(vec4 color, Nothing intensity, Nothing color_map, Nothing color_norm, int index, int len);
vec4 _color(Nothing color, float intensity, sampler1D color_map, vec2 color_norm, int index, int len);
vec4 _color(Nothing color, sampler1D intensity, sampler1D color_map, vec2 color_norm, int index, int len);
vec4 _color(Nothing color, Nothing intensity, sampler1D color_map, vec2 color_norm, int index, int len){
    return color_lookup(get_intensity(rotation, position_z, index), color_map, color_norm);
}

{{stroke_color_type}} stroke_color;
{{glow_color_type}}   glow_color;

uniform uint objectid;
uniform int len;

out uvec2 g_id;
out int   g_primitive_index;
out vec3  g_position;
out vec4  g_offset_width;
out vec4  g_uv_offset_width;
out vec4  g_rotation;
out vec4  g_color;
out vec4  g_stroke_color;
out vec4  g_glow_color;



void main(){
    int index         = gl_VertexID;
	g_primitive_index = index;
    vec3 pos;
    {{position_calc}}
    g_position        = pos;
    g_offset_width.xy = offset.xy;
    g_offset_width.zw = _scale(scale, scale_x, scale_y, scale_z, g_primitive_index).xy;
    g_color           = _color(color, intensity, color_map, color_norm, g_primitive_index, len);
    g_rotation        = _rotation(rotation);
    g_uv_offset_width = uv_offset_width;
    g_stroke_color    = stroke_color;
    g_glow_color      = glow_color;

    g_id              = uvec2(objectid, index+1);
}
