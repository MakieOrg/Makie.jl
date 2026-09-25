# =============================================================================
# The mesh shader: GLMakie's mesh.vert, util.vert `render`, mesh.frag,
# lighting.frag and mesh_stroke.frag (MakieOrg/Makie.jl#5727), for RASTER mode.
# =============================================================================
#
# The GLSL functions are Julia functions here, called by thin stage entry points,
# so a material that generates its own geometry (a mesh stage) shades through the
# same code by calling them from ITS entry point. Where the port differs, the
# target forced it:
#
# - Vertex pulling. The draw is 3 vertices per face, non-indexed, and the vertex
#   stage reads `faces` itself: nothing is de-indexed on the CPU, and the face
#   index travels as a flat varying, which is what `gl_PrimitiveID` was for.
# - The fragment's NDC is the perspective-interpolated clip position over w. For
#   a point on the triangle that is exactly GLSL's `noperspective o_ndc`.
# - Clip planes discard; there is no `gl_ClipDistance`.
# - The colormap is a buffer, read the way a clamped 1D texture is.
# - An `EnvironmentLight` lights through nine spherical-harmonic coefficients of
#   its map, and a shaded result goes through the film's exposure, tone curve and
#   gamma, so RASTER mode matches the traced picture it stands in for. Makie
#   leaves both to the backend.

const MESH_VERTEX_OUT = (world_pos = Vec3f, world_normal = Vec3f, view_normal = Vec3f,
                         camdir = Vec3f, uv = Vec3f, colour = Vec4f, clip = Vec4f,
                         tri = Flat{Float32})

# Where a fragment's colour comes from, decided on the host. GLMakie decides the
# same thing through the Nothing/sampler overloads of `get_color`.
const COLOR_UNIFORM = Int32(0)
const COLOR_VERTEX = Int32(1)
const COLOR_VERTEX_CMAP = Int32(2)        # per-vertex value, mapped per vertex
const COLOR_VERTEX_CMAP_FRAG = Int32(3)   # per-vertex value, mapped per fragment
const COLOR_IMAGE = Int32(4)
const COLOR_IMAGE_CMAP = Int32(5)
const COLOR_MATCAP = Int32(6)
const COLOR_PATTERN = Int32(7)

const SHADING_NONE = Int32(0)
const SHADING_FAST = Int32(1)
const SHADING_MULTI = Int32(2)

# Makie's light type codes, as `register_multi_light_computation` writes them.
const LIGHT_POINT = Int32(2)
const LIGHT_DIRECTIONAL = Int32(3)
const LIGHT_SPOT = Int32(4)
const LIGHT_RECT = Int32(5)

@inline _unit(v::Vec3f) = v * (1f0 / sqrt(dot(v, v)))

# ─── mesh.frag: colormap ─────────────────────────────────────────────────────

# `texture(color_map, u)` on a 1D texture with clamp-to-edge, linear or nearest.
@inline function sample_colormap(cmap, u::Float32, linear::Int32)
    n = Int32(length(cmap))
    if linear != Int32(0)
        x = clamp(u * Float32(n) - 0.5f0, 0f0, Float32(n - Int32(1)))
        i0 = unsafe_trunc(Int32, x)
        i1 = min(i0 + Int32(1), n - Int32(1))
        w = x - Float32(i0)
        @inbounds return cmap[i0 + Int32(1)] * (1f0 - w) + cmap[i1 + Int32(1)] * w
    end
    i = clamp(unsafe_trunc(Int32, u * Float32(n)), Int32(0), n - Int32(1))
    @inbounds return cmap[i + Int32(1)]
end

@inline function get_color_from_cmap(value::Float32, cmap, colorrange::Vec2f, linear::Int32,
                                     lowclip::Vec4f, highclip::Vec4f, nan_color::Vec4f)
    cmin = colorrange[1]
    cmax = colorrange[2]
    if value <= cmax && value >= cmin
    elseif value < cmin
        return lowclip
    elseif value > cmax
        return highclip
    else
        return nan_color
    end
    i01 = clamp((value - cmin) / (cmax - cmin), 0f0, 1f0)
    stepsize = 1f0 / Float32(length(cmap))
    i01 = (1f0 - stepsize) * i01 + 0.5f0 * stepsize
    return sample_colormap(cmap, i01, linear)
