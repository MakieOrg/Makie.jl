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
                            uv_bbox = Vec4f, stroke_colour = Vec4f, glow_colour = Vec4f,
                            pick_index = Float32)

# What the geometry stage hands the fragment stage. Only `uv` varies across the
# quad's four vertices; everything else is the SPRITE's, computed once before the
# emit loop, so it is declared `Flat` and written once per triangle instead of
# four times. GLMakie's sprites.geom wrote all nine per vertex because a geometry
# shader offers no other way.
const SCATTER_GEOM_OUT = (uv = Vec2f, colour = Flat{Vec4f}, vp_from_u = Flat{Float32},
                          df_scale = Flat{Float32}, uv_bbox = Flat{Vec4f},
                          sp_scl = Flat{Vec2f}, shape = Flat{Float32},
                          stroke_colour = Flat{Vec4f}, glow_colour = Flat{Vec4f},
                          pick_index = Flat{Float32})

# ─── Per-vertex attribute: either a single value (uniform) or array (per-element) ───
const PerVertex{T} = Union{T, AbstractVector{<:T}}
#
# `AbstractVector` and not `Mantle.DeviceArray`: the latter is the HOST handle for a
# buffer, and what a shader is handed is whatever the backend's device-side array is
# — `MtlDeviceVector` on Metal, and nothing that shares a supertype with it. Dispatch
# on the host type sent every buffer down the scalar branch on any backend but the one
# it was written for, and the shader then read the array WHERE IT MEANT A VERTEX: the
# first symptom is a `MethodError` for `Vec4f(::MtlDeviceVector, …)` at compile time.
#
# A `Vec` is an `AbstractVector` too and is one value for every vertex, which is what
# the `StaticVector` method is for.
@inline gpu_read(arr::AbstractVector, idx) = arr[idx]
@inline gpu_read(v::StaticVector, idx) = v
@inline gpu_read(scalar, idx) = scalar

function get_scatter_pipeline!(screen)
    get!(screen.gfx_pipelines, :scatter) do
        GraphicsPipeline(;
            vertex = VertexShader(scatter_vertex; outputs = SCATTER_VERTEX_OUT),
            geometry = GeometryShader(scatter_geometry; outputs = SCATTER_GEOM_OUT,
                                      input = PointList(), output = TriangleStrip(),
                                      max_vertices = 4),
            fragment = FragmentShader(scatter_fragment; textures = 1),
            blend = Mantle.AlphaBlend(),
            topology = PointList(),
            cull = NoCull(),
            depth = DepthLessEq(),
        )
    end
end

# ─── Quaternion → rotation matrix ───
# Mantle's rotation (row-major), as the homogeneous 4×4 the sprite transform takes.
@inline function scatter_qmat(quat)
    r = transpose(Mat3f(Mantle.quat_to_rot3x3(Vec4f(quat[1], quat[2], quat[3], quat[4]))...))
    return Mat4f(vcat(hcat(r, zero(Vec3f)), Mat{1,4,Float32}(0f0, 0f0, 0f0, 1f0)))
end

# sprites.vert: mat3(model) * marker_offset (columns, not dot products
# against columns, which would apply the transpose).
@inline function scatter_model_offset(model::Mat4f, offset::Vec3f)
    m = Mat3f(model[1,1], model[2,1], model[3,1],
              model[1,2], model[2,2], model[3,2],
              model[1,3], model[2,3], model[3,3])
    return m * offset
end

# sprites.geom's full derivative of the perspective divide, evaluated at the
# sprite centre. The fourth column matters when trans changes clip-space w.
@inline function scatter_viewport_scale(clip::Vec4f, trans::Mat4f,
                                       resolution::Vec2f, density::Float32)
    inv_w = 1f0 / clip[4]
    w2 = clip[4] * clip[4]
    d_ndc_d_clip = Mat4f(
        inv_w, 0f0, 0f0, 0f0,
        0f0, inv_w, 0f0, 0f0,
        0f0, 0f0, inv_w, 0f0,
        -clip[1] / w2, -clip[2] / w2, -clip[3] / w2, 0f0)
    j = d_ndc_d_clip * trans
    viewport = Mat2f(0.5f0 * density * resolution[1], 0f0,
                    0f0, 0.5f0 * density * resolution[2])
    dxyv_dxys = viewport * Mat2f(j[1,1], j[2,1], j[1,2], j[2,2])
    return sqrt(abs(det(dxyv_dxys)))
