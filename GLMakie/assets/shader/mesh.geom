{{GLSL_VERSION}}
{{shading}}

// Preserve triangle attributes and explicitly forward the primitive ID used
// by mesh and surface strokes. This also avoids broken implicit ID handling.

layout(triangles) in;
layout(triangle_strip, max_vertices = 3) out;
// Match the vertex stage's built-in interface, including clip planes.
in gl_PerVertex {
    vec4 gl_Position;
    float gl_PointSize;
    float gl_ClipDistance[8];
} gl_in[];
in vec3 vo_view_pos[];
out vec3 o_view_pos;
in vec3 vo_view_normal[];
out vec3 o_view_normal;
noperspective in vec3 vo_ndc[];
noperspective out vec3 o_ndc;
#ifndef NO_SHADING
in vec3 vo_world_pos[];
out vec3 o_world_pos;
in vec3 vo_world_normal[];
out vec3 o_world_normal;
in vec3 vo_camdir[];
out vec3 o_camdir;
#endif
flat in uvec2 vo_id[];
flat out uvec2 o_id;
flat in int vo_InstanceID[];
flat out int o_InstanceID;
in vec3 vo_uv[];
out vec3 o_uv;
in vec4 vo_color[];
out vec4 o_color;
out float gl_ClipDistance[8];
void main() {
    for (int i = 0; i < 3; ++i) {
        gl_Position = gl_in[i].gl_Position;
        for (int j = 0; j < 8; ++j)
            gl_ClipDistance[j] = gl_in[i].gl_ClipDistance[j];
        gl_PrimitiveID = gl_PrimitiveIDIn;
        o_view_pos = vo_view_pos[i];
        o_view_normal = vo_view_normal[i];
        o_ndc = vo_ndc[i];
#ifndef NO_SHADING
        o_world_pos = vo_world_pos[i];
        o_world_normal = vo_world_normal[i];
        o_camdir = vo_camdir[i];
#endif
        o_id = vo_id[i];
        o_InstanceID = vo_InstanceID[i];
        o_uv = vo_uv[i];
        o_color = vo_color[i];
        EmitVertex();
    }
    EndPrimitive();
}
