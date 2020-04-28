{{GLSL_VERSION}}

// SSAO + prepare luma for FXAA

in vec2 frag_uv;


// SSAO
uniform sampler2D position_buffer;
uniform sampler2D normal_buffer;
uniform vec3 kernel[{{N_samples}}];
uniform sampler2D noise;
uniform vec2 noise_scale;
uniform mat4 projection;

// bias/epsilon for depth check
uniform float bias;
// max range for depth check
uniform float radius;

layout(location=1) out float o_occlusion;
// out float FragColor;


// luma
uniform sampler2D color_buffer;

layout(location=0) out vec4 o_color_luma;

vec3 linear_tone_mapping(vec3 color, float gamma)
{
    color = clamp(color, 0., 1.);
    color = pow(color, vec3(1. / gamma));
    return color;
}


// both
void main(void)
{
    // SSAO
    vec3 frag_pos = texture(position_buffer, frag_uv).xyz;
    vec3 normal  = texture(normal_buffer, frag_uv).xyz;
    vec3 rand_vec = vec3(texture(noise, frag_uv * noise_scale).xy, 0.0);

    vec3 tangent = normalize(rand_vec - normal * dot(rand_vec, normal));
    vec3 bitangent = cross(normal, tangent);
    mat3 TBN = mat3(tangent, bitangent, normal);

    float occlusion = 0.0;
    for (int i = 0; i < {{N_samples}}; ++i) {
        vec3 sample = TBN * kernel[i];
        sample = frag_pos + sample * radius;

        // view to screen space
        vec4 offset = vec4(sample, 1.0);
        offset = projection * offset;
        offset.xyz /= offset.w;
        offset.xyz = offset.xyz * 0.5 + 0.5;

        float sample_depth = texture(position_buffer, offset.xy).z;
        float range_check = smoothstep(0.0, 1.0, radius / abs(frag_pos.z - sample_depth));
        occlusion += (sample_depth >= sample.z + bias ? 1.0 : 0.0) * range_check;
    }
    occlusion = 1.0 - (occlusion / {{N_samples}});
    o_occlusion = occlusion;

    // luma
    vec4 color = texture(color_buffer, frag_uv).rgba;
    if(color.a <= 0) discard; // TODO is this necessary?
    // do tonemapping
    //opaque = linear_tone_mapping(color.rgb, 1.8);  // linear color output
    o_color_luma.rgb = color.rgb;
    // save luma in alpha for FXAA
    o_color_luma.a = dot(color.rgb, vec3(0.299, 0.587, 0.114)); // compute luma
}
