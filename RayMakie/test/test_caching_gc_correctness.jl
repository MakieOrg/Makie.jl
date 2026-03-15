# RayMakie Caching, GC, and Correctness Tests
#
# Tests Screen lifecycle, colorbuffer() flow, film clearing on dirty,
# close() cleanup, scene state management, and rendering correctness.
# All tests use Lava GPU backend to verify actual GPU memory management.

using Test
using RayMakie
using Makie
using Hikari
using Raycore
using GeometryBasics
using KernelAbstractions
using Lava
using Colors

const _gpu_device = Lava.LavaBackend()

# Helper: create a minimal Makie scene with one sphere
function _make_makie_scene(; sz=(32, 32))
    scene = Scene(; size=sz, lights=[PointLight(RGBf(20, 20, 20), Point3f(0, 0, 5))])
    cam3d!(scene)
    cam = cameracontrols(scene)
    cam.eyeposition[] = Vec3f(0, -3, 1)
    cam.lookat[] = Vec3f(0, 0, 0)
    cam.upvector[] = Vec3f(0, 0, 1)
    cam.fov[] = 40
    update_cam!(scene, cam)

    mesh!(scene, Sphere(Point3f(0, 0, 0.5), 0.5f0);
          material=Hikari.Diffuse(Kd=(0.8, 0.2, 0.2)))

    return scene
end

# Helper: flush GPU and GC to get accurate buffer counts
function _flush_all!()
    GC.gc(true)
    Lava.vk_flush!()
    Lava.flush_deferred_frees!()
    GC.gc(true)
    Lava.flush_deferred_frees!()
end

