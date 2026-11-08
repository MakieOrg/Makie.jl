{{GLSL_VERSION}}

uniform vec4 color;
layout(location=0) out vec4 fragment_color;
layout(location=1) out uvec2 fragment_groupid;

float scene_clip_coverage();

void main() {
    float coverage = scene_clip_coverage();
    if (coverage <= 0.0)
        discard;
    fragment_color = vec4(color.rgb, color.a * coverage);
    fragment_groupid = uvec2(0);
}
