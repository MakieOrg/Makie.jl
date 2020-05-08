{{GLSL_VERSION}}

uniform sampler2D occlusion;
uniform sampler2D color_texture;
uniform vec2 inv_texel_size;
uniform int blur_range;

in vec2 frag_uv;
out vec4 fragment_color;

void main(void)
{
      // occlusion blur
      float blurred_occlusion = 0.0;
      float steps = float((2*blur_range + 1) * (2*blur_range + 1));
      for (int x = -blur_range; x <= blur_range; ++x){
          for (int y = -blur_range; y <= blur_range; ++y){
              vec2 offset = vec2(float(x), float(y)) * inv_texel_size;
              blurred_occlusion += texture(occlusion, frag_uv + offset).r;
          }
      }
      // factor is 1 / (4*4)
      blurred_occlusion = blurred_occlusion / steps;
      fragment_color = texture(color_texture, frag_uv) * blurred_occlusion;

      // Display occlusion instead:
      // fragment_color = vec4(vec3(blurred_occlusion), 1.0);
}
