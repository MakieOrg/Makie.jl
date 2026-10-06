# A figure with no plots at display time used to throw "No renderable scenes
# found." from `colorbuffer`, and a plot added to it afterwards never drew:
# `insert!` returned when the screen had no scene state. Now the empty figure is
# its background, and an inserted plot's scene gets its state as `init_scene!`
# would have made it (`scene_state!`), traced for a 3D camera.

using Test, Makie, RayMakie, GeometryBasics, Colors
RayMakie.activate!()

screens = (
    "raster" => fig -> RayMakie.Screen(fig.scene; visible = false, vsync = false, rasterize = true,
                                       tonemap = nothing, gamma = nothing),
    "traced" => fig -> RayMakie.Screen(fig.scene; visible = false, vsync = false, rasterize = false,
                                       samples = 1, max_depth = 8),
)
reds(img) = count(c -> red(c) > 0.8 && green(c) < 0.3 && blue(c) < 0.3, img)
oranges(img) = count(c -> red(c) > 0.5 && 0.15 < green(c) < 0.75 && blue(c) < 0.25, img)

@testset "a figure empty at display, filled later ($name)" for (name, open) in screens
    fig = Figure(; size = (400, 300), backgroundcolor = RGBf(0.9, 0.9, 1.0))
    screen = open(fig)
    i0 = copy(colorbuffer(screen))
    @test all(==(RGBA{Float32}(0.9, 0.9, 1.0, 1.0)), i0)
    ax = Axis(fig[1, 1]; limits = (0, 11, 0, 2))
    scatter!(ax, [Point2f(i, 1) for i in 1:10]; markersize = 20, color = :red)
    @test reds(copy(colorbuffer(screen))) > 1000
    ls = LScene(fig[1, 2]; show_axis = false)
    m = mesh!(ls, Sphere(Point3f(0), 1f0); color = :orange)
    @test oranges(copy(colorbuffer(screen))) > 2000
    # The LScene got a state of its own: traced unless the screen rasterises.
    @test (m.trace_renderobject[] !== nothing) == (name == "traced")
    close(screen)
end
