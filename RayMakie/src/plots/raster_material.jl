# =============================================================================
# A Hikari material on the RASTER path: what it looks like, and what it lights
# =============================================================================
#
# The raster path stands in for the tracer, so a scene must not need a second
# description to be previewed: a mesh that only has a `material` is drawn in
# that material's colour, a glowing one glows, and a glowing one LIGHTS the
# scene, as the tracer turns its triangles into area lights. Without this a
# material-only scene came out in the plot palette's colours, lit by nothing
# but the ambient term.

"""
    RasterLook(color, emission)

How the raster shader draws a Hikari material. `color` is what the shader takes
as the base colour (sRGB encoded, as a Makie colour is; alpha below one for
glass, zero for no surface at all) or, for a material that emits an image, that
image. `emission` is `(r, g, b, mode)`: mode 0 emits nothing, mode 1 emits the
radiance `rgb` (linear, through the film like the tracer's), mode 2 emits the
sampled colour times `r`, with no surface under it.
"""
struct RasterLook{C}
    color::C
    emission::Vec4f
end

const NO_EMISSION = Vec4f(0)

"""Linear reflectance as an sRGB-encoded colour: the shader decodes it back."""
srgb(c::Hikari.RGBSpectrum, alpha = 1f0) =
    RGBAf(Hikari.linear_to_srgb_gamma(c.c[1]), Hikari.linear_to_srgb_gamma(c.c[2]),
          Hikari.linear_to_srgb_gamma(c.c[3]), alpha)

"""The colour of a constant texture handle, or `fallback` for a sampled one."""
handle_rgb(h::Hikari.TexHandle, fallback) =
    h.kind in (Hikari.TexKind.CONST_SPECTRUM, Hikari.TexKind.CONST_FLOAT) ? Hikari.const_spectrum(h) : fallback
handle_rgb(::Any, fallback) = fallback

const WHITE = Hikari.RGBSpectrum(1f0)

"""
    raster_look(material) -> RasterLook or nothing

`nothing` for a material the raster path has no reading of: it then draws the
plot's own colour, as before.
"""
raster_look(::Any) = nothing
raster_look(m::Hikari.Diffuse) = RasterLook(srgb(handle_rgb(m.Kd, WHITE)), NO_EMISSION)
raster_look(m::Hikari.CoatedDiffuse) = RasterLook(srgb(handle_rgb(m.reflectance, WHITE)), NO_EMISSION)
# The base is unused: `raster_conductor` gives the shader its reflectance.
raster_look(::Hikari.Conductor) = RasterLook(RGBAf(1, 1, 1, 1), NO_EMISSION)
# Glass's colour is its transmittance; how see-through it is at each angle is
# its Fresnel term, worked out by the shader (`glass_transmittance`).
raster_look(m::Hikari.Dielectric) = RasterLook(srgb(handle_rgb(m.Kt, WHITE)), NO_EMISSION)
raster_look(::Hikari.ThinDielectric) = RasterLook(RGBAf(1, 1, 1, 1), NO_EMISSION)
raster_look(m::Hikari.CoatedConductor) = RasterLook(RGBAf(1, 1, 1, 1), NO_EMISSION)
raster_look(m::Hikari.DiffuseTransmission) = RasterLook(srgb(handle_rgb(m.reflectance, WHITE)), NO_EMISSION)
raster_look(::Hikari.NullMaterial) = RasterLook(RGBAf(0, 0, 0, 0), NO_EMISSION)
# A pure emitter reflects nothing.
raster_look(m::Hikari.Emissive) = with_emission(RasterLook(RGBAf(0, 0, 0, 1), NO_EMISSION), m)

"""
Clear water and the like: a dielectric over a scattering medium. The tracer sees
through the surface into the medium and gets back what it scatters; the raster
path has nothing behind the surface to show, so it draws the medium as the
diffuse body under a coat (see `raster_material`), in the reflectance of an
infinitely deep slab of it: per channel, with single-scattering albedo
ω = σs / (σa + σs), (1 - √(1-ω)) / (1 + √(1-ω)) (the two-stream result). Drawn
as glass it showed whatever was behind the water, the sky.
"""
function deep_reflectance(medium::Hikari.HomogeneousMedium)
    a, s = medium.σ_a.c, medium.σ_s.c
    r(i) = (q = sqrt(1f0 - s[i] / (a[i] + s[i])); (1f0 - q) / (1f0 + q))
    return Hikari.RGBSpectrum(r(1), r(2), r(3))
