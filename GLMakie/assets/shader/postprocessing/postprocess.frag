{{GLSL_VERSION}}

{{FILTER_IN_SHADER}}

in vec2 frag_uv;

uniform sampler2D color_buffer;
uniform usampler2D objectid_buffer;

layout(location=0) out vec4 fragment_color;

vec3 linear_tone_mapping(vec3 color, float gamma)
{
    color = clamp(color, 0.0, 1.0);
    color = pow(color, vec3(1. / gamma));
    return color;
}

bool unpack_bool(uint id) {
    uint high_bit_mask = uint(1) << uint(31);
    return id >= high_bit_mask;
}

void main(void)
{
    vec4 color = texture(color_buffer, frag_uv).rgba;
    if(color.a <= 0){
        discard;
    }

    uint id = texture(objectid_buffer, frag_uv).x;
    // do tonemappings
    //opaque = linear_tone_mapping(color.rgb, 1.8);  // linear color output
    fragment_color.rgb = color.rgb;

#ifdef FILTER_IN_SHADER
    // we store fxaa = true/false in highbit of the object id
    if (unpack_bool(id)) {
        fragment_color.a = dot(color.rgb, vec3(0.299, 0.587, 0.114)); // compute luma
    } else {
        // we disable fxaa by setting luma to 1
        fragment_color.a = 1.0;
    }
#else
    fragment_color.a = dot(color.rgb, vec3(0.299, 0.587, 0.114)); // compute luma
#endif
}
