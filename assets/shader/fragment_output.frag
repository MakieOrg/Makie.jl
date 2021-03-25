{{GLSL_VERSION}}

layout(location=0) out vec4 fragment_color;
layout(location=1) out uvec2 fragment_groupid;
{{buffers}}


in vec4 o_view_pos;
in vec3 o_normal;

void write2framebuffer(vec4 color, uvec2 id){
    if(color.a <= 0.0)
        discard;
    // For FXAA & SSAO
    fragment_color = color;
    // For plot/sprite picking
    fragment_groupid = id;
    {{buffer_writes}}
}
