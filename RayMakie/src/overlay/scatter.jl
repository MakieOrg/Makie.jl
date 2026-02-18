# ============================================================================
# Unified Sprite Rasterization (Scatter + Text)
# ============================================================================
# Two-stage pipeline matching GLMakie's sprites.vert → sprites.geom → distance_shape.frag.
# Stage 1 (prep): per-sprite, projects position, computes screen-space data.
# Stage 2 (pixel): per-pixel, iterates sprites, evaluates SDF, alpha blends.

using LinearAlgebra: norm, dot, det

# ============================================================================
# Quaternion to 4x4 rotation matrix: qmat() from sprites.geom
# ============================================================================

@inline function quat_to_mat4(q::Vec4f)
    # Matches GLMakie's sprites.geom qmat() exactly (column-major)
    num  = q[1] * 2f0
    num2 = q[2] * 2f0
    num3 = q[3] * 2f0
    num4 = q[1] * num    # 2x²
    num5 = q[2] * num2   # 2y²
    num6 = q[3] * num3   # 2z²
    num7 = q[1] * num2   # 2xy
    num8 = q[1] * num3   # 2xz
    num9 = q[2] * num3   # 2yz
    num10 = q[4] * num   # 2wx
    num11 = q[4] * num2  # 2wy
    num12 = q[4] * num3  # 2wz
    return Mat4f(
        1f0-(num5+num6), num7+num12,       num8-num11,       0f0,   # col 1
        num7-num12,       1f0-(num4+num6), num9+num10,       0f0,   # col 2
        num8+num11,       num9-num10,       1f0-(num4+num5), 0f0,   # col 3
        0f0,              0f0,              0f0,              1f0,   # col 4
    )
end

# ============================================================================
# Atlas bilinear sampling
# ============================================================================

@inline function sample_atlas_bilinear(
    atlas_data::AbstractMatrix,
    atlas_width::Int32,
    atlas_height::Int32,
    u::Float32,
    v::Float32,
)
    px = u * Float32(atlas_width)
    py = v * Float32(atlas_height)

    x0 = floor(Int, px)
    y0 = floor(Int, py)
    x1 = x0 + 1
    y1 = y0 + 1
    fx = px - Float32(x0)
    fy = py - Float32(y0)

    x0 = clamp(x0, 1, Int(atlas_width))
    x1 = clamp(x1, 1, Int(atlas_width))
    y0 = clamp(y0, 1, Int(atlas_height))
    y1 = clamp(y1, 1, Int(atlas_height))

    # Makie atlas: atlas_data[x, y] (dim1=U, dim2=V)
    v00 = Float32(atlas_data[x0, y0])
    v10 = Float32(atlas_data[x1, y0])
    v01 = Float32(atlas_data[x0, y1])
    v11 = Float32(atlas_data[x1, y1])

    v0 = v00 * (1f0 - fx) + v10 * fx
    v1 = v01 * (1f0 - fx) + v11 * fx
    return v0 * (1f0 - fy) + v1 * fy
end

# ============================================================================
# Stage 1: Prep Kernel (1 thread per sprite)
# ============================================================================
# Replicates sprites.geom main() using full Mat4f operations:
#   position = (preprojection * world_pos).xyz/w + marker_offset     (line 134-135)
#   trans = (billboard ? projection : pview) * qmat(rotation) * ...  (line 149-152)
#   vclip = pview * vec4(position, 1) + trans * vec4(bbox, 0, 0)    (line 155)
#   d_ndc_d_clip = mat4(1/w, ..., -xyz/w², ...)                     (line 167-170)
#   dxyv_dxys = diagm(0.5*ppu*res) * mat2(d_ndc_d_clip * trans)     (line 171)

