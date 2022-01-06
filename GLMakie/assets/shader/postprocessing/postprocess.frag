{{GLSL_VERSION}}

in vec2 frag_uv;

uniform sampler2D color_texture;
uniform usampler2D object_ids;

layout(location=0) out vec4 fragment_color;

vec3 linear_tone_mapping(vec3 color, float gamma)
{
    color = clamp(color, 0.0, 1.0);
    color = pow(color, vec3(1. / gamma));
    return color;
}

void main(void)
{
    vec4 color = texture(color_texture, frag_uv).rgba;
    if(color.a <= 0){
        discard;
    }
    uvec2 ids = texture(object_ids, frag_uv).xy;
    // do tonemappings
    //opaque = linear_tone_mapping(color.rgb, 1.8);  // linear color output
    fragment_color.rgb = color.rgb;
    // save luma in alpha for FXAA
    if (ids.x != uint(0)) {
        fragment_color.a = 1.0;
    } else {
        fragment_color.a = dot(color.rgb, vec3(0.299, 0.587, 0.114)); // compute luma
    }
}
