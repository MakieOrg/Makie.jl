# =============================================================================
# Lava scatter/text rendering — direct port of GLMakie sprites.vert/geom/frag
# =============================================================================
# Shaders use Makie compute graph names directly. Conversions registered as
# separate computations (vk_* prefixed) so update_robj! needs zero conversion.

const SPRITE_AA_RADIUS = 0.8f0

# ─── Per-vertex attribute: either a single value (uniform) or array (per-element) ───
const PerVertex{T} = Union{T, AbstractVector{<:T}}
@inline gpu_read(arr::LavaDeviceArray, idx) = arr[idx]
@inline gpu_read(scalar, idx) = scalar

function get_scatter_pipeline!(screen)
    get!(screen.gfx_pipelines, :scatter) do
        GraphicsPipeline(;
            vertex = scatter_vertex,
            geometry = (scatter_geometry, GeometryConfig(
                input = PointList(), output = TriangleStrip(), max_vertices = 4)),
            fragment = scatter_fragment,
            blend = Premultiplied(),
            topology = PointList(),
            cull = NoCull(),
            depth = DepthOff(),
        )
    end
end

# ─── Quaternion → rotation matrix ───
@inline function scatter_qmat(quat)
    x, y, z, w = Float32(quat[1]), Float32(quat[2]), Float32(quat[3]), Float32(quat[4])
    x2 = x * 2f0; y2 = y * 2f0; z2 = z * 2f0
    xx = x * x2; yy = y * y2; zz = z * z2
    xy = x * y2; xz = x * z2; yz = y * z2
    wx = w * x2; wy = w * y2; wz = w * z2
    Mat4f(1f0-(yy+zz), xy+wz, xz-wy, 0f0,
          xy-wz, 1f0-(xx+zz), yz+wx, 0f0,
          xz+wy, yz-wx, 1f0-(xx+yy), 0f0,
          0f0, 0f0, 0f0, 1f0)
end

# =============================================================================
# Vertex Shader — reads per-vertex buffers, applies model transform
# Names match compute graph outputs (vk_* for converted, direct for others)
# =============================================================================

function scatter_vertex(
    vk_positions::AbstractVector{<:Vec3f},
    vk_colors::PerVertex{Vec4f},
    quad_offset,     # PerVertex — Vec2f or Vector{Vec2f}
    quad_scale,      # PerVertex — Vec2f or Vector{Vec2f}
    marker_offset,   # PerVertex — Point3f/Vec3f or Vector
    vk_rotation,     # PerVertex — Vec4f or Vector{Vec4f}
    sdf_uv,          # PerVertex — Vec4f or Vector{Vec4f}
    vk_stroke_color, # PerVertex — Vec4f or Vector{Vec4f}
    vk_glow_color,   # PerVertex — Vec4f or Vector{Vec4f}
    model_f32c::Mat4f, f32c_scale::Vec3f, vk_transform_marker::Int32,
    preprojection::Mat4f, projection::Mat4f, view::Mat4f,
    resolution::Vec2f, px_per_unit::Float32,
    vk_stroke_width::Float32, vk_glow_width::Float32,
    vk_billboard::Int32, depth_shift::Float32,
    vk_atlas_width::Float32, vk_sdf_marker_shape::Int32,
)
    idx = vertex_index()
    pos = gpu_read(vk_positions, idx)

    w4 = model_f32c * Vec4f(pos[1], pos[2], pos[3], 1f0)
    world_pos = Vec3f(w4[1], w4[2], w4[3])

    moff = gpu_read(marker_offset, idx)
    scaled_moff = Vec3f(f32c_scale[1]*moff[1], f32c_scale[2]*moff[2], f32c_scale[3]*moff[3])
    g_marker_offset = if vk_transform_marker != Int32(0)
        mc1 = Vec3f(model_f32c[1,1], model_f32c[2,1], model_f32c[3,1])
        mc2 = Vec3f(model_f32c[1,2], model_f32c[2,2], model_f32c[3,2])
        mc3 = Vec3f(model_f32c[1,3], model_f32c[2,3], model_f32c[3,3])
        Vec3f(dot(mc1, scaled_moff), dot(mc2, scaled_moff), dot(mc3, scaled_moff))
    else
        scaled_moff
    end

    qoff = gpu_read(quad_offset, idx)
    qscl = gpu_read(quad_scale, idx)
    g_offset_width = Vec4f(f32c_scale[1]*qoff[1], f32c_scale[2]*qoff[2],
                           f32c_scale[1]*qscl[1], f32c_scale[2]*qscl[2])

    set_position!(Vec4f(0f0, 0f0, 0f0, 1f0))
    gfx_output(0, world_pos)
    gfx_output(1, g_marker_offset)
    gfx_output(2, g_offset_width)
    gfx_output(3, gpu_read(vk_rotation, idx))
    gfx_output(4, gpu_read(vk_colors, idx))
    gfx_output(5, gpu_read(sdf_uv, idx))
    gfx_output(6, gpu_read(vk_stroke_color, idx))
    gfx_output(7, gpu_read(vk_glow_color, idx))
    return nothing
