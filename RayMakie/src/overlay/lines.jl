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

# What the vertex stage hands the geometry stage, per input vertex. A
# `LineStripAdjacency` primitive is four of them, read back as `prim.<name>[i]`.
const LINES_VERTEX_OUT = (colour = Vec4f, lastlen = Float32,
                          valid = Float32, thickness = Float32)

# What the geometry stage hands the fragment stage. The first four vary across
# the quad; the ten `Flat` ones are the SEGMENT's and are computed once before the
# emit loop, so they are written once per triangle instead of four times.
# GLMakie's lines.geom wrote all fourteen per vertex because a geometry shader
# offers no other way, and this file did the same through `gfx_output_flat`.
const LINES_GEOM_OUT = (quad_sdf = Vec3f, truncation = Vec2f, linestart = Float32,
                        linelength = Float32,
                        extrusion = Flat{Vec2f}, linewidth = Flat{Float32},
                        pattern_overwrite = Flat{Vec4f}, color1 = Flat{Vec4f},
                        color2 = Flat{Vec4f}, alpha_weight = Flat{Float32},
                        cumulative_length = Flat{Float32}, capmode = Flat{Vec2f},
                        linepoints = Flat{Vec4f}, miter_vecs = Flat{Vec4f})

# The index is a PARAMETER, and the arg-less spelling below hands it the builtin.
#
# Both are needed and they are the same number. Where the geometry stage exists
# the rasteriser supplies the index and there is nothing to pass; where it does
# not, `Mantle.lower_geometry_to_mesh` runs this body once per input vertex of a
# primitive from ONE mesh invocation, at indices it computes out of the index
# buffer — and a zero-argument builtin cannot answer differently on each of those
# calls. `KernelInterface.VertexIndex`'s docstring has the rest.
#
# The fallback's arity is fixed rather than `args...`: at 15 it cannot match its
# own forwarded call, so a signature that drifts out of step with
# `plots/lines.jl`'s `arg_names` is a `MethodError` naming this function instead of
# a recursion that overflows inside a shader compile.
lines_vertex(args::Vararg{Any,15}) = lines_vertex(VertexIndex(vertex_index()), args...)

