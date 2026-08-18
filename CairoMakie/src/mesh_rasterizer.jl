# A software rasterizer for mesh plots, ported from GLMakie's mesh shaders
# (mesh.vert/mesh.frag/mesh_stroke.frag/lighting.frag). Each plot is rendered into
# its own RGBA image with a private depth buffer, which is then composited into the
# Cairo context like an image plot. This makes per-fragment effects possible that
# Cairo's canvas model cannot express, currently edge stroking.

using Colors.FixedPointNumbers: N0f8

const RASTERIZER_SUPERSAMPLING = 2

struct UniformColorSampler
    color::RGBAf
end

struct VertexColorSampler
    colors::Vector{RGBAf}
end

struct TextureColorSampler
    image::Matrix{RGBAf}
    uvs::Vector{Vec2f}
    interpolate::Bool
end

# Numeric colors interpolate the raw values per fragment and look up the colormap
# afterwards, like GLMakie's get_color_from_cmap path. Interpolating the mapped
# colors instead would smear lowclip/highclip/nan regions (e.g. Inf values) into
# gradients and blur sharp colormap bands.
struct ColormapData
    colormap::Vector{RGBAf}
    colorrange::Vec2f
    lowclip::RGBAf
    highclip::RGBAf
    nan_color::RGBAf
    mapping_type::Makie.ColorMappingType
end

function ColormapData(plot::ComputeGraph)
    return ColormapData(
        plot.alpha_colormap[],
        Vec2f(plot.scaled_colorrange[]),
        plot.lowclip_color[],
        plot.highclip_color[],
        plot.nan_color[],
        plot.color_mapping_type[],
    )
end

function sample_colormap(cmap::ColormapData, value::Float32)
    return Makie.sample_color(
        cmap.colormap, value, cmap.colorrange,
        cmap.lowclip, cmap.highclip, cmap.nan_color, cmap.mapping_type
    )
end

struct VertexValueSampler
    values::Vector{Float32}
    cmap::ColormapData
end

struct ValueTextureSampler
    values::Matrix{Float32}
    uvs::Vector{Vec2f}
    interpolate::Bool
    cmap::ColormapData
end

struct MatcapSampler
    image::Matrix{RGBAf}
    view_normals::Vector{Vec3f}
end

# Samples the pattern tile by window position like GLMakie's fetch_pixel path, which
# uses gl_FragCoord with a pixel-to-uv pattern_uv_transform. Raster buffer pixels are
# mapped back to viewport-local logical coordinates with a bottom-left origin.
struct PatternSampler
    image::Matrix{RGBAf}
    uv_transform::Mat{2, 3, Float32}
    viewport::Rect2f
    local_origin::Vec2f
    inv_px_scale::Float32
end

wrap_index(i, n, repeat::Bool) = repeat ? mod(i - 1, n) + 1 : clamp(i, 1, n)

function sample_texture(img::Matrix{RGBAf}, uv::Vec2f, interpolate::Bool, repeat::Bool)
    nx, ny = size(img)
    if interpolate
        x = uv[1] * nx - 0.5f0
        y = uv[2] * ny - 0.5f0
        x0 = floor(Int, x)
        y0 = floor(Int, y)
        fx = x - x0
        fy = y - y0
        i0 = wrap_index(x0 + 1, nx, repeat)
        i1 = wrap_index(x0 + 2, nx, repeat)
        j0 = wrap_index(y0 + 1, ny, repeat)
        j1 = wrap_index(y0 + 2, ny, repeat)
        c00 = img[i0, j0]
        c10 = img[i1, j0]
        c01 = img[i0, j1]
        c11 = img[i1, j1]
        mix2(a, b, f) = (1 - f) * a + f * b
        channel(getter) = mix2(
            mix2(Float32(getter(c00)), Float32(getter(c10)), fx),
            mix2(Float32(getter(c01)), Float32(getter(c11)), fx),
            fy
        )
        return RGBAf(channel(red), channel(green), channel(blue), channel(alpha))
    else
        x = wrap_index(floor(Int, uv[1] * nx) + 1, nx, repeat)
        y = wrap_index(floor(Int, uv[2] * ny) + 1, ny, repeat)
        return img[x, y]
    end
end

fragment_color(s::UniformColorSampler, face, weights, frag_px) = s.color