end

# =============================================================================
# Geometry Shader — expands point to quad
# =============================================================================

function scatter_geometry(
    vk_positions::AbstractVector{<:Vec3f},
    vk_colors::PerVertex{Vec4f},
    quad_offset,     # PerVertex — Vec2f or Vector{Vec2f}
    quad_scale,      # PerVertex — Vec2f or Vector{Vec2f}
    marker_offset,   # PerVertex — Point3f/Vec3f or Vector
    vk_rotation,     # PerVertex — Vec4f or Vector{Vec4f}
    sdf_uv,          # PerVertex — Vec4f or Vector{Vec4f}
    vk_stroke_color, # PerVertex — Vec4f or Vector{Vec4f}
    vk_glow_color,   # PerVertex — Vec4f or Vector{Vec4f}
    model_f32c::Mat4f, f32c_scale::Vec3f, vk_transform_marker::Int32,
    preprojection::Mat4f, projection::Mat4f, view::Mat4f,
    resolution::Vec2f, px_per_unit::Float32,
    vk_stroke_width::Float32, vk_glow_width::Float32,
    vk_billboard::Int32, depth_shift::Float32,
    vk_atlas_width::Float32, vk_sdf_marker_shape::Int32,
)
    world_pos = geom_input(Vec3f, 0, 0)
    g_marker_offset = geom_input(Vec3f, 1, 0)
    o_w = geom_input(Vec4f, 2, 0)
    rot = geom_input(Vec4f, 3, 0)
    col = geom_input(Vec4f, 4, 0)
    uv_bbox = geom_input(Vec4f, 5, 0)
    scol = geom_input(Vec4f, 6, 0)
    gcol = geom_input(Vec4f, 7, 0)

    p = preprojection * Vec4f(world_pos[1], world_pos[2], world_pos[3], 1f0)
    position = Vec3f(p[1]/p[4], p[2]/p[4], p[3]/p[4]) + g_marker_offset

    bbox_sr = Vec2f(0.5f0 * o_w[3], 0.5f0 * o_w[4])
    sprite_ctr = Vec2f(o_w[1] + bbox_sr[1], o_w[2] + bbox_sr[2])

    pview = projection * view
    trans_base = vk_transform_marker != Int32(0) ? model_f32c : Mat4f(
        1f0,0f0,0f0,0f0, 0f0,1f0,0f0,0f0, 0f0,0f0,1f0,0f0, 0f0,0f0,0f0,1f0)
    rot_mat = scatter_qmat(rot)
    trans = vk_billboard != Int32(0) ? projection * rot_mat * trans_base : pview * rot_mat * trans_base

    vclip = pview * Vec4f(position[1], position[2], position[3], 1f0) +
            trans * Vec4f(sprite_ctr[1], sprite_ctr[2], 0f0, 0f0)

    inv_w = 1f0 / vclip[4]
    sx = 0.5f0 * px_per_unit * resolution[1] * inv_w
    sy = 0.5f0 * px_per_unit * resolution[2] * inv_w
    det_J = (sx*trans[1,1]) * (sy*trans[2,2]) - (sx*trans[1,2]) * (sy*trans[2,1])
    vp_from_sp = sqrt(abs(det_J))

    sp_from_u = min(abs(o_w[3]), abs(o_w[4]))
    f_vp_from_u = vp_from_sp * sp_from_u

    f_df_scale = 1f0
    if vk_sdf_marker_shape == Int32(3)
        uv_w = uv_bbox[3] - uv_bbox[1]
        px_x = uv_w * vk_atlas_width
        abs(px_x) > 1f-10 && (f_df_scale = -1f0 / px_x)
    end

    sp_from_vp = vp_from_sp > 1f-10 ? 1f0 / vp_from_sp : 0f0
    buf = sp_from_vp * (SPRITE_AA_RADIUS + max(vk_glow_width, 0f0) + max(vk_stroke_width, 0f0))
    bbox_rb = Vec2f(bbox_sr[1] + sign(bbox_sr[1]) * buf, bbox_sr[2] + sign(bbox_sr[2]) * buf)

    uv_r = Vec2f(0.5f0 * bbox_rb[1] / (abs(bbox_sr[1]) > 1f-10 ? bbox_sr[1] : 1f0),
                 0.5f0 * bbox_rb[2] / (abs(bbox_sr[2]) > 1f-10 ? bbox_sr[2] : 1f0))
    uv_mn = Vec2f(0.5f0 - uv_r[1], 0.5f0 - uv_r[2])
    uv_mx = Vec2f(0.5f0 + uv_r[1], 0.5f0 + uv_r[2])
    b_mn = Vec2f(-bbox_rb[1], -bbox_rb[2])
    b_mx = Vec2f(bbox_rb[1], bbox_rb[2])
    sp_scl = Vec2f(o_w[3], o_w[4])
    sh_f = Float32(vk_sdf_marker_shape)

    # Triangle strip winding: BL, TL, BR, TR (Z pattern, matching GLMakie)
    for c in Int32(1):Int32(4)
        bx = (c == Int32(1) || c == Int32(2)) ? b_mn[1] : b_mx[1]
        by = (c == Int32(1) || c == Int32(3)) ? b_mn[2] : b_mx[2]
        ux = (c == Int32(1) || c == Int32(2)) ? uv_mn[1] : uv_mx[1]
        uy = (c == Int32(1) || c == Int32(3)) ? uv_mx[2] : uv_mn[2]
        v = vclip + trans * Vec4f(bx, by, 0f0, 0f0)
        set_position!(Vec4f(v[1], v[2], v[3] + v[4] * depth_shift, v[4]))
        gfx_output(0, Vec2f(ux, uy))
        gfx_output(1, col)
        gfx_output(2, f_vp_from_u)
        gfx_output(3, f_df_scale)
        gfx_output(4, uv_bbox)
        gfx_output(5, sp_scl)
        gfx_output(6, sh_f)
        gfx_output(7, scol)
        gfx_output(8, gcol)
        emit_vertex!()
    end
    end_primitive!()
    return nothing
