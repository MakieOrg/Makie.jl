out vec3 frag_vert;
out float o_clip_distance[8];

uniform mat4 projection, view;
uniform vec4 clip_planes[8];

void process_clip_planes(vec3 world_pos) {
    for (int i = 0; i < 8; i++)
        o_clip_distance[i] = dot(world_pos, clip_planes[i].xyz) - clip_planes[i].w;
}

void main()
{
    frag_vert = position;
    vec4 world_vert = model * vec4(position, 1);
    process_clip_planes(world_vert.xyz);
    gl_Position = projection * view * world_vert;
    gl_Position.z += gl_Position.w * get_depth_shift();
}
