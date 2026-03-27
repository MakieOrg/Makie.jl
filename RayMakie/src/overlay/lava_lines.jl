# =============================================================================
# Lava lines rendering — direct port of GLMakie's lines.vert/geom/frag pipeline
# =============================================================================
# Single file for Lines and LineSegments: vertex, geometry, fragment shaders,
# pipeline creation, and draw_atomic methods.
#
# GLMakie data flow (no compute shaders):
#   Vertex shader: reads per-vertex buffers, applies projectionview*model, outputs varyings
#   Geometry shader: reads arrayed vertex outputs, computes miter joints, emits triangle strip
#   Fragment shader: evaluates SDF for AA, patterns, color interpolation
#
# The vertex shader receives per-vertex data via BDA arrays (indexed by vertex_index()),
# which maps to gl_VertexID in GLSL. With an index buffer, Vulkan feeds the expanded
# adjacency indices, so vertex_index() returns the actual vertex index.

# ─── Constants (matching GLMakie) ───
const AA_RADIUS = 0.8f0
const AA_THICKNESS = 4f0 * AA_RADIUS  # lines.geom uses 4*AA_RADIUS
const AA_THICKNESS_SEG = 2f0 * AA_RADIUS  # line_segment.geom uses 2*AA_RADIUS
const CAP_BUTT   = Int32(0)
const CAP_SQUARE = Int32(1)
const CAP_ROUND  = Int32(2)
const JOIN_MITER = Int32(0)
const JOIN_BEVEL = Int32(3)

# ─── Helpers ───
@inline function lines_screen_space(clip::Vec4f, px_per_unit::Float32, resolution::Vec2f)
    inv_w = 1f0 / clip[4]
    return Vec3f(
        (0.5f0 * clip[1] * inv_w + 0.5f0) * px_per_unit * resolution[1],
        (0.5f0 * clip[2] * inv_w + 0.5f0) * px_per_unit * resolution[2],
        clip[3] * inv_w)
end

@inline lines_normal(v::Vec2f) = Vec2f(-v[2], v[1])
@inline lines_sign_nz(value::Float32) = value >= 0f0 ? 1f0 : -1f0
# aastep is defined in primitives.jl — reuse it from there

# =============================================================================
# Lines Vertex Shader — port of GLMakie lines.vert
# =============================================================================
# Reads per-vertex buffers, applies projection, outputs varyings to geometry shader.
# FAST_PATH: applies projectionview*model here. Non-fast: vertex already in clip space.
#
# Outputs (via gfx_output):
#   location 0: g_color (vec4)
#   location 1: g_lastlen (float)
#   location 2: g_valid_vertex (float, passed as float to avoid int varying issues)
#   location 3: g_thickness (float)

function lines_vertex(
    vertex::LavaDeviceArray{Vec3f, 1},      # per-vertex position (f32c transformed)
    color::LavaDeviceArray{Vec4f, 1},       # per-vertex RGBA color
    lastlen::LavaDeviceArray{Float32, 1},   # cumulative screen-space length
    valid_vertex::LavaDeviceArray{Float32, 1}, # 0/1/2 validity flag
    thickness::LavaDeviceArray{Float32, 1}, # per-vertex linewidth
    projectionview::Mat4f,
    model::Mat4f,
    px_per_unit::Float32,
    depth_shift::Float32,
    # Geometry/fragment-only uniforms (must be in signature for BDA arg sharing):
    resolution::Vec2f,
    scene_origin::Vec2f,
    linecap::Int32,
    joinstyle::Int32,
    miter_limit::Float32,
    pattern_length::Float32,
)
    vid = vertex_index()
    pos = vertex[vid]

    # Project: projectionview * model * position
    clip = projectionview * model * Vec4f(pos[1], pos[2], pos[3], 1f0)
    clip = Vec4f(clip[1], clip[2], clip[3] + clip[4] * depth_shift, clip[4])
    set_position!(clip)

    # Forward per-vertex data as varyings
    gfx_output(0, color[vid])
    gfx_output(1, px_per_unit * lastlen[vid])
    gfx_output(2, valid_vertex[vid])
    gfx_output(3, px_per_unit * thickness[vid])
    return nothing
end

