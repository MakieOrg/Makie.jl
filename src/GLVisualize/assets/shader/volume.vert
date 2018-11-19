{{GLSL_VERSION}}

in vec3 vertices;
in vec3 texturecoordinates;

out vec3 frag_vert;
out vec3 frag_uv;

uniform mat4 projection, view, model;


void main()
{
    vec4 world_vert = model * vec4(vertices, 1);
    frag_vert = world_vert.xyz;
    frag_uv = texturecoordinates;
    gl_Position = projection * view * world_vert;
}
