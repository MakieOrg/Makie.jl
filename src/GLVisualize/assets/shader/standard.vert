{{GLSL_VERSION}}

{{vertices_type}} vertices;
{{vertex_color_type}} vertex_color;
{{texturecoordinates_type}} texturecoordinates;
in vec3 normals;

uniform vec3 lightposition;
uniform mat4 projection, view, model;
void render(vec4 vertices, vec3 normals, mat4 viewmodel, mat4 projection, vec3 lightposition);

uniform uint objectid;
flat out uvec2 o_id;
out vec2 o_uv;
out vec4 o_color;

vec3 to_3d(vec2 v){return vec3(v, 0);}
vec3 to_3d(vec3 v){return v;}

vec2 to_2d(float v){return vec2(v, 0);}
vec2 to_2d(vec2 v){return v;}

vec4 to_color(vec3 c){return vec4(c, 1);}
vec4 to_color(vec4 c){return c;}

void main()
{
    o_id = uvec2(objectid, gl_VertexID+1);
    o_uv = to_2d(texturecoordinates);
    o_color = to_color(vertex_color);
    vec3 v = to_3d(vertices);
    render(model * vec4(v, 1), (model * vec4(normals, 0)).xyz, view, projection, lightposition);
}