function fragment_color(s::VertexColorSampler, face, weights, frag_px)
    c1, c2, c3 = s.colors[face[1]], s.colors[face[2]], s.colors[face[3]]
    return RGBAf(
        weights[1] * c1.r + weights[2] * c2.r + weights[3] * c3.r,
        weights[1] * c1.g + weights[2] * c2.g + weights[3] * c3.g,
        weights[1] * c1.b + weights[2] * c2.b + weights[3] * c3.b,
        weights[1] * c1.alpha + weights[2] * c2.alpha + weights[3] * c3.alpha,
    )
end

function fragment_color(s::TextureColorSampler, face, weights, frag_px)
    uv = weights[1] * s.uvs[face[1]] + weights[2] * s.uvs[face[2]] + weights[3] * s.uvs[face[3]]
    return sample_texture(s.image, uv, s.interpolate, false)
end

# zero weights are skipped so that Inf values do not turn into NaN via 0 * Inf
function fragment_color(s::VertexValueSampler, face, weights, frag_px)
    value = 0.0f0
    for k in 1:3
        w = weights[k]
        w > 0.0f0 && (value += w * s.values[face[k]])
    end
    return sample_colormap(s.cmap, value)
end

function sample_value(vals::Matrix{Float32}, uv::Vec2f, interpolate::Bool)
    nx, ny = size(vals)
    if interpolate
        x = uv[1] * nx - 0.5f0
        y = uv[2] * ny - 0.5f0
        x0 = floor(Int, x)
        y0 = floor(Int, y)
        fx = x - x0
        fy = y - y0
        i0 = clamp(x0 + 1, 1, nx)
        i1 = clamp(x0 + 2, 1, nx)
        j0 = clamp(y0 + 1, 1, ny)
        j1 = clamp(y0 + 2, 1, ny)
        value = 0.0f0
        w00 = (1 - fx) * (1 - fy)
        w10 = fx * (1 - fy)
        w01 = (1 - fx) * fy
        w11 = fx * fy
        w00 > 0.0f0 && (value += w00 * vals[i0, j0])
        w10 > 0.0f0 && (value += w10 * vals[i1, j0])
        w01 > 0.0f0 && (value += w01 * vals[i0, j1])
        w11 > 0.0f0 && (value += w11 * vals[i1, j1])
        return value
    else
        x = clamp(floor(Int, uv[1] * nx) + 1, 1, nx)
        y = clamp(floor(Int, uv[2] * ny) + 1, 1, ny)
        return vals[x, y]
    end
end

function fragment_color(s::ValueTextureSampler, face, weights, frag_px)
    uv = weights[1] * s.uvs[face[1]] + weights[2] * s.uvs[face[2]] + weights[3] * s.uvs[face[3]]
    return sample_colormap(s.cmap, sample_value(s.values, uv, s.interpolate))
end

# from mesh.frag: muv = normalize(o_view_normal).xy * 0.5 + 0.5, sampled at (1 - muv.y, muv.x)
function fragment_color(s::MatcapSampler, face, weights, frag_px)
    normal = zero_normalize(
        weights[1] * s.view_normals[face[1]] +
            weights[2] * s.view_normals[face[2]] +
            weights[3] * s.view_normals[face[3]]
    )
    uv = Vec2f(0.5f0 - 0.5f0 * normal[2], 0.5f0 + 0.5f0 * normal[1])
    return sample_texture(s.image, uv, true, false)
end

function fragment_color(s::PatternSampler, face, weights, frag_px)
    # frag_px use super sampled and px_per_unit scaled units
    # local_origin moves from scaled framebuffer units to scaled scene.viewport
    # units (removing shifts from matching the framebuffer to the mesh bbox)
    # inv_px_scale maps the scaled (supersampling + px_per_unit) units to the
    # units used in scene.viewport
    # viewport is the (unscaled) scene.viewport which is needed to invert the y
    # direction (map top origin to bottom origin) and get to window relative
    # pixel coordinates
    scene_x = (s.local_origin[1] + frag_px[1]) * s.inv_px_scale
    scene_y = widths(s.viewport)[2] - (s.local_origin[2] + frag_px[2]) * s.inv_px_scale
    window_x, window_y = origin(s.viewport) .+ (scene_x, scene_y)
    uv = s.uv_transform * Vec3f(window_x, window_y, 1)
    return sample_texture(s.image, uv, true, true)
end