end

# ─── lighting.frag ───────────────────────────────────────────────────────────

@inline function smooth_zero_max(x::Float32)
    c = 0.00390625f0
    xswap = 0.6406707f0
    yswap = 0.20508384f0
    s = x + (1f0 + xswap - yswap)
    s2 = s * s
    s4 = s2 * s2
    return x < yswap ? c * (s4 * s4) : x
end

@inline function blinn_phong(light_color::Vec3f, light_dir::Vec3f, camdir::Vec3f, normal::Vec3f,
                             color::Vec3f, diffuse::Vec3f, specular::Vec3f,
                             shininess::Float32, backlight::Float32)
    diff_coeff = smooth_zero_max(dot(light_dir, -normal)) +
                 backlight * smooth_zero_max(dot(light_dir, normal))
    H = _unit(light_dir + camdir)
    spec_coeff = max(dot(H, -normal), 0f0)^shininess +
                 backlight * max(dot(H, normal), 0f0)^shininess
    if diff_coeff <= 0f0 || isnan(spec_coeff)
        spec_coeff = 0f0
    end
    return light_color .* (diffuse .* diff_coeff .* color .+ specular .* spec_coeff)
end

@inline function calc_point_light(light_color, params, idx::Int32, world_pos, camdir, normal,
                                  color, diffuse, specular, shininess, backlight)
    @inbounds position = Vec3f(params[idx + 1], params[idx + 2], params[idx + 3])
    @inbounds param = Vec2f(params[idx + 4], params[idx + 5])
    light_vec = world_pos - position
    dist = sqrt(dot(light_vec, light_vec))
    light_dir = _unit(light_vec)
    attenuation = 1f0 / (1f0 + param[1] * dist + param[2] * dist * dist)
    return attenuation * blinn_phong(light_color, light_dir, camdir, normal, color,
                                     diffuse, specular, shininess, backlight)
end

@inline function calc_directional_light(light_color, params, idx::Int32, camdir, normal,
                                        color, diffuse, specular, shininess, backlight)
    @inbounds light_dir = Vec3f(params[idx + 1], params[idx + 2], params[idx + 3])
    return blinn_phong(light_color, light_dir, camdir, normal, color,
                       diffuse, specular, shininess, backlight)
end

@inline function calc_spot_light(light_color, params, idx::Int32, world_pos, camdir, normal,
                                 color, diffuse, specular, shininess, backlight)
    @inbounds position = Vec3f(params[idx + 1], params[idx + 2], params[idx + 3])
    @inbounds spot_dir = _unit(Vec3f(params[idx + 4], params[idx + 5], params[idx + 6]))
    @inbounds inner_angle = params[idx + 7]
    @inbounds outer_angle = params[idx + 8]
    light_dir = _unit(world_pos - position)
    intensity = smoothstep(outer_angle, inner_angle, dot(light_dir, spot_dir))
    return intensity * blinn_phong(light_color, light_dir, camdir, normal, color,
                                   diffuse, specular, shininess, backlight)
end

@inline function calc_rect_light(light_color, params, idx::Int32, world_pos, camdir, normal,
                                 color, diffuse, specular, shininess, backlight)
    @inbounds origin = Vec3f(params[idx + 1], params[idx + 2], params[idx + 3])
    @inbounds u1 = Vec3f(params[idx + 4], params[idx + 5], params[idx + 6])
    @inbounds u2 = Vec3f(params[idx + 7], params[idx + 8], params[idx + 9])
    @inbounds light_dir = Vec3f(params[idx + 10], params[idx + 11], params[idx + 12])
    t = dot(origin - world_pos, light_dir)
    dir = world_pos + t * light_dir - origin
    w1 = dot(dir, u1) / dot(u1, u1)
    w2 = dot(dir, u2) / dot(u2, u2)
    intensity = smoothstep(0.45f0, 0.55f0, 1f0 - abs(w1)) *
                smoothstep(0.45f0, 0.55f0, 1f0 - abs(w2))
    return intensity * blinn_phong(light_color, light_dir, camdir, normal, color,
                                   diffuse, specular, shininess, backlight)
