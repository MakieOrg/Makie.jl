{{GLSL_VERSION}}

in vec2 position;
uniform mat4 scene_frame;
uniform float depth;

void main() {
    gl_Position = scene_frame * vec4(position, depth, 1.0);
}
