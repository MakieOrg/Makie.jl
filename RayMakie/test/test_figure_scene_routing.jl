# Which scene a plot gets drawn against.
#
# `init_scene!` walks the scenes that own plots and calls `draw_atomic` for each,
# with `screen.state` set to that scene's state. It used to enumerate a scene's
# plots with `Makie.for_each_atomic_plot(rscene)` — which recurses into
# `scene.children` as well as into a plot's own children. So a PARENT claimed its
# children's plots.
#
# In a `Figure` the root scene is first, carries an `EmptyCamera`, and is
# therefore overlay-only with `hikari_scene === nothing`. It drew every `Axis3`'s
# meshes against itself, and `draw_atomic(::Mesh)` reads
# `!should_raytrace(scene, plot) || isnothing(hikari_scene)` — both true — so it
# took the RASTER path. The compute node caches that, and once the plot had a
# `:trace_renderobject` the axis's own pass skipped it.
#
# Net effect: nothing in a Figure was ever raytraced. An `Axis3` sphere came out
# as a flat disc of the raw plot colour over an empty TLAS and an all-zero film,
# and no exposure or tonemap setting could change it — which is what makes the
# pixel assertions below secondary to the two structural ones.

using Test
using Makie, RayMakie, Hikari, Raycore, GeometryBasics, Colors
using Makie: Figure, Axis3, mesh!, Point3f, Sphere

make_screen(scene) = RayMakie.Screen(scene; integrator = Hikari.VolPath(samples = 2, max_depth = 2))

@testset "a plot in a Figure is drawn against its own scene" begin
    fig = Figure(; size = (128, 128))
    ax = Axis3(fig[1, 1])
    plt = mesh!(ax, Sphere(Point3f(0), 1.0f0); color = :tomato)

    screen = make_screen(fig.scene)
    img = Makie.colorbuffer(screen)

    rt_states = filter(s -> !s.overlay_only, screen.scene_states)
    @test !isempty(rt_states)

    # The structural assertions. A raster fallback leaves the TLAS empty and
    # hands back a `LavaRenderObject` instead of a Hikari scene handle.
    @test any(s -> Raycore.n_instances(s.hikari_scene.accel) > 0, rt_states)
    robj = plt[:trace_renderobject][]
    @test !(robj isa RayMakie.LavaRenderObject)
    @test hasproperty(robj, :handle)

    # And the consequence, so a regression is visible in the image too: a
    # raytraced sphere is shaded, so it is NOT one flat colour. `:tomato` exactly
    # — the raw sRGB value, unlit — was what the raster path painted.
    tomato = RGB{Float32}(1.0f0, 0.3882353f0, 0.2784314f0)
    flat = count(c -> RGB{Float32}(red(c), green(c), blue(c)) == tomato, img)
    @test flat < 20
    @test length(unique(img)) > 500
end
