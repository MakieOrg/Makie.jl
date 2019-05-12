
function get_distancefield_scale(distancefield, g_uv_texture_bbox)
    # Glyph distance field units are in pixels; convert to dimensionless
    # x-coordinate of texture instead for consistency with programmatic uv
    # distance fields in fragment shader. See also comments below.
    pixsize_x = (g_uv_texture_bbox[0].z - g_uv_texture_bbox[0].x) *
                      size(distancefield, 1);
    return -1.0/pixsize_x;
end

function get_distancefield_scale(::Nothing)
    return 1.0;
end


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

function emit_sprites(position, markersize, rotation, scale_primitive, model, billboard)
    # Half width of antialiasing smoothstep. NB: Should match fragment shader
    const ANTIALIAS_RADIUS  0.8
    # emit quad as triangle strip
    # v3. ____ . v4
    #    |\   |
    #    | \  |
    #    |  \ |
    #    |___\|
    # v1*      * v2
    # Centred bounding box of billboard
    o_w = (position, markersize)
    bbox_signed_radius = 0.5 .* markersize # note; components may be negative.
    sprite_bbox_centre = position .+ bbox_signed_radius
    pview = projection * view
    # Compute transform for the offset vectors from the central point
    trans = scale_primitive ? model : Mat4f0(I)
    trans = (billboard ? projection : pview * qmat(g_rotation[0])) * trans;

    # Compute centre of billboard in clipping coordinates
    vclip = pview * model * Vec4f0(vertex, 1) + trans * Vec4f0(sprite_bbox_centre..., 0, 0);

    # Extra buffering is required around sprites which are antialiased so that
    # the antialias blur doesn't get cut off (see #15). This blur falls to
    # zero at a radius of ANTIALIAS_RADIUS pixels in the viewport coordinates
    # and we want to buffer the vertices in the *source* sprite coordinate
    # system so that we get this amount in the output coordinates.
    #
    # Here we calculate the derivative of the mapping from sprite xy
    # coordinates (defined by `trans`) into the viewport pixel coordinates.
    # The derivative needs to include the proper term for the perspective
    # divide into NDC, evaluated at the centre point `vclip`.
    d_ndc_d_clip = Mat4f0(
        1.0/vclip.w, 0.0,         0.0,         0.0,
        0.0,         1.0/vclip.w, 0.0,         0.0,
        0.0,         0.0,         1.0/vclip.w, 0.0,
        -vclip.xyz/(vclip.w*vclip.w),          0.0
    )
    dxyv_dxys = diagm(0.5 .* resolution) * Mat2f0(d_ndc_d_clip * trans)
    # Now, our buffer size is expressed in viewport pixels but we get back to
    # the sprite coordinate system using the scale factor of the
    # transformation (for isotropic transformations). For anisotropic
    # transformations, the geometric mean of the two principle scale factors
    # is a reasonable compromise:
    viewport_from_sprite_scale = sqrt(abs(determinant(dxyv_dxys)));

    # In the fragment shader we want our signed distance in viewport (pixel)
    # coords for direct use in antialiasing step functions. We therefore need
    # a scaling factor similar to viewport_from_sprite_scale, but including
    # the uv->sprite coordinate system scaling factor as well.  We choose to
    # use the bounding box *x* width for this. This comes with some
    # consistency conditions:
    # * For procedural distance fields, we need the sprite bounding box to be
    #   square. (If not, the uv coordinates will be anisotropically scaled and
    #   any calculation based on them will not be a distance function.)
    # * For sampled distance fields, we need to consistently choose the *x*
    #   for the scaling in get_distancefield_scale().
    sprite_from_u_scale = abs(markersize[1])
    f_viewport_from_u_scale = viewport_from_sprite_scale * sprite_from_u_scale;
    f_distancefield_scale = get_distancefield_scale(distancefield);

    # Compute required amount of buffering
    sprite_from_viewport_scale = 1.0 / viewport_from_sprite_scale

    # Hack!! antialiasing is disabled for RECTANGLE==1 for now
    # because it's used for boxplots where the sprites are
    # long and skinny (violating assumption 1 above)
    bbox_buf = sprite_from_viewport_scale * (
        (shape == 1 ? 0.0 : ANTIALIAS_RADIUS) +
        max(glow_width, 0) + max(stroke_width, 0)
    )
    # Compute xy bounding box of billboard (in model space units) after
    # buffering and associated bounding box of uv coordinates.
    bbox_radius_buf = bbox_signed_radius + sign(bbox_signed_radius) * bbox_buf
    bbox = Vec4f0(-bbox_radius_buf..., bbox_radius_buf...);
    # uv bounding box is the buffered version of the domain [0,1]x[0,1]
    uv_radius = 0.5 * bbox_radius_buf / bbox_signed_radius;
    uv_center = Vec2f0(0.5)
    #minx, miny, maxx, maxy
    uv_bbox = Vec4f0((uv_center-uv_radius)..., (uv_center+uv_radius)...)

    emit_vertex(vclip + trans*vec4(bbox.xy,0,0), uv_bbox.xw);
    emit_vertex(vclip + trans*vec4(bbox.xw,0,0), uv_bbox.xy);
    emit_vertex(vclip + trans*vec4(bbox.zy,0,0), uv_bbox.zw);
    emit_vertex(vclip + trans*vec4(bbox.zw,0,0), uv_bbox.zy);
end
