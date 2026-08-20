# What a raster overlay drawn over a raytraced scene has to get right.
#
# Four bugs, all of which produced a wrong image with no error, no warning and a
# green test suite:
#
#   1. `colorbuffer` decided "are there overlays?" from `overlay_only`, which
#      comes from `should_raytrace(camera_controls)` — a property of the CAMERA.
#      A 3D scene's `lines!`, `scatter!` and `text!` built their render objects
#      and were then never composited, which is also why an `Axis3` came out with
#      no spines, ticks or labels.
#
#   2. `init_scene!` wrote absolute distances into `Camera3D`'s `near`/`far`. On
#      the default `clipping_mode = :adaptive` those are FACTORS of the view
#      distance, so a camera 6.7 units out got a near plane at 21.9 and clipped
#      every overlay vertex away. Only the raster path reads the projection
#      matrix — `to_trace_camera(::Camera3D, …)` builds from eye/lookat/fov — so
#      the raytraced image looked fine throughout.
#
#   3. The lines pipeline used `LineListAdjacency` against an index buffer built
#      for a STRIP (GLMakie's `generate_indices`: four points give `0 0 1 2 3 3`).
#      The list form reads those six indices as one primitive, so a polyline drew
#      its first segment and nothing else.
#
#   4. The composite framebuffer was `_SRGB`, which encodes what a shader writes.
#      Everything reaching it is already display-referred, so colours were
#      encoded twice: orange 0.647 read back as 0.825. Pure red, green and blue
#      are fixed points of that transform, which is why every primary-coloured
#      test passed.
#
# And one that only shows as a difference BETWEEN paths: skipping
# `fill_aux_buffers!` left `film.depth` unwritten, and `postprocess!` composites
# the background wherever `isinf(depth)` — so a plain 3D scene's background was
# black unless the scene happened to contain an overlay.

using Test, Makie, RayMakie, Hikari, GeometryBasics, Colors
using Makie: Scene, cam3d!, campixel!, mesh!, lines!, scatter!, text!,
             cameracontrols, update_cam!, Point2f, Point3f, Vec3f, Sphere, RGBf, PointLight

const SPHERE_LIGHTS = [PointLight(RGBf(60, 60, 60), Vec3f(4, 4, 6))]

greenish(c) = green(c) > 0.35 && green(c) > 2 * red(c) && green(c) > 2 * blue(c)
lit_rows(mask) = [r for r in 1:size(mask, 1) if any(@view mask[r, :])]

make_screen(scene) = RayMakie.Screen(scene; integrator = Hikari.VolPath(samples = 2, max_depth = 2))

# A raytraced scene viewed from (0, -6, 3): sphere at the origin, overlays above
# it. Fixed camera because bug 2 is about the near plane's relation to the view
# distance, so a moved camera would move the thing under test.
function rt_scene(; size = (96, 96), background = :white)
    sc = Scene(; size, lights = copy(SPHERE_LIGHTS), ambient = RGBf(0.15, 0.15, 0.15),
               backgroundcolor = background)
    cam3d!(sc)
    mesh!(sc, Sphere(Point3f(0), 1.0f0); material = Hikari.Diffuse(Kd = (0.8, 0.2, 0.2)))
    cam = cameracontrols(sc)
    cam.eyeposition[] = Vec3f(0, -6, 3)
    cam.lookat[] = Vec3f(0, 0, 0)
    cam.upvector[] = Vec3f(0, 0, 1)
    cam.fov[] = 45
    update_cam!(sc, cam)
    return sc
end