# =============================================================================
# Lines Geometry Shader — port of GLMakie lines.geom
# =============================================================================
# lines_adjacency input (4 vertices per invocation): prev, p1, p2, next
# Computes miter/bevel joints, extrusions, SDFs. Emits triangle strip (4 verts).

function lines_geometry(
    vertex::LavaDeviceArray{Vec3f, 1},
    color::LavaDeviceArray{Vec4f, 1},
    lastlen::LavaDeviceArray{Float32, 1},
    valid_vertex::LavaDeviceArray{Float32, 1},
    thickness::LavaDeviceArray{Float32, 1},
    projectionview::Mat4f,
    model::Mat4f,
    px_per_unit::Float32,
    depth_shift::Float32,
    # Uniforms only used in geometry/fragment:
    resolution::Vec2f,
    scene_origin::Vec2f,
    linecap::Int32,
    joinstyle::Int32,
    miter_limit::Float32,
    pattern_length::Float32,
)
    # Read vertex shader outputs for 4 input vertices (0-based indices)
    # gl_in[i].gl_Position
    clip_p0 = geom_input_position(0)
    clip_p1 = geom_input_position(1)
    clip_p2 = geom_input_position(2)
    clip_p3 = geom_input_position(3)

    # Per-vertex varyings from vertex shader
    g_color_0 = geom_input(Vec4f, 0, 0)
    g_color_1 = geom_input(Vec4f, 0, 1)
    g_color_2 = geom_input(Vec4f, 0, 2)
    g_color_3 = geom_input(Vec4f, 0, 3)

    g_lastlen_1 = geom_input(Float32, 1, 1)

    g_valid_0 = geom_input(Float32, 2, 0)
    g_valid_1 = geom_input(Float32, 2, 1)
    g_valid_2 = geom_input(Float32, 2, 2)
    g_valid_3 = geom_input(Float32, 2, 3)

    g_thickness_1 = geom_input(Float32, 3, 1)
    g_thickness_2 = geom_input(Float32, 3, 2)

    # Skip zero-width lines
    if g_thickness_1 == 0f0 && g_thickness_2 == 0f0
        return nothing
    end

    # Valid vertex logic (matching GLMakie lines.geom)
    gvv0 = unsafe_trunc(Int32, g_valid_0 + 0.5f0)
    gvv1 = unsafe_trunc(Int32, g_valid_1 + 0.5f0)
    gvv2 = unsafe_trunc(Int32, g_valid_2 + 0.5f0)
    gvv3 = unsafe_trunc(Int32, g_valid_3 + 0.5f0)

    # TODO: g_id comparison — for now use index-based check (always different)
    isvalid_0 = gvv0 > Int32(0)
    isvalid_1 = (gvv1 > Int32(0)) && !((gvv0 == Int32(0)) && (gvv1 == Int32(2)))
    isvalid_2 = (gvv2 > Int32(0)) && !((gvv2 == Int32(2)) && (gvv3 == Int32(0)))
    isvalid_3 = gvv3 > Int32(0)

    if !isvalid_1 || !isvalid_2
        return nothing
    end

    # Colors for this segment
    f_color1 = g_color_1
    f_color2 = g_color_2

    # Clip handling for behind-camera vertices
    v1_clip = clip_p2 - clip_p1
    if clip_p1[4] < 0f0
        isvalid_0 = false
        t_clip = (-clip_p1[4] - clip_p1[3]) / (v1_clip[3] + v1_clip[4])
        clip_p1 = clip_p1 + v1_clip * t_clip
        f_color1 = f_color1 + (f_color2 - f_color1) * t_clip
    end
    if clip_p2[4] < 0f0
        isvalid_3 = false
        t_clip = (-clip_p2[4] - clip_p2[3]) / (v1_clip[3] + v1_clip[4])
        clip_p2 = clip_p2 + v1_clip * t_clip
        f_color2 = f_color2 + (f_color2 - f_color1) * t_clip
    end

    # Transform to screen space
    p0 = lines_screen_space(clip_p0, px_per_unit, resolution)
    p1 = lines_screen_space(clip_p1, px_per_unit, resolution)
    p2 = lines_screen_space(clip_p2, px_per_unit, resolution)
    p3 = lines_screen_space(clip_p3, px_per_unit, resolution)

    halfwidth = 0.5f0 * max(AA_RADIUS, g_thickness_1)

    # Segment direction and length
    v1_3d = p2 - p1
    segment_length = sqrt(v1_3d[1]^2 + v1_3d[2]^2)
    inv_seg = segment_length > 1f-10 ? 1f0 / segment_length : 0f0
    v1 = v1_3d * inv_seg

    # Adjacent segment directions
    v0 = Vec2f(v1[1], v1[2])
    v2 = Vec2f(v1[1], v1[2])
    if p1 != p0 && isvalid_0
        d10 = Vec2f(p1[1] - p0[1], p1[2] - p0[2])
        len10 = norm(d10)
        if len10 > 1f-10; v0 = d10 / len10; end
    end
    if p3 != p2 && isvalid_3
        d23 = Vec2f(p3[1] - p2[1], p3[2] - p2[2])
        len23 = norm(d23)
        if len23 > 1f-10; v2 = d23 / len23; end
    end

    # Normals
    n0 = lines_normal(v0)
    n1 = lines_normal(Vec2f(v1[1], v1[2]))
    n2 = lines_normal(v2)

    # Miter normals
    miter_x = dot(v0, Vec2f(v1[1], v1[2]))
    miter_y = dot(Vec2f(v1[1], v1[2]), v2)

    miter_n1 = if miter_x < 0f0
        diff = v0 - Vec2f(v1[1], v1[2])
        l = norm(diff)
        l > 1f-10 ? lines_sign_nz(dot(v0, n1)) * diff / l : n1
    else
        s = n0 + n1; l = norm(s); l > 1f-10 ? s / l : n1
    end

    miter_n2 = if miter_y < 0f0
        diff = Vec2f(v1[1], v1[2]) - v2
        l = norm(diff)
        l > 1f-10 ? lines_sign_nz(dot(Vec2f(v1[1], v1[2]), n2)) * diff / l : n2
    else
        s = n1 + n2; l = norm(s); l > 1f-10 ? s / l : n1
    end

    # Truncation check
    is_trunc_0 = joinstyle == JOIN_BEVEL ? miter_x < 0.99f0 : miter_x < miter_limit
    is_trunc_1 = joinstyle == JOIN_BEVEL ? miter_y < 0.99f0 : miter_y < miter_limit

    # Miter vectors and offsets
    miter_v1 = Vec2f(miter_n1[2], -miter_n1[1])
    miter_v2 = Vec2f(miter_n2[2], -miter_n2[1])
    miter_offset1 = dot(miter_n1, n1)
    miter_offset2 = dot(miter_n2, n1)

    # Extrusion
    v1_2d = Vec2f(v1[1], v1[2])
    ext_0p, ext_0n = if is_trunc_0
        e = -abs(miter_offset1 / dot(miter_v1, n1)); (e, e)
    else
        e = dot(miter_n1, v1_2d) / miter_offset1; (e, -e)
    end
    ext_1p, ext_1n = if is_trunc_1
        e = abs(miter_offset2 / dot(miter_n2, v1_2d)); (e, e)
    else
        e = dot(miter_n2, v1_2d) / miter_offset2; (e, -e)
    end

    # Shape factor
    shape_n = (isvalid_0 && isvalid_3) || (linecap == CAP_BUTT) ?
        max(0f0, segment_length / max(segment_length, (halfwidth + AA_THICKNESS) * (ext_0n - ext_1n))) : 1f0
    shape_p = (isvalid_0 && isvalid_3) || (linecap == CAP_BUTT) ?
        max(0f0, segment_length / max(segment_length, (halfwidth + AA_THICKNESS) * (ext_0p - ext_1p))) : 1f0

    # Flat outputs
    f_linepoints_xy = isvalid_0 && is_trunc_0 ?
        Vec2f(p1[1] + px_per_unit * scene_origin[1], p1[2] + px_per_unit * scene_origin[2]) :
        Vec2f(-1f12, -1f12)
    f_miter_vecs_xy = isvalid_0 && is_trunc_0 ? Vec2f(-miter_v1[1], -miter_v1[2]) :
        Vec2f(-0.70710677f0, -0.70710677f0)
    f_linepoints_zw = isvalid_3 && is_trunc_1 ?
        Vec2f(p2[1] + px_per_unit * scene_origin[1], p2[2] + px_per_unit * scene_origin[2]) :
        Vec2f(-1f12, -1f12)
    f_miter_vecs_zw = isvalid_3 && is_trunc_1 ? miter_v2 : Vec2f(-0.70710677f0, -0.70710677f0)

    f_extrusion_x = !isvalid_0 ? 0f0 : 1f12
    f_extrusion_y = !isvalid_3 ? 0f0 : 1f12
    f_capmode_x = isvalid_0 ? joinstyle : linecap
    f_capmode_y = isvalid_3 ? joinstyle : linecap
    f_alpha_weight = min(1f0, g_thickness_1 / AA_RADIUS)
    f_cumulative_length = g_lastlen_1
    f_pattern_overwrite = Vec4f(-1f12, 1f0, 1f12, 1f0)

    # Emit 4 vertices (triangle strip): x=0,1 (p1,p2), y=0,1 (-n,+n)
    for x in Int32(0):Int32(1)
        for y in Int32(0):Int32(1)
            ext_y = y == Int32(0) ?
                (x == Int32(0) ? ext_0n : ext_1n) :
                (x == Int32(0) ? ext_0p : ext_1p)
            is_trunc = x == Int32(0) ? is_trunc_0 : is_trunc_1
            isvalid_far = x == Int32(0) ? isvalid_0 : isvalid_3
            sf = y == Int32(0) ? shape_n : shape_p
            side = Float32(2 * y - 1)
            dir = Float32(2 * x - 1)

            offset = if is_trunc || !isvalid_far
                sf * Vec3f(
                    (halfwidth * max(1f0, abs(ext_y)) + AA_THICKNESS) * dir * v1[1] + side * (halfwidth + AA_THICKNESS) * n1[1],
                    (halfwidth * max(1f0, abs(ext_y)) + AA_THICKNESS) * dir * v1[2] + side * (halfwidth + AA_THICKNESS) * n1[2],
                    0f0)
            else
                mn = x == Int32(0) ? miter_n1 : miter_n2
                mo = x == Int32(0) ? miter_offset1 : miter_offset2
                sf * side * (halfwidth + AA_THICKNESS) / mo * Vec3f(mn[1], mn[2], 0f0)
            end

            bp = x == Int32(0) ? p1 : p2
            vp = bp + offset
            ndc_x = 2f0 * vp[1] / (px_per_unit * resolution[1]) - 1f0
            ndc_y = 2f0 * vp[2] / (px_per_unit * resolution[2]) - 1f0
            set_position!(Vec4f(ndc_x, ndc_y, vp[3], 1f0))

            VP1 = Vec2f(vp[1] - p1[1], vp[2] - p1[2])
            VP2 = Vec2f(vp[1] - p2[1], vp[2] - p2[2])

            quad_sdf = Vec3f(dot(VP1, -v1_2d), dot(VP2, v1_2d), dot(VP1, n1))
            trunc_x = !is_trunc_0 ? -1f0 :
                dot(VP1, lines_sign_nz(dot(miter_n1, -v1_2d)) * miter_n1) - halfwidth * abs(miter_offset1)
            trunc_y = !is_trunc_1 ? -1f0 :
                dot(VP2, lines_sign_nz(dot(miter_n2, v1_2d)) * miter_n2) - halfwidth * abs(miter_offset2)

            f_linestart = sf * halfwidth * ext_y
            f_linelength = max(1f0, segment_length - sf * halfwidth * (
                (x == Int32(0) ? ext_0p : ext_1p) - (x == Int32(0) ? ext_0n : ext_1n)))

            # Interpolated varyings
            gfx_output(0, quad_sdf)                   # f_quad_sdf
            gfx_output(1, Vec2f(trunc_x, trunc_y))    # f_truncation
            gfx_output(2, f_linestart)                 # f_linestart
            gfx_output(3, f_linelength)                # f_linelength

            # Flat varyings
            gfx_output_flat(4, Vec2f(f_extrusion_x, f_extrusion_y))
            gfx_output_flat(5, halfwidth)
            gfx_output_flat(6, f_pattern_overwrite)
            gfx_output_flat(7, f_color1)
            gfx_output_flat(8, f_color2)
            gfx_output_flat(9, f_alpha_weight)
            gfx_output_flat(10, f_cumulative_length)
            gfx_output_flat(11, Vec2f(Float32(f_capmode_x), Float32(f_capmode_y)))
            gfx_output_flat(12, Vec4f(f_linepoints_xy[1], f_linepoints_xy[2],
                                       f_linepoints_zw[1], f_linepoints_zw[2]))
            gfx_output_flat(13, Vec4f(f_miter_vecs_xy[1], f_miter_vecs_xy[2],
                                       f_miter_vecs_zw[1], f_miter_vecs_zw[2]))
            emit_vertex!()
        end
    end
    end_primitive!()
    return nothing
