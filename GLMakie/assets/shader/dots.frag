{{GLSL_VERSION}}

flat in vec4  o_color;
flat in uvec2 o_objectid;

void write2framebuffer(vec4 color, uvec2 id);

void main(){
    // vec2 p = gl_PointCoord - 0.5; // Normalized coordinates centered at (0.5, 0.5)
    // float len = length(p * 2.0); // Length from center, scale to range [-1, 1]
    // float alpha = 1.0 - smoothstep(0.0, 1.0, len); // Smoothstep for smooth transition
    // alpha = clamp(alpha, 0.0, 1.0); // Ensure alpha is in [0, 1] range
    write2framebuffer(vec4(o_color.rgb, o_color.a), o_objectid);
}
