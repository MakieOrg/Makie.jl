{{GLSL_VERSION}}

in vec3 vertices;

out vec3 frag_vert;

uniform mat4 projectionview, model;
uniform mat4 modelinv;
uniform float depth_shift;

// SSAO
out vec3 o_view_pos;
out vec3 o_view_normal;

// Lighting (unused but sometimes necessary)
out vec3 o_world_pos;
out vec3 o_camdir;

void main()
{
    // TODO set these in volume.frag
    o_view_pos = vec3(0);
    o_view_normal = vec3(0);

    o_world_pos = vec3(0);
    o_camdir = vec3(0);

    vec4 world_vert = model * vec4(vertices, 1);
    frag_vert = world_vert.xyz;

    gl_Position = projectionview * world_vert;
    gl_Position.z += gl_Position.w * depth_shift;
}
