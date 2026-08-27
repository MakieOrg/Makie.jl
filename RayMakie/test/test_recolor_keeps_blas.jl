using Test
using Makie, RayMakie, Hikari, Lava, GeometryBasics, Raycore

# Recolouring a mesh used to tear down its BLAS and rebuild it: `trace_color_tex`
# sat in `mesh_trace_dispatch!`'s `needs_rebuild` set beside `faces` and
# `positions`, even though the colour only ever reaches `extract_material` in
# `push_to_scene_simple` and never touches the geometry.
#
# Nothing about the image says which path ran, so this asserts on the handle: a
# rebuild calls `delete_trace_handles!` and re-pushes, producing a new TLAS
# instance, while a material update leaves it alone. Without that, "recolour is
# cheap" is only ever a claim about the source.
#
# Read colours with `Hikari.constant_value`, NOT `Kd.data[]` — a ConstTexture
# keeps its value in `constval` and leaves `data` an uninitialised 0-dim array,
# so `data[]` reads denormal garbage that compares unequal to everything and
# makes this test look like it passes.
@testset "recolour keeps the BLAS" begin
    scene = Makie.Scene(size = (64, 64))
    Makie.Camera3D(scene)
    p = mesh!(scene, Rect3f(Vec3f(-1), Vec3f(2)), color = :red)
    screen = RayMakie.Screen(scene; device = Mantle.LavaBackend(), visible = false)
    # The Screen constructor does not build the scene; `colorbuffer` does it
    # lazily and so does this.
    RayMakie.init_scene!(screen, scene)

    before = p.attributes[:trace_renderobject][]
    @test before !== nothing
    @test hasproperty(before, :handle)
    n_before = Raycore.n_instances(screen.scene_states[1].hikari_scene.accel)

    p.color = :blue
    RayMakie.poll_all_plots(screen, scene)
    after = p.attributes[:trace_renderobject][]

    # Same instance, same instance count: no delete + re-push happened.
    @test after.instance_idx == before.instance_idx
    @test Raycore.n_instances(screen.scene_states[1].hikari_scene.accel) == n_before
    # In-place `MultiTypeSet.update!` requires the concrete type to match.
    @test typeof(after.material) === typeof(before.material)
    # And the colour actually reached the material, so this is not passing by
    # doing nothing at all.
    @test Hikari.constant_value(before.material.Kd) != Hikari.constant_value(after.material.Kd)
    # `==`, not `≈`: RGBSpectrum has no isapprox method.
    @test Hikari.constant_value(after.material.Kd) == Hikari.RGBSpectrum(0.0f0, 0.0f0, 1.0f0, 1.0f0)

    close(screen)
end

# NOT COVERED, deliberately: the rebuild fallback for a colour change that alters
# the material's concrete type. `mesh_trace_dispatch!` guards on
# `typeof(recolor_material) !== typeof(last_robj.material)` because
# `MultiTypeSet.update!` cannot replace across types, but Makie's compute-graph
# inputs are type-locked after creation — assigning a `Vector{RGBA{Float32}}` to
# a plot created with a scalar colour throws in `ComputePipeline`, before RayMakie
# is reached at all. So the guard is defensive and no test here can drive it; if
# a future plot type does make `trace_color_tex` change type, this is the note
# saying the branch was never exercised.
