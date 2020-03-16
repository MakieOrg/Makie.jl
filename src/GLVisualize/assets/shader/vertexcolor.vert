{{GLSL_VERSION}}

in vec3 vertices;
in vec3 normals;
in vec4 vertex_color;

uniform vec3 lightposition;

uniform mat4 projection, view, model;

void render(vec4 vertices, vec3 normals, mat4 view, mat4 projection, vec3 lightposition);

uniform uint objectid;

out vec4 o_color;
flat out uvec2 o_id;
out vec2 o_uv;

void main()
{
    o_uv = vec2(0.0);
    o_id = uvec2(objectid, 0);
    o_color = vertex_color;
    render(model * vec4(vertices, 1), (model * vec4(normals, 0)).xyz, view, projection, lightposition);
}