struct RasterStrokeData
    color::RGBAf
    width_px::Float32
    aa_px::Float32
    edge_widths::Vector{Vec3f}
    wing_indices::Vector{Vec{6, Int32}}
    wing_widths::Vector{Vec{6, Float32}}
end

struct RasterLighting
    ambient::Vec3f
    light_color::Vec3f
    light_direction::Vec3f
    diffuse::Vec3f
    specular::Vec3f
    shininess::Float32
    backlight::Float32
end

# from lighting.frag
function smooth_zero_max(x::Float32)
    c = 0.00390625f0
    xswap = 0.6406707f0
    yswap = 0.20508383f0
    shift = 1.0f0 + xswap - yswap
    return x < yswap ? c * (x + shift)^8 : x
end

function blinn_phong(l::RasterLighting, camdir::Vec3f, normal::Vec3f, color::Vec3f)
    diff_coeff = smooth_zero_max(dot(l.light_direction, -normal)) +
        l.backlight * smooth_zero_max(dot(l.light_direction, normal))
    H = normalize(l.light_direction + camdir)
    spec_coeff = max(dot(H, -normal), 0.0f0)^l.shininess +
        l.backlight * max(dot(H, normal), 0.0f0)^l.shininess
    if diff_coeff <= 0.0f0 || isnan(spec_coeff)
        spec_coeff = 0.0f0
    end
    return l.light_color .* (l.diffuse .* diff_coeff .* color .+ l.specular .* spec_coeff)
end

function illuminate(l::RasterLighting, camdir::Vec3f, normal::Vec3f, color::RGBAf)
    base = Vec3f(color.r, color.g, color.b)
    shaded = l.ambient .* base .+ blinn_phong(l, camdir, normal, base)
    return RGBAf(shaded[1], shaded[2], shaded[3], color.alpha)
end

glsl_smoothstep(lo, hi, x) = let t = clamp((x - lo) / (hi - lo), 0.0f0, 1.0f0)
    t * t * (3.0f0 - 2.0f0 * t)
end

function distance_to_segment(p::Vec2f, a::Vec2f, b::Vec2f)
    ab = b - a
    len2 = dot(ab, ab)
    len2 < 1.0f-20 && return norm(p - a)
    t = clamp(dot(p - a, ab) / len2, 0.0f0, 1.0f0)
    return norm(p - a - t * ab)
end

function edge_face_factor(stroke::RasterStrokeData, p::Vec2f, a::Vec2f, b::Vec2f, width_multiplier::Float32)
    width_multiplier <= 0.0f0 && return 1.0f0
    width = width_multiplier * stroke.width_px
    return glsl_smoothstep(-stroke.aa_px, stroke.aa_px, distance_to_segment(p, a, b) - width)
end

# A wing band may only paint fragments whose surface plane the wing edge actually
# touches. A wing that merely projects nearby in screen space (the surface folding
# back on itself, the far side of a curved shape) lies at a different depth than the
# fragment's plane extrapolated to the same screen position, so it is rejected here.
function wing_face_factor(
        stroke::RasterStrokeData, p::Vec2f, a::Vec2f, b::Vec2f, width_multiplier::Float32,
        za::Float32, zb::Float32, frag_z::Float32, z_gradient::Vec2f
    )
    width_multiplier <= 0.0f0 && return 1.0f0

    ab = b - a
    len2 = dot(ab, ab)
    t = len2 < 1.0f-20 ? 0.0f0 : clamp(dot(p - a, ab) / len2, 0.0f0, 1.0f0)
    closest = a + t * ab
    dist = norm(p - closest)

    wing_z = (1.0f0 - t) * za + t * zb
    plane_z = frag_z + dot(z_gradient, closest - p)
    z_tolerance = (abs(z_gradient[1]) + abs(z_gradient[2])) * (dist + 1.0f0) + 1.0f-4
    abs(wing_z - plane_z) > z_tolerance && return 1.0f0

    width = width_multiplier * stroke.width_px
    return glsl_smoothstep(-stroke.aa_px, stroke.aa_px, dist - width)
end

