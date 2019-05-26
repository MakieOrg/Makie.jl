out vec3 frag_vert;
out vec3 frag_uv;

uniform mat4 projectionMatrix, viewMatrix, modelMatrix;

void main()
{
    vec4 world_vert = modelMatrix * vec4(position, 1);
    frag_vert = world_vert.xyz;
    frag_uv = texturecoordinates;
    gl_Position =  projectionMatrix * viewMatrix * world_vert;
}
