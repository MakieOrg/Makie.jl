using GeometryBasics, Hikari
using Colors, FileIO
using RayMakie
using Makie
using ImageShow, LinearAlgebra

# ============================================================================
# Caustic Glass Scene - Demonstrates SPPM rendering for caustics
# ============================================================================

begin
    # ========================================================================
    # Load model
    # ========================================================================
    model = load(joinpath(dirname(pathof(Hikari)), "..", "docs", "src", "assets", "models", "caustic-glass.ply"))

    # ========================================================================
    # Setup lighting
    # ========================================================================
    sun_dir = normalize(Vec3f(0.4f0, 0.5f0, 0.85f0))
    lights = [
        Makie.SunSkyLight(
            Vec3f(0.4, -0.3, 0.7);           # sun direction (late afternoon)
            intensity=1.0f0,
            turbidity=3.0f0,
            ground_enabled=false,             # pure sky dome, no ground plane
        ),
    ]

    ax = Scene(; size=(1024, 1024), lights=lights, ambient=RGBf(0.02, 0.02, 0.02))
    cam3d!(ax)

    # ========================================================================
    # Define materials
    # ========================================================================
    glass = Hikari.Dielectric(Kt=(1, 1, 1), index=1.25)

    floor_material = Hikari.Plastic(
        color=(0.64, 0.64, 0.64),
        roughness=0.01,
    )

    # ========================================================================
    # Setup scene geometry
    # ========================================================================
    mesh!(ax, model, material=glass)

    # Create floor below the glass model
    mini, maxi = extrema(Rect3f(decompose(Point, model)))
    floorrect = Rect3f(Vec3f(-10, mini[2], -10), Vec3f(20, -1, 20))
    mesh!(ax, floorrect, material=floor_material)

    # ========================================================================
    # Camera setup
    # ========================================================================
    cam = cameracontrols(ax)
    cam.eyeposition[] = Vec3f(-1.6, 6.2, 0.2)
    cam.lookat[] = Vec3f(-3.2, 2.5, 2.4)
    cam.upvector[] = Vec3f(0, 1, 0)
    cam.fov[] = 45
    update_cam!(ax, cam)
end
using AMDGPU
using Abacus
# Render with SPPM (good for caustics)

RayMakie.activate!(
    device=AMDGPU.ROCBackend(),
    # device=Abacus.VulkanBackend(),
    exposure=0.6f0,
    tonemap=:aces,
    gamma=2.2f0,
    sensor=Hikari.FilmSensor(iso=100)
)
integrator = Hikari.VolPath(samples=10, max_depth=30)
img = @time colorbuffer(ax; backend=RayMakie, integrator=integrator)
# save(joinpath(@__DIR__, "caustic_glass.png"), img)
img
