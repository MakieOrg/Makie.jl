{{GLSL_VERSION}}

// SSAO
uniform sampler2D position_buffer;
uniform sampler2D normal_occlusion_buffer;
uniform sampler2D noise;
uniform vec3 kernel[{{N_samples}}];
uniform vec2 noise_scale;
uniform mat4 projection;

// bias/epsilon for depth check
uniform float bias;
// max range for depth check
uniform float radius;


in vec2 frag_uv;
// occlusion.xyz is a normal vector, occlusion.w the occlusion value
out vec4 o_normal_occlusion;


void main(void)
{
    vec3 view_pos = texture(position_buffer, frag_uv).xyz;
    vec3 normal  = texture(normal_occlusion_buffer, frag_uv).xyz;

    // The normal buffer gets cleared every frame. (also position, color etc)
    // If normal == vec3(1) then there is no geometry at this fragment.
    // Therefore skip SSAO calculation
    if (normal != vec3(1)) {
        vec3 rand_vec = vec3(texture(noise, frag_uv * noise_scale).xy, 0.0);
        vec3 tangent = normalize(rand_vec - normal * dot(rand_vec, normal));
        vec3 bitangent = cross(normal, tangent);
        mat3 TBN = mat3(tangent, bitangent, normal);

        float occlusion = 0.0;
        for (int i = 0; i < {{N_samples}}; ++i) {
            // random offset in view space
            vec3 sample_view_offset = TBN * kernel[i] * radius;

            /*
                We want to get the uv (screen) coordinate of position + offset in
                view space. Usually this would be:
                clip_coordinate = projection * view_coordinate
                clip_coordinate /= clip_coordinate.w
                screen_coordinate = 0.5 * clip_coordinate + 0.5

                But Makie allows multiple scenes, which each have their own
                coordinate system. This means it is possible that multiple
                regions of the screen (different scenes) refer to the same view
                position. To differentiate between them we must calculate the
                screen space coordinate using frag_uv and an offset derived from
                the view space offset.

                Instead of

                clip_coord = projection * (view_pos + view_offset)
                clip_coord /= clip_coord.w
                screen_coordinate = 0.5 * clip_coord + 0.5

                we essentially calculate

                clip_offset = projection * view_offset
                clip_offset /= (projection * (view_pos + view_offset)).w
                clip_position = frag_uv - 0.5
                clip_position *= (projection * view_pos).w
                clip_position /= (projection * (view_pos + view_offset)).w
                screen_coordinate = clip_position + 0.5 * clip_offset+ 0.5
            */

            vec4 sample_frag_pos = vec4(
                (projection * vec4(sample_view_offset, 1.0)).xyz,
                (projection * vec4(view_pos + sample_view_offset, 1.0)).w
            );
            float sample_clip_pos_w = sample_frag_pos.w;
            float clip_pos_w = (projection * vec4(view_pos, 1.0)).w;
            sample_frag_pos.xyz /= sample_frag_pos.w;
            sample_frag_pos.xyz = sample_frag_pos.xyz * 0.5 + 0.5;
            sample_frag_pos.xy += (frag_uv - 0.5) * clip_pos_w / sample_clip_pos_w;


            float sample_depth = texture(position_buffer, sample_frag_pos.xy).z;
            float range_check = smoothstep(0.0, 1.0, radius / abs(view_pos.z - sample_depth));
            occlusion += (sample_depth >= sample_view_offset.z + view_pos.z + bias ? 1.0 : 0.0) * range_check;
        }
        o_normal_occlusion.w = occlusion / {{N_samples}};
    } else {
        o_normal_occlusion.w = 0.0;
    }
}
