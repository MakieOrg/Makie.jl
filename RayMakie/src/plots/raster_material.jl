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
    RasterLook(color, emission, glow = nothing)

How the raster shader draws a Hikari material. `color` is what the shader takes
as the base colour (sRGB encoded, as a Makie colour is; alpha below one for
glass, zero for no surface at all), one colour or an image for a sampled
reflectance, or, for a material that emits an image, that image. `emission` is
`(r, g, b, mode)`: mode 0 emits nothing, mode 1 emits the radiance `rgb`
(linear, through the film like the tracer's), mode 2 emits the sampled colour
times `r`, with no surface under it, mode 3 emits the image `glow` (sRGB
encoded, sampled as a second texture) times `r` over the surface `color` is.
"""
struct RasterLook{C, G}
    color::C
    emission::Vec4f
    glow::G
end
RasterLook(color, emission::Vec4f) = RasterLook(color, emission, nothing)

const NO_EMISSION = Vec4f(0)

"""Linear reflectance as an sRGB-encoded colour: the shader decodes it back."""
srgb(c::Hikari.RGBSpectrum, alpha = 1.0f0) =
    RGBAf(
    Hikari.linear_to_srgb_gamma(c.c[1]), Hikari.linear_to_srgb_gamma(c.c[2]),
    Hikari.linear_to_srgb_gamma(c.c[3]), alpha
)

"""Linear radiance as a colour the shader takes as it is."""
linear_rgba(c::Hikari.RGBSpectrum) = RGBAf(c.c[1], c.c[2], c.c[3], 1.0f0)

"""The colour of a constant texture handle, or `fallback` for a sampled one."""
handle_rgb(h::Hikari.TexHandle, fallback) =
    h.kind in (Hikari.TexKind.CONST_SPECTRUM, Hikari.TexKind.CONST_FLOAT) ? Hikari.const_spectrum(h) : fallback
handle_rgb(t::Hikari.Texture{<:Hikari.RGBSpectrum, 0}, fallback) = Hikari.constant_value(t)
# A material keeps a constant as it was given: a number, a tuple, a colour.
handle_rgb(x::Union{Real, Tuple{Real, Real, Real}, Colorant, Hikari.RGBSpectrum}, fallback) =
    Hikari.const_spectrum(Hikari.TexHandle(x))
handle_rgb(::Any, fallback) = fallback

const WHITE = Hikari.RGBSpectrum(1.0f0)

"""Whether a material parameter is an image rather than one value."""
is_sampled(t::Hikari.Texture{<:Any, 2}) = !t.isconst
is_sampled(::Any) = false

"""
    raster_image(f, texture) -> Matrix

A sampled texture as the raster shader's image of it, `f` applied to each
texel. The data goes as it is: the raster stage samples a texture at a uv where
the tracer's `sample_texture_data` does (dim 1 is 1 - v, dim 2 is u).
"""
raster_image(f, t::Hikari.Texture) = map(f, t.data)

"""
A reflectance parameter as the base colour: one colour, or for a sampled one its
image, in 8 bits as albedo maps are (14.6 MB for the film's 2700×1350 Earth
against 58 MB in floats).
"""
base_color(p) = is_sampled(p) ? raster_image(c -> RGBA{N0f8}(srgb(c)), p) : srgb(handle_rgb(p, WHITE))

"""
    raster_look(material) -> RasterLook or nothing

`nothing` for a material the raster path has no reading of: it then draws the
plot's own colour, as before.
"""
raster_look(::Any) = nothing
raster_look(m::Hikari.Diffuse) = RasterLook(base_color(m.color), NO_EMISSION)
raster_look(m::Union{Hikari.Glossy, Hikari.Translucent, Hikari.Sheen}) = RasterLook(base_color(m.color), NO_EMISSION)
raster_look(m::Hikari.Principled) = RasterLook(base_color(m.base_color), NO_EMISSION)
# The base is unused: `raster_material` gives the shader the metal's reflectance.
raster_look(::Hikari.Metallic) = RasterLook(RGBAf(1, 1, 1, 1), NO_EMISSION)
raster_look(m::Hikari.OpenPBR) = raster_look(Hikari.Principled(m))
# glTF's base colour texture is its colour; its factor, usually one, is what an untextured one has.
raster_look(m::Hikari.GLTF) =
    RasterLook(
    isnothing(m.base_color_texture) ? srgb(handle_rgb(Hikari.rgb(m.base_color_factor), WHITE)) :
        base_color(m.base_color_texture), NO_EMISSION
)
raster_look(m::Hikari.CoatedDiffuse) = RasterLook(base_color(m.reflectance), NO_EMISSION)
# The base is unused: `raster_conductor` gives the shader its reflectance.
raster_look(::Hikari.Conductor) = RasterLook(RGBAf(1, 1, 1, 1), NO_EMISSION)
# Glass's colour is its transmittance; how see-through it is at each angle is
# its Fresnel term, worked out by the shader (`glass_transmittance`).
raster_look(::Union{Hikari.Dielectric, Hikari.ThinDielectric}) = RasterLook(RGBAf(1, 1, 1, 1), NO_EMISSION)
raster_look(m::Hikari.CoatedConductor) = RasterLook(RGBAf(1, 1, 1, 1), NO_EMISSION)
raster_look(m::Hikari.DiffuseTransmission) = RasterLook(base_color(m.reflectance), NO_EMISSION)
raster_look(::Hikari.NullMaterial) = RasterLook(RGBAf(0, 0, 0, 0), NO_EMISSION)
# A pure emitter reflects nothing; an image it emits is all there is of it.
raster_look(m::Hikari.Emission) =
    is_sampled(m.color) ? emitted_image(m) : with_emission(RasterLook(RGBAf(0, 0, 0, 1), NO_EMISSION), m)

"""
    mixed(mix) -> Material

The material of a `Mix` the raster path draws. The tracer mixes the two by
`factor` (the share of `b`); the raster path has one material per mesh, so it
takes the one with more of it. The film's Earth mixes matte land and glossy
water by a water mask: 49 % water once the clouds are on it, so the raster
Earth is matte. A sum draws its first.
"""
mixed(m::Hikari.Mix) = mean_amount(m.factor) > 0.5f0 ? m.b : m.a
mixed(m::Hikari.Add) = m.a
mean_amount(t::Hikari.Texture{<:Any, 2}) = Float32(sum(t.data) / length(t.data))
mean_amount(t::Hikari.Texture{<:Any, 0}) = Float32(Hikari.constant_value(t))
mean_amount(x) = handle_float(x, 0.5f0)
raster_look(m::Union{Hikari.Mix, Hikari.Add}) = raster_look(mixed(m))

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
    r(i) = (q = sqrt(1.0f0 - s[i] / (a[i] + s[i])); (1.0f0 - q) / (1.0f0 + q))
    return Hikari.RGBSpectrum(r(1), r(2), r(3))
end

function raster_look(m::Hikari.MediumInterface{<:Union{Hikari.Dielectric, Hikari.Principled}, <:Hikari.HomogeneousMedium})
    m.material isa Hikari.Principled && handle_float(m.material.transmission_weight, 0.0f0) < 0.5f0 &&
        return invoke(raster_look, Tuple{Hikari.MediumInterface}, m)
    return m.emission === nothing ? RasterLook(srgb(deep_reflectance(m.inside)), NO_EMISSION) :
        with_emission(RasterLook(srgb(deep_reflectance(m.inside)), NO_EMISSION), m.emission)
end

function raster_look(m::Hikari.MediumInterface)
    surface = raster_look(m.material)
    surface === nothing && return nothing
    return m.emission === nothing ? surface : with_emission(surface, m.emission)
end

"""
The radiance an `Emission` sends out, linear RGB: its colour times its strength,
without the photometric normalisation the tracer applies to the spectrum it
uplifts that RGB to.
"""
emitted_scale(e::Hikari.Emission) = Float32(e.strength)

"""
    with_emission(look, emissive) -> RasterLook

The surface `look` glowing with `emissive`'s radiance: mode 1 for one radiance,
mode 3 for an image over a surface, mode 2 for an image with no surface under it
(a `NullMaterial`).
"""
function with_emission(look::RasterLook, e::Hikari.Emission)
    is_sampled(e.color) && return glowing(look, e)
    c = handle_rgb(e.color, Hikari.RGBSpectrum(0.0f0))
    s = emitted_scale(e)
    return RasterLook(look.color, Vec4f(c.c[1] * s, c.c[2] * s, c.c[3] * s, 1))
end

"""Mode 2: the image is the emission, the surface is gone."""
emitted_image(e::Hikari.Emission) = RasterLook(raster_image(linear_rgba, e.color), Vec4f(emitted_scale(e), 0, 0, 2))

# Mode 3 samples the surface's colour as an image too: one colour is an image of
# one texel. The Earth's city lights over its day colours are the case. The glow
# is 8-bit sRGB of the radiance over its peak, the peak going into the scale: a
# texture table takes one texel type, and the surface's is 8 bits.
glowing(look::RasterLook{<:Colorant}, e::Hikari.Emission) =
    alpha(look.color) == 0.0f0 ? emitted_image(e) :
    glowing(RasterLook(fill(RGBA{N0f8}(look.color), 1, 1), look.emission), e)
function glowing(look::RasterLook{<:AbstractMatrix}, e::Hikari.Emission)
    peak = max(maximum(c -> max(c.c[1], c.c[2], c.c[3]), e.color.data), floatmin(Float32))
    img = raster_image(c -> RGBA{N0f8}(srgb(Hikari.RGBSpectrum(c.c[1] / peak, c.c[2] / peak, c.c[3] / peak))), e.color)
    return RasterLook(look.color, Vec4f(emitted_scale(e) * peak, 0, 0, 3), img)
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
casts_shadow(look::RasterLook{<:Colorant}) = look.emission[4] == 0.0f0 && alpha(look.color) > 0.0f0
# An image is a sampled surface (modes 0 and 3) or what an emitter emits (mode 2).
casts_shadow(look::RasterLook{<:AbstractMatrix}) = look.emission[4] == 0.0f0
# Glass does cast: the tracer's shadow rays stop at any surface with a material.

"""
Whether a mesh is drawn see-through: a glass or glowing look, or a plot that
asks for `transparency`. It then writes no depth and is drawn after the opaque
meshes, so what is behind it shows through.
"""
is_see_through(look, plot) = (haskey(plot, :transparency) && to_value(plot.transparency) === true) ||
    see_through_look(look) || is_glass(raster_material(overlay_material(plot)))
see_through_look(::Nothing) = false
see_through_look(look::RasterLook{<:Colorant}) = alpha(look.color) < 1.0f0 || look.emission[4] == 2.0f0
see_through_look(look::RasterLook{<:AbstractMatrix}) = look.emission[4] == 2.0f0


"""
The image a look glows with (mode 3), as the second texture's texels, or
`nothing`.
"""
glow_texels(::Nothing) = nothing
glow_texels(look::RasterLook{<:Any, Nothing}) = nothing
glow_texels(look::RasterLook) = texeldata(look.glow)

# A material's image repeats past the uv square, as the tracer samples it
# (`Hikari.sample_texture_data`); an image given as the plot's colour is clamped,
# as GLMakie draws it.
material_wrap(colorinfo, ::RasterLook{<:AbstractMatrix}) = merge(colorinfo, (wrap = :repeat,))
material_wrap(colorinfo, ::Any) = colorinfo

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
function emission_of(e::Hikari.Emission)
    Le = e.color
    # An image emits its mean as far as lighting goes.
    c = Le isa Hikari.Texture && !Le.isconst ?
        Vec3f(sum(x -> Vec3f(x.c[1], x.c[2], x.c[3]), Le.data) / length(Le.data)) :
        (r = handle_rgb(Le, Hikari.RGBSpectrum(0.0f0)); Vec3f(r.c[1], r.c[2], r.c[3]))
    return (L = c * emitted_scale(e), two_sided = e.two_sided)
end

"""
    raster_emitter(positions, faces, material) -> Vector{RasterEmitter}

The area light a mesh is, in its own space (its transformed, Float32-converted
positions, before the model matrix): its largest face fixes the normal, and the
faces turned the same way give the area and the centre. For a thin box (a
softbox) that is one side, which is the side that shines; the other is behind
it. The in-plane extent of those faces' corners gives the rectangle
(`patch_extent`). Empty when the material does not glow. A vector, so the
compute node holding it (`:raster_emitter_local`) keeps one type whether or not
the mesh glows.
"""
function raster_emitter(positions::AbstractVector, faces::AbstractVector, material)
    e = emission_of(material)
    (e === nothing || isempty(faces)) && return RasterEmitter[]
    P = map(Vec3f, positions)
    tris = map(faces) do f
        a, b, c = P[f[1]], P[f[2]], P[f[3]]
        n = cross(b - a, c - a)
        (n, (a + b + c) / 3)
    end
    ref = normalize(first(argmax(t -> norm(t[1]), tris)))
    area = 0.0f0
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
    return [RasterEmitter(centre, ref, area, e.two_sided, e.L, axis, half)]
end

"""
    placed(emitter, model) -> RasterEmitter

`emitter`, found in a mesh's own space, where the raster path draws it: moved by
the plot's `model` matrix. The centre and the rectangle's axes go through the
matrix, the normal through its inverse transpose, and the area by how the
matrix stretches the patch's plane. The light's shape is the one found in the
mesh's own space, which for a rotation, translation or uniform scale (a turning
globe) is exactly the shape found after it.
"""
function placed(e::RasterEmitter, model::Mat4f)
    L = Mat3f(
        model[1, 1], model[2, 1], model[3, 1], model[1, 2], model[2, 2], model[3, 2],
        model[1, 3], model[2, 3], model[3, 3]
    )
    h = model * Vec4f(e.centre[1], e.centre[2], e.centre[3], 1.0f0)
    m = transpose(inv(L)) * e.normal
    axis = L * e.axis
    across = L * cross(e.normal, e.axis)
    return RasterEmitter(
        Vec3f(h[1], h[2], h[3]) / h[4], normalize(m), e.area * abs(det(L)) * norm(m),
        e.two_sided, e.L, normalize(axis), Vec2f(e.half[1] * norm(axis), e.half[2] * norm(across))
    )
end

"""
    raster_emitter_node!(plot) -> plot