end

# =============================================================================
# Fragment Shader — SDF evaluation
# =============================================================================

function scatter_fragment(
    vk_positions::AbstractVector{<:Vec3f},
    vk_colors::PerVertex{Vec4f},
    quad_offset,     # PerVertex — Vec2f or Vector{Vec2f}
    quad_scale,      # PerVertex — Vec2f or Vector{Vec2f}
    marker_offset,   # PerVertex — Point3f/Vec3f or Vector
    vk_rotation,     # PerVertex — Vec4f or Vector{Vec4f}
    sdf_uv,          # PerVertex — Vec4f or Vector{Vec4f}
    vk_stroke_color, # PerVertex — Vec4f or Vector{Vec4f}
    vk_glow_color,   # PerVertex — Vec4f or Vector{Vec4f}
    model_f32c::Mat4f, f32c_scale::Vec3f, vk_transform_marker::Int32,
    preprojection::Mat4f, projection::Mat4f, view::Mat4f,
    resolution::Vec2f, px_per_unit::Float32,
    vk_stroke_width::Float32, vk_glow_width::Float32,
    vk_billboard::Int32, depth_shift::Float32,
    vk_atlas_width::Float32, vk_sdf_marker_shape::Int32,
)
    f_uv = gfx_input(Vec2f, 0)
    f_color = gfx_input(Vec4f, 1)
    f_vp_from_u = gfx_input(Float32, 2)
    f_df_scale = gfx_input(Float32, 3)
    f_uv_bbox = gfx_input(Vec4f, 4)
    f_sp_scl = gfx_input(Vec2f, 5)
    f_shape = gfx_input(Float32, 6)
    f_scol = gfx_input(Vec4f, 7)
    f_gcol = gfx_input(Vec4f, 8)

    u = f_uv[1]; v = f_uv[2]
    sh = Base.fptosi(Int32, f_shape + 0.5f0)

    sd = if sh == Int32(3)
        cu = clamp(u, 0f0, 1f0); cv = clamp(v, 0f0, 1f0)
        tu = f_uv_bbox[1] + cu * (f_uv_bbox[3] - f_uv_bbox[1])
        tv = f_uv_bbox[2] + cv * (f_uv_bbox[4] - f_uv_bbox[2])
        raw = sample_texture_2d(UInt32(0), tu, tv, UInt32(0))
        bu = u - cu; bv = v - cv
        f_df_scale * raw - sqrt(bu*bu + bv*bv)
    elseif sh == Int32(1)
        sx = f_sp_scl[1] / min(abs(f_sp_scl[1]), abs(f_sp_scl[2]))
        sy = f_sp_scl[2] / min(abs(f_sp_scl[1]), abs(f_sp_scl[2]))
        dx = sx * max(-u, u-1f0); dy = sy * max(-v, v-1f0)
        -(sqrt(max(0f0,dx)^2 + max(0f0,dy)^2) + min(0f0, max(dx,dy)))
    elseif sh == Int32(4)
        px = u-0.5f0; py = v-0.5f0
        tx = 1.4142135f0*(px-py); ty = 1.4142135f0*(px+py)
        -max(max(abs(tx),abs(ty))-0.35355338f0, py)
    else
        0.5f0 - sqrt((u-0.5f0)^2 + (v-0.5f0)^2)
    end

    sd = sd * f_vp_from_u
    aa = 0.70710677f0
    inside = aastep(0f0, sd, aa)
    fill_c = Vec4f(f_color[1], f_color[2], f_color[3], max(f_color[4], 0.001f0))
    color = Vec4f(fill_c[1], fill_c[2], fill_c[3], fill_c[4] * inside)

    s_sw = px_per_unit * vk_stroke_width
    if s_sw > 0.001f0
        ti = aastep(-s_sw, sd, aa); to = aastep(0f0, sd, aa)
        st = ti - to
        st > 0.001f0 && (color = color * (1f0-st) + f_scol * st)
    end

    s_gw = px_per_unit * vk_glow_width
    if s_gw > 0.001f0
        od = (abs(sd) - s_sw) / s_gw
        ga = max(0f0, 1f0 - od)
        gi = aastep(-s_sw, sd, aa)
        if ga > 0.001f0 && gi < 0.999f0
            glow = Vec4f(f_gcol[1], f_gcol[2], f_gcol[3], f_gcol[4]*ga)
            color = glow * (1f0-gi) + color * gi
        end
    end

    gfx_output(0, Vec4f(color[1]*color[4], color[2]*color[4], color[3]*color[4], color[4]))
    return nothing
