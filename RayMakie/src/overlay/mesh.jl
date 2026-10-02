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
# Not a Makie light: a glowing mesh the raster path lights with, as the tracer
# makes its triangles area lights. See plots/raster_material.jl.
const LIGHT_EMITTER = Int32(6)

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

# ─── the tracer's lights ─────────────────────────────────────────────────────
#
# A display-encoded film stands in for the traced picture, so its lights mean
# what they mean to Hikari (pbrt-v4): a directional light of colour `c` is
# irradiance `c` on a surface facing it, a point or spot light is intensity `c`
# falling off as `1/r²`, and the plot's `Diffuse` material reflects `albedo/π`
# of it, with no highlight. GLMakie's Blinn-Phong has none of the `1/π` and adds
# a highlight, which lit a directional scene 2.5x brighter than its traced self.
#
# A light gives its irradiance and the direction it comes from; the material
# turns that into radiance (`reflect_light`).

"""
    incoming(kind, lc, params, idx, world_pos) -> (irradiance at normal incidence, direction to the light)
"""
@inline function incoming(kind::Int32, lc::Vec3f, params, idx::Int32, world_pos::Vec3f)
    if kind == LIGHT_POINT
        @inbounds position = Vec3f(params[idx + 1], params[idx + 2], params[idx + 3])
        light_vec = position - world_pos
        return lc * (1f0 / dot(light_vec, light_vec)), _unit(light_vec)
    elseif kind == LIGHT_DIRECTIONAL
        @inbounds light_dir = Vec3f(params[idx + 1], params[idx + 2], params[idx + 3])
        return lc, -light_dir
    elseif kind == LIGHT_SPOT
        @inbounds position = Vec3f(params[idx + 1], params[idx + 2], params[idx + 3])
        @inbounds spot_dir = _unit(Vec3f(params[idx + 4], params[idx + 5], params[idx + 6]))
        @inbounds inner = params[idx + 7]
        @inbounds outer = params[idx + 8]
        light_vec = position - world_pos
        cone = smoothstep(outer, inner, dot(-_unit(light_vec), spot_dir))
        return lc * (cone / dot(light_vec, light_vec)), _unit(light_vec)
    elseif kind == LIGHT_EMITTER
        # A flat patch of area A and radiance L (`lc`): irradiance L A cosθ /
        # (r² + A/π), cosθ at the patch. On its axis that is exactly what a disc
        # of that area gives, and it tends to π L, an infinite plane, close up.
        @inbounds centre = Vec3f(params[idx + 1], params[idx + 2], params[idx + 3])
        @inbounds n = Vec3f(params[idx + 4], params[idx + 5], params[idx + 6])
        @inbounds area = params[idx + 7]
        @inbounds two_sided = params[idx + 8]
        light_vec = centre - world_pos
        d2 = dot(light_vec, light_vec)
        l = _unit(light_vec)
        c = -dot(n, l)
        c = two_sided != 0f0 ? abs(c) : max(c, 0f0)
        return lc * (area * c / (d2 + area * Float32(inv(π)))), l
    else  # LIGHT_RECT, which the tracer does not convert; lit as its direction
        @inbounds light_dir = Vec3f(params[idx + 10], params[idx + 11], params[idx + 12])
        return lc, -light_dir
    end
end

# ─── pbrt's materials ────────────────────────────────────────────────────────
#
# The Hikari material a mesh is traced with, as the raster shader evaluates it
# (`raster_material` in plots/raster_material.jl converts one): pbrt-v4's
# BxDFs, closed-form. A Trowbridge-Reitz (GGX) lobe with Smith's masking and the
# exact Fresnel terms where pbrt has a microfacet lobe; the stochastic layered
# BxDF of a coated material as its single-scattering limit, a coat lobe over
# the base seen through the coat twice, with the base's light bouncing inside
# the coat summed in closed form (energy-conserving: a white base under a
# clear coat reflects all of uniform light).
#
# What a raster pass cannot do it leaves out: refraction (glass is see-through
# with its Fresnel transmittance), and light reflected off other surfaces.

const MAT_LAMBERT = 0f0                # `Diffuse`, or a plot without a Hikari material
const MAT_COATED_DIFFUSE = 1f0
const MAT_CONDUCTOR = 2f0
const MAT_COATED_CONDUCTOR = 3f0
const MAT_DIELECTRIC = 4f0
const MAT_THIN_DIELECTRIC = 5f0
const MAT_DIFFUSE_TRANSMISSION = 6f0

