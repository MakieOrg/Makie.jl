# A plot whose data changes must change ON SCREEN.
#
# Two bugs of one kind, both found by the first GUI that animated anything, and
# both invisible to every earlier test because those made a fresh `Screen` per
# frame — which rebuilds the cached plan and so can never see staleness.
#
# This failed silently for as long as RayMakie has composited frames, and every
# part of it looked healthy: the observable updated, `trace_renderobject`
# recomputed, `update_texture!` ran and really did produce new bindings. The
# picture never moved.
#
# The cause is that a composited frame is a RECORDED Mantle plan, and
# `cmd_bind_descriptor_sets` bakes the descriptor set handle into the command
# buffer. Handing `rebind!` a DIFFERENT set writes a value nothing reads again.
# `update_texture!` now uploads into the texture it already has, so the baked
# set stays correct; `frame_signature` carries the bindings' identity so the
# cases that genuinely need a new texture rebuild the plan.
#
# Tested against ONE screen, deliberately. Every earlier test of this made a
# fresh `Screen` per frame, which rebuilds the plan and so could never see it.

using Test, RayMakie, Makie, Colors

"Pixels of a given pure colour, so a frame can be identified by what it drew."
countcolour(img, c; tol = 0.3) =
    count(p -> abs(Colors.red(p) - Colors.red(c)) < tol &&
               abs(Colors.green(p) - Colors.green(c)) < tol &&
               abs(Colors.blue(p) - Colors.blue(c)) < tol, img)

@testset "image! updates on an existing screen" begin
    RED = RGBAf(1, 0, 0, 1); BLUE = RGBAf(0, 0, 1, 1); GREEN = RGBAf(0, 1, 0, 1)

    @testset "same size: the texture is reused and the frame follows" begin
        obs = Observable(fill(RED, 32, 32))
        fig = Figure(size = (200, 200)); ax = Axis(fig[1, 1])
        image!(ax, obs)
        screen = RayMakie.Screen(fig.scene; visible = false)
        frames = Any[Makie.colorbuffer(screen)]
        for c in (BLUE, GREEN, RED)
            obs[] = fill(c, 32, 32)
            push!(frames, Makie.colorbuffer(screen))
        end
        close(screen)

        n = countcolour(frames[1], RED)
        @test n > 1000                                   # it drew something
        @test countcolour(frames[2], BLUE) == n          # and then blue
        @test countcolour(frames[3], GREEN) == n
        @test countcolour(frames[4], RED) == n           # and back
        # The negative half: each frame shows ONLY its own colour.
        @test countcolour(frames[2], RED) == 0
        @test countcolour(frames[3], BLUE) == 0
    end

    @testset "a resized image needs a new texture, and still updates" begin
        # The path `update_texture!` cannot take the fast route on, so it makes
        # a new texture — and `frame_signature` has to notice, or the recorded
        # plan keeps the old one.
        obs = Observable(fill(RED, 16, 16))
        fig = Figure(size = (200, 200)); ax = Axis(fig[1, 1])
        image!(ax, obs)
        screen = RayMakie.Screen(fig.scene; visible = false)
        before = Makie.colorbuffer(screen)
        obs[] = fill(BLUE, 64, 64)
        after = Makie.colorbuffer(screen)
        close(screen)
        @test countcolour(before, RED) > 1000
        @test countcolour(after, BLUE) > 1000
        @test countcolour(after, RED) == 0
    end

    @testset "heatmap! too" begin
        obs = Observable(zeros(Float32, 16, 16))
        fig = Figure(size = (200, 200)); ax = Axis(fig[1, 1])
        heatmap!(ax, obs; colorrange = (0f0, 1f0))
        screen = RayMakie.Screen(fig.scene; visible = false)
        a = Makie.colorbuffer(screen)
        obs[] = ones(Float32, 16, 16)
        b = Makie.colorbuffer(screen)
        close(screen)
        @test a != b
    end
end


