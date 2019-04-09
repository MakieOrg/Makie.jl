{{GLSL_VERSION}}
{{GLSL_EXTENSIONS}}

{{vertex_type}} vertex;
{{color_type}} color;
{{thickness_type}} thickness;

uniform mat4 projection, view, model;
uniform uint objectid;

out uvec2 g_id;
out vec4 g_color;
out float g_thickness;

vec4 getindex(sampler2D tex, int index);
vec4 getindex(sampler1D tex, int index);

vec4 to_vec4(vec3 v){return vec4(v, 1);}
vec4 to_vec4(vec2 v){return vec4(v, 0, 1);}

vec4 to_color(vec4 v, int index){return v;}
vec4 to_color(vec3 v, int index){return vec4(v, 1);}
vec4 to_color(sampler2D tex, int index){return getindex(tex, index);}
vec4 to_color(sampler1D tex, int index){return getindex(tex, index);}


void main()
{
    int index   = gl_VertexID;
    g_id        = uvec2(objectid, index+1);
    g_color     = to_color(color, index);
    g_thickness = thickness;
    gl_Position = projection*view*model*to_vec4(vertex);
}
