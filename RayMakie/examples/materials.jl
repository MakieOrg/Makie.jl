using GeometryBasics, Hikari
using Colors, FileIO
using RayMakie
using Makie
using ImageShow
using Lava

function make_perlin_texture(resolution::Int; scale=4.0, bias=0.5, contrast=1.0)
    tex = Matrix{Float32}(undef, resolution, resolution)
    for j in 1:resolution, i in 1:resolution
        u, v = (i - 0.5) / resolution, (j - 0.5) / resolution
        n = Hikari.fbm3d(u * scale, v * scale, 0.0; octaves=4, persistence=0.5)
        tex[i, j] = Float32(clamp(bias + contrast * n, 0, 1))
    end
    return tex
end

function make_perlin_rgb_texture(resolution::Int; scale=4.0, base_color=(1.0, 1.0, 1.0), variation=0.3)
    tex = Matrix{Hikari.RGBSpectrum}(undef, resolution, resolution)
    for j in 1:resolution, i in 1:resolution
        u, v = (i - 0.5) / resolution, (j - 0.5) / resolution
        n = Hikari.fbm3d(u * scale, v * scale, 0.0; octaves=4)
        n2 = Hikari.fbm3d(u * scale + 5.3, v * scale - 2.1, 0.0; octaves=3)
        r = Float32(clamp(base_color[1] + variation * n, 0, 1))
        g = Float32(clamp(base_color[2] + variation * n2, 0, 1))
        b = Float32(clamp(base_color[3] + variation * (n + n2) * 0.5, 0, 1))
        tex[i, j] = Hikari.RGBSpectrum(r, g, b, 1.0f0)
    end
    return tex
end

