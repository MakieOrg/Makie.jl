# =============================================================================
# Scatter/text rendering — direct port of GLMakie sprites.vert/geom/frag
# =============================================================================
# Shaders use Makie compute graph names directly. Conversions registered as
# separate computations (gpu_* prefixed) so update_robj! needs zero conversion.

const SPRITE_AA_RADIUS = 0.8f0

# What the vertex stage hands the geometry stage: one point's attributes, read
# back there as `prim.<name>[1]` because a `PointList` primitive is one vertex.
const SCATTER_VERTEX_OUT = (world_pos = Vec3f, marker_offset = Vec3f,
                            offset_width = Vec4f, rotation = Vec4f, colour = Vec4f,
                            uv_bbox = Vec4f, stroke_colour = Vec4f, glow_colour = Vec4f)

# What the geometry stage hands the fragment stage. Only `uv` varies across the
# quad's four vertices; everything else is the SPRITE's, computed once before the
# emit loop, so it is declared `Flat` and written once per triangle instead of
# four times. GLMakie's sprites.geom wrote all nine per vertex because a geometry
# shader offers no other way.
const SCATTER_GEOM_OUT = (uv = Vec2f, colour = Flat{Vec4f}, vp_from_u = Flat{Float32},
                          df_scale = Flat{Float32}, uv_bbox = Flat{Vec4f},
                          sp_scl = Flat{Vec2f}, shape = Flat{Float32},
                          stroke_colour = Flat{Vec4f}, glow_colour = Flat{Vec4f})

# ─── Per-vertex attribute: either a single value (uniform) or array (per-element) ───
const PerVertex{T} = Union{T, AbstractVector{<:T}}
# The ELEMENT TYPE is passed, and it is not decoration: an attribute is either
# one value for every vertex or one per vertex, and NEITHER shape can be told
# from the argument alone.
#
#   * `Mantle.DeviceArray` is the host handle for a pool region — its own
#     docstring says it does not index — and never reaches a stage. Dispatching
#     on it sent every per-vertex array to the scalar method, so `pos[1]` was
#     the first COMPONENT of the array's first element.
#   * `AbstractVector` catches the array, and catches a `Vec4f` too: a `Vec` is
#     a `StaticVector`. A uniform colour then read as `colour[idx]`, one float.
#
# With the type in hand both questions are one dispatch and the wrong shape is a
# `MethodError` at compile rather than a picture that is subtly wrong.
#
# The uniform method dispatches on `StaticVector`, which is STRICTLY more
# specific than `AbstractVector`, and not on `x::T`. `Tuple{Type{T}, T, Any}`
# and `Tuple{Type{T}, AbstractVector, Any}` are AMBIGUOUS — neither implies the
# other, because `T` is not constrained to be a vector — and Julia resolved the
# ambiguity to the ARRAY method: `gpu_read(Vec4f, Vec4f(.1,.2,.3,1), 2)`
# answered `Vec4f(0.2, 0.2, 0.2, 0.2)`, one component splatted, and past the
# fourth vertex it read out of bounds. Every uniform colour, markersize,
# rotation and marker offset was wrong on screen with no error anywhere, and
# `test_gpu_read.jl` pins each shape.
#
# Both methods CONVERT rather than requiring the exact type: a position buffer
# is `Point3f` where the stage wants `Vec3f`, and the two are the same three
# floats.
@inline gpu_read(::Type{T}, xs::AbstractVector, idx) where {T} = T(xs[idx])
@inline gpu_read(::Type{T}, x::StaticVector, idx) where {T} = T(x)
@inline gpu_read(::Type{T}, x::Number, idx) where {T} = T(x)