end

# =============================================================================
# Lines Fragment Shader — port of GLMakie lines.frag
# =============================================================================
# Shared by Lines and LineSegments.

function lines_fragment(
    # BDA args (same signature as vertex/geometry — Lava passes all args to all stages)
    vertex::LavaDeviceArray{Vec3f, 1},
    color::LavaDeviceArray{Vec4f, 1},
    lastlen::LavaDeviceArray{Float32, 1},
    valid_vertex::LavaDeviceArray{Float32, 1},
    thickness::LavaDeviceArray{Float32, 1},
    projectionview::Mat4f,
    model::Mat4f,
    px_per_unit::Float32,
    depth_shift::Float32,
    resolution::Vec2f,
    scene_origin::Vec2f,
    linecap::Int32,
    joinstyle::Int32,
    miter_limit::Float32,
    pattern_length::Float32,
)
    # Read interpolated varyings
    f_quad_sdf = gfx_input(Vec3f, 0)
    f_truncation = gfx_input(Vec2f, 1)
    f_linestart = gfx_input(Float32, 2)
    f_linelength = gfx_input(Float32, 3)

    # Read flat varyings
    f_extrusion = gfx_input_flat(Vec2f, 4)
    f_linewidth = gfx_input_flat(Float32, 5)
    f_pattern_overwrite = gfx_input_flat(Vec4f, 6)
    f_color1 = gfx_input_flat(Vec4f, 7)
    f_color2 = gfx_input_flat(Vec4f, 8)
    f_alpha_weight = gfx_input_flat(Float32, 9)
    f_cumulative_length = gfx_input_flat(Float32, 10)
    f_capmode_v = gfx_input_flat(Vec2f, 11)
    f_linepoints = gfx_input_flat(Vec4f, 12)
    f_miter_vecs = gfx_input_flat(Vec4f, 13)

    f_capmode_x = unsafe_trunc(Int32, f_capmode_v[1] + 0.5f0)
    f_capmode_y = unsafe_trunc(Int32, f_capmode_v[2] + 0.5f0)

    # Discard on truncated joint
    frag_x = frag_coord_x()
    frag_y = frag_coord_y()
    discard_sdf1 = (frag_x - f_linepoints[1]) * f_miter_vecs[1] +
                   (frag_y - f_linepoints[2]) * f_miter_vecs[2]
    discard_sdf2 = (frag_x - f_linepoints[3]) * f_miter_vecs[3] +
                   (frag_y - f_linepoints[4]) * f_miter_vecs[4]

    if (f_quad_sdf[1] > 0f0 && discard_sdf1 > 0f0) ||
       (f_quad_sdf[2] > 0f0 && discard_sdf2 >= 0f0)
        gfx_output(0, Vec4f(0f0, 0f0, 0f0, 0f0))
        return nothing
    end

    # SDF computation
    sdf = if f_capmode_x == CAP_ROUND
        min(sqrt(f_quad_sdf[1]^2 + f_quad_sdf[3]^2) - f_linewidth, f_quad_sdf[1])
    elseif f_capmode_x == CAP_SQUARE
        f_quad_sdf[1] - f_linewidth
    else
        max(f_quad_sdf[1] - f_extrusion[1], f_truncation[1])
    end

    sdf = if f_capmode_y == CAP_ROUND
        max(sdf, min(sqrt(f_quad_sdf[2]^2 + f_quad_sdf[3]^2) - f_linewidth, f_quad_sdf[2]))
    elseif f_capmode_y == CAP_SQUARE
        max(sdf, f_quad_sdf[2] - f_linewidth)
    else
        max(max(sdf, f_quad_sdf[2] - f_extrusion[2]), f_truncation[2])
    end

    # Width SDF
    sdf = max(sdf, abs(f_quad_sdf[3]) - f_linewidth)

    # Inner truncation
    sdf = max(sdf, min(f_quad_sdf[1] + 1f0, 100f0 * discard_sdf1 - 1f0))
    sdf = max(sdf, min(f_quad_sdf[2] + 1f0, 100f0 * discard_sdf2 - 1f0))

    # Pattern SDF
    if pattern_length > 0f0
        uv_x = (f_cumulative_length - f_quad_sdf[1] + 0.5f0) / (2f0 * f_linewidth * pattern_length)
        w = 2f0 * f_linewidth
        pattern_val = sample_texture_2d(UInt32(0), uv_x, 0.5f0, UInt32(0))

        pattern_sdf = if uv_x <= f_pattern_overwrite[1]
            sdf_ow = w * pattern_length * (f_pattern_overwrite[1] - uv_x)
            edge_sample = w * sample_texture_2d(UInt32(0), f_pattern_overwrite[1], 0.5f0, UInt32(0))
            sdf_offset = max(f_pattern_overwrite[2] * edge_sample, -AA_RADIUS)
            f_pattern_overwrite[2] * (sdf_ow + sdf_offset)
        elseif uv_x >= f_pattern_overwrite[3]
            sdf_ow = w * pattern_length * (uv_x - f_pattern_overwrite[3])
            edge_sample = w * sample_texture_2d(UInt32(0), f_pattern_overwrite[3], 0.5f0, UInt32(0))
            sdf_offset = max(f_pattern_overwrite[4] * edge_sample, -AA_RADIUS)
            f_pattern_overwrite[4] * (sdf_ow + sdf_offset)
        else
            w * pattern_val
        end
        sdf = max(sdf, pattern_sdf)
    end

    # Color interpolation
    factor = clamp((-f_quad_sdf[1] - f_linestart) / f_linelength, 0f0, 1f0)
    col = f_color1 + factor * (f_color2 - f_color1)
    alpha = col[4] * f_alpha_weight * aastep(0f0, -sdf)

    # Premultiply
    gfx_output(0, Vec4f(col[1] * alpha, col[2] * alpha, col[3] * alpha, alpha))
    return nothing
