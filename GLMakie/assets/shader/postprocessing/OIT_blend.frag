{{GLSL_VERSION}}

// Based on https://jcgt.org/published/0002/02/09/
// See https://github.com/JuliaPlots/Makie.jl/issues/1390

in vec2 frag_uv;

// contains sum_i C_i * weight(depth_i, alpha_i)
uniform sampler2D sum_color;
// contains pod_i (1 - alpha_i)
uniform sampler2D prod_alpha;

out vec4 fragment_color;

void main(void)
{
    vec4 summed_color_weight = texture(sum_color, frag_uv);
    float transmittance = texture(prod_alpha, frag_uv).r;

    vec3 weighted_transparent = summed_color_weight.rgb / max(summed_color_weight.a, 0.00001);
    vec3 full_weighted_transparent = weighted_transparent * (1 - transmittance);

    fragment_color.rgb = full_weighted_transparent;
    fragment_color.a = transmittance;
}
