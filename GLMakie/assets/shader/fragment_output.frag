{{GLSL_VERSION}}

layout(location=0) out vec4 fragment_color;
layout(location=1) out uvec2 fragment_groupid;
{{buffers}}
// resolves to:
// // if transparency == true
// layout(location=2) out float coverage;

// // if transparency == false && enable_SSAO[] = true
// layout(location=2) out vec3 fragment_position;
// layout(location=3) out vec3 fragment_normal_occlusion;


in vec3 o_view_pos;
in vec3 o_normal;

void write2framebuffer(vec4 color, uvec2 id){
    if(color.a <= 0.0)
        discard;

    // For plot/sprite picking
    fragment_groupid = id;

    {{buffer_writes}}
    // resolves to:

    // // if transparency == true
    // float weight = color.a * max(0.01, 3000 * pow((1 - gl_FragCoord.z), 3));
    // fragment_color = weight * color;
    // coverage = color.a;

    // // if transparency == false && enable_SSAO[] = true
    // fragment_color = color;
    // fragment_position = o_view_pos;
    // fragment_normal_occlusion.xyz = o_normal;

    // // else
    // fragment_color = color;
}