function create_scene()
    lights = [
        PointLight(RGBf(60, 60, 60), Vec3f(8, 8, 10)),
        PointLight(RGBf(20, 20, 20), Vec3f(-2, -6, 3)),
    ]

    ax = Scene(; size=(1200, 900), lights=lights, ambient=RGBf(0.02, 0.02, 0.025))
    cam3d!(ax)

    # --- Glass and transparent materials (front row) ---
    glass = Hikari.Dielectric(Kt=(1, 1, 1), index=1.5)
    thin_glass = Hikari.ThinDielectric(eta=1.5)

    # Textured glass with Perlin color variation
    glass_tint_tex = make_perlin_rgb_texture(64; scale=3.0, base_color=(0.95, 0.98, 1.0), variation=0.08)
    textured_glass = Hikari.Dielectric(Kt=Hikari.Texture(glass_tint_tex), index=1.5)

    # --- Volumetric materials ---
    milk_medium = Hikari.Milk(scale=0.1)
    milk_glass = Hikari.MediumInterface(
        Hikari.Dielectric(Kt=(1, 1, 1), index=1.5);
        inside=milk_medium, outside=nothing
    )

    smoke_medium = Hikari.Smoke(density=5.0, albedo=0.95, g=0.3)
    smoke_vol = Hikari.MediumInterface(
        Hikari.Dielectric(Kt=(1, 1, 1), index=1.0);
        inside=smoke_medium, outside=nothing
    )

    coffee_medium = Hikari.Coffee(scale=0.5)
    coffee_glass = Hikari.MediumInterface(
        Hikari.Dielectric(Kt=(0.95, 0.9, 0.85), index=1.5);
        inside=coffee_medium, outside=nothing
    )

    # Cloud (GridMedium) - positioned for row 2
    sphere_radius = 0.25f0
    spacing = 0.7f0
    nrows, ncols = 5, 4

    # Cloud bounds (will be at row 2, col 2)
    cloud_row, cloud_col = 2, 2
    cloud_x = (cloud_col - (ncols + 1) / 2) * spacing
    cloud_y = (cloud_row - (nrows + 1) / 2) * spacing - 4.5
    sphere_center = Vec3f(cloud_x, cloud_y, sphere_radius)
    cloud_origin = sphere_center - Vec3f(sphere_radius)
    cube_size = sphere_radius * 2

    cloud_density = Hikari.generate_cloud_density(128;
        scale=2.5,           # Larger cells for visible puffiness
        threshold=0.15,      # Include more density
        worley_weight=0.2,   # Balance of Worley (puffy) and billow (detail)
        edge_sharpness=4.0,  # Soft puffy edges
        density_scale=4.5    # Match real cloud density range (~2-3 max)
    )
    cloud_grid = Hikari.GridMedium(
        cloud_density;
        σ_a = Hikari.RGBSpectrum(0.5f0),   # Same as bunny cloud
        σ_s = Hikari.RGBSpectrum(15.0f0),  # Same as bunny cloud
        g = 0.0f0,                          # Isotropic scattering
        bounds=Hikari.Bounds3(cloud_origin, cloud_origin + Vec3f(cube_size)),
        majorant_res=Vec3i(32)              # Higher res majorant grid
    )
    cloud_vol = Hikari.MediumInterface(
        Hikari.Dielectric(Kt=(1, 1, 1), index=1.0);
        inside=cloud_grid, outside=nothing
    )

    # --- Metals with textures ---
    # Textured gold with varying roughness (Perlin pattern)
    gold_roughness_tex = make_perlin_texture(64; scale=6.0, bias=0.03, contrast=0.08)
    textured_gold = Hikari.Conductor(
        eta = (0.143f0, 0.374f0, 1.442f0),
        k = (3.983f0, 2.385f0, 1.603f0),
        roughness = Hikari.Texture(gold_roughness_tex)
    )

    silver = Hikari.Silver(roughness=0.02)
    copper = Hikari.Copper(roughness=0.08)
    mirror = Hikari.Mirror(Kr=(0.95, 0.95, 0.95))

    # --- Coated materials ---
    coated_gold = Hikari.Gold()
    car_paint = Hikari.CoatedConductor(
        interface_roughness=0.08,
        reflectance=(0.85, 0.1, 0.1),
        conductor_roughness=0.01
    )
    coated_blue = Hikari.CoatedDiffuse(reflectance=(0.1, 0.2, 0.7), roughness=0.05)

    # --- Plastic ---
    plastic_white = Hikari.Plastic(Kd=(0.9, 0.9, 0.9), Ks=(0.4, 0.4, 0.4), roughness=0.15)

    # --- Emissive materials (pure emitters via MediumInterface) ---
    emissive_white = Hikari.MediumInterface(Hikari.Emissive(Le=(4, 4, 4)))
    emissive_warm = Hikari.MediumInterface(Hikari.Emissive(Le=(2.0, 1.2, 0.5)))
    emissive_cyan = Hikari.MediumInterface(Hikari.Emissive(Le=(0.3, 1.5, 1.5)))

    # Textured emissive with Perlin pattern
    emissive_pattern_tex = make_perlin_rgb_texture(64; scale=5.0, base_color=(1.5, 0.3, 1.2), variation=0.8)
    textured_emissive = Hikari.MediumInterface(Hikari.Emissive(Le=Hikari.Texture(emissive_pattern_tex)))

    # --- Simple materials (back) ---
    diffuse_gray = Hikari.Diffuse(Kd=(0.6, 0.6, 0.6))
    paper = Hikari.DiffuseTransmission(reflectance=(0.85, 0.85, 0.85), transmittance=(0.4, 0.4, 0.4))

    # ========================================================================
    # Arrange materials in 5x4 grid
    # Row 1 (front): Glass and volumetrics
    # Row 2: Cloud behind emissive, more interesting materials
    # Row 3: Metals
    # Row 4: Coated materials
    # Row 5 (back): Diffuse + emissives in diagonal
    # ========================================================================

    materials = [
        # Row 1 (front): Glass and volumetrics - most visually interesting
        glass          textured_glass  milk_glass     smoke_vol;
        # Row 2: Cloud (col 2) behind emissive (col 1)
        emissive_white cloud_vol       coffee_glass   thin_glass;
        # Row 3: Metals
        textured_gold  silver          copper         mirror;
        # Row 4: Coated and plastic
        coated_gold    car_paint       coated_blue    plastic_white;
        # Row 5 (back): Simple + emissives diagonal (positions 1 and 4)
        emissive_warm  paper           diffuse_gray   textured_emissive
    ]

    labels = [
        "Glass"        "TexturedGlass" "Milk"         "Smoke";
        "Emissive"     "Cloud"         "Coffee"       "ThinGlass";
        "TexturedGold" "Silver"        "Copper"       "Mirror";
        "CoatedGold"   "CarPaint"      "CoatedBlue"   "Plastic";
        "WarmLight"    "Paper"         "Diffuse"      "PatternEmit"
    ]

    # Floor
    floor_material = Hikari.Diffuse(Kd=(0.7, 0.7, 0.7))
    floor_mesh = Rect3f(Vec3f(-10, -10, -0.001), Vec3f(20, 20, 0.001))
    mesh!(ax, floor_mesh; material=floor_material)

    # Place spheres in grid
    for i in CartesianIndices(materials)
        row, col = Tuple(i)
        mat = materials[i]
        x = (col - (ncols + 1) / 2) * spacing
        y = (row - (nrows + 1) / 2) * spacing - 4.5
        pos = Point3f(x, y, sphere_radius)
        mesh!(ax, Sphere(pos, sphere_radius), material=mat)
    end

    # Camera setup
    cam = cameracontrols(ax)
    cam.eyeposition[] = Vec3f(0, -7.5, 2.5)
    cam.lookat[] = Vec3f(0, -4.7, 0)
    cam.upvector[] = Vec3f(0, 0, 1)
    cam.fov[] = 42
    update_cam!(ax, cam)
    return ax