Give a mesh plot its `:raster_emitter_local` node: `raster_emitter` of its
positions, faces and material, recomputed only when one of them changes. Walking
a 130k-face globe and averaging its 3.6-megapixel city-light texture per frame
held a scene with it to 3 fps.
"""
function raster_emitter_node!(plot)
    attr = plot.attributes
    haskey(attr, :raster_emitter_local) && return plot
    Makie.ComputePipeline.map!(
        raster_emitter, attr,
        [:positions_transformed_f32c, :faces, :material], :raster_emitter_local
    )
    return plot
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
    sxx = sxy = syy = 0.0f0
    for p in points
        x, y = dot(p - centre, e1), dot(p - centre, e2)
        sxx += x * x; sxy += x * y; syy += y * y
    end
    θ = 0.5f0 * atan(2sxy, sxx - syy)
    axis = cos(θ) * e1 + sin(θ) * e2
    across = cross(normal, axis)
    hu = maximum(p -> abs(dot(p - centre, axis)), points)
    hv = maximum(p -> abs(dot(p - centre, across)), points)
    s = sqrt(area / max(4hu * hv, 1.0f-12))
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
            (ap isa Makie.Mesh && ap.visible[] && haskey(ap.attributes, :material)) || return nothing
            raster_emitter_node!(ap)
            model = Mat4f(ap.model_f32c[])
            for e in ap.raster_emitter_local[]
                push!(emitters, placed(e, model))
            end
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
    return (
        n + length(suns),
        vcat(types, fill(Int32(Makie.LightType.DirectionalLight), length(suns))),
        vcat(colors, [RGBf(Hikari.sunsky_sun_rgb(Vec3f(s.direction); s.intensity, s.turbidity)) for s in suns]),
        vcat(params, reduce(vcat, [Float32.(-normalize(s.direction)) for s in suns])),
    )
end

function register_raster_emitters!(graph)
    haskey(graph, :raster_emitters) && return
    Makie.ComputePipeline.add_input!(graph, :raster_emitters, RasterEmitter[])
    Makie.ComputePipeline.map!(
        with_suns, graph,
        [:lights, :N_lights, :light_types, :light_colors, :light_parameters],
        [:raster_sun_N_lights, :raster_sun_light_types, :raster_sun_light_colors, :raster_sun_light_parameters]
    )
    Makie.ComputePipeline.map!(
        with_emitters, graph,
        [:raster_sun_N_lights, :raster_sun_light_types, :raster_sun_light_colors, :raster_sun_light_parameters, :raster_emitters],
        [:raster_all_N_lights, :raster_all_light_types, :raster_all_light_colors, :raster_all_light_parameters]
    )
    return
end

# -----------------------------------------------------------------------------
# Hikari materials as pbrt materials for the raster shader
# -----------------------------------------------------------------------------

"""A constant float texture's value, or `fallback` for a sampled one."""
handle_float(h::Hikari.TexHandle, fallback) = h.kind in (Hikari.TexKind.CONST_FLOAT, Hikari.TexKind.CONST_SPECTRUM) ?
    Hikari.const_float(h) : Float32(fallback)