end

# =============================================================================
# Vertex Shader — reads per-vertex buffers, applies model transform
# Names match compute graph outputs (gpu_* for converted, direct for others)
# =============================================================================

# The index is a PARAMETER, and the arg-less spelling below hands it the builtin.
# Both are needed and they are the same number; see the same pair in
# `overlay/lines.jl` for why, and `KernelInterface.VertexIndex` for the contract.
# The fallback's arity is `length(SCATTER_ARG_NAMES)`, fixed so it cannot match
# its own forwarded call.
scatter_vertex(args::Vararg{Any,26}) = scatter_vertex(VertexIndex(vertex_index()), args...)

function scatter_vertex(
    vertexid::VertexIndex,
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
    uniform_clip_planes::AbstractVector{Vec4f}, uniform_num_clip_planes::Int32, fxaa::Int32,
)
    idx = vertexid.value
    pos = gpu_read(gpu_positions, idx)

    w4 = model_f32c * Vec4f(pos[1], pos[2], pos[3], 1f0)
    world_pos = Vec3f(w4[1], w4[2], w4[3])

    moff = gpu_read(marker_offset, idx)
    scaled_moff = Vec3f(f32c_scale[1]*moff[1], f32c_scale[2]*moff[2], f32c_scale[3]*moff[3])
    g_marker_offset = if gpu_transform_marker != Int32(0)
        scatter_model_offset(model_f32c, scaled_moff)
    else
        scaled_moff
    end

    qoff = gpu_read(quad_offset, idx)
    qscl = gpu_read(quad_scale, idx)
    g_offset_width = Vec4f(f32c_scale[1]*qoff[1], f32c_scale[2]*qoff[2],
                           f32c_scale[1]*qscl[1], f32c_scale[2]*qscl[2])

    # The clip position is the GEOMETRY stage's to compute; this one is a
    # placeholder the rasteriser never sees, and it has to be written because
    # every vertex stage has a position.
    return (position = Vec4f(0f0, 0f0, 0f0, 1f0),
            world_pos = world_pos,
            marker_offset = g_marker_offset,
            offset_width = g_offset_width,
            rotation = gpu_read(gpu_rotation, idx),
            colour = gpu_read(gpu_colors, idx),
            uv_bbox = gpu_read(sdf_uv, idx),
            stroke_colour = gpu_read(gpu_stroke_color, idx),
            glow_colour = gpu_read(gpu_glow_color, idx), pick_index = Float32(idx))
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
    uniform_clip_planes::AbstractVector{Vec4f}, uniform_num_clip_planes::Int32, fxaa::Int32,
)
    # A `PointList` primitive is one vertex, so every field is its first.
    world_pos = prim.world_pos[1]
    # sprites.geom's is_clipped: reject the complete sprite at its original
    # world-space position, before the marker-space projection and offsets.
    for i in Int32(1):uniform_num_clip_planes
        plane = @inbounds uniform_clip_planes[i]
        dot(world_pos, Vec3f(plane[1], plane[2], plane[3])) - plane[4] < 0f0 &&
            return nothing
    end
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

    vp_from_sp = scatter_viewport_scale(vclip, trans, resolution, px_per_unit)

    sp_from_u = min(abs(o_w[3]), abs(o_w[4]))
    f_vp_from_u = vp_from_sp * sp_from_u

    f_df_scale = 1f0
    if gpu_sdf_marker_shape == Int32(3)
        uv_w = uv_bbox[3] - uv_bbox[1]
        px_x = uv_w * gpu_atlas_width
        f_df_scale = -1f0 / px_x
    end

    sp_from_vp = 1f0 / vp_from_sp
    buf = sp_from_vp * (SPRITE_AA_RADIUS + max(gpu_glow_width, 0f0) + max(gpu_stroke_width, 0f0))
    bbox_rb = Vec2f(bbox_sr[1] + sign(bbox_sr[1]) * buf, bbox_sr[2] + sign(bbox_sr[2]) * buf)

    uv_r = Vec2f(0.5f0 * bbox_rb[1] / bbox_sr[1],
                 0.5f0 * bbox_rb[2] / bbox_sr[2])
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
            stroke_colour = scol, glow_colour = gcol, pick_index = prim.pick_index[1])

    # Triangle strip winding: BL, TL, BR, TR (Z pattern, matching GLMakie)
    for c in Int32(1):Int32(4)
        bx = (c == Int32(1) || c == Int32(2)) ? b_mn[1] : b_mx[1]
        by = (c == Int32(1) || c == Int32(3)) ? b_mn[2] : b_mx[2]
        ux = (c == Int32(1) || c == Int32(2)) ? uv_mn[1] : uv_mx[1]
        uy = (c == Int32(1) || c == Int32(3)) ? uv_mx[2] : uv_mn[2]
        v = vclip + trans * Vec4f(bx, by, 0f0, 0f0)
        pos = gl_to_clip_depth(Vec4f(v[1], v[2], v[3] + v[4] * depth_shift, v[4]))
        emit!(gs, merge((position = pos, uv = Vec2f(ux, uy)), flat))
    end
    endprimitive!(gs)
    return nothing