"""
    RasterMaterial(a, b, c, d)

A pbrt material for the raster shader. The base colour (diffuse reflectance,
glass transmittance) comes with the mesh's colour, so it can be a texture.

* `a`: kind (`MAT_*`), α of the top lobe (coat, conductor or glass), η of the
  coat or glass, coat thickness (DiffuseTransmission: its scale)
* `b`: conductor η at 630, 532 and 465 nm (relative to the coat when coated),
  α of a coated conductor's conductor
* `c`: conductor k likewise, and the coat's hemispherical-average external
  Fresnel reflectance F̄ₑ
* `d`: tint (a conductor's reflectance, glass Kr, DiffuseTransmission's
  transmittance), and the coat's internal F̄ᵢ
"""
struct RasterMaterial
    a::Vec4f
    b::Vec4f
    c::Vec4f
    d::Vec4f
end

const LAMBERT = RasterMaterial(Vec4f(0), Vec4f(0), Vec4f(0), Vec4f(0))

@inline material_kind(m::RasterMaterial) = m.a[1]

"""Whether glass: drawn see-through with its Fresnel transmittance."""
@inline is_glass(m::RasterMaterial) =
    material_kind(m) == MAT_DIELECTRIC || material_kind(m) == MAT_THIN_DIELECTRIC

# Trowbridge-Reitz (isotropic) as pbrt-v4 writes it, from cosines.
@inline function tr_d(nh::Float32, α::Float32)
    a2 = α * α
    t = nh * nh * (a2 - 1f0) + 1f0
    return a2 / (Float32(π) * t * t)
end
@inline function tr_lambda(c::Float32, α::Float32)
    c2 = max(c * c, 1f-8)
    return (sqrt(1f0 + α * α * (1f0 - c2) / c2) - 1f0) * 0.5f0
end
@inline tr_g(nv::Float32, nl::Float32, α::Float32) = 1f0 / (1f0 + tr_lambda(nv, α) + tr_lambda(nl, α))

"""
A microfacet lobe of roughness α, without its Fresnel: D G / (4 cos θₒ), i.e.
f cos θᵢ / F. Seen in an area light (`widen` > 0, see `emitter_highlight`) the
lobe is evaluated towards the light's representative point and its peak
lowered to the widened lobe's, (α / (α + widen))² (Karis): the energy of a
light that size, without blurring a sharp lobe's edge. A smooth lobe (below
pbrt's threshold) is evaluated at α = 0.01, still a mirror to the eye but wide
enough that its peak is not lost to Float32 rounding of n·h; for a point light
(`widen` 0) it sees nothing, as a delta lobe never meets one.
"""
@inline function microfacet(nv::Float32, nl::Float32, nh::Float32, α::Float32, widen::Float32)
    if α < 1f-3
        widen == 0f0 && return 0f0
        α = 1f-2
    end
    α2 = α + widen
    norm = (α / α2) * (α / α2)
    return tr_d(nh, α) * norm * tr_g(nv, nl, α2) / (4f0 * nv)
end

@inline fr_dielectric(c::Float32, η::Float32) = Hikari.fresnel_dielectric(c, η)
@inline fr_conductor(c::Float32, m::RasterMaterial) =
    Vec3f(Hikari.fr_complex(c, m.b[1], m.c[1]), Hikari.fr_complex(c, m.b[2], m.c[2]),
          Hikari.fr_complex(c, m.b[3], m.c[3])) .* Vec3f(m.d[1], m.d[2], m.d[3])

"""pbrt's ThinDielectric: both faces' reflections summed, R = F + T²F/(1-F²)."""
@inline function thin_reflectance(c::Float32, η::Float32)
    r = fr_dielectric(c, η)
    t = 1f0 - r
    return r < 1f0 ? r + t * t * r / (1f0 - r * r) : r
end

"""The cosine inside a coat of index η of a direction with cosine `c` outside it."""
@inline coat_cos(c::Float32, η::Float32) = sqrt(max(1f0 - (1f0 - c * c) / (η * η), 1f-4))

"""
How much of what a coat's base sends up, and of what reaches it, gets through:
the two Fresnel transmittances and the coat's absorption over its thickness
along both paths (pbrt's `Tr`), over the light that bounces back down
(1 - R F̄ᵢ) and the radiance spread over the wider cone in air (η²).
"""
@inline function coat_transfer(nv::Float32, nl::Float32, m::RasterMaterial)
    η, thickness = m.a[3], m.a[4]
    tr = exp(-thickness / coat_cos(nv, η) - thickness / coat_cos(nl, η))
    return (1f0 - fr_dielectric(nv, η)) * (1f0 - fr_dielectric(nl, η)) * tr / (η * η)
end