end

# Irradiance over π from nine SH coefficients with the cosine lobe folded in
# (Ramamoorthi and Hanrahan 2001), columns in the order `project_environment!` writes.
@inline function env_irradiance(sh, n::Vec3f)
    x = n[1]; y = n[2]; z = n[3]
    col(k) = Vec3f(sh[1, k], sh[2, k], sh[3, k])
    return col(1) * 0.282095f0 +
           col(2) * (0.488603f0 * y) + col(3) * (0.488603f0 * z) + col(4) * (0.488603f0 * x) +
           col(5) * (1.092548f0 * x * y) + col(6) * (1.092548f0 * y * z) +
           col(7) * (0.315392f0 * (3f0 * z * z - 1f0)) + col(8) * (1.092548f0 * x * z) +
           col(9) * (0.546274f0 * (x * x - y * y))
end

"""
The scene's lights on a surface point, as lighting.frag's `illuminate` for the
scene's shading mode, plus the environment's diffuse irradiance.
"""
@inline function illuminate(world_pos::Vec3f, camdir::Vec3f, normal::Vec3f, base_color::Vec3f,
                            shading_mode::Int32, ambient::Vec3f, light_color::Vec3f,
                            light_direction::Vec3f, N_lights::Int32, light_types, light_colors,
                            light_parameters, has_env::Int32, env_sh,
                            diffuse::Vec3f, specular::Vec3f, shininess::Float32, backlight::Float32)
    final_color = ambient .* base_color
    if has_env != Int32(0)
        e = env_irradiance(env_sh, normal) + backlight * env_irradiance(env_sh, -normal)
        final_color = final_color + diffuse .* base_color .* max.(e, 0f0)
    end
    if shading_mode == SHADING_FAST
        final_color = final_color + blinn_phong(light_color, light_direction, camdir, normal,
                                                base_color, diffuse, specular, shininess, backlight)
    elseif shading_mode == SHADING_MULTI
        idx = Int32(0)
        for i in Int32(1):min(N_lights, Int32(length(light_types)))
            @inbounds kind = light_types[i]
            @inbounds lc = light_colors[i]
            if kind == LIGHT_POINT
                final_color = final_color + calc_point_light(lc, light_parameters, idx, world_pos,
                    camdir, normal, base_color, diffuse, specular, shininess, backlight)
                idx += Int32(5)
            elseif kind == LIGHT_DIRECTIONAL
                final_color = final_color + calc_directional_light(lc, light_parameters, idx,
                    camdir, normal, base_color, diffuse, specular, shininess, backlight)
                idx += Int32(3)
            elseif kind == LIGHT_SPOT
                final_color = final_color + calc_spot_light(lc, light_parameters, idx, world_pos,
                    camdir, normal, base_color, diffuse, specular, shininess, backlight)
                idx += Int32(8)
            elseif kind == LIGHT_RECT
                final_color = final_color + calc_rect_light(lc, light_parameters, idx, world_pos,
                    camdir, normal, base_color, diffuse, specular, shininess, backlight)
                idx += Int32(12)
            else
                return Vec3f(1f0, 0f0, 1f0)
            end
        end
    end
    return final_color
end

# The film's display mapping (Hikari's `postprocess_kernel!`) on one colour.
@inline function film_mapping(c::Vec3f, exposure::Float32, tonemap::Int32, white_point::Float32,
                              inv_gamma::Float32, apply_gamma::Int32)
    r, g, b = Hikari.apply_tonemap(c[1] * exposure, c[2] * exposure, c[3] * exposure,
                                   UInt8(tonemap), white_point)
    if apply_gamma != Int32(0)
        r = r^inv_gamma
        g = g^inv_gamma
        b = b^inv_gamma
    end
    return Vec3f(r, g, b)
