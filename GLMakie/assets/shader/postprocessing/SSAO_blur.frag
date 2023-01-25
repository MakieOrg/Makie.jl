{{GLSL_VERSION}}

// occlusion.w is the occlusion value
uniform sampler2D normal_occlusion;
uniform sampler2D color_texture;
uniform usampler2D ids;
uniform vec2 inv_texel_size;
// Settings/Attributes
uniform int blur_range;

in vec2 frag_uv;
out vec4 fragment_color;

void main(void)
{
    // occlusion blur
    uvec2 id0 = texture(ids, frag_uv).xy;
    if (id0.x == 0){
        fragment_color = texture(color_texture, frag_uv);
        // fragment_color = vec4(1,0,1,1); // show discarded
        return;
    }

    float blurred_occlusion = 0.0;
    float weight = 0;

    for (int x = -blur_range; x <= blur_range; ++x){
        for (int y = -blur_range; y <= blur_range; ++y){
            vec2 offset = vec2(float(x), float(y)) * inv_texel_size;
            // The id check makes it so that the blur acts per object.
            // Without this, a high (low) occlusion from one object can bleed
            // into the low (high) occlusion of another, giving an unwanted
            // shine effect.
            uvec2 id = texture(ids, frag_uv + offset).xy;
            float valid = float(id == id0);
            blurred_occlusion += valid * texture(normal_occlusion, frag_uv + offset).w;
            weight += valid;
        }
    }
    blurred_occlusion = 1.0 - blurred_occlusion / weight;
    fragment_color = texture(color_texture, frag_uv) * blurred_occlusion;
    // Display occlusion instead:
    // fragment_color = vec4(vec3(blurred_occlusion), 1.0);
}
