# A screen's path tracer is its own.
#
# RayMakie used to take an `integrator` object, and `activate!` put one
# `Hikari.VolPath` into Makie's global theme, so every screen made afterwards
# shared it. A `VolPath` is mutable and holds its render state, and `render!`
# swapped each screen's state into the shared one for a sample, so closing any
# screen freed whatever was swapped in at the time. Makie frees a collected scene
# from an `@async` task that runs at whatever yield a render is waiting in, so in
# a suite it landed mid-sample: `TypeError: expected Hikari.VolPathState, got a
# value of type Nothing` out of `render!`, or a frame drawn from accumulators that
# had been given back. The config holds the tracer's SETTINGS now, as values, and
# each scene state builds its own `VolPath` from them.

using Test, RayMakie, Makie, Hikari, GeometryBasics

function traced_screen(; kw...)
    fig = Figure(size = (160, 120), backgroundcolor = :white)
    pts = [Point3f(cos(t), sin(t), 0) for t in range(0, 2pi; length = 12)]
    meshscatter!(LScene(fig[1, 1]), pts; color = :red, markersize = 0.2)
    return RayMakie.Screen(fig.scene; visible = false, samples = 1, max_depth = 2, kw...)
end

traced_state(screen) = only(filter(ss -> !ss.overlay_only, screen.scene_states))
intact(st) = st !== nothing && st.plans !== nothing && Hikari.nallocations(st.memory) > 0
config(; kw...) = Makie.merge_screen_config(RayMakie.ScreenConfig, Dict{Symbol, Any}(kw))

@testset "a screen's path tracer is its own" begin
    @testset "closing one screen leaves another's alone" begin
        # `close`, and the `delete!` Makie's scene finalizer calls.
        for release! in (close, s -> delete!(s, s.scene))
            a = traced_screen()
            b = traced_screen()
            Makie.colorbuffer(a)
            before = Makie.colorbuffer(b)
            vb = traced_state(b).integrator
            @test traced_state(a).integrator !== vb
            release!(a)
            @test intact(vb.state)
            @test Makie.colorbuffer(b) == before
            held = vb.state
            close(b)
            @test !intact(held)
        end
    end

    @testset "the settings reach the tracer" begin
        s = traced_screen(max_depth = 3, hw_accel = false, regularize = false,
                          max_component_value = 5)
        Makie.colorbuffer(s)
        vp = traced_state(s).integrator
        @test vp.samples_per_pixel == 1
        @test vp.max_depth == 3
        @test vp.hw_accel == false
        @test vp.regularize == false
        @test vp.max_component_value == 5f0
        # `automatic` keeps Hikari's own default.
        @test vp.russian_roulette_depth == Hikari.VolPath().russian_roulette_depth
        close(s)
    end

    @testset "an equal config keeps the tracer, a different one replaces it" begin
        # `Makie.save` builds a new config on every call. When the tracer was an
        # object in it, a fresh-but-equal one read as "changed" and cleared what
        # an accumulating screen had built up.
        s = traced_screen()
        Makie.colorbuffer(s)
        vp = traced_state(s).integrator
        @test Makie.apply_screen_config!(s, config(samples = 1, max_depth = 2, visible = false),
                                         s.scene) === s
        @test traced_state(s).integrator === vp
        @test intact(vp.state)

        held = vp.state
        Makie.apply_screen_config!(s, config(samples = 1, max_depth = 5, visible = false), s.scene)
        @test traced_state(s).integrator !== vp
        @test traced_state(s).integrator.max_depth == 5
        @test !intact(held)   # given back, not leaked
        close(s)
    end

    @testset "`integrator` is refused, not ignored" begin
        # A per-call config is merged key by key and an unknown key is dropped,
        # so an old `integrator = VolPath(...)` would have rendered with the
        # defaults and said nothing.
        fig = Figure(size = (32, 32))
        err = @test_throws ArgumentError RayMakie.Screen(fig.scene; integrator = Hikari.VolPath())
        @test occursin("max_depth", err.value.msg)
        @test_throws ArgumentError Makie.colorbuffer(fig; backend = RayMakie,
                                                     integrator = Hikari.VolPath())
        @test_throws ArgumentError RayMakie.activate!(integrator = Hikari.VolPath())
    end
end
