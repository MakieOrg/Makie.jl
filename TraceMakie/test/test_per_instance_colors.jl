# Test per-instance colors for meshscatter
using Revise
using Makie, TraceMakie
using GeometryBasics
using Colors
using FileIO

"""
Test per-instance colors in meshscatter.
"""
function test_per_instance_colors()
    println("Testing per-instance colors for meshscatter...")

    # Create scene
    scene = Scene(size=(800, 600); camera=cam3d!,
        lights=[
            PointLight(RGBf(5000, 5000, 5000), Point3f(0, 0, 50)),
            AmbientLight(RGBf(0.3, 0.3, 0.3))
        ]
    )

    cam = cameracontrols(scene)
    cam.eyeposition[] = Vec3f(30, 30, 20)
    cam.lookat[] = Vec3f(0, 0, 5)
    cam.upvector[] = Vec3f(0, 0, 1)
    cam.fov[] = 50f0

    # Floor
    floor_mesh = normal_mesh(Rect3f(Vec3f(-20, -20, 0), Vec3f(40, 40, 0.5)))
    mesh!(scene, floor_mesh; color=RGBf(0.5, 0.5, 0.5))

    # Create spheres with per-instance colors (rainbow)
    sphere = Sphere(Point3f(0), 1.0f0)
    n = 7
    positions = [Point3f(i * 4 - 14, 0, 3) for i in 1:n]
    sizes = [Vec3f(2.5) for _ in 1:n]

    # Rainbow colors
    colors = [
        RGBf(1, 0, 0),      # Red
        RGBf(1, 0.5, 0),    # Orange
        RGBf(1, 1, 0),      # Yellow
        RGBf(0, 1, 0),      # Green
        RGBf(0, 0.5, 1),    # Cyan
        RGBf(0, 0, 1),      # Blue
        RGBf(0.5, 0, 1),    # Purple
    ]

    meshscatter!(scene, positions;
        marker=sphere,
        markersize=sizes,
        color=colors
    )

    # Render
    screen = TraceMakie.Screen(scene;
        integrator=TraceMakie.Whitted(samples_per_pixel=4, max_depth=2)
    )

    println("Rendering...")
    img = Makie.colorbuffer(screen)
    println("Done! Image size: $(size(img))")

    # Save result
    outpath = joinpath(@__DIR__, "per_instance_colors_test.png")
    save(outpath, img)
    println("Saved to: $outpath")

    return img, scene
end

# Run test
test_per_instance_colors()