function stroke_face_factor(stroke::RasterStrokeData, t::Int, face, pixel_positions, inv_ws, depths, p::Vec2f, frag_z::Float32)
    a = pixel_positions[face[1]]
    b = pixel_positions[face[2]]
    c = pixel_positions[face[3]]
    widths = stroke.edge_widths[t]

    factor = 1.0f0
    factor = min(factor, edge_face_factor(stroke, p, a, b, widths[1]))
    factor = min(factor, edge_face_factor(stroke, p, b, c, widths[2]))
    factor = min(factor, edge_face_factor(stroke, p, c, a, widths[3]))

    det = (b[1] - a[1]) * (c[2] - a[2]) - (b[2] - a[2]) * (c[1] - a[1])
    dzb = depths[face[2]] - depths[face[1]]
    dzc = depths[face[3]] - depths[face[1]]
    z_gradient = Vec2f(
        (c[2] - a[2]) * dzb - (b[2] - a[2]) * dzc,
        (b[1] - a[1]) * dzc - (c[1] - a[1]) * dzb,
    ) / det

    wing_indices = stroke.wing_indices[t]
    wing_widths = stroke.wing_widths[t]
    corners = (a, b, c)
    for i in 1:3, k in 1:2
        j = 2 * (i - 1) + k
        idx = wing_indices[j]
        idx == 0 && continue
        inv_ws[idx] > 0.0f0 || continue
        factor = min(
            factor,
            wing_face_factor(
                stroke, p, corners[i], pixel_positions[idx], wing_widths[j],
                depths[face[i]], depths[idx], frag_z, z_gradient
            )
        )
    end
    return factor
end

function mix_colors(a::RGBAf, b::RGBAf, factor::Float32)
    m(x, y) = (1.0f0 - factor) * x + factor * y
    return RGBAf(m(a.r, b.r), m(a.g, b.g), m(a.b, b.b), m(a.alpha, b.alpha))
end

# NaN → 0 like the GPU's float-to-unorm conversion (e.g. NaN lighting from
# degenerate-cell normals must not throw in the N0f8 constructor)
clamp01_nan(x::Float32) = ifelse(isnan(x), 0.0f0, clamp(x, 0.0f0, 1.0f0))

# source-over blending of straight-alpha src onto premultiplied dst
function blend_premultiplied(dst::RGBA{N0f8}, src::RGBAf)
    a = clamp01_nan(src.alpha)
    rest = 1.0f0 - a
    return RGBA{N0f8}(
        clamp(a * clamp01_nan(src.r) + rest * Float32(dst.r), 0.0f0, 1.0f0),
        clamp(a * clamp01_nan(src.g) + rest * Float32(dst.g), 0.0f0, 1.0f0),
        clamp(a * clamp01_nan(src.b) + rest * Float32(dst.b), 0.0f0, 1.0f0),
        clamp(a + rest * Float32(dst.alpha), 0.0f0, 1.0f0),
    )
end

