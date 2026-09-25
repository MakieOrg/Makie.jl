# Integration test for materials scene rendering
# Tests the full render pipeline with various materials
# Run with: julia --check-bounds=yes test_materials_scene.jl

using Test
using GeometryBasics, Hikari
using Colors
using RayMakie
using Makie
# `Raycore.KA.CPU()` is the default backend for every entry point below, but the
# import was missing — the file depended on whatever harness ran it having
# imported Raycore already. Same failure shape as denoise.jl's unbound `KA`.
using Raycore

"""
    create_test_materials_scene(; size=(400, 300))

Create a simplified materials test scene with a variety of materials.
This is a smaller version of materials.jl example for quick testing.
"""
function create_test_materials_scene(; size=(400, 300))
    # Setup lighting
    lights = [
        PointLight(RGBf(50, 50, 50), Vec3f(10, 10, 10)),
        PointLight(RGBf(15, 15, 15), Vec3f(-0.3, -5.5, 1.5)),
    ]

    ax = Scene(; size=size, lights=lights, ambient=RGBf(0, 0, 0))
    cam3d!(ax)

    # Define a subset of materials for testing
    # Row 1: Basic materials
    diffuse_red = Hikari.Diffuse(Kd=(0.8, 0.2, 0.2))
    mirror = Hikari.Mirror(Kr=(0.95, 0.95, 0.95))
    glass = Hikari.Dielectric(Kt=(1, 1, 1), index=1.5)

    # Row 2: Metals
    gold = Hikari.Gold(roughness=0.05)
    copper = Hikari.Copper(roughness=0.1)

    # Row 3: Coated materials
    plastic_blue = Hikari.Plastic(color=(0.1, 0.2, 0.8), roughness=0.05)
    coated_red = Hikari.CoatedDiffuse(reflectance=(0.8, 0.2, 0.2), roughness=0.1)

    # Row 4: Emissive
    emissive_white = Hikari.Emissive(Le=(3, 3, 3))

    # Arrange in grid (2 rows x 4 columns)
    materials = [
        diffuse_red    mirror         glass          gold;
        copper         plastic_blue   coated_red     emissive_white
    ]

    # Floor
    floor_material = Hikari.Diffuse(Kd=(0.8, 0.8, 0.8))
    floor_mesh = Rect3f(Vec3f(-10, -10, -0.001), Vec3f(20, 20, 0.001))
    mesh!(ax, floor_mesh; color=:white, material=floor_material)

    # Place spheres in grid
    sphere_radius = 0.25f0
    spacing = 0.7f0
    nrows, ncols = Base.size(materials)

    for i in CartesianIndices(materials)
        row, col = Tuple(i)
        mat = materials[i]

        # Center the grid
        x = (col - (ncols + 1) / 2) * spacing
        y = (row - (nrows + 1) / 2) * spacing - 2.0  # Offset towards camera

        pos = Point3f(x, y, sphere_radius)
        mesh!(ax, Sphere(pos, sphere_radius), material=mat)
    end

    # Camera setup
    cam = cameracontrols(ax)
    cam.eyeposition[] = Vec3f(0, -5, 1.5)
    cam.lookat[] = Vec3f(0, -2, 0)
    cam.upvector[] = Vec3f(0, 0, 1)
    cam.fov[] = 40
    update_cam!(ax, cam)

    return ax
end

"""
    test_render_materials(; backend=Raycore.KA.CPU(), samples=1)

Test rendering the materials scene with the given backend.

The tone mapping and exposure go to `colorbuffer`, NOT to `activate!`.
`activate!` writes the global default theme and nothing here puts it back, so
this file used to leave `tonemap = nothing, exposure = 0.5, gamma = 2.2` set for
every test that ran after it — the whole rest of the suite, rendering HDR
radiance with no tone map, which saturates to white. runtests.jl already
re-activated the DEVICE afterwards to undo half of this; the other half stayed,
and it is what made the sphere in test_window_frame.jl come out white and
invisible when that file ran in the suite and orange when it ran alone.
Per-call config leaks nothing and needs no restoring.
"""
function test_render_materials(; backend=Raycore.KA.CPU(), samples=1)
    scene = create_test_materials_scene()
    # This file once drifted across three API moves at once, which is why it
    # errored on its first line and sat outside runtests.jl: `Hikari.FilmSensor`
    # became `PixelSensor` (and `white_balance` became `whitebalance`), `Raycore`
    # was never imported despite `Raycore.KA.CPU()` being the default argument,
    # and `sensor` moved. It is a screen setting, next to the tracer's others.
    # `hw_accel = false` is what this ran with when the tracer was a `VolPath`.
    sensor = Hikari.PixelSensor(iso=50, exposure_time=1.0, whitebalance=0)
    img = colorbuffer(scene; backend=RayMakie, samples, max_depth=4, sensor, hw_accel=false,
                      device=backend, exposure=0.5f0, tonemap=nothing, gamma=2.2f0)
    return img
end

@testset "Materials Scene Rendering" begin
    # Read BEFORE, so the leak is pinned rather than described. `activate!`
    # writes the global default theme and this file has no business changing it
    # for whatever runs next: with `tonemap = nothing` left set, every later
    # render maps HDR radiance straight to the display and saturates to white,
    # which took test_window_frame.jl's sphere out of its own picture.
    theme_before = let t = Makie.current_default_theme()[:RayMakie]
        Dict(k => t[k][] for k in (:device, :exposure, :tonemap, :gamma))
    end

    @testset "CPU Array backend" begin
        img = test_render_materials(backend=Raycore.KA.CPU(), samples=1)
        @test size(img) == (300, 400)
        @test eltype(img) <: Colorant
    end

    @testset "renders on its own config and leaves the defaults alone" begin
        t = Makie.current_default_theme()[:RayMakie]
        for (k, v) in theme_before
            @test t[k][] === v
        end
    end
end

# Can be run standalone to test
if abspath(PROGRAM_FILE) == @__FILE__
    println("Running materials scene test...")
    @time test_render_materials(backend=Raycore.KA.CPU(), samples=1)
    println("Test completed successfully!")
end
