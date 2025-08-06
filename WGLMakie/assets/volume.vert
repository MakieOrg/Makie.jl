precision highp float;
precision highp int;

out vec3 frag_vert;

uniform mat4 projection, view;

void main()
{
    frag_vert = position;
    vec4 world_vert = model * vec4(position, 1);
    gl_Position = projection * view * world_vert;
    gl_Position.z = 0.0;
}
