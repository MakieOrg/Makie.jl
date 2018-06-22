{{GLSL_VERSION}}

in vec3 vertices;
in vec3 normals;
in vec2 texturecoordinates;


uniform vec3 light[4];
uniform mat4 projection, view, model;
void render(vec4 vertices, vec3 normals, mat4 view, mat4 projection, vec3 light[4]);

uniform uint objectid;
flat out uvec2 o_id;
out vec2 o_uv;
out vec4 o_color;


void main()
{
    o_color = vec4(0);
    o_uv = texturecoordinates;
    o_uv = vec2(1.0 - o_uv.y, o_uv.x);
	o_id = uvec2(objectid, gl_VertexID+1);
	render(model * vec4(vertices, 1), (model * vec4(normals, 0)).xyz, view, projection, light);
}