"""
    diffuse_part(m, base, n, v, l) -> f cos θᵢ (rgb)

The material's diffuse lobe towards the eye `v` per unit irradiance from `l`:
Lambert, a coated base seen through its coat, or DiffuseTransmission's
reflectance (lit side) and transmittance (from behind).
"""
@inline function diffuse_part(m::RasterMaterial, base::Vec3f, n::Vec3f, v::Vec3f, l::Vec3f)
    kind = material_kind(m)
    nl = dot(n, l)
    if kind == MAT_DIFFUSE_TRANSMISSION
        s = m.a[4] * Float32(inv(π)) * abs(nl)
        return nl >= 0f0 ? base * s : Vec3f(m.d[1], m.d[2], m.d[3]) * s
    end
    nl <= 0f0 && return Vec3f(0f0)
    kind == MAT_LAMBERT && return base * (nl * Float32(inv(π)))
    kind == MAT_COATED_DIFFUSE || return Vec3f(0f0)
    nv = max(dot(n, v), 1f-4)
    return base * (Float32(inv(π)) * nl * coat_transfer(nv, nl, m)) ./ (Vec3f(1f0) - base * m.d[4])
end

"""
    specular_part(m, n, v, l, widen) -> f cos θᵢ (rgb)

The material's microfacet lobes towards the eye `v` per unit irradiance from
`l`, widened by `widen` (half an area light's angular radius, zero for a point
or directional light): a lobe narrower than pbrt's smoothness threshold then
sees nothing, as a delta lobe never meets a point light.
"""
@inline function specular_part(m::RasterMaterial, n::Vec3f, v::Vec3f, l::Vec3f, widen::Float32)
    kind = material_kind(m)
    (kind == MAT_LAMBERT || kind == MAT_DIFFUSE_TRANSMISSION) && return Vec3f(0f0)
    nl = dot(n, l)
    nl <= 0f0 && return Vec3f(0f0)
    nv = max(dot(n, v), 1f-4)
    h = _unit(v + l)
    nh = max(dot(n, h), 0f0)
    vh = max(dot(v, h), 0f0)
    spec = microfacet(nv, nl, nh, m.a[2], widen)
    if kind == MAT_COATED_DIFFUSE
        return Vec3f(spec * fr_dielectric(vh, m.a[3]))
    elseif kind == MAT_CONDUCTOR
        return fr_conductor(vh, m) * spec
    elseif kind == MAT_COATED_CONDUCTOR
        η = m.a[3]
        under = microfacet(nv, nl, nh, m.b[4], widen) * coat_transfer(nv, nl, m) * η * η
        return Vec3f(spec * fr_dielectric(vh, η)) + fr_conductor(vh, m) * under
    elseif kind == MAT_DIELECTRIC
        return Vec3f(m.d[1], m.d[2], m.d[3]) * (spec * fr_dielectric(vh, m.a[3]))
    else  # MAT_THIN_DIELECTRIC
        return Vec3f(spec * thin_reflectance(vh, m.a[3]))
    end
end

"""
What the material reflects of light arriving equally from everywhere (the
ambient light, the environment), split as (diffuse, specular): the diffuse
part is lit by the irradiance around the normal, the specular part by the
light around the mirror direction.
"""
@inline function ambient_response(m::RasterMaterial, base::Vec3f, n::Vec3f, v::Vec3f)
    kind = material_kind(m)
    nv = max(dot(n, v), 1f-4)
    if kind == MAT_LAMBERT
        return base, Vec3f(0f0)
    elseif kind == MAT_DIFFUSE_TRANSMISSION
        # uniform light reaches it from both sides
        return (base + Vec3f(m.d[1], m.d[2], m.d[3])) * m.a[4], Vec3f(0f0)
    elseif kind == MAT_COATED_DIFFUSE
        η = m.a[3]
        # the coat transfer averaged over the incoming hemisphere: (1 - F̄ₑ) for
        # the Fresnel term, the absorption along a typical (60°) path
        tr = exp(-m.a[4] / coat_cos(nv, η) - m.a[4] / coat_cos(0.5f0, η))
        diffuse = base * ((1f0 - fr_dielectric(nv, η)) * (1f0 - m.c[4]) * tr / (η * η)) ./ (Vec3f(1f0) - base * m.d[4])
        return diffuse, Vec3f(fr_dielectric(nv, η))
    elseif kind == MAT_CONDUCTOR
        return Vec3f(0f0), fr_conductor(nv, m)
    elseif kind == MAT_COATED_CONDUCTOR
        fc = fr_dielectric(nv, m.a[3])
        return Vec3f(0f0), Vec3f(fc) + fr_conductor(nv, m) * ((1f0 - fc) * (1f0 - m.c[4]))
    elseif kind == MAT_DIELECTRIC
        return Vec3f(0f0), Vec3f(m.d[1], m.d[2], m.d[3]) * fr_dielectric(nv, m.a[3])
    else
        return Vec3f(0f0), Vec3f(thin_reflectance(nv, m.a[3]))
    end
end

