{{GLSL_VERSION}}

uniform sampler2D layer_color;
uniform usampler2D layer_objectid;
uniform float alpha;
layout(location=0) out vec4 fragment_color;
layout(location=1) out uvec2 fragment_groupid;

void main() {
    ivec2 px = ivec2(gl_FragCoord.xy);
    vec4 premultiplied = texelFetch(layer_color, px, 0);
    if (premultiplied.a <= 0.0)
        discard;
    fragment_color = alpha * premultiplied;
    fragment_groupid = texelFetch(layer_objectid, px, 0).xy;
}
