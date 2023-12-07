{{GLSL_VERSION}}
{{GLSL_EXTENSIONS}}

struct Nothing{ //Nothing type, to encode if some variable doesn't contain any data
    bool _; //empty structs are not allowed
};

{{define_fast_path}}

{{vertex_type}} vertex;

in float lastlen;
{{valid_vertex_type}} valid_vertex;

{{color_type}}      color;
{{color_map_type}}  color_map;
{{intensity_type}}  intensity;
{{color_norm_type}} color_norm;
{{thickness_type}}  thickness;

vec4 _color(vec3 color, Nothing intensity, Nothing color_map, Nothing color_norm, int index, int len);
vec4 _color(vec4 color, Nothing intensity, Nothing color_map, Nothing color_norm, int index, int len);
vec4 _color(Nothing color, float intensity, sampler1D color_map, vec2 color_norm, int index, int len);
vec4 _color(Nothing color, sampler1D intensity, sampler1D color_map, vec2 color_norm, int index, int len);

uniform mat4 projectionview, model;
uniform uint objectid;
uniform int total_length;
uniform float px_per_unit;

out uvec2 g_id;
out vec4 g_color;
out float g_lastlen;
out int g_valid_vertex;
out float g_thickness;

vec4 getindex(sampler2D tex, int index);
vec4 getindex(sampler1D tex, int index);

vec4 to_vec4(vec3 v){return vec4(v, 1);}
vec4 to_vec4(vec2 v){return vec4(v, 0, 1);}

int get_valid_vertex(float se){return int(se);}
int get_valid_vertex(Nothing se){return 1;}

uniform float depth_shift;

void main()
{
    g_lastlen = lastlen;
    int index = gl_VertexID;
    g_id = uvec2(objectid, index+1);
    g_valid_vertex = get_valid_vertex(valid_vertex);
    g_thickness = px_per_unit * thickness;

    g_color = _color(color, intensity, color_map, color_norm, index, total_length);
    #ifdef FAST_PATH
        gl_Position = projectionview * model * to_vec4(vertex);
    #else
        gl_Position = to_vec4(vertex);
    #endif
    gl_Position.z += gl_Position.w * depth_shift;
}