end

# =============================================================================
# Pipeline creation
# =============================================================================

function get_lines_pipeline!(screen)
    get!(screen.gfx_pipelines, :lines) do
        GraphicsPipeline(;
            vertex = lines_vertex,
            geometry = (lines_geometry, GeometryConfig(
                input = LineListAdjacency(), output = TriangleStrip(), max_vertices = 4)),
            fragment = lines_fragment,
            blend = Premultiplied(),
            topology = LineListAdjacency(),
            cull = NoCull(),
            depth = DepthOff(),
        )
    end
end

# TODO: line_segment vertex/geometry shaders (simpler: no joints, GL_LINES topology)
# For now, LineSegments can reuse the joined lines pipeline with dummy adjacency.

# =============================================================================
# CPU-side data preparation (matching GLMakie plot-primitives.jl)
# =============================================================================

"""
Generate adjacency indices and valid_vertex flags for GL_LINE_STRIP_ADJACENCY.
Direct port of GLMakie's `generate_indices`. Returns 0-based indices for Vulkan index buffer.
"""
function lines_generate_indices(ps, indices=UInt32[], valid=Float32[])
    empty!(indices)
    resize!(valid, length(ps))

    if length(ps) < 2
        valid .= 0f0
        return (indices, valid)
    end

    sizehint!(indices, length(ps) + 2)
    last_start_pos = eltype(ps)(NaN)
    last_start_idx = -1

    for (i, p) in enumerate(ps)
        not_nan = isfinite(p)
        valid[i] = Float32(not_nan)

        if not_nan
            if last_start_idx == -1
                push!(indices, UInt32(max(1, i - 1)))
                last_start_idx = length(indices) + 1
                last_start_pos = p
            end
            push!(indices, UInt32(i))
        elseif (last_start_idx != -1) &&
               (length(indices) - last_start_idx > 2) &&
               (ps[max(1, i - 1)] ≈ last_start_pos)
            indices[last_start_idx - 1] = UInt32(max(1, i - 2))
            push!(indices, UInt32(indices[last_start_idx + 1]), UInt32(i))
            valid[i - 2] = 2f0
            valid[indices[last_start_idx + 1]] = 2f0
            last_start_idx = -1
        elseif last_start_idx != -1
            push!(indices, UInt32(i))
            last_start_idx = -1
        end
    end

    if (last_start_idx != -1) && (length(indices) - last_start_idx > 2) && (ps[end] ≈ last_start_pos)
        indices[last_start_idx - 1] = UInt32(length(ps) - 1)
        push!(indices, UInt32(indices[last_start_idx + 1]))
        valid[end - 1] = 2f0
        valid[indices[last_start_idx + 1]] = 2f0
    elseif last_start_idx != -1
        push!(indices, UInt32(length(ps)))
    end

    # Convert to 0-based for Vulkan index buffer
    indices .-= UInt32(1)

    return (indices, valid)