end

raster_look(m::Hikari.MediumInterface{<:Hikari.Dielectric, <:Hikari.HomogeneousMedium}) =
    m.emission === nothing ? RasterLook(srgb(deep_reflectance(m.inside)), NO_EMISSION) :
                             with_emission(RasterLook(srgb(deep_reflectance(m.inside)), NO_EMISSION), m.emission)

function raster_look(m::Hikari.MediumInterface)
    surface = raster_look(m.material)
    surface === nothing && return nothing
    return m.emission === nothing ? surface : with_emission(surface, m.emission)
end

"""
The radiance an `Emissive` sends out, linear RGB: its `Le` times its scale,
without the photometric normalisation the tracer applies to the spectrum it
uplifts that RGB to (and so takes back out).
"""
emitted_scale(e::Hikari.Emissive) = e.scale * Hikari.D65_PHOTOMETRIC

function with_emission(look::RasterLook, e::Hikari.Emissive)
    Le = e.Le
    if Le isa Hikari.Texture && !Le.isconst
        # Mode 2: the image is the emission, the surface is gone.
        img = map(c -> RGBAf(c.c[1], c.c[2], c.c[3], 1f0), Le.data)
        return RasterLook(img, Vec4f(emitted_scale(e), 0, 0, 2))
    end
    c = handle_rgb(Le, Hikari.RGBSpectrum(0f0))
    s = emitted_scale(e)
    return RasterLook(look.color, Vec4f(c.c[1] * s, c.c[2] * s, c.c[3] * s, 1))
end

"""
    plot_raster_look(plot) -> RasterLook or nothing

The look of a mesh plot from its material, unless its colour was set
explicitly: a colour given with the material is what the tracer merges into the
material too, so the raster path shows it as given.
"""
function plot_raster_look(plot)
    material = overlay_material(plot)
    material isa Hikari.Material || return nothing
    color_was_set(plot) && return nothing
    return raster_look(material)
end

"""
Whether a mesh with this look blocks light in the shadow map. Not what glows:
in the tracer an emitter is the light and does not shadow it. Not what has no
surface (a glowing sheet): the tracer's rays pass it.
"""
casts_shadow(::Nothing) = true
casts_shadow(look::RasterLook{<:Colorant}) = look.emission[4] == 0f0 && alpha(look.color) > 0f0
casts_shadow(::RasterLook) = false   # an image look is an emitted image, mode 2
# Glass does cast: the tracer's shadow rays stop at any surface with a material.

"""
Whether a mesh is drawn see-through: a glass or glowing look, or a plot that
asks for `transparency`. It then writes no depth and is drawn after the opaque
meshes, so what is behind it shows through.
"""
is_see_through(look, plot) = (haskey(plot, :transparency) && to_value(plot.transparency) === true) ||
                             see_through_look(look) || is_glass(raster_material(overlay_material(plot)))
see_through_look(::Nothing) = false
see_through_look(look::RasterLook{<:Colorant}) = alpha(look.color) < 1f0 || look.emission[4] == 2f0
see_through_look(::RasterLook) = true   # an image look is an emitted image, mode 2

# -----------------------------------------------------------------------------
# Glowing meshes as lights
# -----------------------------------------------------------------------------

"""
    RasterEmitter(centre, normal, area, two_sided, L, axis, half)

A glowing mesh as the raster path lights with it: a flat patch of `area`
emitting radiance `L` from its `centre` along its `normal`, both ways when
`two_sided`. The tracer makes every triangle of it an area light; this is the
same light with the triangles summed. `axis` is the patch's long in-plane
direction and `half` its half extents along `axis` and `normal × axis`: what a
glossy surface reflects of it is that rectangle, not a disc of its area. A
24×5 softbox drawn as a disc put a 12-unit-wide highlight on every flat glass
face under it.
"""
struct RasterEmitter
    centre::Vec3f
    normal::Vec3f
    area::Float32
    two_sided::Bool
    L::Vec3f
    axis::Vec3f
    half::Vec2f
end

