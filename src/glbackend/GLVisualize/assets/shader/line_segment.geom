{{GLSL_VERSION}}
{{GLSL_EXTENSIONS}}

layout(lines) in;
layout(triangle_strip, max_vertices = 4) out;

uniform vec2 resolution;
uniform float maxlength;
uniform float thickness;
uniform float pattern_length;

in vec4 g_color[];
in uvec2 g_id[];
in float g_thickness[];

out float f_thickness;
out vec4 f_color;
out vec2 f_uv;
flat out uvec2 f_id;

#define AA_THICKNESS 2.0

vec2 screen_space(vec4 vertex)
{
    return vec2(vertex.xy / vertex.w)*resolution;
}
void emit_vertex(vec2 position, vec2 uv, int index)
{
    vec4 inpos    = gl_in[index].gl_Position;
    f_uv          = uv;
    f_color       = g_color[index];
    gl_Position   = vec4((position / resolution) * inpos.w, inpos.z, inpos.w);
    f_id          = g_id[index];
    f_thickness   = g_thickness[index]+AA_THICKNESS;
    EmitVertex();
}

uniform int max_primtives;

void main(void)
{
    // get the four vertices passed to the shader:
    vec2 p0 = screen_space(gl_in[0].gl_Position); // start of previous segment
    vec2 p1 = screen_space(gl_in[1].gl_Position); // end of previous segment, start of current segment

    float thickness_aa0 = g_thickness[0]+AA_THICKNESS;
    float thickness_aa1 = g_thickness[1]+AA_THICKNESS;
    // determine the direction of each of the 3 segments (previous, current, next)
    vec2 vun0 = p1 - p0;
    vec2 v0 = normalize(vun0);
    // determine the normal of each of the 3 segments (previous, current, next)
    vec2 n0 = vec2(-v0.y, v0.x);
    float l = length(p1-p0);
    l /= (pattern_length*10);

    float uv0 = thickness_aa0/g_thickness[0];
    float uv1 = thickness_aa1/g_thickness[1];
    emit_vertex(p0 + thickness_aa0 * n0, vec2(0, -uv0), 0);
    emit_vertex(p0 - thickness_aa0 * n0, vec2(0, uv0), 0);
    emit_vertex(p1 + thickness_aa1 * n0, vec2(l, -uv1), 1);
    emit_vertex(p1 - thickness_aa1 * n0, vec2(l, uv1), 1);
}