end

# Render
sensor = Hikari.FilmSensor(; iso=50, exposure_time=1.0, white_balance=0)
device = Lava.LavaBackend()
# device = KernelAbstractions.CPU()
RayMakie.activate!(
    device=device,
    exposure=0.6f0,
    tonemap=:aces,
    gamma=2.2f0,
    sensor=sensor
)
nsamples = 1000
ax = create_scene();
RayMakie.vulkan_viewer(ax; sensor=sensor, exposure=0.6f0, tonemap=:aces, gamma=1.0f0)

integrator = Hikari.VolPath(; samples=nsamples, max_depth=5, hw_accel=true)

img = @time colorbuffer(ax; backend=RayMakie, integrator=integrator)
img = @time colorbuffer(ax; backend=RayMakie, integrator=integrator)
img = @time colorbuffer(ax; backend=RayMakie, integrator=integrator)
img
screen = Makie.getscreen(ax)
colorbuffer(screen; clear=false)


# save(joinpath(@__DIR__, "materials-julia-$(nsamples)spp2.png"), img)
# Benchmark 10 samples
# Lava 7900xtx hw:  1.063923 seconds (3.38 M allocations: 184.093 MiB, 1.56% gc time)
# Lava 7900xtx: 1.349905 seconds (1.45 M allocations: 278.549 MiB, 4.80% gc time)
# Lava 3070m hw: 1.682083 secoRecommendations (ordered by expected impact)
#=
  High impact:

  1. Inline queue routing into RT shaders — Instead of the extract→trace→reconstruct pattern, have the raygen shader read directly from the work queue and the closest-hit shader write directly to output queues. This eliminates the
   intermediate RTRay/RTHitResult buffers and the extra compute kernel. This is a significant refactor but is the single biggest architectural difference from pbrt-v4.
  2. Single-launch shadow rays with media — Instead of 4 rounds of RT+compute, implement a raygen shader that loops internally (trace → check hit → handle medium transition → trace again). Vulkan RT supports calling traceRayEXT
  from within raygen shaders in a loop, just like OptiX's optixTrace().

  Medium impact:

  3. Alpha textures in any-hit shader — Requires texture sampling support in Lava's RT shaders (Phase 2 work anyway). Until then, scenes with cutout geometry take the slow path.
  4. Ray flags — Use gl_RayFlagsOpaqueEXT when no any-hit needed, gl_RayFlagsTerminateOnFirstHitEXT for shadow rays (easy win).

nds (1.60 M allocations: 135.306 MiB, 1.11% gc time)
# ROCarray 7900xtx: 1.685820 seconds (822.75 k allocations: 62.698 MiB, 2 lock conflicts)
# Lava 3070m:  1.546421 seconds (806.15 k allocations: 100.501 MiB, 1.36% gc time)
# CUDA 3070m: 1.767812 seconds (1.23 M allocations: 57.798 MiB, 1.04% gc time)
# Abacus: 12.221356 seconds (1.49 M allocations: 200.444 MiB)
# OpenCL: 23.625098 seconds (1.01 M allocations: 134.024 MiB, 0.16% gc time)
# Array: 26.235557 seconds (957.16 M allocations: 94.225 GiB, 44.58% gc time)
#=
Benchmarks with:
add https://github.com/SimonDanisch/Abacus.jl#sd/vk Hikari#master Raycore#sd/multitype-vec Makie#sd/hikari


 Info: Lava: initialized Vulkan device with RT
│   device = "NVIDIA GeForce RTX 3070 Laptop GPU"
│   queue_family = 0x00000000
│   handle_size = 0x00000020
│   max_recursion = 0x0000001f
│   validation = true
└   debug_utils = true

Lava hw_accel=false
152.691834 seconds (484.70 M allocations: 20.000 GiB, 3.56% gc time, 77.72% compilation time: 1% of which was recompilation)
  2.438812 seconds (1.59 M allocations: 137.244 MiB, 16.58% gc time, 0.14% compilation time)
  2.236804 seconds (1.59 M allocations: 137.193 MiB, 16.25% gc time, 0.21% compilation time)
Lava hw_accel=true
 24.346725 seconds (81.08 M allocations: 2.587 GiB, 8.57% gc time, 33.13% compilation time: <1% of which was recompilation)
  2.433334 seconds (3.38 M allocations: 190.531 MiB, 16.42% gc time)
  2.478928 seconds (3.38 M allocations: 190.537 MiB, 16.16% gc time)
CUDA:
113.600948 seconds (245.80 M allocations: 10.745 GiB, 2.13% gc time, 1 lock conflict, 50.61% compilation time: <1% of which was recompilation)
  1.817287 seconds (1.22 M allocations: 57.380 MiB, 2.05% gc time)
  1.768847 seconds (1.22 M allocations: 57.342 MiB, 1 lock conflict)
=#
=#
