{{GLSL_VERSION}}

{{SHADERTOY_INPUTS}}
{{TOY_SHADER}}

in vec2 f_uv;
layout (location = 0) out vec4 fragment_color;
layout (location = 1) out uvec2 fragment_groupid;

void main()
{
	vec4 color = mainImage(f_uv * iResolution.xy);
	if (color.a <= 0.0) discard;
	fragment_color = vec4(1, 0, 0, 1) * 0.5;
}