end

# =============================================================================
# Fragment Shader — SDF evaluation
# =============================================================================

"Glyph distance in the same normalized units as the sprite's horizontal UV."
@inline function glyph_distance(uv::Vec2f, bbox::Vec4f, scale::Float32)
    u = clamp(uv[1], 0f0, 1f0)
    v = clamp(uv[2], 0f0, 1f0)
    # GLSL mix(x, y, a), as used by distance_shape.frag.
    tu = bbox[1] * (1f0 - u) + bbox[3] * u
    tv = bbox[2] * (1f0 - v) + bbox[4] * v
    return scale * sample_texture_2d(UInt32(0), tu, tv, UInt32(0))
end

# GLMakie's distance_shape.frag samples each side separately: a centered
# difference can cancel at a local extremum in a glyph's distance field.
@inline glyph_squared_partial(center::Float32, hi::Float32, lo::Float32) =
    2f0 * max((hi - center)^2, (center - lo)^2)

@inline function glyph_squared_partial(center::Float32, uv::Vec2f, delta::Vec2f,
                                      bbox::Vec4f, scale::Float32)
    hi = glyph_distance(uv + 0.5f0 * delta, bbox, 1f0)
    lo = glyph_distance(uv - 0.5f0 * delta, bbox, 1f0)
    # GLSL contracts get_distancefield(...)-center into one multiply-add.
    # Preserve that rounding in the portable shader rather than rounding the
    # scaled sample before subtracting the centre value.
    df1 = muladd(scale, hi, -center)
    df2 = muladd(-scale, lo, center)
    return 2f0 * max(df1 * df1, df2 * df2)
end

@inline glyph_aa_radius(viewport_scale::Float32, dx2::Float32, dy2::Float32) =
    viewport_scale * ANTIALIAS_RADIUS * sqrt(2f0) * sqrt(dx2 + dy2)

@inline function scatter_rectangle_distance(uv::Vec2f, scale::Vec2f, rounded::Bool)
    s = scale / min(scale[1], scale[2])
    lo = rounded ? 0.2f0 : 0f0
    hi = rounded ? 0.8f0 : 1f0
    dx = s[1] * max(lo - uv[1], uv[1] - hi)
    dy = s[2] * max(lo - uv[2], uv[2] - hi)
    radius = rounded ? s[1] * lo : 0f0
    return -(sqrt(max(0f0, dx)^2 + max(0f0, dy)^2) + min(0f0, max(dx, dy)) - radius)
end

# distance_shape.frag's ellipse(), including its five Newton iterations.
@inline function scatter_ellipse_distance(uv::Vec2f, scale::Vec2f)
    wh = scale / min(scale[1], scale[2])
    p = wh .* abs.(uv - Vec2f(0.5f0))
    wh = 0.5f0 * wh
    q = wh .* (p - wh)
    cs = q[1] < q[2] ? Vec2f(0.01f0, 1f0) : Vec2f(1f0, 0.01f0)
    cs = cs / sqrt(dot(cs, cs))
    for i in Int32(0):Int32(4)
        u = wh .* cs
        v = wh .* Vec2f(-cs[2], cs[1])
        a = dot(p - u, v)
        c = dot(p - u, u) + dot(v, v)
        b = sqrt(c * c - a * a)
        cs = Vec2f(cs[1] * b - cs[2] * a, cs[2] * b + cs[1] * a) / c
    end
    delta = p - wh .* cs
    d = sqrt(dot(delta, delta))
    scaled = Vec2f(p[1] / wh[1], p[2] / wh[2])
    return dot(scaled, scaled) > 1f0 ? -d : d
