out vec3 frag_vert;
out vec3 o_light_dir;

uniform mat4 projectionMatrix, viewMatrix, modelMatrix;

void main()
{
    vec4 world_vert = modelMatrix * vec4(position, 1);
    frag_vert = world_vert.xyz;
    o_light_dir = vec3(modelinv * vec4(get_lightposition(), 1));
    gl_Position = projectionMatrix * viewMatrix * world_vert;
}
