{{GLSL_VERSION}}

{{TARGET_STAGE}}

layout(location=0) out vec4 fragment_color;
layout(location=1) out uvec2 fragment_groupid;

#ifdef SSAO_TARGET
layout(location=2) out vec3 fragment_position;
layout(location=3) out vec3 fragment_normal;
#endif

#ifdef OIT_TARGET
layout(location=2) out float coverage;

uniform float oit_scale;
#endif

in vec3 o_view_pos;
in vec3 o_view_normal;

void write2framebuffer(vec4 color, uvec2 id){
    if(color.a <= 0.0)
        discard;

    // For plot/sprite picking
    fragment_groupid = id;

#ifdef DEFAULT_TARGET
    fragment_color = color;
#endif

#ifdef SSAO_TARGET
    fragment_color = color;
    fragment_position.xyz = o_view_pos;
    fragment_normal.xyz = o_view_normal;
#endif

#ifdef OIT_TARGET
    float weight = color.a * max(0.01, oit_scale * pow((1 - gl_FragCoord.z), 3));
    coverage = 1.0 - clamp(color.a, 0.0, 1.0);
    fragment_color.rgb = weight * color.rgb;
    fragment_color.a = weight;
#endif
}
