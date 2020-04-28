{{GLSL_VERSION}}

uniform sampler2D position_buffer;
uniform sampler2D normal_buffer;
uniform sampler2D color_buffer;
uniform vec3 kernel[64];
uniform sampler2D noise;
uniform vec2 noise_scale;
uniform mat4 projection;

in vec2 frag_uv;
out vec4 fragment_color;

// bias/epsilon for depth check
const float bias = 0.025;
// max range for depth check
const float radius = 0.5;

void main(void)
{
    vec3 frag_pos = texture(position_buffer, frag_uv).xyz;
    vec3 normal  = texture(normal_buffer, frag_uv).xyz;
    vec3 rand_vec = vec3(texture(noise, frag_uv * noise_scale).xy, 0.0);

    vec3 tangent = normalize(rand_vec - normal * dot(rand_vec, normal));
    vec3 bitangent = cross(normal, tangent);
    mat3 TBN = mat3(tangent, bitangent, normal);

    float occlusion = 0.0;
    for (int i = 0; i < 64; ++i) {// TODO mustache?
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
    occlusion = 1.0 - (occlusion / 64); // TODO mustache
    fragment_color = vec4(vec3(occlusion), 1.0);

    // Testing
    // fragment_color = vec4(0.9, 0.6, 0.2, 1.0);
    // fragment_color = vec4(texture(position_buffer, frag_uv).xyz, 1.0);

}

// TODO blur
