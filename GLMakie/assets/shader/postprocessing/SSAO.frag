{{GLSL_VERSION}}

// SSAO
uniform sampler2D position_buffer;
uniform sampler2D normal_buffer;
uniform sampler2D noise;
uniform vec3 kernel[{{N_samples}}];
uniform vec2 noise_scale;
uniform mat4 projection;
uniform vec4 scene_viewport;

// bias/epsilon for depth check
uniform float bias;
// max range for depth check
uniform float radius;


in vec2 frag_uv;
out float o_occlusion;


void main(void)
{
    vec3 view_pos = texture(position_buffer, frag_uv).xyz;
    vec3 normal  = texture(normal_buffer, frag_uv).xyz;

    // Pixels without geometry have a zero normal.
    if (normal != vec3(0)) {
        vec3 rand_vec = vec3(texture(noise, frag_uv * noise_scale).xy, 0.0);
        vec3 tangent = normalize(rand_vec - normal * dot(rand_vec, normal));
        vec3 bitangent = cross(normal, tangent);
        mat3 TBN = mat3(tangent, bitangent, normal);

        vec4 view_clip = projection * vec4(view_pos, 1.0);
        float occlusion = 0.0;
        for (int i = 0; i < {{N_samples}}; ++i) {
            // random offset in view space
            vec3 sample_view_offset = TBN * kernel[i] * radius;

            vec4 sample_clip = projection * vec4(view_pos + sample_view_offset, 1.0);
            vec2 offset = sample_clip.xy / sample_clip.w - view_clip.xy / view_clip.w;
            vec2 sample_uv = frag_uv + 0.5 * offset * scene_viewport.zw;
            if (any(lessThan(sample_uv, scene_viewport.xy)) ||
                any(greaterThanEqual(sample_uv, scene_viewport.xy + scene_viewport.zw))) continue;
            if (texture(normal_buffer, sample_uv).xyz == vec3(0)) continue;

            float sample_depth = texture(position_buffer, sample_uv).z;
            float range_check = smoothstep(0.0, 1.0, radius / abs(view_pos.z - sample_depth));
            occlusion += (sample_depth >= sample_view_offset.z + view_pos.z + bias ? 1.0 : 0.0) * range_check;
        }
        o_occlusion = occlusion / {{N_samples}};
    } else {
        o_occlusion = 0.0;
    }
}