end

# ─── mesh_stroke.frag ────────────────────────────────────────────────────────

# Screen position in physical pixels with NDC depth in z.
@inline function stroke_screen_space(p::Vec3f, pvm::Mat4f, scale::Vec2f)
    c = pvm * Vec4f(p[1], p[2], p[3], 1f0)
    return Vec3f((0.5f0 * c[1] / c[4] + 0.5f0) * scale[1],
                 (0.5f0 * c[2] / c[4] + 0.5f0) * scale[2], c[3] / c[4])
end

@inline function distance_to_segment(p::Vec2f, a::Vec2f, b::Vec2f)
    ab = b - a
    len2 = dot(ab, ab)
    len2 < 1f-20 && return sqrt(dot(p - a, p - a))
    t = clamp(dot(p - a, ab) / len2, 0f0, 1f0)
    d = p - a - t * ab
    return sqrt(dot(d, d))
end

@inline function edge_face_factor(frag::Vec2f, a::Vec2f, b::Vec2f, width_multiplier::Float32,
                                  strokewidth::Float32, px_per_unit::Float32)
    width_multiplier <= 0f0 && return 1f0
    aa_radius = 0.7f0 * px_per_unit
    width = width_multiplier * strokewidth * px_per_unit
    return smoothstep(-aa_radius, aa_radius, distance_to_segment(frag, a, b) - width)
end

@inline function wing_face_factor(frag::Vec2f, a::Vec3f, b::Vec3f, width_multiplier::Float32,
                                  frag_z::Float32, z_gradient::Vec2f,
                                  strokewidth::Float32, px_per_unit::Float32)
    width_multiplier <= 0f0 && return 1f0
    ab = Vec2f(b[1] - a[1], b[2] - a[2])
    len2 = dot(ab, ab)
    t = len2 < 1f-20 ? 0f0 : clamp(dot(frag - Vec2f(a[1], a[2]), ab) / len2, 0f0, 1f0)
    closest = Vec2f(a[1], a[2]) + t * ab
    d = frag - closest
    dist = sqrt(dot(d, d))
    wing_z = a[3] + (b[3] - a[3]) * t
    plane_z = frag_z + dot(z_gradient, closest - frag)
    z_tolerance = (abs(z_gradient[1]) + abs(z_gradient[2])) * (dist + 1f0) + 1f-4
    abs(wing_z - plane_z) > z_tolerance && return 1f0
    aa_radius = 0.7f0 * px_per_unit
    width = width_multiplier * strokewidth * px_per_unit
    return smoothstep(-aa_radius, aa_radius, dist - width)
end

@inline function wing_factor(ff::Float32, data, at::Int32, corner::Vec3f, frag::Vec2f, ndc_z::Float32,
                             z_gradient::Vec2f, pvm::Mat4f, scale::Vec2f,
                             strokewidth::Float32, px_per_unit::Float32)
    @inbounds wing = data[at]
    wing[4] > 0f0 || return ff
    endpoint = stroke_screen_space(Vec3f(wing[1], wing[2], wing[3]), pvm, scale)
    return min(ff, wing_face_factor(frag, corner, endpoint, wing[4], ndc_z, z_gradient,
                                    strokewidth, px_per_unit))
end