end

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
    uniform_clip_planes::AbstractVector{Vec4f}, uniform_num_clip_planes::Int32, fxaa::Int32,
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

    aa = ANTIALIAS_RADIUS
    sd = if sh == Int32(3)
        center = glyph_distance(f_uv, f_uv_bbox, f_df_scale)
        # KernelInterface's portable fragment derivatives are scalar, as in
        # footprint_texel; Metal implements those scalar intrinsics directly.
        du = Vec2f(dFdx(f_uv[1]), dFdx(f_uv[2]))
        dv = Vec2f(dFdy(f_uv[1]), dFdy(f_uv[2]))
        dx2 = glyph_squared_partial(center, f_uv, du, f_uv_bbox, f_df_scale)
        dy2 = glyph_squared_partial(center, f_uv, dv, f_uv_bbox, f_df_scale)
        aa = glyph_aa_radius(f_vp_from_u, dx2, dy2)
        cu = clamp(u, 0f0, 1f0); cv = clamp(v, 0f0, 1f0)
        bu = u - cu; bv = v - cv
        # Extend a clamped glyph only for its stroke/glow, as in GLMakie.
        center - (gpu_stroke_width > 0f0 || gpu_glow_width > 0f0 ? sqrt(bu*bu + bv*bv) : 0f0)
    elseif sh == Int32(1) || sh == Int32(2)
        scatter_rectangle_distance(f_uv, f_sp_scl, sh == Int32(2))
    elseif sh == Int32(4)
        px = u-0.5f0; py = v-0.5f0
        tx = 1.4142135f0*(px-py); ty = 1.4142135f0*(px+py)
        -max(max(abs(tx),abs(ty)) - 1f0 / (2f0 * 1.4142135f0), py)
    elseif sh == Int32(5)
        scatter_ellipse_distance(f_uv, f_sp_scl)
    elseif sh == Int32(0)
        0.5f0 - sqrt((u-0.5f0)^2 + (v-0.5f0)^2)
    else
        0f0
    end

    sd = sd * f_vp_from_u
    # With `fxaa` the edge is a hard step and FXAA smooths it afterwards, as in
    # distance_shape.frag; smoothing both ways left a halo.
    s_sw = px_per_unit * gpu_stroke_width
    inside = fxaa_or_aastep(fxaa, max(-s_sw, 0f0), sd, aa)
    color = Vec4f(f_color[1], f_color[2], f_color[3], f_color[4] * inside)

    # distance_shape.frag's stroke/stroke_fxaa, with width = -s_stroke_width.
    if s_sw != 0f0
        width = -s_sw
        st = fxaa_or_aastep(fxaa, min(width, 0f0), sd, aa) -
             fxaa_or_aastep(fxaa, max(width, 0f0), sd, aa)
        bg = sd < 0.5f0 * width ? Vec4f(f_scol[1], f_scol[2], f_scol[3], 0f0) : color
        color = bg * (1f0 - st) + f_scol * st
    end

    s_gw = px_per_unit * gpu_glow_width
    if gpu_glow_width > 0f0
        od = (abs(sd) - s_sw) / s_gw
        ga = 1f0 - od
        gi = aastep(-s_sw, sd, aa)
        glow = Vec4f(f_gcol[1], f_gcol[2], f_gcol[3], f_gcol[4] * ga)
        color = glow * (1f0 - gi) + color * gi
    end

    # A transparent fragment must not claim DEPTH: with writes on, an
    # alpha-zero corner of a glyph or marker quad occludes whatever should
    # have shown through it. Discarding is what lets a BLENDED pass use a
    # depth buffer, which is how a scene's z translation gets honoured.
    # Match fragment_output.frag: a faded-out glyph must not write depth.
    color[4] <= 0f0 && discard()
    return raster_output(color, fxaa,
                         unsafe_trunc(UInt32, inputs.pick_index + 0.5f0))
end

# =============================================================================
# Arg names — order matches shader signature exactly
# =============================================================================