end

# =============================================================================
# Arg names — order matches shader signature exactly
# =============================================================================

const SCATTER_ARG_NAMES = (
    :vk_positions, :vk_colors,
    :quad_offset, :quad_scale, :marker_offset, :vk_rotation, :sdf_uv,
    :vk_stroke_color, :vk_glow_color,
    :model_f32c, :f32c_scale, :vk_transform_marker,
    :preprojection, :projection, :view, :resolution, :px_per_unit,
    :vk_stroke_width, :vk_glow_width, :vk_billboard, :depth_shift,
    :vk_atlas_width, :vk_sdf_marker_shape,
)

# =============================================================================
# setup_scatter! — registers conversions + robj
# =============================================================================

function setup_scatter!(screen, scene, plot, attr, backend)

    Makie.all_marker_computations!(attr)
    Makie.add_computation!(attr, scene, Val(:meshscatter_f32c_scale))

    # ── Conversion computations (vk_* = GPU-ready type) ──

    # positions_transformed_f32c (Point2f/3f mixed) → vk_positions (Vec3f[])
    Makie.ComputePipeline.map!(
        ps -> [Vec3f(Makie.to_ndim(Point3f, p, 0f0)) for p in ps],
        attr, :positions_transformed_f32c, :vk_positions)

    # scaled_color + colormap → vk_colors (Vec4f[]) — must match position count!
    Makie.ComputePipeline.register_computation!(attr,
        [:scaled_color, :alpha_colormap, :scaled_colorrange, :positions_transformed_f32c], [:vk_colors]
    ) do (sc, cmap, crange, pos), changed, cached
        npos = length(pos)
        n = sc isa AbstractVector ? length(sc) : 1
        colors = scatter_resolve_colors(sc, cmap, crange, n)
        # Expand to match position count (single color → fill)
        cvec = [Vec4f(c.r, c.g, c.b, c.alpha) for c in colors]
        length(cvec) == 1 && npos > 1 && (cvec = fill(cvec[1], npos))
        return (cvec,)
    end

    # stroke/glow colors from plot attributes → vk_stroke_color, vk_glow_color (Vec4f[])
    Makie.ComputePipeline.register_computation!(attr,
        [:positions_transformed_f32c], [:vk_stroke_color, :vk_glow_color]
    ) do (pos,), changed, cached
        n = length(pos)
        sc = haskey(plot, :strokecolor) ? Makie.to_value(plot.strokecolor) : RGBAf(0,0,0,0)
        sc_c = sc isa Colorant ? RGBA{Float32}(sc) : RGBA{Float32}(0,0,0,0)
        gc = haskey(plot, :glowcolor) ? Makie.to_value(plot.glowcolor) : RGBAf(0,0,0,0)
        gc_c = gc isa Colorant ? RGBA{Float32}(gc) : RGBA{Float32}(0,0,0,0)
        return (fill(Vec4f(sc_c.r, sc_c.g, sc_c.b, sc_c.alpha), n),
                fill(Vec4f(gc_c.r, gc_c.g, gc_c.b, gc_c.alpha), n))
    end

    # converted_rotation (Quaternionf or Vector{Quaternionf}) → Vec4f
    # (Quaternionf is NOT a VecTypes — must extract components explicitly)
    haskey(attr, :converted_rotation) && Makie.ComputePipeline.map!(attr, :converted_rotation, :vk_rotation) do rot
        if rot isa AbstractVector
            return [Vec4f(r[1], r[2], r[3], r[4]) for r in rot]
        else
            return Vec4f(rot[1], rot[2], rot[3], rot[4])
        end
    end

    # Scalar conversions (vk_ prefix for type-converted values)
    Makie.ComputePipeline.map!(x -> Int32(x isa Bool ? x : false), attr, :transform_marker, :vk_transform_marker)
    Makie.ComputePipeline.map!(x -> Int32(x isa Bool ? x : true), attr, :billboard, :vk_billboard)
    Makie.ComputePipeline.map!(x -> Int32(x), attr, :sdf_marker_shape, :vk_sdf_marker_shape)

    # Constants
    atlas = Makie.get_texture_atlas()
    haskey(attr, :px_per_unit) || Makie.ComputePipeline.add_constant!(attr, :px_per_unit, 1f0)
    haskey(attr, :vk_stroke_width) || Makie.ComputePipeline.add_constant!(attr, :vk_stroke_width,
        Float32(haskey(plot, :strokewidth) ? Makie.to_value(plot.strokewidth) : 0f0))
    haskey(attr, :vk_glow_width) || Makie.ComputePipeline.add_constant!(attr, :vk_glow_width,
        Float32(haskey(plot, :glowwidth) ? Makie.to_value(plot.glowwidth) : 0f0))
    haskey(attr, :depth_shift) || Makie.ComputePipeline.add_constant!(attr, :depth_shift, 0f0)
    haskey(attr, :vk_atlas_width) || Makie.ComputePipeline.add_constant!(attr, :vk_atlas_width, Float32(size(atlas.data, 1)))

    # ── Final robj registration — all inputs already correct type ──

    deps = collect(SCATTER_ARG_NAMES)

    Makie.ComputePipeline.register_computation!(attr, deps, [:trace_renderobject]) do args, changed, cached
        n = length(args.vk_positions)
        n == 0 && return (nothing,)

        if !isnothing(cached) && cached.trace_renderobject isa LavaRenderObject
            robj = cached.trace_renderobject
            update_robj!(robj, args, changed)
            robj.vertex_count = n
            robj.visible = true
            return (robj,)
        end

        robj = construct_robj(get_scatter_pipeline!(screen), args, SCATTER_ARG_NAMES;
                              backend, vertex_count=n)
        robj.bindings = get_atlas_bindings(screen)
        return (robj,)
    end
