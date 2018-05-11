{{GLSL_VERSION}}
{{GLSL_EXTENSIONS}}
{{SUPPORTED_EXTENSIONS}}

layout(location=0) out vec4 fragment_color;
layout(location=1) out uvec2 fragment_groupid;

#ifdef DEPTH_LAYOUT
    layout (depth_greater) out float gl_FragDepth;
#endif
void write2framebuffer(vec4 color, uvec2 id){
    fragment_color = color;
    if (color.a > 0.5){
        gl_FragDepth = gl_FragCoord.z;
    }else{
        gl_FragDepth = 1.0;
    }
    fragment_groupid = id;
}