@testset "overlays in a raytraced scene" begin
    @testset "a 3D scene's overlays are composited at all" begin
        # One straight segment above and behind the sphere. Before the fix this
        # frame contained the sphere and nothing else.
        sc = rt_scene()
        lines!(sc, Point3f[(-2, 2, 1.5), (2, 2, 1.5)]; color = :green, linewidth = 4)
        img = Makie.colorbuffer(make_screen(sc))
        @test count(greenish, img) > 50

        sc2 = rt_scene()
        scatter!(sc2, Point3f[(-1.5, 2, 1.5), (0, 2, 1.5), (1.5, 2, 1.5)];
                 color = :green, markersize = 14)
        @test count(greenish, Makie.colorbuffer(make_screen(sc2))) > 50

        sc3 = rt_scene()
        text!(sc3, Point3f(-1.5, 2, 1.5); text = "RM", color = :green, fontsize = 30)
        @test count(greenish, Makie.colorbuffer(make_screen(sc3))) > 20
    end

    @testset "near/far are factors under :adaptive, not distances" begin
        sc = rt_scene()
        lines!(sc, Point3f[(-2, 2, 1.5), (2, 2, 1.5)]; color = :green, linewidth = 4)
        Makie.colorbuffer(make_screen(sc))
        cc = sc.camera_controls

        # Untouched: these are multipliers and `init_scene!` has no business
        # writing view-space distances into them.
        @test cc.near[] == 0.1
        @test cc.far[] == 100.0
        # What it does set instead — the scene's real extent.
        @test cc.bounding_sphere[].r > 0.9

        # The near plane must sit in front of the geometry, not past it. Derived
        # from the projection matrix so this is the value the rasterizer clips
        # against, not the value the camera was asked for.
        proj = sc.camera.projection[]
        a, b = proj[3, 3], proj[3, 4]
        near = b / (a - 1)
        @test 0 < near < 4      # eye is 6.7 out, sphere radius ~1.7; 21.9 was the bug
    end

    @testset "every segment of a polyline is drawn" begin
        # Asserted at the MIDPOINT of each segment rather than on a pixel count,
        # because the failure is "segments 2 and 3 are missing" and a count only
        # says "less green than expected". `LineListAdjacency` drew segment 1
        # alone, so segment 1 passing and 2 and 3 failing is the exact signature.
        pts = Point3f[(-2, -2, 1.5), (2, -2, 1.5), (2, 2, 1.5), (-2, 2, 1.5)]
        sc = rt_scene()
        lines!(sc, pts; color = :green, linewidth = 5)
        img = Makie.colorbuffer(make_screen(sc))
        mask = greenish.(img)
        h, w = size(mask)
        pv = sc.camera.projectionview[]

        for i in 1:(length(pts) - 1)
            mid = (pts[i] .+ pts[i + 1]) ./ 2
            clip = pv * Makie.Vec4f(mid[1], mid[2], mid[3], 1)
            col = round(Int, (clip[1] / clip[4] + 1) / 2 * w)
            row = round(Int, (1 - clip[2] / clip[4]) / 2 * h)
            @test 1 <= row <= h && 1 <= col <= w
            # A few pixels of slack: the line has width, and the midpoint of a
            # perspective-projected segment is not the projection of its midpoint.
            near = mask[max(1, row - 4):min(h, row + 4), max(1, col - 4):min(w, col + 4)]
            @test any(near)
        end
    end
end

@testset "overlay colours round-trip" begin
    # Orange is the test colour precisely because it is NOT a fixed point of the
    # sRGB transfer function: 1.055·0.647^(1/2.4) − 0.055 = 0.825.
    orange = RGBf(1.0, 0.647, 0.0)
    sc = Scene(; size = (64, 64), backgroundcolor = :black)
    campixel!(sc)
    lines!(sc, Point2f[(5, 32), (59, 32)]; color = orange, linewidth = 12)
    img = Makie.colorbuffer(make_screen(sc))

    # The modal lit colour, not just any: the line is antialiased, so its edge
    # pixels are blends with the black background and would answer a different
    # question.
    lit = filter(c -> red(c) > 0.9, vec(img))
    @test !isempty(lit)
    got = argmax(c -> count(==(c), lit), unique(lit))
    # One 8-bit step of tolerance for the readback, and nothing like the 0.18
    # that a second encode costs.
    @test abs(green(got) - 0.647) < 0.005
    @test blue(got) < 0.005
end

@testset "the background does not depend on whether an overlay is present" begin
    # `postprocess!` composites the background wherever `isinf(film.depth)`, and
    # the aux-buffer fill that writes those Infs used to be skipped when there
    # was neither an overlay nor denoising — so this scene came out black.
    plain = Makie.colorbuffer(make_screen(rt_scene()))

    with_overlay = let sc = rt_scene()
        lines!(sc, Point3f[(-2, 2, 1.5), (2, 2, 1.5)]; color = :green, linewidth = 4)
        Makie.colorbuffer(make_screen(sc))
    end

    corner = plain[end, 1]
    @test red(corner) > 0.9 && green(corner) > 0.9 && blue(corner) > 0.9

    # Below the overlay the two frames are the same image, up to the 8-bit
    # quantisation the overlay path's readback costs.
    lo = maximum(lit_rows(greenish.(with_overlay))) + 3
    for f in (red, green, blue)
        @test maximum(abs, Float64.(f.(plain[lo:end, :])) .- Float64.(f.(with_overlay[lo:end, :]))) < 0.01
    end
end
