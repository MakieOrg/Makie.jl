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
    fov = 90f0
    if pbrt.camera !== nothing
        fov = Float32(Hikari.pbrt_get_float(pbrt.camera, "fov", 90.0))
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
    scene.camera_controls.fov[] = Float64(fov)

    # --- Build Hikari textures and materials from pbrt data ---
    hikari_textures = Hikari.build_pbrt_textures(pbrt)
    mat_cache = Dict{String, Hikari.Material}()
    for (name, entity) in pbrt.named_materials
        mat_cache[name] = Hikari.build_pbrt_material(entity, pbrt, hikari_textures)
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

    # Area light: wrap in MediumInterface with Emissive using keyword constructor
    # (applies photometric normalization like a user would)
    if srec.area_light !== nothing
        Le = Hikari.pbrt_get_rgb(srec.area_light, "L", (1.0, 1.0, 1.0))
        al_scale = Float32(Hikari.pbrt_get_float(srec.area_light, "scale", 1.0))
        two_sided = Hikari.pbrt_get_bool(srec.area_light, "twosided", false)
        emissive = Hikari.Emissive(Le=Le, scale=al_scale, two_sided=two_sided)
        mesh!(scene, geom; material=Hikari.MediumInterface(mat;
            emission=emissive, inside=inside_medium, outside=outside_medium))
    elseif inside_medium !== nothing || outside_medium !== nothing
        mesh!(scene, geom; material=Hikari.MediumInterface(mat;
            inside=inside_medium, outside=outside_medium))
    else
        mesh!(scene, geom; material=mat)
    end
end