handle_float(x::Real, fallback) = Float32(x)
handle_float(x::Union{Tuple{Real, Real, Real}, Colorant, Hikari.RGBSpectrum}, fallback) = handle_rgb(x, fallback).c[1]
# An IOR that is a spectrum, at the sodium D line, where an index of refraction is quoted.
handle_float(s::Hikari.PiecewiseLinearSpectrum, fallback) = Hikari.sample(s, 589.3f0)
handle_float(::Any, fallback) = Float32(fallback)

"""The GGX α a material's roughness pair stands for, as pbrt remaps it; a sampled roughness reads as 0.5."""
function material_alpha(u, v, remap::Bool)
    r = (handle_float(u, 0.5f0) + handle_float(v, 0.5f0)) / 2
    return remap ? Hikari.roughness_to_α(r) : r
end

# A spectrum at the red, green and blue wavelengths the raster shader stands in for.
spectral(s::Hikari.PiecewiseLinearSpectrum, λ, i) = Hikari.sample(s, λ)
spectral(h::Hikari.TexHandle, λ, i) = h.rgb.c[i]
spectral(x, λ, i) = handle_rgb(x, GREY).c[i]
rgb_of(s) = Vec3f(spectral(s, 630.0f0, 1), spectral(s, 532.0f0, 2), spectral(s, 465.0f0, 3))

