# The render loop presents a frame, with the overlays drawn over the blit.
#
# `display` opens a window and starts the loop: each frame is one closed
# command buffer — the blit of the composited output buffer, every scene's
# overlays drawn over it, and the present — see `present_composited!`. That
# path had no test, and it had been broken twice over since the queue stopped
# holding an open batch: the loop drew into `bq.active_batch` and presented
# with the two-argument `present_frame!` that took the batch over, and before
# it got that far the window itself failed to open, because `Mantle.Window`
# was handed the portable `BGRA{N0f8}` and the Vulkan constructor took only a
# `VK.Format`. `test_overlay_compositing.jl` covers the offscreen path; this is
# the window.
#
# What a live window OWES its caller is `colorbuffer`, because that is what
# `save` and `record` call. Two bugs lived there, and both produced a picture
# rather than an error:
#
#   1. `colorbuffer` fell through to rendering the frame ITSELF while the loop
#      was mid-frame. Both driving the device at once is a deadlock, and was
#      one. The loop draws it now, between two of its own frames, and
#      `requestframe` waits — so this file asserts the handshake, not a field.
#
#   2. Before that it returned `output_buffer`, the image BEFORE the overlays,
#      so `save()` on a figure with a window open produced a picture with no
#      plots in it. Asserted here by looking for the ORANGE sphere, which only
#      exists in a composited frame.
#
# Deliberately NOT asserted: that the screen caches every frame it shows. It
# used to, at 1.3 ms a frame, to serve a call that usually never comes;
# `requested_frame` is the answer slot of a request and is `nothing` at every
# other moment. A test that waits for it to become non-`nothing` on its own
# waits forever, which is how this file first failed once it stopped being
# skipped.
using Test, Makie, RayMakie, Hikari, GeometryBasics, Colors
using GeometryBasics: Point3f, Vec3f, Sphere

orangeish(c) = red(c) > 0.35 && red(c) > 1.6 * green(c) && green(c) > 1.5 * blue(c)

@testset "the render loop presents frames with overlays" begin
    sc = Scene(size = (320, 240), lights = [PointLight(RGBf(30, 30, 30), Vec3f(4, 5, 6))])
    cam3d!(sc)
    mesh!(sc, Sphere(Point3f(0, 0, 0), 0.8f0); color = :orange)
    lines!(sc, [Point3f(-1, -1, 0), Point3f(1, 1, 0), Point3f(1, -1, 0)]; color = :black, linewidth = 3)
    scr = RayMakie.Screen(sc; integrator = Hikari.VolPath(samples = 1, max_depth = 3, hw_accel = true),
                          visible = true)
    display(scr, sc)
    @test RayMakie.renderloop_running(scr)

    # `px_per_unit` is the WINDOW's content scale, not the primary monitor's:
    # the window knows which display it landed on. The pre-window guess is the
    # primary monitor, and it is only a guess — here it cannot even be made,
    # because a `GetPrimaryMonitor` that answers NULL is exactly what used to
    # take this file down with SIGSEGV.
    ppu = Makie.px_per_unit(scr)
    @test ppu ≈ first(RayMakie.GLFW.GetWindowContentScale(scr.window.handle))

    # The handshake: the LOOP draws this, we only wait for it. A figure is
    # `size` UNITS, so the frame is the DRAWABLE — that many pixels times the
    # scale — and not the half-size image this asserted while `px_per_unit` was
    # pinned to 1.
    #
    # Against the drawable rather than against `round(Int, 240 * ppu)`: the
    # window is asked for that many pixels and the window manager is free to
    # give one more. It did — `(348, 463)` against an expected `(347, 463)`,
    # because `240 * 1.4479166` is `347.4999…`. What the frame has to match is
    # the thing it is blitted into; that the drawable is the figure's size in
    # units is the second assertion, and it is the one `ppu` belongs in.
    img = Makie.colorbuffer(scr)
    @test img !== nothing
    @test size(img) == size(scr.output_buffer)
    @test (round(Int, size(img)[2] / ppu), round(Int, size(img)[1] / ppu)) == (320, 240)
    @test RayMakie.renderloop_running(scr)      # asking did not kill the loop

    # Composited, not `output_buffer`: the sphere is in the picture.
    @test count(orangeish, img) > 200

    # …and the loop keeps going, and the slot goes back to empty.
    sleep(1.0)
    @test RayMakie.renderloop_running(scr)
    @test scr.requested_frame === nothing

    # A second request works, so the flag was cleared and not merely consumed.
    @test size(Makie.colorbuffer(scr)) == size(scr.output_buffer)

    # The loop presented frames of its own between the two requests — which is
    # also what `requestframe` waits on, so a loop that is merely slow is never
    # mistaken for one that is stuck.
    @test scr.frames_presented[] > 2

    # A LIVE resize, as dragging the window's corner makes one. The frame's
    # depth attachment was declared at a fixed `(w, h)`, while a backend may
    # notice the resize only inside `run!`, after the plan was built: the first
    # frame at the new size met a depth buffer of the old one, `checkextents`
    # refused it, and the render loop died — on Metal, on every resize. It
    # follows its target now, and `run!` refits it.
    gw = scr.window.handle
    RayMakie.GLFW.SetWindowSize(gw, 400, 300)
    f0 = scr.frames_presented[]
    t0 = time()
    while scr.frames_presented[] < f0 + 5 && time() - t0 < 30
        sleep(0.05)
    end
    @test RayMakie.renderloop_running(scr)
    @test scr.frames_presented[] >= f0 + 5
    fw, fh = RayMakie.GLFW.GetFramebufferSize(gw)
    @test size(scr.window) == (fw, fh)
    img2 = Makie.colorbuffer(scr)
    @test size(img2) == size(scr.output_buffer) == (fh, fw)
    # Still composited, and framed the same: the sphere covers the same FRACTION
    # of a frame with the same aspect. `warm` rather than `orangeish` — shaded,
    # this sphere is an olive brown that `orangeish` only sometimes accepts, and
    # what matters here is that it is drawn, in the right place, at the new size.
    warm(c) = red(c) > blue(c) + 0.15f0
    frac(im) = count(warm, im) / length(im)
    @test frac(img) > 0.05
    @test isapprox(frac(img2), frac(img); atol = 0.02)

    close(scr)
    sleep(0.5)
    @test !RayMakie.renderloop_running(scr)
end