"""
mesh_stroke.frag's `apply_stroke`: stroke or face by the fragment's screen-space
distance to its own triangle's stroked edges and their wings. `tri` is the
0-based face index into Makie's `:stroke_data_packed` (9 texels per face).
"""
@inline function apply_stroke(color::Vec4f, data, tri::Int32, ndc::Vec3f, z_gradient::Vec2f,
                              pvm::Mat4f, scale::Vec2f, strokewidth::Float32,
                              strokecolor::Vec4f, px_per_unit::Float32)
    strokewidth <= 0f0 && return color
    base = Int32(9) * tri
    @inbounds c0 = data[base + Int32(1)]
    @inbounds c1 = data[base + Int32(2)]
    @inbounds c2 = data[base + Int32(3)]
    p0 = stroke_screen_space(Vec3f(c0[1], c0[2], c0[3]), pvm, scale)
    p1 = stroke_screen_space(Vec3f(c1[1], c1[2], c1[3]), pvm, scale)
    p2 = stroke_screen_space(Vec3f(c2[1], c2[2], c2[3]), pvm, scale)
    frag = Vec2f((0.5f0 * ndc[1] + 0.5f0) * scale[1], (0.5f0 * ndc[2] + 0.5f0) * scale[2])
    ff = 1f0
    ff = min(ff, edge_face_factor(frag, Vec2f(p0[1], p0[2]), Vec2f(p1[1], p1[2]), c0[4], strokewidth, px_per_unit))
    ff = min(ff, edge_face_factor(frag, Vec2f(p1[1], p1[2]), Vec2f(p2[1], p2[2]), c1[4], strokewidth, px_per_unit))
    ff = min(ff, edge_face_factor(frag, Vec2f(p2[1], p2[2]), Vec2f(p0[1], p0[2]), c2[4], strokewidth, px_per_unit))
    # The six wings, two per corner, unrolled: a corner picked by a runtime index
    # would be a tuple read at a runtime position.
    ff = wing_factor(ff, data, base + Int32(4), p0, frag, ndc[3], z_gradient, pvm, scale, strokewidth, px_per_unit)
    ff = wing_factor(ff, data, base + Int32(5), p0, frag, ndc[3], z_gradient, pvm, scale, strokewidth, px_per_unit)
    ff = wing_factor(ff, data, base + Int32(6), p1, frag, ndc[3], z_gradient, pvm, scale, strokewidth, px_per_unit)
    ff = wing_factor(ff, data, base + Int32(7), p1, frag, ndc[3], z_gradient, pvm, scale, strokewidth, px_per_unit)
    ff = wing_factor(ff, data, base + Int32(8), p2, frag, ndc[3], z_gradient, pvm, scale, strokewidth, px_per_unit)
    ff = wing_factor(ff, data, base + Int32(9), p2, frag, ndc[3], z_gradient, pvm, scale, strokewidth, px_per_unit)
    return strokecolor * (1f0 - ff) + color * ff
end

"""
The fragment's NDC and its depth gradient in GL's y-up screen space.

The clip position is interpolated perspective-correctly, so dividing it by w
gives the NDC of the surface point under this fragment. `dFdy` is taken along
framebuffer rows, which run DOWN, so its sign is flipped to match the y-up
coordinates `stroke_screen_space` produces.
"""
@inline function fragment_ndc(clip::Vec4f)
    ndc = Vec3f(clip[1] / clip[4], clip[2] / clip[4], clip[3] / clip[4])
    return ndc, Vec2f(dFdx(ndc[3]), -dFdy(ndc[3]))
end

# ─── Makie meshes: the arguments, the stages, the pipelines ─────────────────

const MESH_ARG_NAMES = (
    :raster_positions, :raster_faces, :raster_normals, :raster_uvs,
    :raster_vertex_color, :raster_vertex_value, :raster_colormap, :stroke_data,
    :clip_planes, :light_types, :light_colors, :light_parameters,
    :model, :view, :projection, :eyeposition, :world_normalmatrix, :view_normalmatrix,
    :depth_shift, :has_normals, :has_uvs, :uv_transform,
    :color_source, :uniform_color, :colorrange, :colormap_linear,
    :lowclip, :highclip, :nan_color,
    :shading_mode, :ambient, :light_color, :light_direction, :N_lights,
    :has_env, :env_sh, :diffuse, :specular, :shininess, :backlight,
    :exposure, :tonemap, :white_point, :inv_gamma, :apply_gamma,
    :strokewidth, :strokecolor, :resolution, :px_per_unit, :viewport_origin,
    :num_clip_planes,
)
const MESH_NARGS = length(MESH_ARG_NAMES)