@kernel function prep_sprites_kernel!(
    # Outputs (per-sprite)
    screen_centers,         # Vec2f: center in screen pixels (top-left origin)
    half_extents,           # Vec2f: AABB half-size in screen pixels
    inv_jacobians,          # Mat2f: inv(J), maps screen offset → sprite offset
    out_depths,             # Float32: depth for depth test (clip.w)
    out_colors,             # RGBA{Float32}
    viewport_from_u_scales, # Float32: SDF→viewport scale
    distancefield_scales,   # Float32: atlas SDF scale
    visibles,               # UInt32: 1=visible, 0=hidden
    # Inputs (per-sprite)
    @Const(positions),      # Point3f: world-space positions
    @Const(quad_offsets),    # Vec2f: offset to quad origin (markerspace)
    @Const(quad_scales),     # Vec2f: quad size (markerspace)
    @Const(marker_offsets),  # Vec3f: additional offset (markerspace)
    @Const(rotations),       # Vec4f: quaternion rotation
    @Const(colors),          # RGBA{Float32}: per-element color
    @Const(uv_rects),        # Vec4f: atlas UV bounds
    @Const(shapes),          # UInt8: shape per sprite
    # Uniforms
    preprojection::Mat4f,    # space → markerspace (e.g. data→pixel or I for data markerspace)
    marker_pview::Mat4f,     # projection * view in markerspace (markerspace → clip)
    resolution_x::Float32,
    resolution_y::Float32,
    px_per_unit::Float32,
    atlas_width::Int32,
    billboard::Int32,
    scale_primitive::Int32,
    model::Mat4f,
    marker_projection::Mat4f, # billboard ? plot.projection : projectionview
)
    i = @index(Global)
    @inbounds begin
        pos = positions[i]
        qoff = quad_offsets[i]
        qscl = quad_scales[i]
        moff = marker_offsets[i]
        rot = rotations[i]
        color = colors[i]
        uv_rect = uv_rects[i]
        shape = shapes[i]

        # ====== sprites.geom line 134-135: position in markerspace ======
        # vec4 p = preprojection * vec4(g_world_position[0], 1);
        # vec3 position = p.xyz / p.w + g_marker_offset[0];
        pp = preprojection * Vec4f(pos[1], pos[2], pos[3], 1f0)
        pp_w = pp[4]
        inv_pp_w = ifelse(abs(pp_w) > 1f-10, 1f0 / pp_w, 1f0)
        pos_x = pp[1] * inv_pp_w + moff[1]
        pos_y = pp[2] * inv_pp_w + moff[2]
        pos_z = pp[3] * inv_pp_w + moff[3]

        # ====== sprites.geom line 145-147: centred bounding box ======
        # vec2 bbox_signed_radius = 0.5*o_w.zw;
        # vec2 sprite_bbox_centre = o_w.xy + bbox_signed_radius;
        bbox_cx = qoff[1] + 0.5f0 * qscl[1]
        bbox_cy = qoff[2] + 0.5f0 * qscl[2]

        # ====== sprites.geom line 149-152: trans (FULL Mat4f) ======
        # mat4 pview = projection * view;           (= marker_pview)
        # mat4 trans = scale_primitive ? model : mat4(1.0);
        # trans = (billboard ? projection : pview) * qmat(g_rotation[0]) * trans;
        # marker_projection = billboard ? projection : pview (selected by caller)
        rot_4x4 = quat_to_mat4(rot)
        trans = if scale_primitive == Int32(1)
            marker_projection * rot_4x4 * model
        else
            marker_projection * rot_4x4
        end

        # ====== sprites.geom line 155: vclip (FULL Vec4f) ======
        # vec4 vclip = pview*vec4(position, 1) + trans*vec4(sprite_bbox_centre,0,0);
        p4 = Vec4f(pos_x, pos_y, pos_z, 1f0)
        vclip = marker_pview * p4 + trans * Vec4f(bbox_cx, bbox_cy, 0f0, 0f0)

        # Visibility: behind camera or zero-alpha → hidden
        vw = vclip[4]
        vis = vw > 0f0 && color.alpha > 0.001f0
        if !vis
            visibles[i] = UInt32(0)
            screen_centers[i] = Vec2f(0f0, 0f0)
            half_extents[i] = Vec2f(0f0, 0f0)
            inv_jacobians[i] = Mat2f(1f0, 0f0, 0f0, 1f0)
            out_depths[i] = 0f0
            out_colors[i] = RGBA{Float32}(0f0, 0f0, 0f0, 0f0)
            viewport_from_u_scales[i] = 0f0
            distancefield_scales[i] = 0f0
        else
            # ====== Screen center from vclip ======
            inv_w = 1f0 / vw
            ndc_cx = vclip[1] * inv_w
            ndc_cy = vclip[2] * inv_w
            screen_cx = (ndc_cx * 0.5f0 + 0.5f0) * resolution_x
            screen_cy = (1f0 - (ndc_cy * 0.5f0 + 0.5f0)) * resolution_y

            # ====== sprites.geom line 167-171: Jacobian (FULL Mat4f) ======
            # mat4 d_ndc_d_clip = mat4(1/w, 0, 0, 0,  0, 1/w, 0, 0,
            #                          0, 0, 1/w, 0,  -xyz/w², 0);
            # mat2 dxyv_dxys = diagm(0.5*ppu*resolution) * mat2(d_ndc_d_clip * trans);
            inv_w2 = inv_w * inv_w
            d_ndc_d_clip = Mat4f(
                inv_w, 0f0,   0f0,   0f0,                                          # col 1
                0f0,   inv_w, 0f0,   0f0,                                          # col 2
                0f0,   0f0,   inv_w, 0f0,                                          # col 3
                -vclip[1]*inv_w2, -vclip[2]*inv_w2, -vclip[3]*inv_w2, 0f0,        # col 4
            )
            DT = d_ndc_d_clip * trans  # full 4x4 multiply

            # mat2(DT) scaled by diagm(0.5*ppu*res), with NEGATIVE Y for top-left origin
            sx = 0.5f0 * px_per_unit * resolution_x
            sy = -0.5f0 * px_per_unit * resolution_y
            J00 = sx * DT[1,1];  J01 = sx * DT[1,2]
            J10 = sy * DT[2,1];  J11 = sy * DT[2,2]

            # ====== sprites.geom line 177: viewport_from_sprite_scale ======
            det_J = J00 * J11 - J01 * J10
            viewport_from_sprite = sqrt(abs(det_J))

            # ====== sprites.geom line 190-191: SDF scale ======
            sprite_from_u = min(abs(qscl[1]), abs(qscl[2]))
            vfu_scale = viewport_from_sprite * sprite_from_u

            # ====== sprites.geom line 192: distancefield_scale ======
            df_scale = if shape == DISTANCEFIELD
                pixsize_x = (uv_rect[3] - uv_rect[1]) * Float32(atlas_width)
                ifelse(abs(pixsize_x) > 1f-10, -1f0 / pixsize_x, 0f0)
            else
                1f0
            end

            # ====== AABB from Jacobian ======
            half_sx = 0.5f0 * abs(qscl[1])
            half_sy = 0.5f0 * abs(qscl[2])
            aabb_hx = abs(J00) * half_sx + abs(J01) * half_sy
            aabb_hy = abs(J10) * half_sx + abs(J11) * half_sy

            # ====== Inverse Jacobian (screen pixels → sprite space) ======
            inv_det = 1f0 / det_J
            inv_J = Mat2f(
                 J11 * inv_det,   # [1,1]
                -J10 * inv_det,   # [2,1]
                -J01 * inv_det,   # [1,2]
                 J00 * inv_det,   # [2,2]
            )

            # Write outputs
            screen_centers[i] = Vec2f(screen_cx, screen_cy)
            half_extents[i] = Vec2f(aabb_hx, aabb_hy)
            inv_jacobians[i] = inv_J
            out_depths[i] = vw
            out_colors[i] = color
            viewport_from_u_scales[i] = vfu_scale
            distancefield_scales[i] = df_scale
            visibles[i] = UInt32(1)
        end
    end
