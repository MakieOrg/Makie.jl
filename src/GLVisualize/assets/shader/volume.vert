{{GLSL_VERSION}}

in vec3 vertices;

out vec3 frag_vert;
out vec3 o_light_dir;

uniform mat4 projectionview, model;
uniform vec3 lightposition;
uniform mat4 modelinv;

void main()
{
    vec4 world_vert = model * vec4(vertices, 1);
    frag_vert = world_vert.xyz;
    o_light_dir = vec3(modelinv * vec4(lightposition, 1));
    gl_Position = projectionview * world_vert;
}
