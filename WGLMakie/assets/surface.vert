struct Grid2D{
    ivec2 lendiv;
    vec2 start;
    vec2 stop;
    ivec2 dims;
};

attribute vec2 position;
uniform sampler2D position_z;

uniform mat4 view, model, projection;

uniform bool wireframe;
uniform uint objectid;
uniform float stroke_width;
flat out uvec2 o_id;
out vec4 o_color;
out vec2 o_uv;

flat out vec2            f_scale;
flat out vec4            f_color;
flat out vec4            f_bg_color;
flat out vec4            f_stroke_color;
flat out vec4            f_glow_color;
flat out int             f_primitive_index;
flat out uvec2           f_id;

out vec2                 f_uv;
out vec2                 f_uv_offset;

void main()
{
    int index = gl_InstanceID;
    vec2 offset = vertices;
    ivec2 offseti = ivec2(offset);
    ivec2 dims = textureSize(position_z, 0);
    vec2 final_scale = ((scale.xy)/(scale.xy-stroke_width));

    const float uv_w = 0.9;

    vec3 pos;
    {{position_calc}}
    o_color = get_color(color, pos.z, color_map, color_norm, index);
    o_uv = index01;
    vec3 normalvec = {{normal_calc}};
    render(model * vec4(pos, 1), (model * vec4(normalvec, 0)).xyz, view, projection, light);
}