"""The radiance a material emits and whether both sides do, or `nothing`."""
emission_of(::Any) = nothing
emission_of(m::Hikari.MediumInterface) = m.emission === nothing ? emission_of(m.material) : emission_of(m.emission)
function emission_of(e::Hikari.Emissive)
    Le = e.Le
    # An image emits its mean as far as lighting goes.
    c = Le isa Hikari.Texture && !Le.isconst ?
        Vec3f(sum(x -> Vec3f(x.c[1], x.c[2], x.c[3]), Le.data) / length(Le.data)) :
        (r = handle_rgb(Le, Hikari.RGBSpectrum(0f0)); Vec3f(r.c[1], r.c[2], r.c[3]))
    return (L = c * emitted_scale(e), two_sided = e.two_sided)
end

"""
    raster_emitter(plot) -> RasterEmitter or nothing

The area light a mesh plot is, in the space the raster path draws in (the
plot's model matrix applied to its transformed, Float32-converted positions):
its largest face fixes the normal, and the faces turned the same way give the
area and the centre. For a thin box (a softbox) that is one side, which is the
side that shines; the other is behind it. The in-plane extent of those faces'
corners gives the rectangle (`patch_extent`).
"""
function raster_emitter(plot)
    e = emission_of(overlay_material(plot))
    e === nothing && return nothing
    model = Mat4f(plot.model_f32c[])
    world(p) = (h = model * Vec4f(p[1], p[2], p[3], 1f0); Vec3f(h[1], h[2], h[3]) / h[4])
    P = world.(plot.positions_transformed_f32c[])
    faces = plot.faces[]
    isempty(faces) && return nothing
    tris = map(faces) do f
        a, b, c = P[f[1]], P[f[2]], P[f[3]]
        n = cross(b - a, c - a)
        (n, (a + b + c) / 3)
    end
    ref = normalize(first(argmax(t -> norm(t[1]), tris)))
    area = 0f0
    centre = Vec3f(0)
    corners = Vec3f[]
    for ((n, c), f) in zip(tris, faces)
        a = norm(n) / 2
        # turned the way of the largest face: within 60 degrees of it
        (a > 0 && dot(n, ref) > 0.5f0 * norm(n)) || continue
        area += a
        centre += a * c
        push!(corners, P[f[1]], P[f[2]], P[f[3]])
    end
    centre = centre / area
    # Each corner once: two triangles of a quad share a diagonal, and counting
    # its ends twice turned a 24×5 softbox's axis towards that diagonal and
    # shrank its rectangle to 21×6.
    axis, half = patch_extent(unique!(corners), centre, ref, area)
    return RasterEmitter(centre, ref, area, e.two_sided, e.L, axis, half)
end

"""
    patch_extent(points, centre, normal, area) -> (axis, half)

The rectangle a flat patch covers: its principal in-plane direction (of the
corners' spread about `centre`) and its half extents along it and across. The
extents are scaled to the patch's `area`, so a disc or a ring keeps its light's
size rather than its bounding box's.
"""
function patch_extent(points, centre::Vec3f, normal::Vec3f, area::Float32)
    seed = abs(normal[1]) < 0.9f0 ? Vec3f(1, 0, 0) : Vec3f(0, 1, 0)
    e1 = normalize(seed - dot(seed, normal) * normal)
    e2 = cross(normal, e1)
    sxx = sxy = syy = 0f0
    for p in points
        x, y = dot(p - centre, e1), dot(p - centre, e2)
        sxx += x * x; sxy += x * y; syy += y * y
    end
    θ = 0.5f0 * atan(2sxy, sxx - syy)
    axis = cos(θ) * e1 + sin(θ) * e2
    across = cross(normal, axis)
    hu = maximum(p -> abs(dot(p - centre, axis)), points)
    hv = maximum(p -> abs(dot(p - centre, across)), points)
    s = sqrt(area / max(4hu * hv, 1f-12))
    return axis, Vec2f(hu * s, hv * s)
end

