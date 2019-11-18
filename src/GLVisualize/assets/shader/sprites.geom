{{GLSL_VERSION}}
{{GLSL_EXTENSIONS}}

struct Nothing{ bool _; };

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

{{distancefield_type}}  distancefield;

uniform bool scale_primitive;
uniform bool billboard;
uniform float stroke_width;
uniform float glow_width;
uniform int shape; // for RECTANGLE hack below
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
flat out float f_viewport_from_u_scale;
flat out float f_distancefield_scale;
flat out vec4 f_color;
flat out vec4 f_bg_color;
flat out vec4 f_stroke_color;
flat out vec4 f_glow_color;
flat out uvec2 f_id;
out vec2 f_uv;
flat out vec4 f_uv_texture_bbox;


uniform mat4 projection, view, model, pixel_projection;

float get_distancefield_scale(sampler2D distancefield){
    // Glyph distance field units are in pixels; convert to dimensionless
    // x-coordinate of texture instead for consistency with programmatic uv
    // distance fields in fragment shader. See also comments below.
    float pixsize_x = (g_uv_texture_bbox[0].z - g_uv_texture_bbox[0].x) *
                      textureSize(distancefield, 0).x;
    return -1.0/pixsize_x;
}
float get_distancefield_scale(Nothing distancefield){
    return 1.0;
}

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

mat2 diagm(vec2 v){
    return mat2(v.x, 0.0, 0.0, v.y);
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
    // Centred bounding box of billboard
    vec4 o_w = g_offset_width[0];
    vec2 bbox_signed_radius = 0.5*o_w.zw; // note; components may be negative.
    vec2 sprite_bbox_centre = o_w.xy + bbox_signed_radius;

    mat4 pview = projection * view;
    // Compute transform for the offset vectors from the central point
    mat4 trans = scale_primitive ? model : mat4(1.0);
    trans = (billboard ? pixel_projection : pview * qmat(g_rotation[0])) * trans;

    // Compute centre of billboard in clipping coordinates
    vec4 vclip = pview*model*vec4(g_position[0],1) + trans*vec4(sprite_bbox_centre,0,0);

    // Extra buffering is required around sprites which are antialiased so that
    // the antialias blur doesn't get cut off (see #15). This blur falls to
    // zero at a radius of ANTIALIAS_RADIUS pixels in the viewport coordinates
    // and we want to buffer the vertices in the *source* sprite coordinate
    // system so that we get this amount in the output coordinates.
    //
    // Here we calculate the derivative of the mapping from sprite xy
    // coordinates (defined by `trans`) into the viewport pixel coordinates.
    // The derivative needs to include the proper term for the perspective
    // divide into NDC, evaluated at the centre point `vclip`.
    mat4 d_ndc_d_clip = mat4(1.0/vclip.w, 0.0,         0.0,         0.0,
                             0.0,         1.0/vclip.w, 0.0,         0.0,
                             0.0,         0.0,         1.0/vclip.w, 0.0,
                             -vclip.xyz/(vclip.w*vclip.w),          0.0);
    mat2 dxyv_dxys = diagm(0.5*resolution) * mat2(d_ndc_d_clip*trans);
    // Now, our buffer size is expressed in viewport pixels but we get back to
    // the sprite coordinate system using the scale factor of the
    // transformation (for isotropic transformations). For anisotropic
    // transformations, the geometric mean of the two principle scale factors
    // is a reasonable compromise:
    float viewport_from_sprite_scale = sqrt(abs(determinant(dxyv_dxys)));

    // In the fragment shader we want our signed distance in viewport (pixel)
    // coords for direct use in antialiasing step functions. We therefore need
    // a scaling factor similar to viewport_from_sprite_scale, but including
    // the uv->sprite coordinate system scaling factor as well.  We choose to
    // use the bounding box *x* width for this. This comes with some
    // consistency conditions:
    // * For procedural distance fields, we need the sprite bounding box to be
    //   square. (If not, the uv coordinates will be anisotropically scaled and
    //   any calculation based on them will not be a distance function.)
    // * For sampled distance fields, we need to consistently choose the *x*
    //   for the scaling in get_distancefield_scale().
    float sprite_from_u_scale = abs(o_w.z);
    f_viewport_from_u_scale = viewport_from_sprite_scale * sprite_from_u_scale;
    f_distancefield_scale = get_distancefield_scale(distancefield);

    // Compute required amount of buffering
    float sprite_from_viewport_scale = 1.0 / viewport_from_sprite_scale;
    float bbox_buf = sprite_from_viewport_scale *
                     (// Hack!! antialiasing is disabled for RECTANGLE==1 for now
                      // because it's used for boxplots where the sprites are
                      // long and skinny (violating assumption 1 above)
                      (shape == 1 ? 0.0 : ANTIALIAS_RADIUS) +
                      max(glow_width, 0) + max(stroke_width, 0));
    // Compute xy bounding box of billboard (in model space units) after
    // buffering and associated bounding box of uv coordinates.
    vec2 bbox_radius_buf = bbox_signed_radius + sign(bbox_signed_radius)*bbox_buf;
    vec4 bbox = vec4(-bbox_radius_buf, bbox_radius_buf);
    // uv bounding box is the buffered version of the domain [0,1]x[0,1]
    vec2 uv_radius = 0.5 * bbox_radius_buf / bbox_signed_radius;
    vec2 uv_center = vec2(0.5);
    vec4 uv_bbox = vec4(uv_center-uv_radius, uv_center+uv_radius); //minx, miny, maxx, maxy

    emit_vertex(vclip + trans*vec4(bbox.xy,0,0), uv_bbox.xw);
    emit_vertex(vclip + trans*vec4(bbox.xw,0,0), uv_bbox.xy);
    emit_vertex(vclip + trans*vec4(bbox.zy,0,0), uv_bbox.zw);
    emit_vertex(vclip + trans*vec4(bbox.zw,0,0), uv_bbox.zy);

    EndPrimitive();
}