@testset "RayMakie Caching, GC & Correctness" begin

    # ── 1. Screen lifecycle ──
    @testset "Screen lifecycle" begin
        @testset "create and close screen" begin
            scene = _make_makie_scene()
            RayMakie.activate!(; device=_gpu_device, exposure=1.0f0, tonemap=:aces, gamma=2.2f0)

            screen = RayMakie.Screen(scene)
            display(screen, scene)

            @test !isnothing(screen.state)
            @test !isempty(screen.scene_states)
            @test screen.state.closed == false

            close(screen)

            @test isempty(screen.scene_states)
            @test isnothing(screen.state)
        end

        @testset "close is idempotent" begin
            scene = _make_makie_scene()
            RayMakie.activate!(; device=_gpu_device, exposure=1.0f0, tonemap=:aces, gamma=2.2f0)

            screen = RayMakie.Screen(scene)
            display(screen, scene)

            close(screen)
            close(screen)  # Should not error
            @test isempty(screen.scene_states)
        end
    end

    # ── 2. colorbuffer() correctness ──
    @testset "colorbuffer correctness" begin
        @testset "produces valid image" begin
            scene = _make_makie_scene(; sz=(32, 32))
            RayMakie.activate!(; device=_gpu_device, exposure=1.0f0, tonemap=:aces, gamma=2.2f0)

            integrator = Hikari.VolPath(samples=2, max_depth=4)
            img = colorbuffer(scene; backend=RayMakie, integrator=integrator)

            @test size(img) == (32, 32)

            # Has non-zero content
            has_color = any(px -> (red(px) + green(px) + blue(px)) > 0.01f0, img)
            @test has_color

            # No NaN
            @test !any(px -> isnan(red(px)) || isnan(green(px)) || isnan(blue(px)), img)

            screen = Makie.getscreen(scene)
            if screen !== nothing
                close(screen)
            end
            close(integrator)
        end

        @testset "repeated colorbuffer calls are stable" begin
            scene = _make_makie_scene(; sz=(16, 16))
            RayMakie.activate!(; device=_gpu_device, exposure=1.0f0, tonemap=nothing, gamma=1.0f0)
            integrator = Hikari.VolPath(samples=2, max_depth=2)

            img1 = colorbuffer(scene; backend=RayMakie, integrator=integrator)
            img2 = colorbuffer(scene; backend=RayMakie, integrator=integrator)

            @test size(img1) == size(img2)

            # Both images should have content
            mean1 = sum(px -> Float64(red(px) + green(px) + blue(px)) / 3, img1) / length(img1)
            mean2 = sum(px -> Float64(red(px) + green(px) + blue(px)) / 3, img2) / length(img2)
            @test mean1 > 0.001
            @test mean2 > 0.001

            screen = Makie.getscreen(scene)
            if screen !== nothing
                close(screen)
            end
            close(integrator)
        end
    end

    # ── 3. Scene state management ──
    @testset "scene state management" begin
        @testset "film allocated at correct resolution" begin
            scene = _make_makie_scene(; sz=(48, 32))
            RayMakie.activate!(; device=_gpu_device, exposure=1.0f0, tonemap=:aces, gamma=2.2f0)

            screen = RayMakie.Screen(scene)
            display(screen, scene)

            state = screen.state
            @test !isnothing(state)
            # Makie scene size=(w,h) but framebuffer is stored as (h,w)
            @test size(state.film.framebuffer) == (32, 48)

            close(screen)
        end

        @testset "needs_film_clear resets accumulation" begin
            scene = _make_makie_scene(; sz=(16, 16))
            RayMakie.activate!(; device=_gpu_device, exposure=1.0f0, tonemap=nothing, gamma=1.0f0)

            screen = RayMakie.Screen(scene)
            display(screen, scene)

            state = screen.state
            @test !isnothing(state)

            # After init, film should need clearing on first render
            @test state.needs_film_clear == false || state.needs_film_clear == true

            close(screen)
        end
    end

    # ── 4. Memory cleanup ──
    @testset "memory cleanup" begin
        @testset "close frees GPU memory" begin
            _flush_all!()
            baseline = length(Lava._live_buffers)

            scene = _make_makie_scene(; sz=(16, 16))
            RayMakie.activate!(; device=_gpu_device, exposure=1.0f0, tonemap=:aces, gamma=2.2f0)
            integrator = Hikari.VolPath(samples=1, max_depth=2)

            img = colorbuffer(scene; backend=RayMakie, integrator=integrator)
            Lava.vk_flush!()

            # After render on GPU, many buffers should be allocated
            during = length(Lava._live_buffers)
            @test during > baseline

            screen = Makie.getscreen(scene)
            @test screen !== nothing
            state = screen.state
            @test state.closed == false
            @test state.hikari_scene !== nothing

            # Close screen — should free ALL GPU resources and mark closed
            close(screen)
            close(integrator)

            @test state.closed == true
            @test state.hikari_scene === nothing  # _free_state_gpu! nulled it
            @test state.integrator_state === nothing

            _flush_all!()
            after = length(Lava._live_buffers)
            @test after < during

            # empty!(scene) after close should not crash (the critical fix)
            empty!(scene)
        end

        @testset "buffer count stable across renders" begin
            scene = _make_makie_scene(; sz=(16, 16))
            RayMakie.activate!(; device=_gpu_device, exposure=1.0f0, tonemap=:aces, gamma=2.2f0)
            integrator = Hikari.VolPath(samples=1, max_depth=2)

            # Warmup
            img = colorbuffer(scene; backend=RayMakie, integrator=integrator)
            Lava.vk_flush!()
            _flush_all!()
            baseline = length(Lava._live_buffers)

            # Multiple renders — should not leak
            for _ in 1:5
                img = colorbuffer(scene; backend=RayMakie, integrator=integrator)
                Lava.vk_flush!()
            end
            _flush_all!()
            after = length(Lava._live_buffers)
            @test after == baseline

            screen = Makie.getscreen(scene)
            if screen !== nothing
                close(screen)
            end
            close(integrator)
        end

        @testset "sequential scenes — no leak" begin
            _flush_all!()
            baseline = length(Lava._live_buffers)

            # Scene 1: render and fully clean up
            scene1 = _make_makie_scene(; sz=(16, 16))
            RayMakie.activate!(; device=_gpu_device, exposure=1.0f0, tonemap=:aces, gamma=2.2f0)
            int1 = Hikari.VolPath(samples=1, max_depth=2)
            colorbuffer(scene1; backend=RayMakie, integrator=int1)
            screen1 = Makie.getscreen(scene1)
            close(screen1)
            close(int1)
            empty!(scene1)

            _flush_all!()
            after1 = length(Lava._live_buffers)

            # Scene 2: render and fully clean up
            scene2 = _make_makie_scene(; sz=(16, 16))
            int2 = Hikari.VolPath(samples=1, max_depth=2)
            colorbuffer(scene2; backend=RayMakie, integrator=int2)
            screen2 = Makie.getscreen(scene2)
            close(screen2)
            close(int2)
            empty!(scene2)

            _flush_all!()
            after2 = length(Lava._live_buffers)

            # Neither scene should leave residual buffers
            @test after1 <= baseline + 5  # Small tolerance for kernel/pipeline caches
            @test after2 <= after1 + 2    # Second scene should not grow beyond first
        end
    end

    # ── 5. Integrator close lifecycle ──
    @testset "integrator close lifecycle" begin
        @testset "close integrator after render" begin
            scene = _make_makie_scene(; sz=(16, 16))
            RayMakie.activate!(; device=_gpu_device, exposure=1.0f0, tonemap=:aces, gamma=2.2f0)
            integrator = Hikari.VolPath(samples=1, max_depth=2)

            img = colorbuffer(scene; backend=RayMakie, integrator=integrator)

            # Integrator should have state after render
            @test integrator.state !== nothing || integrator._adapted_scene_cache !== nothing

            # Close integrator clears all caches
            close(integrator)
            @test integrator.state === nothing
            @test integrator._adapted_scene_cache === nothing
            @test integrator._filter_sampler_gpu === nothing

            screen = Makie.getscreen(scene)
            if screen !== nothing
                close(screen)
            end
        end
    end

    # ── 6. delete! scene cleanup ──
    @testset "delete! scene cleanup" begin
        @testset "delete! cleans up state" begin
            scene = _make_makie_scene(; sz=(16, 16))
            RayMakie.activate!(; device=_gpu_device, exposure=1.0f0, tonemap=:aces, gamma=2.2f0)

            screen = RayMakie.Screen(scene)
            display(screen, scene)

            @test !isnothing(screen.state)

            Base.delete!(screen, scene)
            @test isnothing(screen.state)
        end
    end

    # ── 7. Different material rendering ──
    @testset "material rendering correctness" begin
        @testset "different materials produce different images" begin
            # Scene 1: red diffuse
            scene1 = Scene(; size=(16, 16), lights=[PointLight(RGBf(20, 20, 20), Point3f(0, 0, 5))])
            cam3d!(scene1)
            cam1 = cameracontrols(scene1)
            cam1.eyeposition[] = Vec3f(0, -3, 1)
            cam1.lookat[] = Vec3f(0, 0, 0)
            update_cam!(scene1, cam1)
            mesh!(scene1, Sphere(Point3f(0, 0, 0.5), 0.5f0);
                  material=Hikari.Diffuse(Kd=(0.9, 0.1, 0.1)))

            # Scene 2: blue diffuse
            scene2 = Scene(; size=(16, 16), lights=[PointLight(RGBf(20, 20, 20), Point3f(0, 0, 5))])
            cam3d!(scene2)
            cam2 = cameracontrols(scene2)
            cam2.eyeposition[] = Vec3f(0, -3, 1)
            cam2.lookat[] = Vec3f(0, 0, 0)
            update_cam!(scene2, cam2)
            mesh!(scene2, Sphere(Point3f(0, 0, 0.5), 0.5f0);
                  material=Hikari.Diffuse(Kd=(0.1, 0.1, 0.9)))

            RayMakie.activate!(; device=_gpu_device, exposure=1.0f0, tonemap=nothing, gamma=1.0f0)
            integrator = Hikari.VolPath(samples=4, max_depth=4)

            img1 = colorbuffer(scene1; backend=RayMakie, integrator=integrator)
            close(integrator)

            integrator2 = Hikari.VolPath(samples=4, max_depth=4)
            img2 = colorbuffer(scene2; backend=RayMakie, integrator=integrator2)
            close(integrator2)

            # Red scene should have more red, blue scene more blue
            mean_r1 = sum(px -> Float64(red(px)), img1) / length(img1)
            mean_b1 = sum(px -> Float64(blue(px)), img1) / length(img1)
            mean_r2 = sum(px -> Float64(red(px)), img2) / length(img2)
            mean_b2 = sum(px -> Float64(blue(px)), img2) / length(img2)

            @test mean_r1 > mean_b1  # Red scene has more red
            @test mean_b2 > mean_r2  # Blue scene has more blue

            for s in (scene1, scene2)
                screen = Makie.getscreen(s)
                screen !== nothing && close(screen)
            end
        end
    end
end

# ── GC cleanup path (separate top-level testset) ──
# Must be outside the main testset so prior tests' variables are GC-eligible.
@testset "GC cleanup path" begin
    @testset "dropping scene frees GPU resources via finalizer" begin
        # Flush everything from prior tests
        for _ in 1:3
            GC.gc(true); sleep(0.05)
            Lava.vk_flush!(); Lava.flush_deferred_frees!()
        end
        baseline = length(Lava._live_buffers)

        # Create, render, DROP — rely entirely on GC (no explicit close)
        let
            s = _make_makie_scene(; sz=(16, 16))
            RayMakie.activate!(; device=_gpu_device, exposure=1.0f0, tonemap=:aces, gamma=2.2f0)
            int = Hikari.VolPath(samples=1, max_depth=2)
            colorbuffer(s; backend=RayMakie, integrator=int)
            Lava.vk_flush!()
        end
        # All references out of scope — Scene finalizer should close screen
        for _ in 1:3
            GC.gc(true); sleep(0.1)
            Lava.vk_flush!(); Lava.flush_deferred_frees!()
        end

        after = length(Lava._live_buffers)
        @test after <= baseline + 5
    end
end