end

"""
Compute cumulative screen-space lengths for pattern UV (port of GLMakie sumlengths).
"""
function lines_sumlengths(points, resolution)
    f(p::VecTypes{4}) = p[Vec(1, 2)] / p[4]
    f(p::VecTypes) = p[Vec(1, 2)]
    invalid(p::VecTypes{4}) = p[4] <= 1.0f-6
    invalid(p::VecTypes) = false

    T = Float32
    result = zeros(T, length(points))
    for (i, idx) in enumerate(eachindex(points))
        idx0 = max(idx - 1, 1)
        p1, p2 = points[idx0], points[idx]
        if any(map(isnan, p1)) || any(map(isnan, p2)) || invalid(p1) || invalid(p2)
            result[i] = 0f0
        else
            result[i] = result[max(i - 1, 1)] + 0.5f0 * norm(resolution .* (f(p1) - f(p2)))
        end
    end
    return result
end

function sample_colormap(cmap, v::Float32, cmin::Float32, cmax::Float32, n_cmap::Int)
    nv = cmax > cmin ? clamp((v - cmin) / (cmax - cmin), 0f0, 1f0) : 0.5f0
    idx = clamp(nv * (n_cmap - 1) + 1, 1, n_cmap)
    i0 = floor(Int, idx); i1 = min(i0 + 1, n_cmap); t = idx - i0
    c0 = RGBA{Float32}(cmap[i0]); c1 = RGBA{Float32}(cmap[i1])
    Vec4f(c0.r*(1-t)+c1.r*t, c0.g*(1-t)+c1.g*t, c0.b*(1-t)+c1.b*t, c0.alpha*(1-t)+c1.alpha*t)