"""
A conductor's `(η, k)` at red, green and blue, as `Hikari.conductor_ior` makes them: its own, or
pbrt-v4's of the reflectance it was given instead. A sampled reflectance reads as mid grey.
"""
conductor_rgb(eta, k, reflectance::Hikari.TexHandle) =
    Hikari.is_none(reflectance) ? (rgb_of(eta), rgb_of(k)) : reflectance_rgb(handle_rgb(reflectance, GREY))
conductor_rgb(eta, k, ::Nothing) = (rgb_of(eta), rgb_of(k))
conductor_rgb(eta, k, reflectance) = reflectance_rgb(handle_rgb(reflectance, GREY))
function reflectance_rgb(c::Hikari.RGBSpectrum)
    r = clamp.(Vec3f(c.c[1], c.c[2], c.c[3]), 0.0f0, 0.9999f0)
    return Vec3f(1), 2.0f0 .* sqrt.(r) ./ sqrt.(1.0f0 .- r)
end
const GREY = Hikari.RGBSpectrum(0.5f0)

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
raster_material(m::Union{Hikari.Mix, Hikari.Add}) = raster_material(mixed(m))

"A dielectric over a scattering medium, as a coat over its deep reflectance; see `deep_reflectance`."
function raster_material(m::Hikari.MediumInterface{<:Union{Hikari.Dielectric, Hikari.Principled}, <:Hikari.HomogeneousMedium})
    m.material isa Hikari.Principled && handle_float(m.material.transmission_weight, 0.0f0) < 0.5f0 &&
        return invoke(raster_material, Tuple{Hikari.MediumInterface}, m)
    α, η = glass_alpha_ior(m.material)
    fe, fi = coat_averages(η)
    return RasterMaterial(Vec4f(MAT_COATED_DIFFUSE, α, η, 0.01f0), Vec4f(0), Vec4f(0, 0, 0, fe), Vec4f(0, 0, 0, fi))
