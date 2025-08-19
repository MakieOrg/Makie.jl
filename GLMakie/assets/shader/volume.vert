{{GLSL_VERSION}}

// Writes "#define ENABLE_DEPTH" if the attribute is initialized as true
// Otherwise writes nothing
{{ENABLE_DEPTH}}

in vec3 vertices;

out vec3 frag_vert;

uniform mat4 projectionview, model;
uniform mat4 modelinv;

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

#ifdef ENABLE_DEPTH
    gl_Position.z = 0.0;
#endif
}
