using GeometryBasics, Hikari
using Colors, FileIO
using RayMakie
using Makie
using ImageShow
using pocl_jll, OpenCL, AMDGPU
# ============================================================================
# Material Gallery Scene - Reorganized with interesting materials in front
# ============================================================================

begin
    # ========================================================================
    # Helper: Generate Perlin noise texture
    # ========================================================================
    function make_perlin_texture(resolution::Int; scale=4.0, bias=0.5, contrast=1.0)
        tex = Matrix{Float32}(undef, resolution, resolution)
        for j in 1:resolution, i in 1:resolution
            u, v = (i - 0.5) / resolution, (j - 0.5) / resolution
            n = Hikari.fbm3d(u * scale, v * scale, 0.0; octaves=4, persistence=0.5)
            tex[i, j] = Float32(clamp(bias + contrast * n, 0, 1))
        end
        tex
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
            tex[i, j] = Hikari.RGBSpectrum(r, g, b, 1f0)
        end
        tex
    end

    # ========================================================================
    # Setup lighting
    # ========================================================================
    lights = [
        PointLight(RGBf(60, 60, 60), Vec3f(8, 8, 10)),
        PointLight(RGBf(20, 20, 20), Vec3f(-2, -6, 3)),
    ]

    ax = Scene(; size=(1200, 900), lights=lights, ambient=RGBf(0.02, 0.02, 0.025))
    cam3d!(ax)

    # ========================================================================
    # Define materials - organized by visual interest
    # ========================================================================

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
end

# Render
sensor = Hikari.FilmSensor(; iso=50, exposure_time=1.0, white_balance=0)
using pocl_jll, OpenCL, KernelAbstractions, Abacus
device = OpenCL.OpenCLBackend()
device = AMDGPU.ROCBackend()
device = KernelAbstractions.CPU()
device = Abacus.AbacusBackend()
RayMakie.activate!(
    device=device,
    exposure=0.6f0,
    tonemap=:aces,
    gamma=2.2f0,
    sensor=sensor
)
nsamples = 10
integrator = Hikari.VolPath(samples=nsamples, max_depth=50)
img = @time colorbuffer(ax; backend=RayMakie, integrator=integrator)
img = @time colorbuffer(ax; backend=RayMakie, integrator=integrator)
img = @time colorbuffer(ax; backend=RayMakie, integrator=integrator)

# save(joinpath(@__DIR__, "materials-julia-$(nsamples)spp2.png"), img)
# Benchmark 10 samples
# ROCarray: 1.685820 seconds (822.75 k allocations: 62.698 MiB, 2 lock conflicts)
# Abacus: 12.221356 seconds (1.49 M allocations: 200.444 MiB)
# OpenCL: 23.625098 seconds (1.01 M allocations: 134.024 MiB, 0.16% gc time)
# Array: 26.235557 seconds (957.16 M allocations: 94.225 GiB, 44.58% gc time)

img