end

function raster_material(m::Hikari.CoatedDiffuse)
    α = material_alpha(Hikari.roughness_pair(m.roughness)..., m.remap_roughness)
    η = handle_float(m.ior, 1.5f0)
    fe, fi = coat_averages(η)
    return RasterMaterial(
        Vec4f(MAT_COATED_DIFFUSE, α, η, handle_float(m.thickness, 0.01f0)),
        Vec4f(0), Vec4f(0, 0, 0, fe), Vec4f(0, 0, 0, fi)
    )
end

function raster_material(m::Hikari.Conductor)
    α = material_alpha(Hikari.roughness_pair(m.roughness)..., m.remap_roughness)
    η, k = conductor_rgb(m.ior, m.extinction, m.reflectance)
    return RasterMaterial(Vec4f(MAT_CONDUCTOR, α, 1, 0), Vec4f(η..., 0), Vec4f(k..., 0), Vec4f(1, 1, 1, 0))
end

function raster_material(m::Hikari.CoatedConductor)
    α = material_alpha(Hikari.roughness_pair(m.interface_roughness)..., m.remap_roughness)
    αc = material_alpha(Hikari.roughness_pair(m.conductor_roughness)..., m.remap_roughness)
    ηi = handle_float(m.interface_ior, 1.5f0)
    # pbrt divides the conductor's η and k by the coat's index
    η, k = conductor_rgb(m.conductor_ior, m.conductor_extinction, m.reflectance) ./ ηi
    fe, fi = coat_averages(ηi)
    return RasterMaterial(
        Vec4f(MAT_COATED_CONDUCTOR, α, ηi, handle_float(m.thickness, 0.01f0)),
        Vec4f(η..., αc), Vec4f(k..., fe), Vec4f(1, 1, 1, fi)
    )