end

# =============================================================================
# Color helpers
# =============================================================================

function scatter_resolve_colors(scaled_color, colormap, colorrange, n::Int)
    if scaled_color isa AbstractVector{<:Colorant}
        [RGBA{Float32}(c) for c in scaled_color]
    elseif scaled_color isa Colorant
        fill(RGBA{Float32}(scaled_color), n)
    elseif scaled_color isa AbstractVector{<:Real}
        cmin = Float32(colorrange[1]); cmax = Float32(colorrange[2])
        cmap = colormap isa AbstractVector ? colormap : RGBAf[RGBAf(0,0,0,1)]
        [scatter_cmap_sample(cmap, Float32(v), cmin, cmax) for v in scaled_color]
    elseif scaled_color isa Real
        cmin = Float32(colorrange[1]); cmax = Float32(colorrange[2])
        cmap = colormap isa AbstractVector ? colormap : RGBAf[RGBAf(0,0,0,1)]
        fill(scatter_cmap_sample(cmap, Float32(scaled_color), cmin, cmax), n)
    else
        fill(RGBA{Float32}(0f0, 0f0, 0f0, 1f0), n)
    end
end

function scatter_cmap_sample(cmap::AbstractVector, v::Float32, cmin::Float32, cmax::Float32)
    t = clamp((v - cmin) / (cmax - cmin + 1f-10), 0f0, 1f0)
    nc = length(cmap); idx = t * Float32(nc - 1) + 1f0
    i0 = clamp(floor(Int, idx), 1, nc); i1 = clamp(i0 + 1, 1, nc); f = idx - Float32(i0)
    c0 = RGBA{Float32}(cmap[i0]); c1 = RGBA{Float32}(cmap[i1])
    RGBA{Float32}((1f0-f)*c0.r+f*c1.r, (1f0-f)*c0.g+f*c1.g,
                   (1f0-f)*c0.b+f*c1.b, (1f0-f)*c0.alpha+f*c1.alpha)
end
