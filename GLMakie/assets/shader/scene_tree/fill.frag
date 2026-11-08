{{GLSL_VERSION}}

uniform vec4 color;
layout(location=0) out vec4 fragment_color;
layout(location=1) out uvec2 fragment_groupid;

void main() {
    fragment_color = color;
    fragment_groupid = uvec2(0);
}