end

"""A glass's GGX α and IOR: pbrt's remapped roughness, or Blender's roughness squared."""
glass_alpha_ior(d::Hikari.Dielectric) = (material_alpha(Hikari.roughness_pair(d.roughness)..., d.remap_roughness), handle_float(d.ior, 1.5f0))
glass_alpha_ior(g::Hikari.Principled) = (handle_float(g.roughness, 0.5f0)^2, handle_float(g.ior, 1.5f0))

function raster_material(m::Hikari.Dielectric)
    α, η = glass_alpha_ior(m)
    return RasterMaterial(Vec4f(MAT_DIELECTRIC, α, η, 0), Vec4f(0), Vec4f(0), Vec4f(1, 1, 1, 0))
end

raster_material(m::Hikari.ThinDielectric) =
    RasterMaterial(Vec4f(MAT_THIN_DIELECTRIC, 0, handle_float(m.ior, 1.5f0), 0), Vec4f(0), Vec4f(0), Vec4f(0))

# Blender's BSDFs, as the nearest pbrt material the raster shader has: a metal of the reflectance at
# normal incidence, a glossy reflection as a metal reflecting all of it, tinted, and the Principled
# BSDF as its glass, its metal, or its specular layer over the diffuse base, by its weights.
"""A metal reflecting `color` at normal incidence, of GGX α `α`, tinted by `tint`."""
function reflecting(color, α, tint = WHITE)
    η, k = reflectance_rgb(handle_rgb(color, GREY))
    return RasterMaterial(Vec4f(MAT_CONDUCTOR, α, 1, 0), Vec4f(η..., 0), Vec4f(k..., 0), Vec4f(tint.c[1], tint.c[2], tint.c[3], 0))
end
raster_material(m::Hikari.Metallic) = reflecting(m.base_color, handle_float(m.roughness, 0.5f0)^2)
raster_material(m::Hikari.Glossy) = reflecting(1, handle_float(m.roughness, 0.5f0)^2, handle_rgb(m.color, WHITE))
raster_material(m::Union{Hikari.GLTF, Hikari.OpenPBR}) = raster_material(Hikari.Principled(m))
function raster_material(m::Hikari.Principled)
    α = handle_float(m.roughness, 0.5f0)^2
    η = handle_float(m.ior, 1.5f0)
    handle_float(m.transmission_weight, 0.0f0) >= 0.5f0 &&
        return RasterMaterial(Vec4f(MAT_DIELECTRIC, α, η, 0), Vec4f(0), Vec4f(0), Vec4f(1, 1, 1, 0))
    handle_float(m.metallic, 0.0f0) >= 0.5f0 && return reflecting(m.base_color, α)
    fe, fi = coat_averages(η)
    return RasterMaterial(Vec4f(MAT_COATED_DIFFUSE, α, η, 0.0f0), Vec4f(0), Vec4f(0, 0, 0, fe), Vec4f(0, 0, 0, fi))
end

function raster_material(m::Hikari.DiffuseTransmission)
    t = handle_rgb(m.transmittance, WHITE)
    return RasterMaterial(
        Vec4f(MAT_DIFFUSE_TRANSMISSION, 0, 1, m.scale), Vec4f(0), Vec4f(0),
        Vec4f(t.c[1], t.c[2], t.c[3], 0)
    )
end
