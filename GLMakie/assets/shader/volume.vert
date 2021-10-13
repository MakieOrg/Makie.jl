{{GLSL_VERSION}}

in vec3 vertices;

out vec3 frag_vert;
out vec3 o_light_dir;

uniform mat4 projectionview, model;
uniform vec3 lightposition;
uniform mat4 modelinv;
uniform float depth_shift;

out vec4 o_view_pos;
out vec3 o_normal;

void main()
{
    // TODO set these in volume.frag
    o_view_pos = vec4(0);
    o_normal = vec3(0);
    vec4 world_vert = model * vec4(vertices, 1);
    frag_vert = world_vert.xyz;
    o_light_dir = vec3(modelinv * vec4(lightposition, 1));
    gl_Position = projectionview * world_vert;
    gl_Position += gl_Position.w * depth_shift;
}
