{{GLSL_VERSION}}
{{GLSL_EXTENSIONS}}

layout(points) in;
layout(triangle_strip, max_vertices = 4) out;

vec3 qmul(vec4 quat, vec3 vec){
    float num = quat.x * 2.0;
    float num2 = quat.y * 2.0;
    float num3 = quat.z * 2.0;
    float num4 = quat.x * num;
    float num5 = quat.y * num2;
    float num6 = quat.z * num3;
    float num7 = quat.x * num2;
    float num8 = quat.x * num3;
    float num9 = quat.y * num3;
    float num10 = quat.w * num;
    float num11 = quat.w * num2;
    float num12 = quat.w * num3;
    return vec3(
        (1.0 - (num5 + num6)) * vec.x + (num7 - num12) * vec.y + (num8 + num11) * vec.z,
        (num7 + num12) * vec.x + (1.0 - (num4 + num6)) * vec.y + (num9 - num10) * vec.z,
        (num8 - num11) * vec.x + (num9 + num10) * vec.y + (1.0 - (num4 + num5)) * vec.z
    );
}

uniform bool scale_primitive;
uniform bool billboard;
uniform float stroke_width;
uniform float glow_width;
uniform vec2 resolution;

in int  g_primitive_index[];
in vec4 g_uv_offset_width[];
in vec4 g_color[];
in vec4 g_stroke_color[];
in vec4 g_glow_color[];
in vec3 g_position[];
in vec4 g_rotation[];
in vec4 g_offset_width[];
in uvec2 g_id[];

flat out int  f_primitive_index;
flat out vec2 f_scale;
flat out vec4 f_color;
flat out vec4 f_bg_color;
flat out vec4 f_stroke_color;
flat out vec4 f_glow_color;
flat out uvec2 f_id;
out vec2 f_uv;
out vec2 f_uv_offset;


uniform mat4 projection, view, model;



void emit_vertex(vec2 vertex, vec2 uv, vec2 uv_offset)
{
    vec4 sprite_position, final_position;
    mat4 mview = projection * view;
    vec4 datapoint = mview * model * vec4(g_position[0], 1);
    if(scale_primitive)
        final_position = model * vec4(vertex, 0, 0);
    else{
        final_position = vec4(vertex, 0, 0);
    }
    if(billboard){
        final_position = projection * final_position;
    }else{
        final_position = mview * vec4(
            qmul(g_rotation[0], final_position.xyz), 0
        );
    }
    gl_Position = datapoint + final_position;

    f_uv              = uv;
    f_uv_offset       = uv_offset;
    f_primitive_index = g_primitive_index[0];
    f_color           = g_color[0];
    f_bg_color        = vec4(g_color[0].rgb, 0);
    f_stroke_color    = g_stroke_color[0];
    f_glow_color      = g_glow_color[0];
    f_id              = g_id[0];

    EmitVertex();
}


void main(void)
{
    // emit quad as triangle strip
    // v3. ____ . v4
    //    |\   |
    //    | \  |
    //    |  \ |
    //    |___\|
    // v1*      * v2
    vec4 o_w = g_offset_width[0];
    vec4 uv_o_w = g_uv_offset_width[0];
    float glow_stroke = max(glow_width, 0) + max(stroke_width, 0); //we don't need negativity here
    vec2 final_scale = o_w.zw + 2*glow_stroke;
    vec2 scale_rel = (final_scale / o_w.zw);
    float hfs = glow_stroke;
    vec4 uv_min_max = vec4(-scale_rel, scale_rel); //minx, miny, maxx, maxy
    vec4 vertices = vec4(-hfs + o_w.xy, (o_w.zw) + o_w.xy + glow_stroke); // use offset as origin quad (x,y,w,h)
    f_scale = vec2(stroke_width, glow_width)/o_w.zw;
    emit_vertex(vertices.xy, uv_min_max.xw, uv_o_w.xw);
    emit_vertex(vertices.xw, uv_min_max.xy, uv_o_w.xy);
    emit_vertex(vertices.zy, uv_min_max.zw, uv_o_w.zw);
    emit_vertex(vertices.zw, uv_min_max.zy, uv_o_w.zy);
    EndPrimitive();
}
