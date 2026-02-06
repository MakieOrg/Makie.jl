# Bunny Cloud Scene - NanoVDB Volumetric Path Tracing Example
# Uses actual NanoVDB volumetric data from pbrt-v4-scenes for spatially-varying density
#
# This parses the NanoVDB file format directly in Julia and renders with GridMedium + VolPath
using TraceMakie, Makie, Hikari, GeometryBasics
using FileIO

# Rotation matrix helpers for pbrt-style transforms
_RotX(θ) = Mat3f(1, 0, 0, 0, cos(θ), -sin(θ), 0, sin(θ), cos(θ))
_RotZ(θ) = Mat3f(cos(θ), -sin(θ), 0, sin(θ), cos(θ), 0, 0, 0, 1)

function create_nanovdb_bunny_scene_direct(nvdb_path::String;
    resolution=(800, 600),
    sigma_s=10.0f0,
    sigma_a=0.5f0,
    g=0.0f0,
    majorant_res=Vec3i(64, 64, 64)
)
    # pbrt bunny-cloud applies: Rotate 180 0 0 1, then Rotate 90 1 0 0
    # Matrix form: R_x(90°) * R_z(180°) (right-to-left application)
    bunny_transform = _RotX(Float32(π/2)) * _RotZ(Float32(π))

    # Create NanoVDBMedium directly from file with rotation transform
    nanovdb_medium = Hikari.NanoVDBMedium(
        nvdb_path;
        σ_a = Hikari.RGBSpectrum(sigma_a),
        σ_s = Hikari.RGBSpectrum(sigma_s),
        g = g,
        transform = bunny_transform,
        majorant_res = majorant_res
    )
    println("Created NanoVDBMedium:")
    println("  Bounds: $(nanovdb_medium.bounds)")
    println("  Buffer size: $(length(nanovdb_medium.buffer)) bytes")

    # Create scene
    s = Scene(size=resolution; lights=Makie.AbstractLight[])
    cam3d!(s)

    # Camera setup matching pbrt
    cam_pos = Vec3f(0, 120, 50)
    look_at = Vec3f(7, 0, 17)
    update_cam!(s, cam_pos, look_at, Vec3f(0, 0, 1))
    s.camera_controls.fov[] = 25.0

    # Transparent boundary material
    transparent = Hikari.GlassMaterial(
        Kr = Hikari.RGBSpectrum(0f0),
        Kt = Hikari.RGBSpectrum(1f0),
        index = 1.0f0
    )

    # Sphere geometry for medium boundary
    sphere_mesh = GeometryBasics.normal_mesh(GeometryBasics.Sphere(Point3f(0, 0, 0), 45f0))

    # Volume sphere with NanoVDBMedium
    volume_material = Hikari.MediumInterface(transparent; inside=nanovdb_medium, outside=nothing)
    mesh!(s, sphere_mesh; material=volume_material)

    # Ground
    ground_size = 1000f0
    ground_geo = Rect3f(Vec3f(-ground_size, -ground_size, -0.1f0),
                        Vec3f(2*ground_size, 2*ground_size, 0.2f0))
    ground_material = Hikari.CoatedDiffuseMaterial(
        reflectance = (0.4f0, 0.45f0, 0.35f0),
        roughness = 0f0,
        eta = 1.5f0,
        thickness = 0.01f0
    )
    mesh!(s, ground_geo; color=RGBf(0.4f0, 0.45f0, 0.35f0), material=ground_material)

    # Environment light
    sky_path = joinpath(dirname(nvdb_path), "textures", "sky.exr")
    sky_image = FileIO.load(sky_path)
    env_light = Makie.EnvironmentLight(4.0f0, sky_image)
    push_light!(s, env_light)
    println("Loaded environment light from: $sky_path")

    return s
end

function render_nanovdb_bunny(nvdb_path::String;
    resolution=(1920, 1080),
    samples_per_pixel=32,
    max_depth=50,
    exposure=1.0f0,
    iso=90f0,
    white_balance=4000f0,
    tonemap=:aces,
    gamma=2.2f0,
    backend=Array,
    kwargs...
)
    # Configure VolPath integrator with pbrt-matching sensor settings
    volpath_config = (
        backend = backend,
        integrator = TraceMakie.VolPath(
            samples=samples_per_pixel,
            max_depth=max_depth,
        ),
        exposure = exposure,
        tonemap = tonemap,
        gamma = gamma,
        sensor = Hikari.FilmSensor(iso=iso, white_balance=white_balance),
    )
    TraceMakie.activate!(; volpath_config...)
    # Create and render scene
    scene = create_nanovdb_bunny_scene_direct(nvdb_path; resolution=resolution, kwargs...)
    img = colorbuffer(scene; backend=TraceMakie)

    return img, scene
end
nvdb_path = joinpath(@__DIR__, "..", "..", "..", "..", "pbrt-v4-scenes", "bunny-cloud", "bunny_cloud.nvdb")
using AMDGPU
nsamples = 5
@time img, scene = render_nanovdb_bunny(
    nvdb_path;
    samples_per_pixel=nsamples,
    max_depth=50,
    iso=50f0,
    gamma=2.2f0,
    exposure=0.5,
    tonemap=nothing,
    white_balance=5000,
    backend=ROCArray
)
img
# img
save("bunny-$(nsamples)ssp-tm.png", img)
