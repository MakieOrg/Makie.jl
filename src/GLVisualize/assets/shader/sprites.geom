{{GLSL_VERSION}}
{{GLSL_EXTENSIONS}}

layout(points) in;
layout(triangle_strip, max_vertices = 4) out;

mat4 qmat(vec4 quat){
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
    return mat4(
        (1.0 - (num5 + num6)), (num7 + num12),        (num8 - num11),        0.0,
        (num7 - num12),        (1.0 - (num4 + num6)), (num9 + num10),        0.0,
        (num8 + num11),        (num9 - num10),        (1.0 - (num4 + num5)), 0.0,
        0.0,                   0.0,                   0.0,                   1.0
    );
}

uniform bool scale_primitive;
uniform bool billboard;
uniform float stroke_width;
uniform float glow_width;
uniform vec2 resolution;

in int  g_primitive_index[];
in vec4 g_uv_texture_bbox[];
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
out vec2 f_uv; // f_uv.{x,y} are in -1..1
flat out vec4 f_uv_texture_bbox;


uniform mat4 projection, view, model;



void emit_vertex(vec4 vertex, vec2 uv)
{
    gl_Position       = vertex;
    f_uv              = uv;
    f_uv_texture_bbox = g_uv_texture_bbox[0];
    f_primitive_index = g_primitive_index[0];
    f_color           = g_color[0];
    f_bg_color        = vec4(g_color[0].rgb, 0);
    f_stroke_color    = g_stroke_color[0];
    f_glow_color      = g_glow_color[0];
    f_id              = g_id[0];
    EmitVertex();
}

// Half width of antialiasing smoothstep. NB: Should match fragment shader
#define ANTIALIAS_RADIUS  0.8

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

    // Transform central point into scene
    mat4 pview = projection * view;
    vec4 datapoint = pview * model * vec4(g_position[0], 1);

    // Compute transform for the offset vectors from the central `datapoint`
    mat4 trans = scale_primitive ? model : mat4(1.0);
    trans = (billboard ? projection : pview * qmat(g_rotation[0])) * trans;

    // Extra buffering is required around sprites which are antialiased so that
    // the antialias blur doesn't get cut off (see #15). This blur falls to
    // zero at a radius of ANTIALIAS_RADIUS pixels in the viewport coordinates
    // and we want to buffer the vertices in the *source* sprite coordinate
    // system so that we get this amount in the output coordinates.
    //
    // However this is quite tricky for arbitrary sprite rotations.  For now we
    // just do something which is a cheap-ish and works for non-rotated sprites.
    // For rotated sprites at glancing angles it's an underestimate, but sdf
    // based antialiasing can't work perfectly there anyway.
    //
    // The following transform is the model->view->proj->clip->ndc->viewport
    // forward transformation for vectors.
    vec2 aa_viewport_x = 0.5*resolution*(trans*vec4(1,0,0,0)).xy / datapoint.w;
    vec2 aa_viewport_y = 0.5*resolution*(trans*vec4(0,1,0,0)).xy / datapoint.w;
    float aa_buf = ANTIALIAS_RADIUS/max(length(aa_viewport_x), length(aa_viewport_y));

    float bbox_buf = aa_buf + max(glow_width, 0) + max(stroke_width, 0);
    // Bounding box of billboard
    vec4 bbox = vec4(-bbox_buf + o_w.xy,
                     o_w.xy + o_w.zw + bbox_buf);
    vec2 scale_rel = (bbox.zw - bbox.xy) / o_w.zw;
    vec4 uv_min_max = vec4(-scale_rel, scale_rel); //minx, miny, maxx, maxy
    f_scale = vec2(stroke_width, glow_width)/o_w.zw;

    emit_vertex(datapoint + trans*vec4(bbox.xy,0,0), uv_min_max.xw);
    emit_vertex(datapoint + trans*vec4(bbox.xw,0,0), uv_min_max.xy);
    emit_vertex(datapoint + trans*vec4(bbox.zy,0,0), uv_min_max.zw);
    emit_vertex(datapoint + trans*vec4(bbox.zw,0,0), uv_min_max.zy);
    EndPrimitive();
}