# The arg-less spelling, as in `overlay/lines.jl`. Written out rather than
# splatted: inference resolves a splat of at most 32 elements, and a 51-element
# `args...` stays a dynamic `_apply_iterate` that no GPU compiler accepts.
@generated function mesh_vertex(args::Vararg{Any,MESH_NARGS})
    return :(mesh_vertex(VertexIndex(vertex_index()), $((:(args[$i]) for i in 1:MESH_NARGS)...)))
end

function mesh_vertex(vertexid::VertexIndex,
        positions, faces, normals, uvs, vertex_colors, vertex_values, cmap, stroke_data,
        clip_planes, light_types, light_colors, light_parameters,
        model::Mat4f, view::Mat4f, projection::Mat4f, eyeposition::Vec3f,
        world_normalmatrix::Mat3f, view_normalmatrix::Mat3f,
        depth_shift::Float32, has_normals::Int32, has_uvs::Int32, uv_transform::Mat{2,3,Float32},
        color_source::Int32, uniform_color::Vec4f, colorrange::Vec2f, colormap_linear::Int32,
        lowclip::Vec4f, highclip::Vec4f, nan_color::Vec4f,
        shading_mode::Int32, ambient::Vec3f, light_color::Vec3f, light_direction::Vec3f,
        N_lights::Int32, has_env::Int32, env_sh::Mat{3,9,Float32},
        diffuse::Vec3f, specular::Vec3f, shininess::Float32, backlight::Float32,
        exposure::Float32, tonemap::Int32, white_point::Float32, inv_gamma::Float32, apply_gamma::Int32,
        strokewidth::Float32, strokecolor::Vec4f, resolution::Vec2f, px_per_unit::Float32,
        viewport_origin::Vec2f, num_clip_planes::Int32)
    v0 = vertexid.value - Int32(1)
    tri = v0 ÷ Int32(3)
    @inbounds vi = Int32(faces[v0 + Int32(1)])
    @inbounds p = positions[vi]

    # util.vert `render`
    position_world = model * Vec4f(p[1], p[2], p[3], 1f0)
    view_pos = view * position_world
    view_pos = view_pos / view_pos[4]
    clip = Vec4f(projection * view_pos)
    shifted = Vec4f(clip[1], clip[2], clip[3] + clip[4] * depth_shift, clip[4])
    world_pos = Vec3f(position_world[1], position_world[2], position_world[3]) / position_world[4]

    n = has_normals != Int32(0) ? (@inbounds normals[vi]) : Vec3f(0f0, 0f0, 0f0)
    uv = has_uvs != Int32(0) ? (@inbounds uvs[vi]) : Vec2f(0f0, 0f0)
    uvt = uv_transform * Vec3f(uv[1], uv[2], 1f0)

    # mesh.vert `to_color`
    colour = if color_source == COLOR_VERTEX
        @inbounds vertex_colors[vi]
    elseif color_source == COLOR_VERTEX_CMAP
        get_color_from_cmap((@inbounds vertex_values[vi]), cmap, colorrange, colormap_linear,
                            lowclip, highclip, nan_color)
    elseif color_source == COLOR_VERTEX_CMAP_FRAG
        Vec4f((@inbounds vertex_values[vi]), 0f0, 0f0, 0f0)
    else
        uniform_color
    end

    return (position = gl_to_clip_depth(shifted),
            world_pos = world_pos,
            world_normal = Vec3f(world_normalmatrix * n),
            view_normal = Vec3f(view_normalmatrix * n),
            camdir = world_pos - eyeposition,
            uv = Vec3f(uvt[1], uvt[2], 0f0),
            colour = colour,
            clip = clip,
            tri = Float32(tri))
end

