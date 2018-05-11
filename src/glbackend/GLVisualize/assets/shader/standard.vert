{{GLSL_VERSION}}

in vec3 vertices;
in vec3 normals;

uniform vec3 light[4];
uniform vec4 color;
uniform mat4 projection, view, model;
void render(vec4 vertices, vec3 normals, mat4 viewmodel, mat4 projection, vec3 light[4]);

uniform uint objectid;
flat out uvec2 o_id;
out vec2 o_uv;
out vec4 o_color;

void main()
{
  o_id = uvec2(objectid, gl_VertexID+1);
  o_uv = vec2(0);
  o_color = color;
  render(model * vec4(vertices, 1), (model * vec4(normals, 0)).xyz, view, projection, light);
}
