{{GLSL_VERSION}}

layout(location=0) out vec4 fragment_color;
layout(location=1) out uvec2 fragment_groupid;
layout(location=2) out vec4 fragment_position;
layout(location=3) out vec3 fragment_normal;

void write2framebuffer(vec4 color, uvec2 id){
    if(color.a <= 0.0)
        discard;
    fragment_color = color;
    fragment_groupid = id;
    fragment_position = gl_FragCoord;
    fragment_normal = vec3(0.0, 0.0, 1.0);
}

void write2framebuffer(vec4 color, uvec2 id, vec3 normal){
    if(color.a <= 0.0)
        discard;
    fragment_color = color;
    fragment_groupid = id;
    fragment_position = gl_FragCoord;
    fragment_normal = normal;
}