"""
Everything mesh.frag does after the base colour: clip planes, lighting, the
film mapping, the stroke, and the premultiplied output a blended pass wants.
"""
@inline function mesh_finish(inputs, color::Vec4f, stroke_data, clip_planes, num_clip_planes::Int32,
        light_types, light_colors, light_parameters, model::Mat4f, view::Mat4f,
        projection::Mat4f, has_normals::Int32,
        shading_mode::Int32, ambient::Vec3f, light_color::Vec3f, light_direction::Vec3f,
        N_lights::Int32, has_env::Int32, env_sh, diffuse::Vec3f, specular::Vec3f,
        shininess::Float32, backlight::Float32,
        exposure::Float32, tonemap::Int32, white_point::Float32, inv_gamma::Float32,
        apply_gamma::Int32, strokewidth::Float32, strokecolor::Vec4f,
        resolution::Vec2f, px_per_unit::Float32)
    world_pos = inputs.world_pos
    for i in Int32(1):num_clip_planes
        @inbounds plane = clip_planes[i]
        dot(world_pos, Vec3f(plane[1], plane[2], plane[3])) - plane[4] < 0f0 && discard()
    end
    if shading_mode != SHADING_NONE && has_normals != Int32(0)
        rgb = illuminate(world_pos, _unit(inputs.camdir), _unit(inputs.world_normal),
                         Vec3f(color[1], color[2], color[3]), shading_mode, ambient,
                         light_color, light_direction, N_lights, light_types, light_colors,
                         light_parameters, has_env, env_sh, diffuse, specular, shininess, backlight)
        rgb = film_mapping(rgb, exposure, tonemap, white_point, inv_gamma, apply_gamma)
        color = Vec4f(rgb[1], rgb[2], rgb[3], color[4])
    end
    ndc, z_gradient = fragment_ndc(inputs.clip)
    tri = unsafe_trunc(Int32, inputs.tri + 0.5f0)
    color = apply_stroke(color, stroke_data, tri, ndc, z_gradient, projection * view * model,
                         px_per_unit * resolution, strokewidth, strokecolor, px_per_unit)
    a = color[4]
    a < 1f-3 && discard()
    return Vec4f(color[1] * a, color[2] * a, color[3] * a, a)
end

function mesh_fragment(inputs,
        positions, faces, normals, uvs, vertex_colors, vertex_values, cmap, stroke_data,
        clip_planes, light_types, light_colors, light_parameters,
        model::Mat4f, view::Mat4f, projection::Mat4f, eyeposition::Vec3f,
        world_normalmatrix::Mat3f, view_normalmatrix::Mat3f,
        depth_shift::Float32, has_normals::Int32, has_uvs::Int32, uv_transform::Mat{2,3,Float32},
        color_source::Int32, uniform_color::Vec4f, colorrange::Vec2f, colormap_linear::Int32,
        lowclip::Vec4f, highclip::Vec4f, nan_color::Vec4f,
        shading_mode::Int32, ambient::Vec3f, light_color::Vec3f, light_direction::Vec3f,
        N_lights::Int32, has_env::Int32, env_sh::Mat{3,9,Float32},
        diffuse::Vec3f, specular::Vec3f, shininess::Float32, backlight::Float32,
        exposure::Float32, tonemap::Int32, white_point::Float32, inv_gamma::Float32, apply_gamma::Int32,
        strokewidth::Float32, strokecolor::Vec4f, resolution::Vec2f, px_per_unit::Float32,
        viewport_origin::Vec2f, num_clip_planes::Int32)
    color = color_source == COLOR_VERTEX_CMAP_FRAG ?
        get_color_from_cmap(inputs.colour[1], cmap, colorrange, colormap_linear,
                            lowclip, highclip, nan_color) :
        inputs.colour
    return mesh_finish(inputs, color, stroke_data, clip_planes, num_clip_planes,
        light_types, light_colors, light_parameters, model, view, projection, has_normals,
        shading_mode, ambient, light_color, light_direction, N_lights, has_env, env_sh,
        diffuse, specular, shininess, backlight, exposure, tonemap, white_point,
        inv_gamma, apply_gamma, strokewidth, strokecolor, resolution, px_per_unit)