# The compute-graph nodes the render object is built from; the stages then take
# the plot's `:fxaa` flag, which the render object carries (renderobject.jl).
const SCATTER_GRAPH_ARGS = (
    :gpu_positions, :gpu_colors,
    :quad_offset, :quad_scale, :marker_offset, :gpu_rotation, :sdf_uv,
    :gpu_stroke_color, :gpu_glow_color,
    :model_f32c, :f32c_scale, :gpu_transform_marker,
    :preprojection, :projection, :view, :resolution, :px_per_unit,
    :gpu_stroke_width, :gpu_glow_width, :gpu_billboard, :depth_shift,
    :gpu_atlas_width, :gpu_sdf_marker_shape,
    :uniform_clip_planes, :uniform_num_clip_planes,
)
const SCATTER_ARG_NAMES = (SCATTER_GRAPH_ARGS..., :fxaa)

# `scatter_vertex`'s native-path arity is written out as a literal, and this is
# what stops the two drifting: an argument added here without adding one there
# would leave the arg-less spelling matching nothing, on the backend that has a
# geometry stage only.
length(SCATTER_ARG_NAMES) == 26 || error(
    "SCATTER_ARG_NAMES has $(length(SCATTER_ARG_NAMES)) entries and " *
    "`scatter_vertex(args::Vararg{Any,26})` expects 26. Update the fallback's " *
    "arity in this file to match.")

# =============================================================================
# setup_scatter! — registers conversions + robj
# =============================================================================

"""One position as the shader wants it: `Vec3f`, padding a 2D point with z = 0.

Its own function so the conversion can be BROADCAST — see `gpu_positions`.
"""
@inline to_gpu_position(p) = Vec3f(Makie.to_ndim(Point3f, p, 0f0))

function setup_scatter!(screen, scene, plot, attr, backend)

    Makie.all_marker_computations!(attr)
    Makie.add_computation!(attr, scene, Val(:meshscatter_f32c_scale))
    haskey(attr, :uniform_clip_planes) || Makie.add_computation!(attr, Val(:uniform_clip_planes))

    # ── Conversion computations (gpu_* = GPU-ready type) ──

    # positions_transformed_f32c (Point2f/3f mixed) → gpu_positions (Vec3f[])
    #
    # BROADCAST, not a comprehension. A comprehension iterates, and iterating a
    # device array is scalar indexing — which GPUArrays refuses, so a
    # `scatter!` handed Mantle positions resolved to nothing and silently drew
    # not one point. Broadcast dispatches per backend instead: a `Vector` runs
    # the CPU loop and a `LavaArray` runs the GPU broadcast kernel, from the
    # same source. Same rule `meshscatter!`'s transforms are built on.
    Makie.ComputePipeline.map!(ps -> to_gpu_position.(ps),
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
    haskey(attr, :px_per_unit) || Makie.ComputePipeline.add_constant!(attr, :px_per_unit, screen.px_per_unit)
    haskey(attr, :gpu_stroke_width) || Makie.ComputePipeline.add_constant!(attr, :gpu_stroke_width,
        Float32(haskey(plot, :strokewidth) ? Makie.to_value(plot.strokewidth) : 0f0))
    haskey(attr, :gpu_glow_width) || Makie.ComputePipeline.add_constant!(attr, :gpu_glow_width,
        Float32(haskey(plot, :glowwidth) ? Makie.to_value(plot.glowwidth) : 0f0))
    haskey(attr, :depth_shift) || Makie.ComputePipeline.add_constant!(attr, :depth_shift, 0f0)
    haskey(attr, :gpu_atlas_width) || Makie.ComputePipeline.add_constant!(attr, :gpu_atlas_width, Float32(size(atlas.data, 1)))

    # ── Final robj registration — all inputs already correct type ──

    deps = collect(SCATTER_GRAPH_ARGS)

    Makie.ComputePipeline.register_computation!(attr, deps, [:trace_renderobject]) do args, changed, cached
        n = length(args.gpu_positions)
        n == 0 && return (nothing,)

        if !isnothing(cached) && cached.trace_renderobject isa RenderObject
            robj = cached.trace_renderobject
            update_robj!(robj, args, changed)
            robj.vertex_count = n
            # Re-read: the atlas may have gained a glyph since this object was
            # built, and a robj that keeps its first bindings draws the new
            # glyph blank. Cheap — `get_atlas_bindings` returns the cached
            # object untouched unless the atlas is dirty.
            robj.bindings = get_atlas_bindings(screen)
            robj.visible = true
            return (robj,)
        end

        robj = construct_robj(get_scatter_pipeline!(screen), args, SCATTER_ARG_NAMES;
                              backend, fxaa = plot_fxaa(plot), vertex_count=n)
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