function get_scatter_pipeline!(screen)
    get!(screen.gfx_pipelines, :scatter) do
        GraphicsPipeline(;
            vertex = VertexShader(scatter_vertex; outputs = SCATTER_VERTEX_OUT),
            geometry = GeometryShader(scatter_geometry; outputs = SCATTER_GEOM_OUT,
                                      input = PointList(), output = TriangleStrip(),
                                      max_vertices = 4),
            fragment = FragmentShader(scatter_fragment),
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
# Names match compute graph outputs (gpu_* for converted, direct for others)
# =============================================================================

function scatter_vertex(
    gpu_positions::AbstractVector{<:Vec3f},
    gpu_colors::PerVertex{Vec4f},
    quad_offset,     # PerVertex — Vec2f or Vector{Vec2f}
    quad_scale,      # PerVertex — Vec2f or Vector{Vec2f}
    marker_offset,   # PerVertex — Point3f/Vec3f or Vector
    gpu_rotation,     # PerVertex — Vec4f or Vector{Vec4f}
    sdf_uv,          # PerVertex — Vec4f or Vector{Vec4f}
    gpu_stroke_color, # PerVertex — Vec4f or Vector{Vec4f}
    gpu_glow_color,   # PerVertex — Vec4f or Vector{Vec4f}
    model_f32c::Mat4f, f32c_scale::Vec3f, gpu_transform_marker::Int32,
    preprojection::Mat4f, projection::Mat4f, view::Mat4f,
    resolution::Vec2f, px_per_unit::Float32,
    gpu_stroke_width::Float32, gpu_glow_width::Float32,
    gpu_billboard::Int32, depth_shift::Float32,
    gpu_atlas_width::Float32, gpu_sdf_marker_shape::Int32,
)
    idx = vertex_index()
    pos = gpu_read(Vec3f, gpu_positions, idx)

    w4 = model_f32c * Vec4f(pos[1], pos[2], pos[3], 1f0)
    world_pos = Vec3f(w4[1], w4[2], w4[3])

    moff = gpu_read(Vec3f, marker_offset, idx)
    scaled_moff = Vec3f(f32c_scale[1]*moff[1], f32c_scale[2]*moff[2], f32c_scale[3]*moff[3])
    g_marker_offset = if gpu_transform_marker != Int32(0)
        mc1 = Vec3f(model_f32c[1,1], model_f32c[2,1], model_f32c[3,1])
        mc2 = Vec3f(model_f32c[1,2], model_f32c[2,2], model_f32c[3,2])
        mc3 = Vec3f(model_f32c[1,3], model_f32c[2,3], model_f32c[3,3])
        Vec3f(dot(mc1, scaled_moff), dot(mc2, scaled_moff), dot(mc3, scaled_moff))
    else
        scaled_moff
    end

    qoff = gpu_read(Vec2f, quad_offset, idx)
    qscl = gpu_read(Vec2f, quad_scale, idx)
    g_offset_width = Vec4f(f32c_scale[1]*qoff[1], f32c_scale[2]*qoff[2],
                           f32c_scale[1]*qscl[1], f32c_scale[2]*qscl[2])

    # The clip position is the GEOMETRY stage's to compute; this one is a
    # placeholder the rasteriser never sees, and it has to be written because
    # every vertex stage has a position.
    return (position = Vec4f(0f0, 0f0, 0f0, 1f0),
            world_pos = world_pos,
            marker_offset = g_marker_offset,
            offset_width = g_offset_width,
            rotation = gpu_read(Vec4f, gpu_rotation, idx),
            colour = gpu_read(Vec4f, gpu_colors, idx),
            uv_bbox = gpu_read(Vec4f, sdf_uv, idx),
            stroke_colour = gpu_read(Vec4f, gpu_stroke_color, idx),
            glow_colour = gpu_read(Vec4f, gpu_glow_color, idx))
end

# =============================================================================
# Geometry Shader — expands point to quad
# =============================================================================

function scatter_geometry(
    gs, prim,
    gpu_positions::AbstractVector{<:Vec3f},
    gpu_colors::PerVertex{Vec4f},
    quad_offset,     # PerVertex — Vec2f or Vector{Vec2f}
    quad_scale,      # PerVertex — Vec2f or Vector{Vec2f}
    marker_offset,   # PerVertex — Point3f/Vec3f or Vector
    gpu_rotation,     # PerVertex — Vec4f or Vector{Vec4f}
    sdf_uv,          # PerVertex — Vec4f or Vector{Vec4f}
    gpu_stroke_color, # PerVertex — Vec4f or Vector{Vec4f}
    gpu_glow_color,   # PerVertex — Vec4f or Vector{Vec4f}
    model_f32c::Mat4f, f32c_scale::Vec3f, gpu_transform_marker::Int32,
    preprojection::Mat4f, projection::Mat4f, view::Mat4f,
    resolution::Vec2f, px_per_unit::Float32,
    gpu_stroke_width::Float32, gpu_glow_width::Float32,
    gpu_billboard::Int32, depth_shift::Float32,
    gpu_atlas_width::Float32, gpu_sdf_marker_shape::Int32,
)
    # A `PointList` primitive is one vertex, so every field is its first.
    world_pos = prim.world_pos[1]
    g_marker_offset = prim.marker_offset[1]
    o_w = prim.offset_width[1]
    rot = prim.rotation[1]
    col = prim.colour[1]
    uv_bbox = prim.uv_bbox[1]
    scol = prim.stroke_colour[1]
    gcol = prim.glow_colour[1]

    p = preprojection * Vec4f(world_pos[1], world_pos[2], world_pos[3], 1f0)
    position = Vec3f(p[1]/p[4], p[2]/p[4], p[3]/p[4]) + g_marker_offset

    bbox_sr = Vec2f(0.5f0 * o_w[3], 0.5f0 * o_w[4])
    sprite_ctr = Vec2f(o_w[1] + bbox_sr[1], o_w[2] + bbox_sr[2])

    pview = projection * view
    trans_base = gpu_transform_marker != Int32(0) ? model_f32c : Mat4f(
        1f0,0f0,0f0,0f0, 0f0,1f0,0f0,0f0, 0f0,0f0,1f0,0f0, 0f0,0f0,0f0,1f0)
    rot_mat = scatter_qmat(rot)
    trans = gpu_billboard != Int32(0) ? projection * rot_mat * trans_base : pview * rot_mat * trans_base

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
    if gpu_sdf_marker_shape == Int32(3)
        uv_w = uv_bbox[3] - uv_bbox[1]
        px_x = uv_w * gpu_atlas_width
        abs(px_x) > 1f-10 && (f_df_scale = -1f0 / px_x)
    end

    sp_from_vp = vp_from_sp > 1f-10 ? 1f0 / vp_from_sp : 0f0
    buf = sp_from_vp * (SPRITE_AA_RADIUS + max(gpu_glow_width, 0f0) + max(gpu_stroke_width, 0f0))
    bbox_rb = Vec2f(bbox_sr[1] + sign(bbox_sr[1]) * buf, bbox_sr[2] + sign(bbox_sr[2]) * buf)

    uv_r = Vec2f(0.5f0 * bbox_rb[1] / (abs(bbox_sr[1]) > 1f-10 ? bbox_sr[1] : 1f0),
                 0.5f0 * bbox_rb[2] / (abs(bbox_sr[2]) > 1f-10 ? bbox_sr[2] : 1f0))
    uv_mn = Vec2f(0.5f0 - uv_r[1], 0.5f0 - uv_r[2])
    uv_mx = Vec2f(0.5f0 + uv_r[1], 0.5f0 + uv_r[2])
    b_mn = Vec2f(-bbox_rb[1], -bbox_rb[2])
    b_mx = Vec2f(bbox_rb[1], bbox_rb[2])
    sp_scl = Vec2f(o_w[3], o_w[4])
    sh_f = Float32(gpu_sdf_marker_shape)

    # The sprite's own values, computed once. They are `Flat` in
    # `SCATTER_GEOM_OUT`, so the emitter writes them once per triangle rather
    # than once per vertex — the loop below carries them along, it does not
    # recompute them.
    flat = (colour = col, vp_from_u = f_vp_from_u, df_scale = f_df_scale,
            uv_bbox = uv_bbox, sp_scl = sp_scl, shape = sh_f,
            stroke_colour = scol, glow_colour = gcol)

    # Triangle strip winding: BL, TL, BR, TR (Z pattern, matching GLMakie)
    for c in Int32(1):Int32(4)
        bx = (c == Int32(1) || c == Int32(2)) ? b_mn[1] : b_mx[1]
        by = (c == Int32(1) || c == Int32(3)) ? b_mn[2] : b_mx[2]
        ux = (c == Int32(1) || c == Int32(2)) ? uv_mn[1] : uv_mx[1]
        uy = (c == Int32(1) || c == Int32(3)) ? uv_mx[2] : uv_mn[2]
        v = vclip + trans * Vec4f(bx, by, 0f0, 0f0)
        pos = Vec4f(v[1], clip_y(v[2]), v[3] + v[4] * depth_shift, v[4])
        emit!(gs, merge((position = pos, uv = Vec2f(ux, uy)), flat))
    end
    endprimitive!(gs)
    return nothing
end

# =============================================================================
# Fragment Shader — SDF evaluation
# =============================================================================

function scatter_fragment(
    inputs,
    gpu_positions::AbstractVector{<:Vec3f},
    gpu_colors::PerVertex{Vec4f},
    quad_offset,     # PerVertex — Vec2f or Vector{Vec2f}
    quad_scale,      # PerVertex — Vec2f or Vector{Vec2f}
    marker_offset,   # PerVertex — Point3f/Vec3f or Vector
    gpu_rotation,     # PerVertex — Vec4f or Vector{Vec4f}
    sdf_uv,          # PerVertex — Vec4f or Vector{Vec4f}
    gpu_stroke_color, # PerVertex — Vec4f or Vector{Vec4f}
    gpu_glow_color,   # PerVertex — Vec4f or Vector{Vec4f}
    model_f32c::Mat4f, f32c_scale::Vec3f, gpu_transform_marker::Int32,
    preprojection::Mat4f, projection::Mat4f, view::Mat4f,
    resolution::Vec2f, px_per_unit::Float32,
    gpu_stroke_width::Float32, gpu_glow_width::Float32,
    gpu_billboard::Int32, depth_shift::Float32,
    gpu_atlas_width::Float32, gpu_sdf_marker_shape::Int32,
)
    f_uv = inputs.uv
    f_color = inputs.colour
    f_vp_from_u = inputs.vp_from_u
    f_df_scale = inputs.df_scale
    f_uv_bbox = inputs.uv_bbox
    f_sp_scl = inputs.sp_scl
    f_shape = inputs.shape
    f_scol = inputs.stroke_colour
    f_gcol = inputs.glow_colour

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

    s_sw = px_per_unit * gpu_stroke_width
    if s_sw > 0.001f0
        ti = aastep(-s_sw, sd, aa); to = aastep(0f0, sd, aa)
        st = ti - to
        st > 0.001f0 && (color = color * (1f0-st) + f_scol * st)
    end

    s_gw = px_per_unit * gpu_glow_width
    if s_gw > 0.001f0
        od = (abs(sd) - s_sw) / s_gw
        ga = max(0f0, 1f0 - od)
        gi = aastep(-s_sw, sd, aa)
        if ga > 0.001f0 && gi < 0.999f0
            glow = Vec4f(f_gcol[1], f_gcol[2], f_gcol[3], f_gcol[4]*ga)
            color = glow * (1f0-gi) + color * gi
        end
    end

    return Vec4f(color[1]*color[4], color[2]*color[4], color[3]*color[4], color[4])
end

# =============================================================================
# Arg names — order matches shader signature exactly
# =============================================================================

const SCATTER_ARG_NAMES = (
    :gpu_positions, :gpu_colors,
    :quad_offset, :quad_scale, :marker_offset, :gpu_rotation, :sdf_uv,
    :gpu_stroke_color, :gpu_glow_color,
    :model_f32c, :f32c_scale, :gpu_transform_marker,
    :preprojection, :projection, :view, :resolution, :px_per_unit,
    :gpu_stroke_width, :gpu_glow_width, :gpu_billboard, :depth_shift,
    :gpu_atlas_width, :gpu_sdf_marker_shape,
)

# =============================================================================
# setup_scatter! — registers conversions + robj
# =============================================================================

function setup_scatter!(screen, scene, plot, attr, backend)

    Makie.all_marker_computations!(attr)
    Makie.add_computation!(attr, scene, Val(:meshscatter_f32c_scale))

    # ── Conversion computations (gpu_* = GPU-ready type) ──

    # positions_transformed_f32c (Point2f/3f mixed) → gpu_positions (Vec3f[])
    Makie.ComputePipeline.map!(
        ps -> [Vec3f(Makie.to_ndim(Point3f, p, 0f0)) for p in ps],
        attr, :positions_transformed_f32c, :gpu_positions)

    # scaled_color + colormap → gpu_colors (Vec4f[]) — must match position count!
    Makie.ComputePipeline.register_computation!(attr,
        [:scaled_color, :alpha_colormap, :scaled_colorrange, :positions_transformed_f32c], [:gpu_colors]
    ) do (sc, cmap, crange, pos), changed, cached
        npos = length(pos)
        n = sc isa AbstractVector ? length(sc) : 1
        colors = scatter_resolve_colors(sc, cmap, crange, n)
        # Expand to match position count (single color → fill)
        cvec = [Vec4f(c.r, c.g, c.b, c.alpha) for c in colors]
        length(cvec) == 1 && npos > 1 && (cvec = fill(cvec[1], npos))
        return (cvec,)
    end

    # stroke/glow colors from plot attributes → gpu_stroke_color, gpu_glow_color (Vec4f[])
    Makie.ComputePipeline.register_computation!(attr,
        [:positions_transformed_f32c], [:gpu_stroke_color, :gpu_glow_color]
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
    haskey(attr, :converted_rotation) && Makie.ComputePipeline.map!(attr, :converted_rotation, :gpu_rotation) do rot
        if rot isa AbstractVector
            return [Vec4f(r[1], r[2], r[3], r[4]) for r in rot]
        else
            return Vec4f(rot[1], rot[2], rot[3], rot[4])
        end
    end

    # Scalar conversions (gpu_ prefix for type-converted values)
    Makie.ComputePipeline.map!(x -> Int32(x isa Bool ? x : false), attr, :transform_marker, :gpu_transform_marker)
    Makie.ComputePipeline.map!(x -> Int32(x isa Bool ? x : true), attr, :billboard, :gpu_billboard)
    Makie.ComputePipeline.map!(x -> Int32(x), attr, :sdf_marker_shape, :gpu_sdf_marker_shape)

    # Constants
    atlas = Makie.get_texture_atlas()
    haskey(attr, :px_per_unit) || Makie.ComputePipeline.add_constant!(attr, :px_per_unit, 1f0)
    haskey(attr, :gpu_stroke_width) || Makie.ComputePipeline.add_constant!(attr, :gpu_stroke_width,
        Float32(haskey(plot, :strokewidth) ? Makie.to_value(plot.strokewidth) : 0f0))
    haskey(attr, :gpu_glow_width) || Makie.ComputePipeline.add_constant!(attr, :gpu_glow_width,
        Float32(haskey(plot, :glowwidth) ? Makie.to_value(plot.glowwidth) : 0f0))
    haskey(attr, :depth_shift) || Makie.ComputePipeline.add_constant!(attr, :depth_shift, 0f0)
    haskey(attr, :gpu_atlas_width) || Makie.ComputePipeline.add_constant!(attr, :gpu_atlas_width, Float32(size(atlas.data, 1)))

    # ── Final robj registration — all inputs already correct type ──

    deps = collect(SCATTER_ARG_NAMES)

    Makie.ComputePipeline.register_computation!(attr, deps, [:trace_renderobject]) do args, changed, cached
        n = length(args.gpu_positions)
        n == 0 && return (nothing,)

        if !isnothing(cached) && cached.trace_renderobject isa RenderObject
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