"""
How much of what is behind glass gets through it at this angle (one surface:
a closed solid has two, and both are drawn): the Fresnel transmittance times
the glass's own (`base`, its Kt) for a dielectric, everything not reflected
for a thin one.
"""
@inline function glass_transmittance(m::RasterMaterial, base::Vec3f, n::Vec3f, v::Vec3f)
    nv = max(dot(n, v), 1f-4)
    material_kind(m) == MAT_THIN_DIELECTRIC && return 1f0 - thin_reflectance(nv, m.a[3])
    lum = 0.2126f0 * base[1] + 0.7152f0 * base[2] + 0.0722f0 * base[3]
    return (1f0 - fr_dielectric(nv, m.a[3])) * lum
end

"""
    emitter_highlight(m, n, v, p, centre, en, area, two_sided, L) -> radiance

The specular reflection of a glowing patch (centre, normal `en`, `area`) in the
material's lobes, by the representative-point method: the lobe is evaluated
towards the point of the patch nearest the mirror ray, widened by the patch's
angular size, and weighted by its solid angle. In a mirror that is the patch's
radiance where the mirror ray meets it; in a rough lobe, the light's
highlight.
"""
@inline function emitter_highlight(m::RasterMaterial, n::Vec3f, v::Vec3f, p::Vec3f,
                                   centre::Vec3f, en::Vec3f, area::Float32, two_sided::Float32, L::Vec3f)
    r = 2f0 * dot(n, v) * n - v
    radius = sqrt(area * Float32(inv(π)))
    q = centre
    denom = dot(r, en)
    if abs(denom) > 1f-6
        t = dot(centre - p, en) / denom
        if t > 0f0
            off = p + t * r - centre
            len = sqrt(dot(off, off))
            q = len > radius ? centre + off * (radius / len) : centre + off
        end
    end
    lv = q - p
    d2 = dot(lv, lv)
    l = lv * (1f0 / sqrt(d2))
    cl = -dot(en, l)
    cl = two_sided != 0f0 ? abs(cl) : max(cl, 0f0)
    solid_angle = area * cl / (d2 + area * Float32(inv(π)))
    widen = 0.5f0 * radius / sqrt(d2)
    # the specular lobes only: the diffuse part comes with the patch's irradiance
    return L .* specular_part(m, n, v, l, widen) * solid_angle
end

light_parameter_count(kind) = kind == LIGHT_POINT ? Int32(5) : kind == LIGHT_DIRECTIONAL ? Int32(3) :
                              kind == LIGHT_SPOT ? Int32(8) : kind == LIGHT_EMITTER ? Int32(8) : Int32(12)

# ─── the shadow map ──────────────────────────────────────────────────────────
#
# One directional light casts, through a depth map the frame renders from it
# before anything else (see `shadow_frame` in overlay/shadow.jl). `params` is
# (resolution, world size of a texel, on, 0); a receiver outside the map, or a
# frame without one, is lit.

@inline function shadow_depth(shadow_map, res::Int32, x::Int32, y::Int32)
    x = clamp(x, Int32(0), res - Int32(1))
    y = clamp(y, Int32(0), res - Int32(1))
    @inbounds return shadow_map[y * res + x + Int32(1)]
end

"""
How much of the shadowed light reaches `world_pos`: 1 lit, 0 in shadow.

The point is pushed off the surface along its normal before it is looked up,
more at grazing light, so a surface does not shadow itself (acne) without the
depth bias that detaches shadows from their casters. The comparison is a 4x4
tap box filter with bilinear weights, so a hard shadow's edge moves smoothly
instead of in texel steps as the caster animates.
"""
@inline function shadow_visibility(shadow_map, light_space::Mat4f, params::Vec4f,
                                   world_pos::Vec3f, normal::Vec3f, light_dir::Vec3f)
    params[3] == 0f0 && return 1f0
    res = unsafe_trunc(Int32, params[1])
    texel = params[2]
    cosl = clamp(dot(light_dir, -normal), 0f0, 1f0)
    p = world_pos + normal * (texel * (0.6f0 + 1.8f0 * (1f0 - cosl)))
    c = light_space * Vec4f(p[1], p[2], p[3], 1f0)
    (abs(c[1]) > 1f0 || abs(c[2]) > 1f0) && return 1f0
    depth = 0.5f0 * (c[3] + 1f0)
    depth > 1f0 && return 1f0
    u = (0.5f0 * c[1] + 0.5f0) * params[1] - 0.5f0
    v = (0.5f0 * c[2] + 0.5f0) * params[1] - 0.5f0
    x0 = unsafe_trunc(Int32, floor(u))
    y0 = unsafe_trunc(Int32, floor(v))
    fx = u - Float32(x0)
    fy = v - Float32(y0)
    bias = 2f-4
    lit = 0f0
    for j in Int32(-1):Int32(2)
        wy = j == Int32(-1) ? 1f0 - fy : j == Int32(2) ? fy : 1f0
        for i in Int32(-1):Int32(2)
            wx = i == Int32(-1) ? 1f0 - fx : i == Int32(2) ? fx : 1f0
            d = shadow_depth(shadow_map, res, x0 + i, y0 + j)
            lit += depth - bias <= d ? wx * wy : 0f0
        end
    end
    return lit * (1f0 / 9f0)