function lines_vertex(
    vertexid::VertexIndex,
    vertex::AbstractVector{Vec3f},      # per-vertex position (f32c transformed)
    color::AbstractVector{Vec4f},       # per-vertex RGBA color
    lastlen::AbstractVector{Float32},   # cumulative screen-space length
    valid_vertex::AbstractVector{Float32}, # 0/1/2 validity flag
    thickness::AbstractVector{Float32}, # per-vertex linewidth
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
    vid = vertexid.value
    pos = vertex[vid]

    # Project: projectionview * model * position
    clip = projectionview * model * Vec4f(pos[1], pos[2], pos[3], 1f0)
    clip = Vec4f(clip[1], clip[2], clip[3] + clip[4] * depth_shift, clip[4])
    return (position = gl_to_clip_depth(clip),
            colour = color[vid],
            lastlen = px_per_unit * lastlen[vid],
            valid = valid_vertex[vid],
            thickness = px_per_unit * thickness[vid])
end

# =============================================================================
# Lines Geometry Shader — port of GLMakie lines.geom
# =============================================================================
# lines_adjacency input (4 vertices per invocation): prev, p1, p2, next
# Computes miter/bevel joints, extrusions, SDFs. Emits triangle strip (4 verts).

function lines_geometry(
    gs, prim,
    vertex::AbstractVector{Vec3f},
    color::AbstractVector{Vec4f},
    lastlen::AbstractVector{Float32},
    valid_vertex::AbstractVector{Float32},
    thickness::AbstractVector{Float32},
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
    # Four input vertices: the segment plus a neighbour on each side. One-based
    # here, where `geom_input_position` counted from zero.
    clip_p0 = prim.position[1]
    clip_p1 = prim.position[2]
    clip_p2 = prim.position[3]
    clip_p3 = prim.position[4]

    # Per-vertex varyings from vertex shader
    g_color_0 = prim.colour[1]
    g_color_1 = prim.colour[2]
    g_color_2 = prim.colour[3]
    g_color_3 = prim.colour[4]

    g_lastlen_1 = prim.lastlen[2]

    g_valid_0 = prim.valid[1]
    g_valid_1 = prim.valid[2]
    g_valid_2 = prim.valid[3]
    g_valid_3 = prim.valid[4]

    g_thickness_1 = prim.thickness[2]
    g_thickness_2 = prim.thickness[3]

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

    # The segment's own values. They are `Flat` in `LINES_GEOM_OUT`, so the
    # emitter writes them once per triangle rather than once per vertex; the loop
    # below carries them along, it does not recompute them.
    flat = (extrusion = Vec2f(f_extrusion_x, f_extrusion_y),
            linewidth = halfwidth,
            pattern_overwrite = f_pattern_overwrite,
            color1 = f_color1,
            color2 = f_color2,
            alpha_weight = f_alpha_weight,
            cumulative_length = f_cumulative_length,
            capmode = Vec2f(Float32(f_capmode_x), Float32(f_capmode_y)),
            linepoints = Vec4f(f_linepoints_xy[1], f_linepoints_xy[2],
                               f_linepoints_zw[1], f_linepoints_zw[2]),
            miter_vecs = Vec4f(f_miter_vecs_xy[1], f_miter_vecs_xy[2],
                               f_miter_vecs_zw[1], f_miter_vecs_zw[2]))

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
            pos = Vec4f(ndc_x, ndc_y, vp[3], 1f0)

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

            emit!(gs, merge((position = pos,
                             quad_sdf = quad_sdf,
                             truncation = Vec2f(trunc_x, trunc_y),
                             linestart = f_linestart,
                             linelength = f_linelength), flat))
        end
    end
    endprimitive!(gs)
    return nothing
end

# =============================================================================
# Lines Fragment Shader — port of GLMakie lines.frag
# =============================================================================
# Shared by Lines and LineSegments.

function lines_fragment(
    inputs,
    # BDA args (same signature as vertex/geometry — Lava passes all args to all stages)
    vertex::AbstractVector{Vec3f},
    color::AbstractVector{Vec4f},
    lastlen::AbstractVector{Float32},
    valid_vertex::AbstractVector{Float32},
    thickness::AbstractVector{Float32},
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
    f_quad_sdf = inputs.quad_sdf
    f_truncation = inputs.truncation
    f_linestart = inputs.linestart
    f_linelength = inputs.linelength

    # Read flat varyings
    # Flat or not makes no difference HERE: everything arrives by name, and which
    # plane it came from is the pipeline's business.
    f_extrusion = inputs.extrusion
    f_linewidth = inputs.linewidth
    f_pattern_overwrite = inputs.pattern_overwrite
    f_color1 = inputs.color1
    f_color2 = inputs.color2
    f_alpha_weight = inputs.alpha_weight
    f_cumulative_length = inputs.cumulative_length
    f_capmode_v = inputs.capmode
    f_linepoints = inputs.linepoints
    f_miter_vecs = inputs.miter_vecs

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
        return Vec4f(0f0, 0f0, 0f0, 0f0)
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
    # A transparent fragment must not claim DEPTH: with writes on, an
    # alpha-zero corner of a glyph or marker quad occludes whatever should
    # have shown through it. Discarding is what lets a BLENDED pass use a
    # depth buffer, which is how a scene's z translation gets honoured.
    alpha < 1f-3 && discard()
    return Vec4f(col[1] * alpha, col[2] * alpha, col[3] * alpha, alpha)
end

# =============================================================================
# Pipeline creation
# =============================================================================

function get_lines_pipeline!(screen)
    get!(screen.gfx_pipelines, :lines) do
        GraphicsPipeline(;
            vertex = VertexShader(lines_vertex; outputs = LINES_VERTEX_OUT),
            geometry = GeometryShader(lines_geometry; outputs = LINES_GEOM_OUT,
                                      input = LineStripAdjacency(),
                                      output = TriangleStrip(), max_vertices = 4),
            fragment = FragmentShader(lines_fragment; textures = 1),
            blend = Premultiplied(),
            # STRIP, not list. `lines_generate_indices` is a port of GLMakie's
            # `generate_indices`, which builds a GL_LINE_STRIP_ADJACENCY list:
            # four points become `0 0 1 2 3 3`, and the strip form slides a
            # 4-wide window over it to get one primitive per segment. Under the
            # list form those six indices are a single primitive, so only the
            # first segment of any polyline was ever drawn — a 4-point loop
            # rendered as one edge, a sine curve as dashes.
            topology = LineStripAdjacency(),
            cull = NoCull(),
            depth = DepthLessEq(),
        )
    end
end

"""
The same stages as [`get_lines_pipeline!`](@ref) over a LIST of segments.

`linesegments` gives every segment its own four indices — `i1 i1 i2 i2`, the
adjacency form with each end doubled because a segment has no neighbour to miter
against — and four indices per primitive with none shared is exactly
`LineListAdjacency`.

Drawn as a STRIP, which is what this used to share with the joined pipeline, the
4-wide window also lands on every BOUNDARY between two segments: indices
`i1 i1 i2 i2 j1 j1 j2 j2` yield a primitive whose middle pair is `i2, j1`, and a
line is drawn from the end of one segment to the start of the next. In a plot that
is every grid line joined corner to corner by a diagonal, and it is not specific to
one backend: the strip window is what both APIs mean by the topology.
"""
function get_line_segments_pipeline!(screen)
    get!(screen.gfx_pipelines, :line_segments) do
        GraphicsPipeline(;
            vertex = VertexShader(lines_vertex; outputs = LINES_VERTEX_OUT),
            geometry = GeometryShader(lines_geometry; outputs = LINES_GEOM_OUT,
                                      input = LineListAdjacency(),
                                      output = TriangleStrip(), max_vertices = 4),
            fragment = FragmentShader(lines_fragment; textures = 1),
            blend = Premultiplied(),
            topology = LineListAdjacency(),
            cull = NoCull(),
            depth = DepthLessEq(),
        )
    end
end

# TODO: line_segment vertex/geometry shaders (simpler: no joints, GL_LINES topology)
# For now, LineSegments reuses the joined lines STAGES over the list topology above.

# =============================================================================
# CPU-side data preparation (matching GLMakie plot-primitives.jl)
# =============================================================================

"""
Generate adjacency indices and valid_vertex flags for GL_LINE_STRIP_ADJACENCY.
Direct port of GLMakie's `generate_indices`. Returns 0-based indices for Vulkan index buffer.
"""
# ── Line topology, computed where the positions already live ─────────────────
#
# Both passes below were sequential host loops, and a device position array was
# copied back for them — which defeats the point of the positions being on the
# device at all. Each is now a scan plus a scatter, and that is ONE
# implementation for both cases: on a `Vector` the scans are Base's and the
# kernels run on KernelAbstractions' CPU backend; on a device array the scans
# are Mantle's (`array/accumulate.jl`) and the kernels run on the GPU. Nothing
# branches on the array type — `similar` decides where every intermediate
# lands, the same bargain `meshscatter.jl` makes with broadcast.
#
# The sequential version is not gone: it is the reference the tests check
# against, in `test_lines_topology.jl`, which is where a second implementation
# belongs.
#
# Flags are `Int32` rather than `Bool` because these arrays are device storage
# and a one-byte element type is a question about the backend nobody needs to
# ask here.

"""Per-point validity and run-start flags, in one pass over the positions."""
@kernel function lines_flags_kernel!(valid, startflag, @Const(ps))
    i = @index(Global, Linear)
    @inbounds begin
        v = isfinite(ps[i])
        valid[i] = v ? Int32(1) : Int32(0)
        prev = i > 1 ? isfinite(ps[i - 1]) : false
        startflag[i] = (v && !prev) ? Int32(1) : Int32(0)
    end
end

"""First and last index of every run, scattered by the run's ordinal."""
@kernel function lines_runbounds_kernel!(starts, ends, @Const(ordinal), @Const(valid))
    i = @index(Global, Linear)
    n = length(valid)
    @inbounds if valid[i] != Int32(0)
        r = ordinal[i]
        (i == 1 || valid[i - 1] == Int32(0)) && (starts[r] = Int32(i))
        (i == n || valid[i + 1] == Int32(0)) && (ends[r] = Int32(i))
    end
end

"""
Whether each run closes on itself, and how many index entries it emits.

A run of `L` points costs `L + 2` — the strip, plus an adjacency vertex at each
end for the joins. A CLOSED run (more than three points, last ≈ first) costs one
more in the middle of the array, because it re-emits its second vertex so the
join at the seam has the neighbour it needs; a closed run ending at the last
position has no trailing adjacency to emit and stays at `L + 2`.
"""
@kernel function lines_runlengths_kernel!(outlen, isloop, @Const(starts), @Const(ends),
                                          @Const(ps), n::Int32)
    r = @index(Global, Linear)
    @inbounds begin
        s = starts[r]; e = ends[r]
        L = e - s + Int32(1)
        loop = (L > Int32(3)) && (ps[e] ≈ ps[s])
        isloop[r] = loop ? Int32(1) : Int32(0)
        outlen[r] = L + Int32(2) + ((loop && e < n) ? Int32(1) : Int32(0))
    end
end

"""The body of every run: one thread per position, writing its own slot."""
@kernel function lines_body_kernel!(indices, @Const(ordinal), @Const(valid), @Const(starts),
                                    @Const(offsets), @Const(outlen))
    i = @index(Global, Linear)
    @inbounds if valid[i] != Int32(0)
        r = ordinal[i]
        off = offsets[r] - outlen[r]
        indices[off + Int32(2) + (Int32(i) - starts[r])] = UInt32(i)
    end
end

"""
The adjacency vertices at both ends of every run, and the seam markers.

`valid_vertex == 2` is how the geometry shader is told a vertex sits at a closed
seam rather than at a free end; it goes on the run's second and second-to-last
vertex, which are the two the seam's join is built from.
"""
@kernel function lines_bounds_kernel!(indices, validf, @Const(starts), @Const(ends),
                                      @Const(offsets), @Const(outlen), @Const(isloop), n::Int32)
    r = @index(Global, Linear)
    @inbounds begin
        s = starts[r]; e = ends[r]
        L = e - s + Int32(1)
        off = offsets[r] - outlen[r]
        if isloop[r] != Int32(0)
            indices[off + Int32(1)] = UInt32(e - Int32(1))
            indices[off + Int32(2) + L] = UInt32(s + Int32(1))
            e < n && (indices[off + Int32(3) + L] = UInt32(e + Int32(1)))
            validf[e - Int32(1)] = 2.0f0
            validf[s + Int32(1)] = 2.0f0
        else
            indices[off + Int32(1)] = UInt32(max(Int32(1), s - Int32(1)))
            indices[off + Int32(2) + L] = UInt32(e < n ? e + Int32(1) : e)
        end
    end
end

"""
    lines_generate_indices(ps, indices, valid) -> (indices, valid)

Adjacency index buffer and per-vertex validity for a line strip, built on
whichever device `ps` lives on.

`indices` and `valid` are resized in place and returned, so a plot whose point
count is unchanged reuses its buffers. Both have to be arrays of the same kind
as `ps`; the caller allocates them with `similar`.

Two scalars cross back to the host — the run count and the total index count —
because the output arrays have to be SIZED, and a data-dependent size is not
something `similar` can be told. Everything else stays put. The alternative is
an indirect draw with a device-side count, which is a change to the render
object rather than to this pass.
"""
function lines_generate_indices(ps, indices, valid)
    n = length(ps)
    resize!(valid, n)

    if n < 2
        fill!(valid, 0.0f0)
        resize!(indices, 0)
        return (indices, valid)
    end

    backend = KernelAbstractions.get_backend(ps)
    validb = similar(ps, Int32, n)
    startflag = similar(ps, Int32, n)
    lines_flags_kernel!(backend)(validb, startflag, ps; ndrange = n)

    ordinal = accumulate(+, startflag)
    nruns = Int(scalarat(ordinal, n))
    if nruns == 0
        fill!(valid, 0.0f0)
        resize!(indices, 0)
        return (indices, valid)
    end

    starts = similar(ps, Int32, nruns)
    ends = similar(ps, Int32, nruns)
    lines_runbounds_kernel!(backend)(starts, ends, ordinal, validb; ndrange = n)

    outlen = similar(ps, Int32, nruns)
    isloop = similar(ps, Int32, nruns)
    lines_runlengths_kernel!(backend)(outlen, isloop, starts, ends, ps, Int32(n); ndrange = nruns)

    offsets = accumulate(+, outlen)
    total = Int(scalarat(offsets, nruns))

    resize!(indices, total)
    valid .= Float32.(validb)
    lines_body_kernel!(backend)(indices, ordinal, validb, starts, offsets, outlen; ndrange = n)
    lines_bounds_kernel!(backend)(indices, valid, starts, ends, offsets, outlen, isloop,
                                  Int32(n); ndrange = nruns)

    # Vulkan index buffers are 0-based.
    indices .-= UInt32(1)
    return (indices, valid)
end

@inline lines_screenpos(p::VecTypes{4}) = p[Vec(1, 2)] / p[4]
@inline lines_screenpos(p::VecTypes) = p[Vec(1, 2)]
@inline lines_behind(p::VecTypes{4}) = p[4] <= 1.0f-6
@inline lines_behind(p::VecTypes) = false
@inline lines_isbreak(p1, p2) =
    any(map(isnan, p1)) || any(map(isnan, p2)) || lines_behind(p1) || lines_behind(p2)
@inline lines_seglen(p1, p2, res) =
    lines_isbreak(p1, p2) ? 0.0f0 :
    0.5f0 * norm(res .* (lines_screenpos(p1) - lines_screenpos(p2)))

"""
    lines_sumlengths(points, resolution) -> Float32 array

Cumulative screen-space distance along the strip, restarting at every break, for
the dash pattern's UV coordinate. Port of GLMakie's `sumlengths`, and it stays
on whichever device `points` lives on.

Two scans rather than the obvious running total, because the obvious one is
sequential. A running total that RESETS is a segmented scan, and the textbook
segmented scan carries `(value, flag)` pairs — which do not compile here, since
a scan over a tuple element type fails SPIR-V validation. The way around it uses
a property of this particular scan: a segment length cannot be negative, so the
plain cumulative sum is non-decreasing, and "the sum since the last break" is
just the total minus its value AT that break. A `max` scan finds that value,
because with a non-decreasing total the largest sum-at-a-break seen so far is
also the most recent one. Two scalar scans, no pairs.
"""
function lines_sumlengths(points, resolution)
    n = length(points)
    n == 0 && return similar(points, Float32, 0)

    res = Vec2f(Float32.(resolution)...)
    lens = similar(points, Float32, n)
    breaks = similar(points, Float32, n)

    # Point 1 has no predecessor, so it compares against itself: zero length,
    # and a break only if it is itself invalid.
    first1 = view(points, 1:1)
    view(lens, 1:1) .= lines_seglen.(first1, first1, (res,))
    view(breaks, 1:1) .= Float32.(lines_isbreak.(first1, first1))
    if n > 1
        prev = view(points, 1:(n - 1))
        cur = view(points, 2:n)
        view(lens, 2:n) .= lines_seglen.(prev, cur, (res,))
        view(breaks, 2:n) .= Float32.(lines_isbreak.(prev, cur))
    end

    total = accumulate(+, lens)
    # `breaks` is 0 or 1, so this is the total at a break and zero elsewhere.
    atbreak = accumulate(max, breaks .* total)
    return total .- atbreak
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
