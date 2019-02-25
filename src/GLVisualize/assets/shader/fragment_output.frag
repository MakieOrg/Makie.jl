{{GLSL_VERSION}}

layout(location=0) out vec4 fragment_color;
layout(location=1) out uvec2 fragment_groupid;

void write2framebuffer(vec4 color, uvec2 id){
    if(color.a <= 0.0)
        discard;
    fragment_color = color;
    fragment_groupid = id;
}
