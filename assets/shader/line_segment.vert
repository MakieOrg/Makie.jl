{{GLSL_VERSION}}
{{GLSL_EXTENSIONS}}

struct Nothing{ //Nothing type, to encode if some variable doesn't contain any data
    bool _; //empty structs are not allowed
};

{{vertex_type}} vertex;
{{thickness_type}} thickness;

{{color_type}} color;
{{color_map_type}}  color_map;
{{color_norm_type}} color_norm;

uniform mat4 projectionview, model;
uniform uint objectid;

out uvec2 g_id;
out vec4 g_color;
out float g_thickness;

vec4 getindex(sampler2D tex, int index);
vec4 getindex(sampler1D tex, int index);
vec4 color_lookup(float intensity, sampler1D color_ramp, vec2 norm);

vec4 to_vec4(vec3 v){return vec4(v, 1);}
vec4 to_vec4(vec2 v){return vec4(v, 0, 1);}

vec4 to_color(vec4 v, Nothing color_map, Nothing color_norm, int index){return v;}
vec4 to_color(vec3 v, Nothing color_map, Nothing color_norm, int index){return vec4(v, 1);}
vec4 to_color(sampler1D tex, Nothing color_map, Nothing color_norm, int index){return getindex(tex, index);}
vec4 to_color(sampler2D tex, Nothing color_map, Nothing color_norm, int index){return getindex(tex, index);}
vec4 to_color(float color, sampler1D color_map, vec2 color_norm, int index){
    return color_lookup(color, color_map, color_norm);
}

void main()
{
    int index = gl_VertexID;
    g_id = uvec2(objectid, index+1);
    g_color = to_color(color, color_map, color_norm, index);
    g_thickness = thickness;
    gl_Position = projectionview * model * to_vec4(vertex);
}
