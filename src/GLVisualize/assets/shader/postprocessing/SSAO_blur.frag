{{GLSL_VERSION}}

uniform sampler2D occlusion;
uniform vec2 inv_texel_size;
uniform sampler2D color_texture;

in vec2 frag_uv;
out vec4 fragment_color;

void main(void)
{
      // occlusion blur
      float blurred_occlusion = 0.0;
      for (int x = -2; x < 2; ++x){
          for (int y = -2; y < 2; ++y){
              vec2 offset = vec2(float(x), float(y)) * inv_texel_size;
              blurred_occlusion += texture(occlusion, frag_uv + offset).r;
          }
      }
      // factor is 1 / (4*4)
      blurred_occlusion = 0.0625 * blurred_occlusion;
      fragment_color = texture(color_texture, frag_uv) * blurred_occlusion;

      // Display occlusion instead:
      // fragment_color = vec4(vec3(blurred_occlusion), 1.0);
}