end

# ─── ambient occlusion ───────────────────────────────────────────────────────
#
# The tracer's ambient light is uniform from every direction, so what a point
# gets of it is the cosine-weighted share of its hemisphere that is open. That
# is measured here the way the sun's shadow is: depth maps along `count`
# directions spread over the sphere, all in one atlas, and a point averages
# which of them see it. Every map covers the sphere `centre`/`radius` around
# what the camera sees; `ao_matrix` is shared with the host that renders them.

"""The `k`th of `n` directions (0-based) on a Fibonacci sphere, pointing away from the surface."""
@inline function ao_direction(k::Int32, n::Int32)
    z = 1f0 - (2f0 * Float32(k) + 1f0) / Float32(n)
    r = sqrt(max(0f0, 1f0 - z * z))
    phi = Float32(k) * 2.3999632f0
    return Vec3f(r * cos(phi), r * sin(phi), z)
end

"""An orthonormal frame whose third axis is `z`, the same on host and device."""
@inline function light_basis(z::Vec3f)
    up = abs(z[3]) < 0.99f0 ? Vec3f(0f0, 0f0, 1f0) : Vec3f(0f0, 1f0, 0f0)
    x = _unit(cross(up, z))
    return x, cross(z, x), z
end

"""
Orthographic light matrix, GL clip convention: the square of half-width `half`
around `centre` seen along `-z` and snapped to its texels, depth over
`±depth_radius` with the side nearest the light at 0.
"""
@inline function ortho_light(z::Vec3f, centre::Vec3f, half::Float32, depth_radius::Float32, texel::Float32)
    x, y, z = light_basis(z)
    cx = round(dot(x, centre) / texel) * texel
    cy = round(dot(y, centre) / texel) * texel
    cz = dot(z, centre)
    s = 1f0 / half
    a = -1f0 / depth_radius
    b = cz / depth_radius
    return Mat4f(s * x[1], s * y[1], a * z[1], 0f0,
                 s * x[2], s * y[2], a * z[2], 0f0,
                 s * x[3], s * y[3], a * z[3], 0f0,
                 -s * cx, -s * cy, b, 1f0)
end

"""
    ao_matrix(k, count, centre, params) -> Mat4f

The `k`th ambient map's light matrix. `centre` is (centre, radius) and `params`
(depth radius, resolution, count, atlas columns), the two uniforms every mesh
reads.
"""
@inline function ao_matrix(k::Int32, centre::Vec4f, params::Vec4f)
    n = unsafe_trunc(Int32, params[3])
    radius = centre[4]
    return ortho_light(ao_direction(k, n), Vec3f(centre[1], centre[2], centre[3]), radius,
                       params[1], 2f0 * radius / params[2])
end

@inline function ao_depth(ao_map, width::Int32, x0::Int32, y0::Int32, res::Int32, x::Int32, y::Int32)
    x = clamp(x, Int32(0), res - Int32(1)) + x0
    y = clamp(y, Int32(0), res - Int32(1)) + y0
    @inbounds return ao_map[y * width + x + Int32(1)]
end

"""Depth comparison at texel position (`u`, `v`) over 2x2 texels with bilinear weights."""
@inline function ao_compare(ao_map, width::Int32, x0::Int32, y0::Int32, res::Int32,
                            u::Float32, v::Float32, depth::Float32)
    xi = unsafe_trunc(Int32, floor(u))
    yi = unsafe_trunc(Int32, floor(v))
    fx = u - Float32(xi)
    fy = v - Float32(yi)
    lit = 0f0
    for j in Int32(0):Int32(1), i in Int32(0):Int32(1)
        d = ao_depth(ao_map, width, x0, y0, res, xi + i, yi + j)
        w = (i == Int32(0) ? 1f0 - fx : fx) * (j == Int32(0) ? 1f0 - fy : fy)
        lit += depth <= d ? w : 0f0
    end
    return lit
end