"""
    sync_raster_emitters!(scene)

Hand the scene's raster lights its glowing meshes, as `RasterEmitter`s in the
`:raster_emitters` node; written only when they changed, since that re-runs
every raster mesh's light buffers.
"""
function sync_raster_emitters!(scene::Makie.Scene)
    haskey(scene.compute, :raster_emitters) || return scene
    emitters = RasterEmitter[]
    for p in scene.plots
        Makie.for_each_atomic_plot(p) do ap
            (ap isa Makie.Mesh && ap.visible[]) || return nothing
            e = raster_emitter(ap)
            e === nothing || push!(emitters, e)
            return nothing
        end
    end
    emitters == scene.compute[:raster_emitters][] ||
        Makie.ComputePipeline.update!(scene.compute; raster_emitters = emitters)
    return scene
end

"""
The scene's Makie lights (Makie's multi-light packing) with its emitters after
them, as `LIGHT_EMITTER`s: centre, normal, area, two-sided, axis, half extents.
"""
function with_emitters(N, types, colors, parameters, emitters)
    isempty(emitters) && return (N, types, colors, parameters)
    types = vcat(types, fill(LIGHT_EMITTER, length(emitters)))
    colors = vcat(colors, [RGBf(e.L...) for e in emitters])
    parameters = copy(parameters)
    for e in emitters
        push!(parameters, e.centre..., e.normal..., e.area, Float32(e.two_sided), e.axis..., e.half...)
    end
    return (N + length(emitters), types, colors, parameters)
end

"""
Makie's light arrays plus the sun of every `SunSkyLight`, as a directional light
of the tracer's colour (`Hikari.sunsky_sun_rgb`). Makie leaves sun-and-sky
lights to the backend and drops them from its arrays, so a raster frame under
one was lit by nothing but its sky. (The sky is in `environment_sh`.)
"""
function with_suns(lights, n, types, colors, params)
    suns = filter(l -> l isa Makie.SunSkyLight, lights)
    isempty(suns) && return (n, types, colors, params)
    return (n + length(suns),
            vcat(types, fill(Int32(Makie.LightType.DirectionalLight), length(suns))),
            vcat(colors, [RGBf(Hikari.sunsky_sun_rgb(s.intensity)) for s in suns]),
            vcat(params, reduce(vcat, [Float32.(-normalize(s.direction)) for s in suns])))
end

function register_raster_emitters!(graph)
    haskey(graph, :raster_emitters) && return
    Makie.ComputePipeline.add_input!(graph, :raster_emitters, RasterEmitter[])
    Makie.ComputePipeline.map!(with_suns, graph,
        [:lights, :N_lights, :light_types, :light_colors, :light_parameters],
        [:raster_sun_N_lights, :raster_sun_light_types, :raster_sun_light_colors, :raster_sun_light_parameters])
    Makie.ComputePipeline.map!(with_emitters, graph,
        [:raster_sun_N_lights, :raster_sun_light_types, :raster_sun_light_colors, :raster_sun_light_parameters, :raster_emitters],
        [:raster_all_N_lights, :raster_all_light_types, :raster_all_light_colors, :raster_all_light_parameters])
    return
end

# -----------------------------------------------------------------------------
# Hikari materials as pbrt materials for the raster shader
# -----------------------------------------------------------------------------

"""A constant float texture's value, or `fallback` for a sampled one."""
handle_float(h::Hikari.TexHandle, fallback) = h.kind in (Hikari.TexKind.CONST_FLOAT, Hikari.TexKind.CONST_SPECTRUM) ?
                                              Hikari.const_float(h) : Float32(fallback)
handle_float(x::Real, fallback) = Float32(x)
handle_float(::Any, fallback) = Float32(fallback)

"""The GGX α a material's roughness pair stands for, as pbrt remaps it; a sampled roughness reads as 0.5."""
function material_alpha(u, v, remap::Bool)
    r = (handle_float(u, 0.5f0) + handle_float(v, 0.5f0)) / 2
    return remap ? Hikari.roughness_to_α(r) : r
end

# A spectrum at the red, green and blue wavelengths the raster shader stands in for.
spectral(s::Hikari.PiecewiseLinearSpectrum, λ, i) = Hikari.sample(s, λ)
spectral(h::Hikari.TexHandle, λ, i) = h.rgb.c[i]
rgb_of(s) = Vec3f(spectral(s, 630f0, 1), spectral(s, 532f0, 2), spectral(s, 465f0, 3))