end

# ============================================================================
# Stage 2: Pixel Kernel (1 thread per pixel)
# ============================================================================
# Replicates distance_shape.frag logic.
# Uses the inverse Jacobian to map screen pixel offsets back to sprite-space,
# then to UV coordinates. V is flipped matching GLMakie's vertex emission order:
#   emit_vertex(bbox.xy, uv.xw)  → sprite bottom → UV top
#   emit_vertex(bbox.xw, uv.xy)  → sprite top    → UV bottom

@inline function rasterize_sprite_pixel!(
    overlay,
    depth_buffer,
    # Per-sprite precomputed data
    screen_centers,
    half_extents,
    inv_jacobians,
    depths,
    colors,
    viewport_from_u_scales,
    distancefield_scales,
    visibles,
    # Per-sprite input data
    quad_scales,
    uv_rects,
    shapes,
    # Atlas
    atlas_data,
    atlas_width::Int32,
    atlas_height::Int32,
    # Uniforms
    n_sprites::Int32,
    px::Int,
    py::Int,
)
    h, w = size(overlay)
    (px < 1 || px > w || py < 1 || py > h) && return

    # Pixel centers at half-integer coords (matching OpenGL convention)
    p = Vec2f(Float32(px) - 0.5f0, Float32(py) - 0.5f0)
    result_color = RGBA{Float32}(0f0, 0f0, 0f0, 0f0)
    rt_depth = @inbounds depth_buffer[h - py + 1, px]  # depth buffer is bottom-up

    @inbounds for i in 1:n_sprites
        visibles[i] == UInt32(0) && continue

        center = screen_centers[i]
        half_ext = half_extents[i]
        vfu_scale = viewport_from_u_scales[i]

        # Bounding box rejection (with AA buffer)
        aa_buf = ANTIALIAS_RADIUS + 1f0
        dx = abs(p[1] - center[1])
        dy = abs(p[2] - center[2])
        (dx > half_ext[1] + aa_buf) && continue
        (dy > half_ext[2] + aa_buf) && continue

        # Depth test
        depth = depths[i]
        depth_bias = 0.001f0 * depth
        depth > rt_depth + depth_bias && continue

        # ====== Map screen offset → sprite offset via inverse Jacobian ======
        inv_J = inv_jacobians[i]
        qscl = quad_scales[i]
        offset = p - center
        sprite_x = inv_J[1, 1] * offset[1] + inv_J[1, 2] * offset[2]
        sprite_y = inv_J[2, 1] * offset[1] + inv_J[2, 2] * offset[2]

        # ====== Sprite offset → UV ======
        # Matches GLMakie's vertex emission where sprite bottom → UV max_v:
        #   emit_vertex(bbox.xy, uv.xw) → sprite bottom-left → UV (min_u, max_v)
        # So: u = sprite_x / qscl_x + 0.5 (left→right)
        #     v = -sprite_y / qscl_y + 0.5 (V-flip: sprite Y-up → UV V-down)
        u = sprite_x / qscl[1] + 0.5f0
        v = -sprite_y / qscl[2] + 0.5f0

        shape = shapes[i]
        signed_distance = 0f0

        if shape == DISTANCEFIELD
            uv_rect = uv_rects[i]
            clamped_u = clamp(u, 0f0, 1f0)
            clamped_v = clamp(v, 0f0, 1f0)
            tex_u = uv_rect[1] + clamped_u * (uv_rect[3] - uv_rect[1])
            tex_v = uv_rect[2] + clamped_v * (uv_rect[4] - uv_rect[2])
            raw_sdf = sample_atlas_bilinear(atlas_data, atlas_width, atlas_height, tex_u, tex_v)
            signed_distance = raw_sdf * distancefield_scales[i]

            buf_u = u - clamped_u
            buf_v = v - clamped_v
            signed_distance -= sqrt(buf_u * buf_u + buf_v * buf_v)
        else
            signed_distance = -evaluate_shape_sdf(shape, Vec2f(u, v))
        end

        signed_distance_px = signed_distance * vfu_scale
        inside = aastep(0f0, signed_distance_px)
        inside < 0.001f0 && continue

        color = colors[i]
        alpha = color.alpha * inside
        result_color = alpha_blend(
            RGBA{Float32}(color.r, color.g, color.b, alpha),
            result_color
        )
    end

    @inbounds if result_color.alpha > 0.001f0
        overlay[py, px] = alpha_blend(result_color, overlay[py, px])
    end
    return
