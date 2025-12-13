{{GLSL_VERSION}}

in vec2 vertices;
in vec2 uv;
out vec2 f_uv;
uniform mat4 projection, view, model;

void main(){
    gl_Position = projection * view * vec4(vertices, 0, 1);
    f_uv = uv;
}