"""
The hemispherical averages of a coat of index η: F̄ₑ, of the Fresnel
reflectance for light arriving from outside (cosine weighted), and F̄ᵢ, for
diffuse light hitting the coat from inside, 1 - (1 - F̄ₑ)/η² by reciprocity.
"""
function coat_averages(η::Float32)
    n = 256
    fe = sum(k -> (μ = (k - 0.5f0) / n; Hikari.fresnel_dielectric(μ, η) * 2μ / n), 1:n)
    return Float32(fe), Float32(1 - (1 - fe) / η^2)
end

"""
    raster_material(material) -> RasterMaterial

The pbrt material the raster shader evaluates for a Hikari material: kind,
roughness, indices and tints, read from constant parameters (a sampled
roughness reads as 0.5, a sampled tint as white). Anything else draws as
Lambert in the plot's colour.
"""
raster_material(::Any) = LAMBERT
raster_material(m::Hikari.MediumInterface) = raster_material(m.material)

"A dielectric over a scattering medium, as a coat over its deep reflectance; see `deep_reflectance`."
function raster_material(m::Hikari.MediumInterface{<:Hikari.Dielectric, <:Hikari.HomogeneousMedium})
    d = m.material
    α = material_alpha(d.u_roughness, d.v_roughness, d.remap_roughness)
    η = handle_float(d.index, 1.5f0)
    fe, fi = coat_averages(η)
    return RasterMaterial(Vec4f(MAT_COATED_DIFFUSE, α, η, 0.01f0), Vec4f(0), Vec4f(0, 0, 0, fe), Vec4f(0, 0, 0, fi))
end

function raster_material(m::Hikari.CoatedDiffuse)
    α = material_alpha(m.u_roughness, m.v_roughness, m.remap_roughness)
    fe, fi = coat_averages(m.eta)
    return RasterMaterial(Vec4f(MAT_COATED_DIFFUSE, α, m.eta, handle_float(m.thickness, 0.01f0)),
                          Vec4f(0), Vec4f(0, 0, 0, fe), Vec4f(0, 0, 0, fi))
end

function raster_material(m::Hikari.Conductor)
    α = material_alpha(m.roughness, m.roughness, m.remap_roughness)
    η, k = rgb_of(m.eta), rgb_of(m.k)
    tint = handle_rgb(m.reflectance, WHITE)
    return RasterMaterial(Vec4f(MAT_CONDUCTOR, α, 1, 0), Vec4f(η..., 0), Vec4f(k..., 0),
                          Vec4f(tint.c[1], tint.c[2], tint.c[3], 0))
end

function raster_material(m::Hikari.CoatedConductor)
    α = material_alpha(m.interface_u_roughness, m.interface_v_roughness, m.remap_roughness)
    αc = material_alpha(m.conductor_u_roughness, m.conductor_v_roughness, m.remap_roughness)
    ηi = m.interface_eta
    # pbrt divides the conductor's η and k by the coat's index
    η, k = rgb_of(m.conductor_eta) / ηi, rgb_of(m.conductor_k) / ηi
    fe, fi = coat_averages(ηi)
    return RasterMaterial(Vec4f(MAT_COATED_CONDUCTOR, α, ηi, handle_float(m.thickness, 0.01f0)),
                          Vec4f(η..., αc), Vec4f(k..., fe), Vec4f(1, 1, 1, fi))
end

function raster_material(m::Hikari.Dielectric)
    α = material_alpha(m.u_roughness, m.v_roughness, m.remap_roughness)
    kr = handle_rgb(m.Kr, WHITE)
    return RasterMaterial(Vec4f(MAT_DIELECTRIC, α, handle_float(m.index, 1.5f0), 0), Vec4f(0), Vec4f(0),
                          Vec4f(kr.c[1], kr.c[2], kr.c[3], 0))
end

raster_material(m::Hikari.ThinDielectric) =
    RasterMaterial(Vec4f(MAT_THIN_DIELECTRIC, 0, handle_float(m.eta, 1.5f0), 0), Vec4f(0), Vec4f(0), Vec4f(0))

function raster_material(m::Hikari.DiffuseTransmission)
    t = handle_rgb(m.transmittance, WHITE)
    return RasterMaterial(Vec4f(MAT_DIFFUSE_TRANSMISSION, 0, 1, m.scale), Vec4f(0), Vec4f(0),
                          Vec4f(t.c[1], t.c[2], t.c[3], 0))
end
