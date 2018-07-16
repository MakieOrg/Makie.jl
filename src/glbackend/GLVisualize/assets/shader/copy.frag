{{GLSL_VERSION}}

uniform sampler2D color_texture;
in vec2 frag_uv;
out vec4 fragment_color;

void main(void)
{
    vec4 color = texture(color_texture, frag_uv);
    //if(color.a <= 0){
      //  discard;
    //}
    fragment_color.rgb = color.rgb;
    fragment_color.a = 1.0;
}
