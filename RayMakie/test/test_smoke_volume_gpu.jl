# Test script for Smoke volume with GPU - run with bash to catch segfault
# julia --check-bounds=yes test_smoke_volume_gpu.jl

using GeometryBasics, Hikari
using Colors
using RayMakie
using Makie
using AMDGPU

println("Testing Smoke volume with ROCArray...")
println("AMDGPU functional: ", AMDGPU.functional())

# Test with ROCArray backend
let
    lights = [
        PointLight(RGBf(50, 50, 50), Vec3f(10, 10, 10)),
    ]

    ax = Scene(; size=(100, 100), lights=lights, ambient=RGBf(0, 0, 0))
    cam3d!(ax)

    # Smoke sphere (no glass shell - pure volume)
    smoke_medium = Hikari.Smoke(density=2.0, albedo=0.95, g=0.5)
    smoke_vol = Hikari.MediumInterface(
        Hikari.Dielectric(Kt=(1, 1, 1), index=1.0);
        inside=smoke_medium,
        outside=nothing
    )

    # Floor
    floor_material = Hikari.Diffuse(Kd=(0.8, 0.8, 0.8))
    floor_mesh = Rect3f(Vec3f(-10, -10, -0.001), Vec3f(20, 20, 0.001))
    mesh!(ax, floor_mesh; color=:white, material=floor_material)

    # Smoke sphere
    mesh!(ax, Sphere(Point3f(0, 0, 0.25), 0.25f0), material=smoke_vol)

    # Camera setup
    cam = cameracontrols(ax)
    cam.eyeposition[] = Vec3f(0, -3, 1)
    cam.lookat[] = Vec3f(0, 0, 0)
    cam.upvector[] = Vec3f(0, 0, 1)
    cam.fov[] = 40
    update_cam!(ax, cam)

    # Activate with ROCArray backend
    RayMakie.activate!(
        device=AMDGPU.ROCBackend(),
        exposure=0.5f0,
        tonemap=nothing,
        gamma=2.2f0,
        sensor=Hikari.FilmSensor(iso=50, exposure_time=1.0, white_balance=0)
    )

    integrator = Hikari.VolPath(samples=1, max_depth=4, filter=Hikari.GaussianFilter())

    println("Starting render with Smoke volume (ROCArray backend)...")
    flush(stdout)
    img = @time colorbuffer(ax; backend=RayMakie, integrator=integrator)
    println("ROCArray backend render complete! Size: ", size(img))
end

println("ROCArray backend test passed!")
