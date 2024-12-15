{{GLSL_VERSION}}

{{SHADERTOY_INPUTS}}
{{TOY_SHADER}}

in vec2 f_uv;

uniform uint objectid;

void write2framebuffer(vec4 color, uvec2 id);

void main()
{
    vec4 color = mainImage(f_uv * iResolution.xy);
    write2framebuffer(color, uvec2(objectid, 0));
}