end

@inline texel(u::Float32, v::Float32) =
    Vec4f(sample_texture_2d(UInt32(0), u, v, UInt32(0)), sample_texture_2d(UInt32(0), u, v, UInt32(1)),
          sample_texture_2d(UInt32(0), u, v, UInt32(2)), sample_texture_2d(UInt32(0), u, v, UInt32(3)))

# The same stages over ONE bound texture: an image, an intensity image through
# the colormap, a matcap, or a pattern. mesh.frag's `get_color` overloads with a
# sampler, and `get_pattern_color`.
function mesh_fragment_textured(inputs,
        positions, faces, normals, uvs, vertex_colors, vertex_values, cmap, stroke_data,
        clip_planes, light_types, light_colors, light_parameters,
        model::Mat4f, view::Mat4f, projection::Mat4f, eyeposition::Vec3f,
        world_normalmatrix::Mat3f, view_normalmatrix::Mat3f,
        depth_shift::Float32, has_normals::Int32, has_uvs::Int32, uv_transform::Mat{2,3,Float32},
        color_source::Int32, uniform_color::Vec4f, colorrange::Vec2f, colormap_linear::Int32,
        lowclip::Vec4f, highclip::Vec4f, nan_color::Vec4f,
        shading_mode::Int32, ambient::Vec3f, light_color::Vec3f, light_direction::Vec3f,
        N_lights::Int32, has_env::Int32, env_sh::Mat{3,9,Float32},
        diffuse::Vec3f, specular::Vec3f, shininess::Float32, backlight::Float32,
        exposure::Float32, tonemap::Int32, white_point::Float32, inv_gamma::Float32, apply_gamma::Int32,
        strokewidth::Float32, strokecolor::Vec4f, resolution::Vec2f, px_per_unit::Float32,
        viewport_origin::Vec2f, num_clip_planes::Int32)
    color = if color_source == COLOR_MATCAP
        vn = _unit(inputs.view_normal)
        texel(1f0 - (0.5f0 * vn[2] + 0.5f0), 0.5f0 * vn[1] + 0.5f0)
    elseif color_source == COLOR_PATTERN
        # gl_FragCoord in logical pixels: the viewport's origin plus the NDC.
        ndc = inputs.clip / inputs.clip[4]
        px = viewport_origin + Vec2f((0.5f0 * ndc[1] + 0.5f0) * resolution[1],
                                     (0.5f0 * ndc[2] + 0.5f0) * resolution[2])
        pos = uv_transform * Vec3f(px[1], px[2], 1f0)
        texel(pos[1], pos[2])
    elseif color_source == COLOR_IMAGE_CMAP
        get_color_from_cmap(sample_texture_2d(UInt32(0), inputs.uv[1], inputs.uv[2], UInt32(0)),
                            cmap, colorrange, colormap_linear, lowclip, highclip, nan_color)
    else
        texel(inputs.uv[1], inputs.uv[2])
    end
    return mesh_finish(inputs, color, stroke_data, clip_planes, num_clip_planes,
        light_types, light_colors, light_parameters, model, view, projection, has_normals,
        shading_mode, ambient, light_color, light_direction, N_lights, has_env, env_sh,
        diffuse, specular, shininess, backlight, exposure, tonemap, white_point,
        inv_gamma, apply_gamma, strokewidth, strokecolor, resolution, px_per_unit)
end

function get_mesh_pipeline!(screen, textured::Bool)
    get!(screen.gfx_pipelines, textured ? :mesh_textured : :mesh) do
        GraphicsPipeline(; vertex = VertexShader(mesh_vertex; outputs = MESH_VERTEX_OUT),
                           fragment = textured ? FragmentShader(mesh_fragment_textured; textures = 1) :
                                                 FragmentShader(mesh_fragment),
                           blend = Premultiplied(),
                           topology = TriangleList(),
                           cull = NoCull(),
                           depth = DepthLessEq())
    end
end