function rasterize_mesh!(
        framebuffer::Matrix{RGBA{N0f8}}, depthbuffer::Matrix{Float32},
        faces, face_order, pixel_positions, inv_ws, depths,
        world_positions, world_normals, camdirs, clip_distances,
        color_sampler, lighting::Union{Nothing, RasterLighting},
        stroke::Union{Nothing, RasterStrokeData}
    )
    W, H = size(framebuffer)
    n_planes = size(clip_distances, 1)

    for t in face_order
        face = faces[t]
        i1, i2, i3 = face[1], face[2], face[3]
        (inv_ws[i1] > 0.0f0 && inv_ws[i2] > 0.0f0 && inv_ws[i3] > 0.0f0) || continue

        a = pixel_positions[i1]
        b = pixel_positions[i2]
        c = pixel_positions[i3]
        (isnan(a) || isnan(b) || isnan(c)) && continue

        det = (b[1] - a[1]) * (c[2] - a[2]) - (b[2] - a[2]) * (c[1] - a[1])
        abs(det) < 1.0f-10 && continue
        inv_det = 1.0f0 / det

        xmin = max(1, floor(Int, min(a[1], b[1], c[1]) + 0.5f0))
        xmax = min(W, ceil(Int, max(a[1], b[1], c[1]) + 0.5f0))
        ymin = max(1, floor(Int, min(a[2], b[2], c[2]) + 0.5f0))
        ymax = min(H, ceil(Int, max(a[2], b[2], c[2]) + 0.5f0))
        (xmin > xmax || ymin > ymax) && continue

        @inbounds for y in ymin:ymax, x in xmin:xmax
            p = Vec2f(x - 0.5f0, y - 0.5f0)

            wa = ((c[1] - b[1]) * (p[2] - b[2]) - (c[2] - b[2]) * (p[1] - b[1])) * inv_det
            wb = ((a[1] - c[1]) * (p[2] - c[2]) - (a[2] - c[2]) * (p[1] - c[1])) * inv_det
            wc = 1.0f0 - wa - wb
            (wa >= 0.0f0 && wb >= 0.0f0 && wc >= 0.0f0) || continue

            # depth interpolates linearly in screen space
            z = wa * depths[i1] + wb * depths[i2] + wc * depths[i3]
            (-1.0f0 <= z <= 1.0f0) || continue
            z <= depthbuffer[x, y] || continue

            # perspective-correct attribute weights
            pa = wa * inv_ws[i1]
            pb = wb * inv_ws[i2]
            pc = wc * inv_ws[i3]
            inv_sum = 1.0f0 / (pa + pb + pc)
            pa *= inv_sum
            pb *= inv_sum
            pc *= inv_sum
            weights = Vec3f(pa, pb, pc)

            if n_planes > 0
                clipped = false
                for plane in 1:n_planes
                    dist = pa * clip_distances[plane, i1] + pb * clip_distances[plane, i2] + pc * clip_distances[plane, i3]
                    if dist < 0.0f0
                        clipped = true
                        break
                    end
                end
                clipped && continue
            end

            color = fragment_color(color_sampler, face, weights, p)

            if lighting !== nothing
                normal = zero_normalize(
                    pa * world_normals[i1] + pb * world_normals[i2] + pc * world_normals[i3]
                )
                camdir = zero_normalize(
                    pa * camdirs[i1] + pb * camdirs[i2] + pc * camdirs[i3]
                )
                color = illuminate(lighting, camdir, normal, color)
            end

            if stroke !== nothing
                factor = stroke_face_factor(stroke, t, face, pixel_positions, inv_ws, depths, p, z)
                color = mix_colors(stroke.color, color, factor)
            end

            framebuffer[x, y] = blend_premultiplied(framebuffer[x, y], color)
            depthbuffer[x, y] = z
        end
    end
    return
end

function pack_downsampled_argb32(framebuffer::Matrix{RGBA{N0f8}}, ss::Int)
    W, H = size(framebuffer)
    w = W ÷ ss
    h = H ÷ ss
    out = Matrix{UInt32}(undef, w, h)
    inv_n = 1.0f0 / (ss * ss)
    for y in 1:h, x in 1:w
        r = 0.0f0
        g = 0.0f0
        b = 0.0f0
        a = 0.0f0
        for sy in 1:ss, sx in 1:ss
            c = framebuffer[(x - 1) * ss + sx, (y - 1) * ss + sy]
            r += Float32(c.r)
            g += Float32(c.g)
            b += Float32(c.b)
            a += Float32(c.alpha)
        end
        to_byte(v) = UInt32(round(UInt8, clamp(v * inv_n, 0.0f0, 1.0f0) * 255))
        out[x, y] = to_byte(a) << 24 | to_byte(r) << 16 | to_byte(g) << 8 | to_byte(b)
    end
    return out
end

pattern_tile(sampler::Makie.ShaderAbstractions.Sampler) = Matrix{RGBAf}(sampler.data)
pattern_tile(image::AbstractMatrix{<:Colorant}) = Matrix{RGBAf}(image)

# For surfaces, uvs are rescaled so that grid vertices map to texel centers of a
# same-sized color matrix, like the (W)GLMakie sampling of surface color textures.
function texture_uvs(uvs, uv_transform, grid_size)
    if !(uvs isa Vector{Vec2f})
        error("Meshes with a texture color need 2D texture coordinates.")
    end
    if uv_transform !== nothing
        uvt = uv_transform::Mat{2, 3, Float32, 6}
        uvs = map(uv -> uvt * to_ndim(Vec3f, uv, 1), uvs)
    end
    if grid_size !== nothing
        scale = Vec2f((grid_size .- 1) ./ grid_size)
        trans = Vec2f(0.5 ./ grid_size)
        uvs = map(uv -> scale .* uv .+ trans, uvs)
    end
    return uvs
end

