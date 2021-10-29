{{GLSL_VERSION}}

layout(location=0) out vec4 fragment_color; // RGBAF16
layout(location=1) out uvec2 fragment_groupid; // keep this?
layout(location=2) out float coverage; // F16 or N0f8


in vec4 o_view_pos;
in vec3 o_normal;


void write2framebuffer(vec4 color, uvec2 id){
    if(color.a <= 0.0)
        discard;
    
    // frag_Depth is in (-1, 1) right?
    // summation/product via blend functions
    float weight = color.a * max(0.01, 3000 * pow((1 - gl_FragCoord.z), 3));
    fragment_color = weight * color;
    coverage = color.a;
    fragment_groupid = id;
}