@testset "text! updates when its length changes" begin
    # The other half of the same bug, and the one with a visible symptom: a
    # composited frame is a RECORDED plan, `vkCmdDraw` bakes the vertex count,
    # and `record_draw!` bakes the address of the packed arguments. So a label
    # that grew kept drawing the OLD glyph count — "RAY TRACED" came out as
    # "RAY TR", because the button had once said "RASTER" — and one that shrank
    # kept drawing the longer string's quads.
    #
    # `frame_signature` now carries each device array's `argidentity` (the
    # address, which changes exactly when `resize!` had to reallocate) and the
    # draw counts (which `resize!` DOWNWARD does not change, because it stays
    # inside its capacity).

    ink(img) = count(p -> Colors.red(p) < 0.5 && Colors.green(p) < 0.5, img)

    obs = Observable("AAA")
    fig = Figure(size = (400, 140))
    sc = Scene(fig.scene; camera = campixel!)
    text!(sc, Point2f(20, 60); text = obs, fontsize = 40, color = :black)
    screen = RayMakie.Screen(fig.scene; visible = false)

    n3 = ink(Makie.colorbuffer(screen))
    obs[] = "AAAAAAAAAAAA"; n12 = ink(Makie.colorbuffer(screen))
    obs[] = "AA";           n2  = ink(Makie.colorbuffer(screen))
    obs[] = "AAAAAAAAAAAA"; n12b = ink(Makie.colorbuffer(screen))
    obs[] = "AAA";          n3b = ink(Makie.colorbuffer(screen))
    close(screen)

    @test n3 > 100                       # it drew something to begin with
    # The SAME glyph repeated, so the ink is proportional to the count — which
    # is what makes this a test of how many were drawn rather than of whether
    # anything changed.
    @test isapprox(n12 / n3, 4.0; atol = 0.2)
    @test isapprox(n2 / n3, 2 / 3; atol = 0.2)
    # Both directions, and repeatable: growing worked from the address alone,
    # shrinking needed the counts.
    @test n12b == n12
    @test n3b == n3
end


@testset "a glyph the atlas has never held still draws" begin
    # The third stale-GPU-state bug of the same afternoon, and the one whose
    # symptom is a single missing character: Makie rasterises a new glyph into
    # the global texture atlas and marks it dirty, RayMakie then built a NEW
    # atlas texture — which a recorded plan cannot see, for the same reason a
    # new image texture could not. It showed as "2 AABBs, 0 triangles" rendering
    # without its comma.
    #
    # Two halves: the atlas uploads INTO its existing texture, and an existing
    # render object re-reads `get_atlas_bindings` on update instead of keeping
    # the bindings it was built with.

    ink(img) = count(p -> Colors.red(p) < 0.5 && Colors.green(p) < 0.5, img)

    obs = Observable("oooo")
    fig = Figure(size = (500, 160))
    sc = Scene(fig.scene; camera = campixel!)
    text!(sc, Point2f(20, 70); text = obs, fontsize = 44, color = :black)
    screen = RayMakie.Screen(fig.scene; visible = false)

    base = ink(Makie.colorbuffer(screen))
    # Characters unlikely to be in the atlas from anything else in the suite.
    obs[] = "oooo§±¶"; rare = ink(Makie.colorbuffer(screen))
    obs[] = "oooo";    back = ink(Makie.colorbuffer(screen))
    close(screen)

    @test base > 100
    @test rare > base * 1.15      # the new glyphs drew something
    @test back == base            # and removing them restores exactly
end


@testset "a camera move still does not rebuild the plan" begin
    # The other half of the bargain. `frame_signature` now carries each device
    # array's address and the draw counts, which is what makes changed content
    # visible — and the risk is that it starts changing every frame and the plan
    # cache stops being a cache.
    #
    # Measured when it was added: 54 render objects, 2.57 ms a frame, ONE
    # signature over 20 static frames. A 25-frame zoom on an axis WITH tick
    # labels rebuilt 6 times — the labels genuinely changed — and the same zoom
    # with `hidedecorations!` rebuilt none. So the cost lands only where
    # correctness requires it.

    fig = Figure(size = (600, 450))
    ax = Axis(fig[1, 1])
    for k in 1:20
        lines!(ax, 1:150, sin.((1:150) ./ 10 .+ k))
    end
    hidedecorations!(ax)          # no labels, so nothing legitimately changes
    screen = RayMakie.Screen(fig.scene; visible = false)
    Makie.colorbuffer(screen); Makie.colorbuffer(screen)   # warm

    signatures = Set{Any}()
    for z in range(1.0, 3.0; length = 15)
        Makie.xlims!(ax, 1 / z, 150 / z)
        Makie.colorbuffer(screen)
        push!(signatures, first(values(screen.frame_plans))[1])
    end
    close(screen)

    # One signature across fifteen different camera positions: a zoom rebinds,
    # it does not re-record.
    @test length(signatures) == 1
end
