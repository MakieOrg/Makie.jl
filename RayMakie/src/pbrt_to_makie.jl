# ============================================================================
# pbrt_to_makie — Convert pbrt scene files to Makie scenes
# ============================================================================
# Exercises the full Makie → RayMakie → Hikari conversion path.
# Any energy mismatch between rendering this vs. render_pbrt indicates
# a bug in the Makie→Hikari conversion (to_trace_light, material handling, etc.)

struct PBRTMakieResult
    scene::Makie.Scene
    resolution::Tuple{Int, Int}
    fov::Float32
    integrator_settings::NamedTuple
    sensor::Hikari.PixelSensor
    sensor_name::String
    exposure_time::Float32
end

"""
    pbrt_to_makie(filename::AbstractString) -> PBRTMakieResult

Parse a pbrt-v4 scene file and build a Makie `Scene` using standard Makie API
(`PointLight`, `DirectionalLight`, `mesh!`, etc.).

Lights are created through the same path a user would use, so any energy
mismatch between `render_pbrt` and `pbrt_to_makie + RayMakie` is a real bug
in `to_trace_light` or the material conversion.
"""
function pbrt_to_makie(filename::AbstractString)
    pbrt = Hikari.parse_pbrt(filename)

    # --- Film / sensor ---
    xres = 512; yres = 512
    sensor_name = "cie1931"
    sensor_iso = 100f0
    sensor_wb = 0f0
    exposure_time = 1f0
    if pbrt.film !== nothing
        xres = Hikari.pbrt_get_int(pbrt.film, "xresolution", 512)
        yres = Hikari.pbrt_get_int(pbrt.film, "yresolution", 512)
        sensor_name = Hikari.pbrt_get_string(pbrt.film, "sensor", "cie1931")
        sensor_iso = Float32(Hikari.pbrt_get_float(pbrt.film, "iso", 100.0))
        sensor_wb = Float32(Hikari.pbrt_get_float(pbrt.film, "whitebalance", 0.0))
        exposure_time = Float32(Hikari.pbrt_get_float(pbrt.film, "exposuretime", 1.0))
    end

    # --- Camera ---
    # Defaults match pbrt-v4 cameras.cpp PerspectiveCamera::Create: a zero lens
    # radius is a pinhole, and focaldistance is only consulted when the lens has
    # area. Dropping these silently rendered every depth-of-field scene sharp.
    fov = 90f0
    lens_radius = 0f0
    focal_distance = 1f6
    if pbrt.camera !== nothing
        fov = Float32(Hikari.pbrt_get_float(pbrt.camera, "fov", 90.0))
        lens_radius = Float32(Hikari.pbrt_get_float(pbrt.camera, "lensradius", 0.0))
        focal_distance = Float32(Hikari.pbrt_get_float(pbrt.camera, "focaldistance", 1.0e6))
    end
    # Extract eye / target / up from the world-to-camera matrix
    ctw = inv(pbrt.camera_transform)
    eye = Point3f(ctw[1,4], ctw[2,4], ctw[3,4])
    forward = normalize(Vec3f(-ctw[1,3], -ctw[2,3], -ctw[3,3]))
    target = eye + forward
    up = normalize(Vec3f(ctw[1,2], ctw[2,2], ctw[3,2]))

    # --- Integrator settings ---
    int_samples = 64; int_max_depth = 5
    int_regularize = false; int_rr_depth = 1
    int_max_component = Inf32
    if pbrt.integrator !== nothing
        int_samples = Hikari.pbrt_get_int(pbrt.integrator, "pixelsamples", 64)
        int_max_depth = Hikari.pbrt_get_int(pbrt.integrator, "maxdepth", 5)
        int_regularize = Hikari.pbrt_get_bool(pbrt.integrator, "regularize", false)
    end
    if pbrt.film !== nothing
        int_max_component = Float32(Hikari.pbrt_get_float(pbrt.film, "maxcomponentvalue", Inf))
    end

    # --- Create Makie Scene ---
    scene = Scene(size=(xres, yres); lights=Makie.AbstractLight[], ambient=RGBf(0, 0, 0))
    cam3d!(scene)
    update_cam!(scene, eye, target, up)
    # pbrt-v4 cameras.cpp: fov refers to the *shorter* image dimension. Makie's
    # cam3d uses vertical FOV unconditionally. For tall images (width<height,
    # like Crown's 1000×1400) we must convert horizontal→vertical so the scene
    # is framed identically: scene reads as zoomed-in otherwise.
    aspect = Float32(xres) / Float32(yres)
    makie_fov = if aspect >= 1f0
        fov  # pbrt fov = vertical; matches Makie
    else
        rad2deg(2 * atan(tan(deg2rad(fov) / 2) / aspect))
    end
    scene.camera_controls.fov[] = Float64(makie_fov)
    # Lens is in world units, so unlike fov it needs no aspect conversion.
    # `to_trace_camera` lifts both into Hikari.PerspectiveCamera.
    scene.camera_controls.lens_radius[] = Float64(lens_radius)
    scene.camera_controls.focal_distance[] = Float64(focal_distance)

    # --- Build Hikari textures and materials from pbrt data ---
    hikari_textures = Hikari.build_pbrt_textures(pbrt)
    mat_cache = Dict{String, Hikari.Material}()
    # Two passes: non-mix materials first so mix materials can find their dependencies
    for pass in (false, true)
        for (name, entity) in pbrt.named_materials
            is_mix = lowercase(entity.type) == "mix"
            is_mix == pass || continue
            haskey(mat_cache, name) && continue
            mat_cache[name] = Hikari.attach_bump(
                Hikari.build_pbrt_material(entity, pbrt, hikari_textures, mat_cache),
                entity, hikari_textures)
        end
    end

    media_cache = Dict{String, Hikari.Medium}()
    for (name, entity) in pbrt.named_media
        transform = get(pbrt.media_transforms, name, Hikari.IDENTITY4)
        med = Hikari.build_pbrt_medium(entity, pbrt, transform)
        med !== nothing && (media_cache[name] = med)
    end

    # --- Add lights as Makie lights ---
    for lrec in pbrt.lights
        pbrt_light_to_makie!(scene, lrec, pbrt)
    end

    # --- Add shapes with materials ---
    for srec in pbrt.shapes
        pbrt_shape_to_makie!(scene, srec, pbrt, mat_cache, media_cache, hikari_textures)
    end

    sensor = Hikari.PixelSensor(sensor=sensor_name, iso=sensor_iso,
                                whitebalance=sensor_wb, exposure_time=exposure_time)

    return PBRTMakieResult(
        scene, (xres, yres), fov,
        (samples=int_samples, max_depth=int_max_depth, regularize=int_regularize,
         russian_roulette_depth=int_rr_depth, max_component_value=int_max_component),
        sensor, sensor_name, exposure_time,
    )
