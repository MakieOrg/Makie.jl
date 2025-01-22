{{GLSL_VERSION}}

flat in vec4  o_color;
flat in uvec2 o_objectid;

void write2framebuffer(vec4 color, uvec2 id);

uniform mat4 projection;
uniform vec2 scale;
uniform int marker_shape;

void main(){
    vec2 p = gl_PointCoord - 0.5; // Normalized coordinates centered at (0.5, 0.5)
    float len = length(p * 2.0); // Length from center, scale to range [-1, 1]
    float alpha;
    vec4 color = o_color;
    if (marker_shape == 1) {
        alpha  = 1.0;
    } else if (marker_shape == 2) {
        alpha = 1.0 - smoothstep(0.0, 1.0, len);// Smoothstep for smooth transition
    } else {
        alpha = 1.0 - smoothstep(0.0, 1.0, len);// Ensure alpha is in [0, 1] range
        gl_FragDepth -= abs(projection[3][2] * alpha);
        alpha = 1;
    }
    write2framebuffer(vec4(color.rgb, alpha * color.a), o_objectid);
}