function mesh_color_sampler(plot, uvs, uv_transform, grid_size)
    scaled_color = plot.scaled_color[]
    if scaled_color isa AbstractMatrix{<:Real}
        return ValueTextureSampler(
            Float32.(scaled_color), texture_uvs(uvs, uv_transform, grid_size),
            plot.interpolate[]::Bool, ColormapData(plot)
        )
    elseif scaled_color isa AbstractVector{<:Real}
        return VertexValueSampler(Float32.(scaled_color), ColormapData(plot))
    end

    color = compute_colors(plot)
    if color isa Matrix{RGBAf}
        return TextureColorSampler(color, texture_uvs(uvs, uv_transform, grid_size), plot.interpolate[]::Bool)
    elseif color isa Vector{RGBAf}
        return VertexColorSampler(color)
    else
        return UniformColorSampler(color::RGBAf)
    end
end

function draw_mesh_rasterized(scene::Scene, screen::Screen, plot::ComputeGraph; grid_size = nothing)
    positions = plot.positions_transformed_f32c[]::Union{Vector{Point2f}, Vector{Point3f}}
    faces = plot.faces[]::Vector{GLTriangleFace}
    isempty(faces) && return

    model = plot.model_f32c[]::Mat4f
    projectionview = plot.projectionview[]::Mat4f
    resolution = plot.resolution[]::Vec2f
    depth_shift = plot.depth_shift[]::Float32
    space = plot.space[]::Symbol
    eyeposition = plot.eyeposition[]::Vec3f

    ss = RASTERIZER_SUPERSAMPLING
    px_scale = Float32(ss * screen.device_scaling_factor)
    viewport_w = resolution[1] * px_scale
    viewport_h = resolution[2] * px_scale

    # vertex stage
    n = length(positions)
    pixel_positions = Vector{Vec2f}(undef, n)
    inv_ws = Vector{Float32}(undef, n)
    depths = Vector{Float32}(undef, n)
    world_positions = Vector{Vec3f}(undef, n)
    pvm = projectionview * model
    for i in 1:n
        p4d = to_ndim(Point4f, to_ndim(Point3f, positions[i], 0), 1)
        world = model * p4d
        world_positions[i] = Vec3f(world[1], world[2], world[3]) / world[4]
        clip = pvm * p4d
        if clip[4] <= 1.0f-10
            inv_ws[i] = 0.0f0
            pixel_positions[i] = Vec2f(NaN)
            depths[i] = NaN32
            continue
        end
        inv_ws[i] = 1.0f0 / clip[4]
        ndc = Vec3f(clip[1], clip[2], clip[3]) * inv_ws[i]
        pixel_positions[i] = Vec2f((0.5f0 * ndc[1] + 0.5f0) * viewport_w, (0.5f0 - 0.5f0 * ndc[2]) * viewport_h)
        depths[i] = ndc[3] + depth_shift
    end

    # rasterize only the projected bounding box of the mesh, clamped to the viewport
    xlo = ylo = Inf32
    xhi = yhi = -Inf32
    for i in 1:n
        p = pixel_positions[i]
        (isnan(p) || inv_ws[i] <= 0.0f0) && continue
        xlo = min(xlo, p[1])
        xhi = max(xhi, p[1])
        ylo = min(ylo, p[2])
        yhi = max(yhi, p[2])
    end
    isfinite(xlo) && isfinite(ylo) || return
    # one downsampled pixel of padding keeps a transparent ring around the mesh, so
    # EXTEND_PAD and Cairo's filtering fade the silhouette out instead of smearing it
    x0 = clamp(floor(Int, xlo) - ss, 0, ceil(Int, viewport_w))
    y0 = clamp(floor(Int, ylo) - ss, 0, ceil(Int, viewport_h))
    x1 = clamp(ceil(Int, xhi) + ss, 0, ceil(Int, viewport_w))
    y1 = clamp(ceil(Int, yhi) + ss, 0, ceil(Int, viewport_h))
    W = cld(x1 - x0, ss) * ss
    H = cld(y1 - y0, ss) * ss
    (W <= 0 || H <= 0) && return
    offset = Vec2f(x0, y0)
    for i in 1:n
        pixel_positions[i] = pixel_positions[i] - offset
    end

    # lighting
    shading = plot.shading[]::Bool && (scene.compute.shading[] != NoShading)
    meshnormals = plot.normals[]::Union{Nothing, Vector{Vec3f}}
    lighting = nothing
    world_normals = Vec3f[]
    camdirs = Vec3f[]
    if shading && meshnormals !== nothing
        i3 = Vec(1, 2, 3)
        normalmatrix = transpose(inv(Mat3f(model[i3, i3])))
        world_normals = [zero_normalize(normalmatrix * normal) for normal in meshnormals]
        camdirs = [world_positions[i] - eyeposition for i in 1:n]
        lighting = RasterLighting(
            to_vec(scene.compute[:ambient_color][]),
            to_vec(scene.compute[:dirlight_color][]),
            scene.compute[:dirlight_final_direction][]::Vec3f,
            plot.diffuse[]::Vec3f,
            plot.specular[]::Vec3f,
            plot.shininess[]::Float32,
            plot.backlight[]::Float32,
        )
    end

    # clip planes
    clip_planes = Makie.is_data_space(space) ? plot.clip_planes[]::Vector{Plane3f} : Plane3f[]
    clip_distances = Matrix{Float32}(undef, length(clip_planes), isempty(clip_planes) ? 0 : n)
    for (j, plane) in enumerate(clip_planes), i in 1:n
        clip_distances[j, i] = Makie.distance(plane, world_positions[i])
    end

    # color
    uv_transform = plot.pattern_uv_transform[]::Union{Nothing, Mat{2, 3, Float32, 6}}
    matcap::Union{Nothing, Matrix{RGBAf}} = to_value(get(plot, :matcap, nothing))
    color_sampler = if plot.fetch_pixel[]::Bool
        PatternSampler(
            pattern_tile(compute_colors(plot)), uv_transform::Mat{2, 3, Float32, 6},
            scene.viewport[], Vec2f(x0, y0), 1.0f0 / px_scale
        )
    elseif matcap !== nothing && meshnormals !== nothing
        view = plot.view[]::Mat4f
        i3 = Vec(1, 2, 3)
        view_normalmatrix = transpose(inv(Mat3f((view * model)[i3, i3])))
        view_normals = [zero_normalize(view_normalmatrix * normal) for normal in meshnormals]
        MatcapSampler(matcap, view_normals)
    else
        mesh_color_sampler(plot, plot.texturecoordinates[], uv_transform, grid_size)
    end

    # stroke
    stroke = nothing
    edge_widths = plot.stroke_edge_widths[]::Vector{Vec3f}
    if !iszero(plot.strokewidth[]) && !isempty(edge_widths)
        stroke = RasterStrokeData(
            plot.strokecolor[]::RGBAf,
            Float32(plot.strokewidth[]) * px_scale,
            0.7f0 * px_scale,
            edge_widths,
            plot.stroke_wing_indices[]::Vector{Vec{6, Int32}},
            plot.stroke_wing_widths[]::Vector{Vec{6, Float32}},
        )
    end

    # render back to front with a depth buffer, so that semi-transparent fragments
    # composite correctly while intersecting geometry still resolves per fragment
    face_depth = map(f -> (depths[f[1]] + depths[f[2]] + depths[f[3]]) / 3, faces)
    face_order = sortperm(face_depth, rev = true)

    framebuffer = fill(RGBA{N0f8}(0, 0, 0, 0), W, H)
    depthbuffer = fill(Inf32, W, H)
    rasterize_mesh!(
        framebuffer, depthbuffer,
        faces, face_order, pixel_positions, inv_ws, depths,
        world_positions, world_normals, camdirs, clip_distances,
        color_sampler, lighting, stroke
    )

    # composite like an image plot covering the rasterized region of the viewport
    ctx = screen.context
    surface = to_cairo_image(pack_downsampled_argb32(framebuffer, ss))
    rect_x = x0 / px_scale
    rect_y = y0 / px_scale
    rect_w = W / px_scale
    rect_h = H / px_scale
    Cairo.rectangle(ctx, rect_x, rect_y, rect_w, rect_h)
    Cairo.save(ctx)
    Cairo.translate(ctx, rect_x, rect_y)
    Cairo.scale(ctx, rect_w / surface.width, rect_h / surface.height)
    Cairo.set_source_surface(ctx, surface, 0, 0)
    pattern = Cairo.get_source(ctx)
    if !(screen isa Screen{SVG})
        Cairo.pattern_set_extend(pattern, Cairo.EXTEND_PAD)
    end
    Cairo.pattern_set_filter(pattern, Cairo.FILTER_BILINEAR)
    Cairo.fill(ctx)
    Cairo.restore(ctx)

    return
end