end

"""
    Hikari.VolPath(res::PBRTMakieResult; kwargs...)

Build an integrator whose defaults come from the parsed `.pbrt` instead of from
Hikari's own, which disagree with pbrt-v4 on two knobs that both silently darken
specular highlights:

| knob | pbrt-v4 default | Hikari default |
|---|---|---|
| `regularize` | `false` (`cpu/integrators.cpp:817`) | `true` |
| `maxcomponentvalue` | `Infinity` (`film.cpp:576`) | `10f0` |

A scene that omits both — crown.pbrt does — therefore renders with its specular
lobes roughened AND its bright samples clamped, moving energy out of highlights
and into their surroundings. Measured on crown that was a 1.6 % global energy
deficit concentrated entirely in the bright quintiles.

`pbrt_to_makie` parsed these correctly all along; there was just no way to apply
them short of copying each field by hand, so every caller inherited the wrong
defaults. Explicit keywords still win over the file.
"""
function Hikari.VolPath(res::PBRTMakieResult;
                        samples::Int = res.integrator_settings.samples,
                        max_depth::Int = res.integrator_settings.max_depth,
                        regularize::Bool = res.integrator_settings.regularize,
                        russian_roulette_depth::Int = res.integrator_settings.russian_roulette_depth,
                        max_component_value::Real = res.integrator_settings.max_component_value,
                        sensor::Hikari.PixelSensor = res.sensor,
                        kwargs...)
    return Hikari.VolPath(; samples, max_depth, regularize, russian_roulette_depth,
                          max_component_value, sensor, kwargs...)
end

# ============================================================================
# Light conversion: pbrt light → Makie light
# ============================================================================

