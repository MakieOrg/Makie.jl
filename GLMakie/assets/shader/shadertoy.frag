{{GLSL_VERSION}}

out vec4 fragment_color;

{{SHADERTOY_INPUTS}}
{{TOY_SHADER}}

in vec2 f_uv;

void main()
{
	mainImage(fragment_color, f_uv * iResolution.xy);
}
