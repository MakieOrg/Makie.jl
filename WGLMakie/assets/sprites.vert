uniform mat4 projection;
uniform mat4 view;

uniform float atlas_tex_dim;

out vec4 frag_color;
out vec2 frag_uv;
out float frag_uvscale;
out float frag_distancefield_scale;
out vec4 frag_uv_offset_width;

flat out uint frag_instance_id;

#define ANTIALIAS_RADIUS 0.8


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

float distancefield_scale(){
    // Glyph distance field units are in pixels; convert to dimensionless
    // x-coordinate of texture instead for consistency with programmatic uv
    // distance fields in fragment shader. See also comments below.
    vec4 uv_rect = get_uv_offset_width();
    float pixsize_x = (uv_rect.z - uv_rect.x) * get_atlas_texture_size();
    return -1.0/pixsize_x;
}

vec3 tovec3(vec2 v){return vec3(v, 0.0);}
vec3 tovec3(vec3 v){return v;}

vec4 tovec4(vec3 v){return vec4(v, 1.0);}
vec4 tovec4(vec4 v){return v;}

mat2 diagm(vec2 v){
    return mat2(v.x, 0.0, 0.0, v.y);
}

float _determinant(mat2 m) {
  return m[0][0] * m[1][1] - m[0][1] * m[1][0];
}

void main(){
    // get_pos() returns the position of the scatter marker
    // get_position() returns the (relative) position of the current quad vertex

    vec2 bbox_radius = 0.5 * get_markersize();
    vec2 sprite_bbox_centre = get_quad_offset() + bbox_radius;

    mat4 pview = projection * view;
    mat4 trans = get_transform_marker() ? model : mat4(1.0);

    // Compute centre of billboard in clipping coordinates
    // Always transform text/scatter position argument
    vec4 data_point = get_preprojection() * model * vec4(tovec3(get_pos()), 1);
    // maybe transform marker_offset + glyph offsets
    data_point = vec4(data_point.xyz / data_point.w + mat3(trans) * tovec3(get_marker_offset()), 1);
    data_point = pview * data_point;

    // Compute transform for the offset vectors from the central point
    trans = (get_billboard() ? projection : pview) * qmat(get_rotation()) * trans;
    vec4 sprite_center = trans * vec4(sprite_bbox_centre, 0, 0);

    vec4 vclip = data_point + sprite_center;

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
    mat4 d_ndc_d_clip = mat4(
        1.0/vclip.w, 0.0,         0.0,         0.0,
        0.0,         1.0/vclip.w, 0.0,         0.0,
        0.0,         0.0,         1.0/vclip.w, 0.0,
        -vclip.xyz/(vclip.w*vclip.w),          0.0
    );
    mat2 dxyv_dxys = diagm(0.5 * px_per_unit * get_resolution()) * mat2(d_ndc_d_clip*trans);
    // Now, our buffer size is expressed in viewport pixels but we get back to
    // the sprite coordinate system using the scale factor of the
    // transformation (for isotropic transformations). For anisotropic
    // transformations, the geometric mean of the two principle scale factors
    // is a reasonable compromise:
    float viewport_from_sprite_scale = sqrt(abs(_determinant(dxyv_dxys)));

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
    float sprite_from_u_scale = min(abs(get_markersize().x), abs(get_markersize().y));
    frag_uvscale = viewport_from_sprite_scale * sprite_from_u_scale;
    frag_distancefield_scale = distancefield_scale();

    // add padding for AA, stroke and glow (non native distancefields don't need
    // AA padding but CIRCLE etc do)
    float ppu = get_px_per_unit();
    vec2 padded_bbox_size = bbox_radius + (
        ANTIALIAS_RADIUS + max(0.0, get_strokewidth() * ppu) + max(0.0, get_glowwidth() * ppu)
    ) / viewport_from_sprite_scale;
    vec2 uv_pad_scale = padded_bbox_size / bbox_radius;

    frag_color = tovec4(get_color());
    frag_uv_offset_width = get_uv_offset_width();
    // get_uv() returns (0, 0), (1, 0), (0, 1) or (1, 1)
    // to accomodate stroke and glowwidth we need to extrude uv's outwards from (0.5, 0.5)
    frag_uv = vec2(0.5) + (get_uv() - vec2(0.5)) * uv_pad_scale;

    // screen space coordinates of the position
    vec4 quad_vertex = (trans * vec4(2.0 * padded_bbox_size * get_position(), 0.0, 0.0));
    gl_Position = vclip + quad_vertex;
    gl_Position.z += gl_Position.w * get_depth_shift();

    frag_instance_id = uint(gl_InstanceID);
}
