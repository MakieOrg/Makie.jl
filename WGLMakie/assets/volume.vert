out vec3 frag_vert;
out vec3 o_light_dir;

uniform mat4 projection, view;

void main()
{
    frag_vert = position;
    vec4 world_vert = model * vec4(position, 1);
    o_light_dir = vec3(modelinv * vec4(get_lightposition(), 1));
    gl_Position = projection * view * world_vert;
    gl_Position.z += gl_Position.w * get_depth_shift();
}
