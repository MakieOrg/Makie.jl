{{GLSL_VERSION}}

uniform sampler2D color_texture;
in vec2 frag_uv;
out vec4 fragment_color;

void main(void)
{
    fragment_color = texture(color_texture, frag_uv);
}
