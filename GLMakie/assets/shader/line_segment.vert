{{GLSL_VERSION}}
{{GLSL_EXTENSIONS}}

struct Nothing{ //Nothing type, to encode if some variable doesn't contain any data
    bool _; //empty structs are not allowed
};

in float lastlen;
{{vertex_type}} vertex;
{{thickness_type}} thickness;
{{color_type}} color;

uniform mat4 projectionview, model;
uniform uint objectid;
uniform float depth_shift;
uniform float px_per_unit;

out uvec2 g_id;
out {{stripped_color_type}} g_color;
out float g_thickness;

vec4 to_vec4(vec3 v){return vec4(v, 1);}
vec4 to_vec4(vec2 v){return vec4(v, 0, 1);}

void main()
{
    g_id = uvec2(objectid, gl_VertexID + 1);
    g_color = color;
    g_thickness = px_per_unit * thickness;
    gl_Position = model * to_vec4(vertex);
}
