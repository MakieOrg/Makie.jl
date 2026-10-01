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
# The cause was that a composited frame was a RECORDED Mantle plan, and
# `cmd_bind_descriptor_sets` baked the descriptor set handle into the command
# buffer. A frame is now an unrecorded plan whose draws are cells, re-read on
# every run, so a new set, a new buffer and a new count all reach the frame
# without rebuilding it; `update_texture!` still uploads into the texture it
# already has, because that is cheaper than a new one.
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
        # a new texture and new bindings, which the draw's cell hands the next run.
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
    # The other half of the same bug, and the one with a visible symptom: when
    # a composited frame was a RECORDED plan, `vkCmdDraw` baked the vertex count
    # and `record_draw!` the address of the packed arguments. So a label that
    # grew kept drawing the OLD glyph count — "RAY TRACED" came out as "RAY TR",
    # because the button had once said "RASTER" — and one that shrank kept
    # drawing the longer string's quads. The frame now reads both from the
    # draw's cell on every run.

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
    # The other half of the bargain: what the frame reads from its cells must
    # not also be in `frame_signature`, or the plan cache stops being a cache.

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


@testset "a mesh whose triangle count changes keeps its plan" begin
    # A whirlpool's hole moving through a sea mesh changes its triangle count
    # every frame. With the counts and buffer addresses in `frame_signature`
    # every such frame compiled a new plan; the draw's cell carries both.
    strip(n) = Makie.GeometryBasics.Mesh([Point3f(i, j, 0) for i in 0:n for j in 0:1],
                                         [Makie.GeometryBasics.GLTriangleFace(2i + 1, 2i + 3, 2i + 4) for i in 0:n-1];
                                         normal = [Vec3f(0, 0, 1) for i in 0:n for j in 0:1])
    red(img) = count(p -> Colors.red(p) > 0.6 && Colors.green(p) < 0.5, img)
    sc = Scene(; size = (320, 160), lights = [AmbientLight(RGBf(1, 1, 1))])
    cam3d!(sc)
    m = mesh!(sc, strip(2); color = RGBf(1, 0, 0), shading = NoShading)
    update_cam!(sc, Vec3f(5, 0.5, 12), Vec3f(5, 0.5, 0), Vec3f(0, 1, 0))
    screen = RayMakie.Screen(sc; visible = false, rasterize = true)
    ink = Int[]
    plans = Set{UInt}()
    for n in (2, 8, 4, 2)
        m[1] = strip(n)
        push!(ink, red(Makie.colorbuffer(screen)))
        push!(plans, objectid(screen.frame_plans[:readback][2]))
    end
    close(screen)
    @test ink[1] > 100
    @test isapprox(ink[2] / ink[1], 4.0; atol = 0.3)    # eight triangles are drawn, not two
    @test isapprox(ink[3] / ink[1], 2.0; atol = 0.3)
    @test ink[4] == ink[1]
    @test length(plans) == 1
end
