# Which PATH each kind of update takes, for meshes and for instances.
#
# `test_mesh_update_stress.jl` and `test_meshscatter_update_stress.jl` already
# cover that these updates run and keep their handles; this file covers the
# thing neither can see — whether an update rebuilt the acceleration structure
# or updated in place. That distinction is invisible in the image and is exactly
# where the cost is, so without it a change that turns every recolour into a
# BLAS rebuild passes the whole suite.
#
# `RayMakieState` counts rebuilds split by cause:
#   refit_eligible_rebuilds — only positions/normals were dirty, so a BLAS refit
#                             could have served it
#   topology_rebuilds       — faces or uv changed too, so a new BVH is required
# Both stay put when an update took the in-place path.
using Test, Makie, RayMakie, Lava, Hikari, GeometryBasics, Raycore
using GeometryBasics: Point3f, Vec2f, Vec3f, Rect3f, Sphere

robj_of(plt) = to_value(plt.attributes[:trace_renderobject])
make_screen(scene) = RayMakie.Screen(scene; integrator = Hikari.VolPath(samples = 1, max_depth = 1))
counters(state) = (state.refit_eligible_rebuilds, state.topology_rebuilds)
cube_mesh() = GeometryBasics.normal_mesh(Rect3f(Vec3f(-1), Vec3f(2)))

# A scene ready to be poked, with its state handle.
function trace_fixture(plotf)
    scene = Scene(size = (48, 48))
    cam3d!(scene)
    plt = plotf(scene)
    screen = make_screen(scene)
    RayMakie.init_scene!(screen, scene)
    return scene, plt, screen, screen.scene_states[1]
end

# ---------------------------------------------------------------------------
# Meshes
# ---------------------------------------------------------------------------

@testset "mesh — recolour updates in place" begin
    scene, plt, screen, st = trace_fixture(s -> mesh!(s, cube_mesh(); color = :red))
    before = counters(st)
    inst_before = Raycore.n_instances(st.hikari_scene.accel)

    for c in (:blue, :green, :yellow)
        plt.color = c
        RayMakie.poll_all_plots(screen, scene)
    end

    @test counters(st) == before                                        # no rebuild at all
    @test Raycore.n_instances(st.hikari_scene.accel) == inst_before
    close(screen)
end

@testset "mesh — material swap updates in place" begin
    scene, plt, screen, st = trace_fixture(
        s -> mesh!(s, cube_mesh(); material = Hikari.Diffuse(Kd = Hikari.RGBSpectrum(0.5f0))))
    before = counters(st)
    handle_before = robj_of(plt).handle

    plt.material = Hikari.Diffuse(Kd = Hikari.RGBSpectrum(0.1f0, 0.9f0, 0.1f0, 1.0f0))
    RayMakie.poll_all_plots(screen, scene)

    @test counters(st) == before
    @test robj_of(plt).handle === handle_before
    close(screen)
end

@testset "mesh — transform updates in place" begin
    scene, plt, screen, st = trace_fixture(s -> mesh!(s, cube_mesh(); color = :red))
    before = counters(st)

    for f in 1:5
        Makie.translate!(plt, 0.1f0 * f, 0.0f0, 0.0f0)
        RayMakie.poll_all_plots(screen, scene)
    end

    @test counters(st) == before
    close(screen)
end

# Deformation: same faces, moved vertices. This is the case a BLAS refit exists
# for, and it currently rebuilds — the counter says so rather than the test
# pretending otherwise. When the refit lands, `refit_eligible_rebuilds` should
# stop climbing and this assertion is what will catch it not doing so.
#
# The faces array must be a fresh object each frame: `ComputePipeline.is_same`
# treats an aliased array as CHANGED (in-place mutation between resolves is
# undetectable), so handing back the same faces vector marks topology dirty and
# the deformation is misclassified.
@testset "mesh — deformation is refit-eligible, not topology" begin
    src = cube_mesh()
    pts = GeometryBasics.coordinates(src)
    fcs = GeometryBasics.faces(src)
    # The base must carry the SAME attribute set as the frames that replace it.
    # Starting from `normal_mesh` (which has uv and normals) and deforming into a
    # bare `Mesh` drops both, and dropping an attribute changes the vertex layout
    # — that first frame is a genuine topology rebuild, not a misclassification.
    base = GeometryBasics.Mesh(copy(pts), copy(fcs))
    scene, plt, screen, st = trace_fixture(s -> mesh!(s, base; color = :red))
    before = counters(st)

    for f in 1:6
        moved = [Point3f(v[1], v[2] + 0.01f0 * f, v[3]) for v in pts]
        plt[1] = GeometryBasics.Mesh(moved, copy(fcs))
        RayMakie.poll_all_plots(screen, scene)
    end

    eligible, topology = counters(st) .- before
    @test eligible + topology == 6          # every frame did something
    @test topology == 0                     # none of it was a topology change
    @test eligible == 6
    close(screen)
end

@testset "mesh — resize (vertex and face count change) is a topology rebuild" begin
    cube = cube_mesh()
    sphere = GeometryBasics.normal_mesh(GeometryBasics.Tesselation(Sphere(Point3f(0), 1.0f0), 16))
    @test length(GeometryBasics.faces(cube)) != length(GeometryBasics.faces(sphere))

    scene, plt, screen, st = trace_fixture(s -> mesh!(s, cube; color = :red))
    before = counters(st)

    for f in 1:4
        plt[1] = isodd(f) ? sphere : cube
        RayMakie.poll_all_plots(screen, scene)
    end

    eligible, topology = counters(st) .- before
    @test topology == 4                     # a new BVH is genuinely required
    @test eligible == 0
    # The mesh survived the resize: still one instance, still traceable.
    @test Raycore.n_instances(st.hikari_scene.accel) >= 1
    @test robj_of(plt) !== nothing
    close(screen)
