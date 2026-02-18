using GeometryBasics, Hikari
using Colors, FileIO
using RayMakie
using Makie
using ImageShow

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
    lights = [
        PointLight(RGBf(1500, 1500, 1500), Vec3f(-15, 3, 5)),
    ]

    ax = Scene(; size=(1024, 1024), lights=lights, ambient=RGBf(0.02, 0.02, 0.02))
    cam3d!(ax)

    # ========================================================================
    # Define materials
    # ========================================================================
    glass = Hikari.Dielectric(Kt=(1, 1, 1), index=1.25)

    floor_material = Hikari.Plastic(
        Kd=(0.64, 0.64, 0.64),
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
# Render with SPPM (good for caustics)
RayMakie.activate!(backend=AMDGPU.ROCBackend(),
    exposure=0.6f0,
    tonemap=:aces,
    gamma=2.2f0,
    sensor=Hikari.FilmSensor(iso=50, exposure_time=1.0, white_balance=0)
)
integrator = Hikari.VolPath(samples=100, max_depth=30)
img = @time colorbuffer(ax; backend=RayMakie, integrator=integrator, max_component_value=10000f0)
# save(joinpath(@__DIR__, "caustic_glass.png"), img)
img