"""
How much of one direction's cone of ambient light reaches the point `c` (light
clip space) of the tile at `x0`,`y0`.

A direction stands for the cone around it, about `spread` wide (tangent of the
half-angle), so its shadow is soft and grows with the distance to what casts
it, as the traced ambient's does: the blockers near the point are averaged
first, and the comparison is spread over the penumbra that distance gives.
With hard lookups every direction drew its own copy of a caster's outline.
"""
@inline function ao_lookup(ao_map, width::Int32, x0::Int32, y0::Int32, res::Int32, c::Vec4f,
                           texel::Float32, depth_span::Float32, spread::Float32)
    (abs(c[1]) > 1f0 || abs(c[2]) > 1f0) && return 1f0
    depth = 0.5f0 * (c[3] + 1f0) - 1f-4
    depth > 1f0 && return 1f0
    u = (0.5f0 * c[1] + 0.5f0) * Float32(res) - 0.5f0
    v = (0.5f0 * c[2] + 0.5f0) * Float32(res) - 0.5f0
    search = 12f0
    blockers = 0f0
    found = 0f0
    for j in Int32(0):Int32(3), i in Int32(0):Int32(3)
        du = (Float32(i) - 1.5f0) * (search / 1.5f0)
        dv = (Float32(j) - 1.5f0) * (search / 1.5f0)
        d = ao_depth(ao_map, width, x0, y0, res, unsafe_trunc(Int32, floor(u + du + 0.5f0)),
                     unsafe_trunc(Int32, floor(v + dv + 0.5f0)))
        if d < depth
            blockers += d
            found += 1f0
        end
    end
    found == 0f0 && return 1f0
    distance = (depth - blockers / found) * depth_span
    r = clamp(distance * spread / texel, 1f0, 24f0)
    lit = 0f0
    for j in Int32(-1):Int32(1), i in Int32(-1):Int32(1)
        lit += ao_compare(ao_map, width, x0, y0, res, u + Float32(i) * r, v + Float32(j) * r, depth)
    end
    return lit * (1f0 / 9f0)
end