end

@kernel function rasterize_sprites_kernel!(
    overlay,
    @Const(depth_buffer),
    @Const(screen_centers),
    @Const(half_extents),
    @Const(inv_jacobians),
    @Const(depths),
    @Const(colors),
    @Const(viewport_from_u_scales),
    @Const(distancefield_scales),
    @Const(visibles),
    @Const(quad_scales),
    @Const(uv_rects),
    @Const(shapes),
    @Const(atlas_data),
    atlas_width::Int32,
    atlas_height::Int32,
    n_sprites::Int32,
)
    px, py = @index(Global, NTuple)
    rasterize_sprite_pixel!(
        overlay, depth_buffer,
        screen_centers, half_extents, inv_jacobians, depths, colors,
        viewport_from_u_scales, distancefield_scales, visibles,
        quad_scales, uv_rects, shapes,
        atlas_data, atlas_width, atlas_height,
        n_sprites, px, py
    )
end

# ============================================================================
# High-Level API
# ============================================================================

function rasterize_sprites!(
    overlay::AbstractMatrix{RGBA{Float32}},
    depth_buffer::AbstractMatrix{Float32},
    ctx::RasterContext,
    # Per-sprite data (already on correct backend)
    positions::AbstractVector{<:Point3f},
    quad_offsets::AbstractVector{Vec2f},
    quad_scales::AbstractVector{Vec2f},
    marker_offsets::AbstractVector{Vec3f},
    rotations::AbstractVector{Vec4f},
    colors::AbstractVector{RGBA{Float32}},
    uv_rects::AbstractVector{Vec4f},
    shapes::AbstractVector{UInt8},
    # Atlas
    atlas_data::AbstractMatrix,
    atlas_width::Int32,
    atlas_height::Int32;
    # Options
    billboard::Bool=true,
    scale_primitive::Bool=false,
    model::Mat4f=Mat4f(I),
    marker_projection::Mat4f=ctx.projection,
    preprojection::Mat4f=Mat4f(I),
    marker_pview::Mat4f=ctx.view_proj,
)
    n = length(positions)
    n == 0 && return

    backend = KernelAbstractions.get_backend(overlay)

    # Allocate prep outputs
    scr_centers = KernelAbstractions.allocate(backend, Vec2f, n)
    half_exts = KernelAbstractions.allocate(backend, Vec2f, n)
    inv_Js = KernelAbstractions.allocate(backend, Mat2f, n)
    out_depths = KernelAbstractions.allocate(backend, Float32, n)
    out_colors = KernelAbstractions.allocate(backend, RGBA{Float32}, n)
    vfu_scales = KernelAbstractions.allocate(backend, Float32, n)
    df_scales = KernelAbstractions.allocate(backend, Float32, n)
    vis = KernelAbstractions.allocate(backend, UInt32, n)

    # Stage 1: prep
    prep_sprites_kernel!(backend)(
        scr_centers, half_exts, inv_Js, out_depths, out_colors,
        vfu_scales, df_scales, vis,
        positions, quad_offsets, quad_scales, marker_offsets, rotations,
        colors, uv_rects, shapes,
        preprojection, marker_pview,
        ctx.resolution[1], ctx.resolution[2], ctx.px_per_unit,
        atlas_width,
        Int32(billboard), Int32(scale_primitive), model,
        marker_projection;
        ndrange=n
    )

    # Stage 2: pixel rasterization
    h, w = size(overlay)
    rasterize_sprites_kernel!(backend)(
        overlay, depth_buffer,
        scr_centers, half_exts, inv_Js, out_depths, out_colors,
        vfu_scales, df_scales, vis,
        quad_scales, uv_rects, shapes,
        atlas_data, atlas_width, atlas_height,
        Int32(n);
        ndrange=(w, h)
    )
    KernelAbstractions.synchronize(backend)
end