end

# ---------------------------------------------------------------------------
# Instances (meshscatter)
# ---------------------------------------------------------------------------

@testset "instances — recolour updates in place" begin
    pos = [Point3f(i, 0, 0) for i in 1:6]
    scene, plt, screen, st = trace_fixture(
        s -> meshscatter!(s, pos; marker = cube_mesh(), markersize = 0.3f0, color = :red))
    handles_before = robj_of(plt).handles

    plt.color = :blue
    RayMakie.poll_all_plots(screen, scene)

    # Same handles means no delete + re-push of the instance batch.
    @test robj_of(plt).handles === handles_before
    close(screen)
end

@testset "instances — material swap updates in place" begin
    pos = [Point3f(i, 0, 0) for i in 1:6]
    scene, plt, screen, st = trace_fixture(
        s -> meshscatter!(s, pos; marker = cube_mesh(), markersize = 0.3f0,
                          material = Hikari.Diffuse(Kd = Hikari.RGBSpectrum(0.5f0))))
    handles_before = robj_of(plt).handles

    plt.material = Hikari.Diffuse(Kd = Hikari.RGBSpectrum(0.9f0, 0.1f0, 0.1f0, 1.0f0))
    RayMakie.poll_all_plots(screen, scene)

    @test robj_of(plt).handles === handles_before
    # The handle check alone passed for a build where `material =` never reached
    # the image at all: `extract_meshscatter_materials` merged the cycler's
    # palette colour over the template, so every instance rendered teal both
    # before and after the swap. Assert the material that is actually stored.
    # meshscatter stores Kd as a `TexHandle` (tagged: kind + inline payload),
    # not as the `Texture` the mesh path uses, so the accessor differs —
    # `const_spectrum`, not `constant_value`.
    mats = robj_of(plt).materials
    @test !isempty(mats)
    @test all(m -> Hikari.const_spectrum(m.Kd) ==
                   Hikari.RGBSpectrum(0.9f0, 0.1f0, 0.1f0, 1.0f0), mats)
    close(screen)
end

# `material =` with no user-set colour must be used as given. `color` is a
# cycled attribute, so Makie writes `:cycled` into it when unset and a
# `!== nothing` test mistakes that for an explicit colour — which is how the
# palette colour came to overwrite the material on every meshscatter.
@testset "instances — an unset colour does not overwrite the material" begin
    pos = [Point3f(i, 0, 0) for i in 1:4]
    red = Hikari.RGBSpectrum(0.8f0, 0.2f0, 0.2f0, 1.0f0)
    scene, plt, screen, st = trace_fixture(
        s -> meshscatter!(s, pos; marker = cube_mesh(), markersize = 0.3f0,
                          material = Hikari.Diffuse(Kd = red)))

    mats = robj_of(plt).materials
    @test length(mats) == length(pos)
    @test all(m -> Hikari.const_spectrum(m.Kd) == red, mats)
    close(screen)
end

@testset "instances — moving positions keeps the batch" begin
    pos = Observable([Point3f(i, 0, 0) for i in 1:6])
    scene, plt, screen, st = trace_fixture(
        s -> meshscatter!(s, pos; marker = cube_mesh(), markersize = 0.3f0, color = :red))
    handles_before = robj_of(plt).handles

    for f in 1:5
        pos[] = [Point3f(i, 0.1f0 * f, 0) for i in 1:6]
        RayMakie.poll_all_plots(screen, scene)
    end

    # Instance transforms refit; the batch is not rebuilt while the count holds.
    @test robj_of(plt).handles === handles_before
    close(screen)
end

@testset "instances — resize rebuilds the batch and stays consistent" begin
    pos = Observable([Point3f(i, 0, 0) for i in 1:6])
    scene, plt, screen, st = trace_fixture(
        s -> meshscatter!(s, pos; marker = cube_mesh(), markersize = 0.3f0, color = :red))

    for n in (12, 3, 9)
        pos[] = [Point3f(i, 0, 0) for i in 1:n]
        RayMakie.poll_all_plots(screen, scene)
        # The instance count must actually follow, not just avoid throwing —
        # a stale batch would keep the old count and render the wrong scene.
        @test Raycore.n_instances(st.hikari_scene.accel) == n
        @test robj_of(plt) !== nothing
    end
    close(screen)
end

@testset "instances — marker mesh resize rebuilds, plot stays valid" begin
    pos = [Point3f(i, 0, 0) for i in 1:4]
    marker = Observable{Any}(cube_mesh())
    scene, plt, screen, st = trace_fixture(
        s -> meshscatter!(s, pos; marker = marker, markersize = 0.3f0, color = :red))

    marker[] = GeometryBasics.normal_mesh(GeometryBasics.Tesselation(Sphere(Point3f(0), 1.0f0), 12))
    RayMakie.poll_all_plots(screen, scene)

    @test robj_of(plt) !== nothing
    @test Raycore.n_instances(st.hikari_scene.accel) == length(pos)
    close(screen)
end