function pbrt_light_to_makie!(scene, lrec::Hikari.PBRTLightRecord, pbrt)
    entity = lrec.entity
    type = lowercase(entity.type)

    if type == "point"
        rgb = Hikari.pbrt_get_rgb(entity, "I", (1.0, 1.0, 1.0))
        sc = Float32(Hikari.pbrt_get_float(entity, "scale", 1.0))
        from = Hikari.pbrt_get_rgb(entity, "from", (0.0, 0.0, 0.0))
        pos = Vec3f(Float32(from[1]), Float32(from[2]), Float32(from[3]))
        if lrec.transform != Hikari.IDENTITY4
            p4 = lrec.transform * Vec4f(pos[1], pos[2], pos[3], 1f0)
            pos = Vec3f(p4[1] / p4[4], p4[2] / p4[4], p4[3] / p4[4])
        end
        color = RGBf(Float32(rgb[1]) * sc, Float32(rgb[2]) * sc, Float32(rgb[3]) * sc)
        push_light!(scene, Makie.PointLight(color, pos))

    elseif type == "distant"
        rgb = Hikari.pbrt_get_rgb(entity, "L", (1.0, 1.0, 1.0))
        sc = Float32(Hikari.pbrt_get_float(entity, "scale", 1.0))
        from = Hikari.pbrt_get_rgb(entity, "from", (0.0, 0.0, 0.0))
        to = Hikari.pbrt_get_rgb(entity, "to", (0.0, 0.0, 1.0))
        dir = Vec3f(Float32(to[1] - from[1]), Float32(to[2] - from[2]),
                    Float32(to[3] - from[3]))
        color = RGBf(Float32(rgb[1]) * sc, Float32(rgb[2]) * sc, Float32(rgb[3]) * sc)
        push_light!(scene, Makie.DirectionalLight(color, dir))

    elseif type == "spot"
        rgb = Hikari.pbrt_get_rgb(entity, "I", (1.0, 1.0, 1.0))
        sc = Float32(Hikari.pbrt_get_float(entity, "scale", 1.0))
        cone = Float32(Hikari.pbrt_get_float(entity, "coneangle", 30.0))
        delta = Float32(Hikari.pbrt_get_float(entity, "conedeltaangle", 5.0))
        from = Hikari.pbrt_get_rgb(entity, "from", (0.0, 0.0, 0.0))
        pos = Vec3f(Float32(from[1]), Float32(from[2]), Float32(from[3]))
        to = Hikari.pbrt_get_rgb(entity, "to", (0.0, 0.0, 1.0))
        target = Vec3f(Float32(to[1]), Float32(to[2]), Float32(to[3]))
        dir = normalize(target - pos)
        color = RGBf(Float32(rgb[1]) * sc, Float32(rgb[2]) * sc, Float32(rgb[3]) * sc)
        # Makie SpotLight angles are in radians: [falloff_start, total_width]
        falloff_start_rad = Float32(deg2rad(cone - delta))
        total_width_rad = Float32(deg2rad(cone))
        push_light!(scene, Makie.SpotLight(color, pos, dir, Vec2f(falloff_start_rad, total_width_rad)))

    elseif type == "infinite"
        filename = Hikari.pbrt_get_string(entity, "filename", "")
        sc = Float32(Hikari.pbrt_get_float(entity, "scale", 1.0))
        if !isempty(filename)
            path = isabspath(filename) ? filename : joinpath(pbrt.base_dir, filename)
            if isfile(path)
                env_path = Hikari.convert_envmap_to_srgb(path)
                img = Hikari.FileIO.load(env_path)
                push_light!(scene, Makie.EnvironmentLight(sc, img))
                return
            end
        end
        # Fallback: constant infinite light → ambient
        rgb = Hikari.pbrt_get_rgb(entity, "L", (1.0, 1.0, 1.0))
        color = RGBf(Float32(rgb[1]) * sc, Float32(rgb[2]) * sc, Float32(rgb[3]) * sc)
        if haskey(scene.compute, :ambient_color)
            scene.compute[:ambient_color][] = color
        end

    else
        @warn "pbrt_to_makie: unsupported light type '$type'"
    end
end

# ============================================================================
# Shape conversion: pbrt shape → mesh! call with Hikari material
# ============================================================================

function pbrt_shape_to_makie!(scene, srec::Hikari.PBRTShapeRecord, pbrt,
                              mat_cache, media_cache, hikari_textures)
    geom = Hikari.build_pbrt_shape(srec, pbrt)
    geom === nothing && return

    mat = Hikari.resolve_pbrt_material(srec, mat_cache, pbrt; textures=hikari_textures)

    # Resolve media
    inside_medium = get(media_cache, srec.medium_inner, nothing)
    outside_medium = get(media_cache, srec.medium_outer, nothing)

    # Area light: same construction Hikari's own scene builder uses, so the two
    # importers cannot drift. This used to call the keyword constructor, which
    # normalizes by the D65 constant rather than by the emitter's own spectrum.
    if srec.area_light !== nothing
        emissive = Hikari.Emissive(srec.area_light)
        mesh!(scene, geom; material=Hikari.MediumInterface(mat;
            emission=emissive, inside=inside_medium, outside=outside_medium))
    elseif inside_medium !== nothing || outside_medium !== nothing
        mesh!(scene, geom; material=Hikari.MediumInterface(mat;
            inside=inside_medium, outside=outside_medium))
    else
        mesh!(scene, geom; material=mat)
    end
end