end

"""Resolve per-vertex RGBA colors from plot attributes."""
function lines_resolve_colors(plot, n)

    color = Makie.to_value(plot.color)
    if color isa AbstractVector{<:Colorant}
        return Vec4f[let c = RGBA{Float32}(color[min(i, length(color))]); Vec4f(c.r, c.g, c.b, c.alpha) end for i in 1:n]
    elseif color isa Colorant
        c = RGBA{Float32}(color)
        return fill(Vec4f(c.r, c.g, c.b, c.alpha), n)
    elseif color isa AbstractVector{<:Number} && haskey(plot, :scaled_color)
        sc = Makie.to_value(plot.scaled_color)
        cmap = Makie.to_value(plot.alpha_colormap)
        cr = Makie.to_value(plot.scaled_colorrange)
        cmin, cmax = Float32(cr[1]), Float32(cr[2])
        n_cmap = length(cmap)
        return Vec4f[sample_colormap(cmap, Float32(sc[min(i, length(sc))]), cmin, cmax, n_cmap) for i in 1:n]
    else
        c = RGBA{Float32}(Makie.to_color(color))
        return fill(Vec4f(c.r, c.g, c.b, c.alpha), n)
    end
end

"""Resolve per-vertex linewidths."""
function lines_resolve_thickness(plot, n)

    lw = Makie.to_value(plot.linewidth)
    if lw isa AbstractVector
        return Float32[Float32(lw[min(i, length(lw))]) for i in 1:n]
    else
        return fill(Float32(lw), n)
    end
end