"""The cosine-weighted share of the ambient light that reaches `world_pos`."""
@inline function ambient_visibility(ao_map, centre::Vec4f, params::Vec4f, world_pos::Vec3f, normal::Vec3f)
    params[3] == 0f0 && return 1f0
    n = unsafe_trunc(Int32, params[3])
    res = unsafe_trunc(Int32, params[2])
    cols = unsafe_trunc(Int32, params[4])
    width = cols * res
    texel = 2f0 * centre[4] / params[2]
    p = world_pos + normal * (1.5f0 * texel)
    # Half the angle between neighbouring directions, as a tangent.
    spread = 0.5f0 * sqrt(4f0 * Float32(π) / Float32(n))
    depth_span = 2f0 * params[1]
    open = 0f0
    total = 0f0
    for k in Int32(0):n - Int32(1)
        w = dot(normal, ao_direction(k, n))
        w <= 0f0 && continue
        c = ao_matrix(k, centre, params) * Vec4f(p[1], p[2], p[3], 1f0)
        open += w * ao_lookup(ao_map, width, (k % cols) * res, (k ÷ cols) * res, res, c,
                              texel, depth_span, spread)
        total += w
    end
    return total > 0f0 ? open / total : 1f0
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
The scene's lights on a surface point as the tracer sees them, through the
surface's pbrt material (`diffuse_part`, `specular_part`): each light's
irradiance through both lobes, a glowing patch's specular through its
highlight (`emitter_highlight`), the ambient light and environment through
`ambient_response`. The shadowed light (`shadow_light`, its place in the light
list) is looked up in the shadow map. `normal` faces the camera: the tracer's
materials reflect on whichever side is seen. `v` points to the eye.
"""
@inline function illuminate_physical(world_pos::Vec3f, normal::Vec3f, v::Vec3f, base_color::Vec3f,
                                     material::RasterMaterial, shading_mode::Int32, ambient::Vec3f,
                                     light_color::Vec3f, light_direction::Vec3f, N_lights::Int32,
                                     light_types, light_colors, light_parameters, has_env::Int32,
                                     env_sh, shadow_map, light_space::Mat4f, shadow_light::Int32,
                                     shadow_params::Vec4f, ao_map, ao_centre::Vec4f, ao_params::Vec4f)
    open = ambient_visibility(ao_map, ao_centre, ao_params, world_pos, normal)
    diffuse_albedo, specular_albedo = ambient_response(material, base_color, normal, v)
    final_color = open * ambient .* (diffuse_albedo + specular_albedo)
    if has_env != Int32(0)
        # The diffuse lobe sees the irradiance around the normal, the specular
        # one the environment around the mirror direction, blurred to
        # irradiance: right for a rough lobe, soft for a polished one.
        mirror = 2f0 * dot(normal, v) * normal - v
        final_color = final_color + open * (diffuse_albedo .* max.(env_irradiance(env_sh, normal), 0f0) +
                                            specular_albedo .* max.(env_irradiance(env_sh, mirror), 0f0))
    end
    if shading_mode == SHADING_FAST
        vis = shadow_light == Int32(1) ?
            shadow_visibility(shadow_map, light_space, shadow_params, world_pos, normal, light_direction) : 1f0
        l = -light_direction
        final_color = final_color + vis * light_color .*
            (diffuse_part(material, base_color, normal, v, l) + specular_part(material, normal, v, l, 0f0))
    elseif shading_mode == SHADING_MULTI
        idx = Int32(0)
        for i in Int32(1):min(N_lights, Int32(length(light_types)))
            @inbounds kind = light_types[i]
            @inbounds lc = light_colors[i]
            (kind < LIGHT_POINT || kind > LIGHT_EMITTER) && return Vec3f(1f0, 0f0, 1f0)
            E, l = incoming(kind, lc, light_parameters, idx, world_pos)
            c = E .* diffuse_part(material, base_color, normal, v, l)
            if kind == LIGHT_EMITTER
                @inbounds centre = Vec3f(light_parameters[idx + 1], light_parameters[idx + 2], light_parameters[idx + 3])
                @inbounds en = Vec3f(light_parameters[idx + 4], light_parameters[idx + 5], light_parameters[idx + 6])
                @inbounds area = light_parameters[idx + 7]
                @inbounds two_sided = light_parameters[idx + 8]
                c = c + emitter_highlight(material, normal, v, world_pos, centre, en, area, two_sided, lc)
            else
                c = c + E .* specular_part(material, normal, v, l, 0f0)
            end
            if i == shadow_light
                c = c * shadow_visibility(shadow_map, light_space, shadow_params, world_pos, normal, -l)
            end
            final_color = final_color + c
            idx += light_parameter_count(kind)
        end
    end
    return final_color
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
            elseif kind == LIGHT_EMITTER
                # GLMakie's shader has no area light: an emitter lights only a
                # display-encoded (physical) film.
                idx += Int32(8)
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
    :physical, :shadow_map, :light_space, :shadow_light, :shadow_params,
    :ao_map, :ao_centre, :ao_params, :material, :emission,
    :fxaa,
)
const MESH_NARGS = length(MESH_ARG_NAMES)

# The arg-less spelling, as in `overlay/lines.jl`. Written out rather than
# splatted: inference resolves a splat of at most 32 elements, and a 61-element
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
        viewport_origin::Vec2f, num_clip_planes::Int32,
        physical::Int32, shadow_map, light_space::Mat4f, shadow_light::Int32, shadow_params::Vec4f,
        ao_map, ao_centre::Vec4f, ao_params::Vec4f, material::RasterMaterial, emission::Vec4f,
        fxaa::Int32)
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
        resolution::Vec2f, px_per_unit::Float32, physical::Int32, shadow_map,
        light_space::Mat4f, shadow_light::Int32, shadow_params::Vec4f,
        ao_map, ao_centre::Vec4f, ao_params::Vec4f, material::RasterMaterial, emission::Vec4f)
    world_pos = inputs.world_pos
    for i in Int32(1):num_clip_planes
        @inbounds plane = clip_planes[i]
        dot(world_pos, Vec3f(plane[1], plane[2], plane[3])) - plane[4] < 0f0 && discard()
    end
    # What the surface emits (see `RasterLook`): mode 1 a constant radiance,
    # mode 2 the sampled colour, which then has no surface under it. Linear,
    # mapped through the film below and added over the reflected light, the
    # way the tracer adds an emitter's radiance.
    glow = Vec3f(0f0)
    premultiplied = false
    if emission[4] == 1f0
        glow = Vec3f(emission[1], emission[2], emission[3])
    elseif emission[4] == 2f0
        glow = Vec3f(color[1], color[2], color[3]) * emission[1]
        color = Vec4f(0f0, 0f0, 0f0, 0f0)
    end
    if shading_mode != SHADING_NONE && has_normals != Int32(0)
        # Lit, then film-mapped like the traced image, so the base colour is
        # decoded to the linear reflectance the traced path's `to_spectrum` makes
        # of it. Only when the film encodes for display again: with `gamma =
        # nothing` this is GLMakie's shader on GLMakie's colours, which is what
        # test_mesh_raster.jl compares. An unlit colour is shown as given.
        base = Vec3f(color[1], color[2], color[3])
        if apply_gamma != Int32(0)
            base = Vec3f(Hikari.srgb_gamma_to_linear(base[1]), Hikari.srgb_gamma_to_linear(base[2]),
                         Hikari.srgb_gamma_to_linear(base[3]))
        end
        camdir = _unit(inputs.camdir)
        normal = _unit(inputs.world_normal)
        facing = dot(normal, camdir) > 0f0 ? -normal : normal
        rgb = if physical != Int32(0)
            illuminate_physical(world_pos, facing, -camdir,
                                base, material, shading_mode, ambient, light_color, light_direction,
                                N_lights, light_types, light_colors, light_parameters, has_env,
                                env_sh, shadow_map, light_space, shadow_light, shadow_params,
                                ao_map, ao_centre, ao_params)
        else
            illuminate(world_pos, camdir, normal, base, shading_mode, ambient,
                       light_color, light_direction, N_lights, light_types, light_colors,
                       light_parameters, has_env, env_sh, diffuse, specular, shininess, backlight)
        end
        rgb = film_mapping(rgb, exposure, tonemap, white_point, inv_gamma, apply_gamma)
        if physical != Int32(0) && is_glass(material)
            # Glass shows what it reflects, over what it lets through: its
            # reflection is the premultiplied colour, its opacity what it
            # does not transmit.
            color = Vec4f(rgb[1], rgb[2], rgb[3], 1f0 - glass_transmittance(material, base, facing, -camdir))
            premultiplied = true
        else
            color = Vec4f(rgb[1], rgb[2], rgb[3], color[4])
        end
    end
    ndc, z_gradient = fragment_ndc(inputs.clip)
    tri = unsafe_trunc(Int32, inputs.tri + 0.5f0)
    color = apply_stroke(color, stroke_data, tri, ndc, z_gradient, projection * view * model,
                         px_per_unit * resolution, strokewidth, strokecolor, px_per_unit)
    a = color[4]
    out = premultiplied ? Vec3f(color[1], color[2], color[3]) : Vec3f(color[1] * a, color[2] * a, color[3] * a)
    if emission[4] != 0f0
        # Premultiplied: a glow with no surface (alpha 0) adds to what is behind it.
        out = out + film_mapping(glow, exposure, tonemap, white_point, inv_gamma, apply_gamma)
    end
    (a < 1f-3 && out[1] + out[2] + out[3] < 1f-3) && discard()
    return Vec4f(out[1], out[2], out[3], a)
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
        viewport_origin::Vec2f, num_clip_planes::Int32,
        physical::Int32, shadow_map, light_space::Mat4f, shadow_light::Int32, shadow_params::Vec4f,
        ao_map, ao_centre::Vec4f, ao_params::Vec4f, material::RasterMaterial, emission::Vec4f,
        fxaa::Int32)
    color = color_source == COLOR_VERTEX_CMAP_FRAG ?
        get_color_from_cmap(inputs.colour[1], cmap, colorrange, colormap_linear,
                            lowclip, highclip, nan_color) :
        inputs.colour
    return raster_output(mesh_finish(inputs, color, stroke_data, clip_planes, num_clip_planes,
        light_types, light_colors, light_parameters, model, view, projection, has_normals,
        shading_mode, ambient, light_color, light_direction, N_lights, has_env, env_sh,
        diffuse, specular, shininess, backlight, exposure, tonemap, white_point,
        inv_gamma, apply_gamma, strokewidth, strokecolor, resolution, px_per_unit,
        physical, shadow_map, light_space, shadow_light, shadow_params,
        ao_map, ao_centre, ao_params, material, emission), fxaa)
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
        viewport_origin::Vec2f, num_clip_planes::Int32,
        physical::Int32, shadow_map, light_space::Mat4f, shadow_light::Int32, shadow_params::Vec4f,
        ao_map, ao_centre::Vec4f, ao_params::Vec4f, material::RasterMaterial, emission::Vec4f,
        fxaa::Int32)
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
    return raster_output(mesh_finish(inputs, color, stroke_data, clip_planes, num_clip_planes,
        light_types, light_colors, light_parameters, model, view, projection, has_normals,
        shading_mode, ambient, light_color, light_direction, N_lights, has_env, env_sh,
        diffuse, specular, shininess, backlight, exposure, tonemap, white_point,
        inv_gamma, apply_gamma, strokewidth, strokecolor, resolution, px_per_unit,
        physical, shadow_map, light_space, shadow_light, shadow_params,
        ao_map, ao_centre, ao_params, material, emission), fxaa)
end

"""
    get_mesh_pipeline!(screen, textured, see_through)

The mesh pipeline: with a texture or without, and for see-through surfaces
(glass, a glow) one that tests depth without writing it, so what is behind
them still draws. Those are drawn after everything opaque (`overlay_robjs`).
"""
function get_mesh_pipeline!(screen, textured::Bool, see_through::Bool = false)
    key = Symbol(textured ? :mesh_textured : :mesh, see_through ? :_see_through : :_opaque)
    get!(screen.gfx_pipelines, key) do
        GraphicsPipeline(; vertex = VertexShader(mesh_vertex; outputs = MESH_VERTEX_OUT),
                           fragment = textured ? FragmentShader(mesh_fragment_textured; textures = 1) :
                                                 FragmentShader(mesh_fragment),
                           blend = Premultiplied(),
                           topology = TriangleList(),
                           cull = NoCull(),
                           depth = see_through ? DepthLessEqReadOnly() : DepthLessEq())
    end
end
