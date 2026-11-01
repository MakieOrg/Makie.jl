using Test, Makie, RayMakie, GeometryBasics, Colors
using GeometryBasics: Point3f, Vec3f, Sphere
using LinearAlgebra: norm

# The render loop ticks once a frame, and the input loop polls the window at its own rate.
#
# A tick is a frame Makie can draw into, so what an animation computes on it is drawn.
# Ticked from the input loop, the window sent 99 `RegularRenderTick`s a second while it
# drew one frame a second. Input is the other way round: polled once a frame, a click
# waited for the frame in flight.
@testset "a tick a frame, and input at its own rate" begin
    sc = Scene(size = (640, 480), lights = [PointLight(RGBf(30, 30, 30), Vec3f(4, 5, 6))])
    cam3d!(sc)
    mesh!(sc, Sphere(Point3f(0, 0, 0), 0.8f0); color = :orange)
    scr = RayMakie.Screen(sc; samples = 1, max_depth = 8, hw_accel = true, visible = true)
    shown = time()
    display(scr, sc)
    states = Makie.TickState[]
    last_time = Ref(NaN)
    on(events(sc).tick) do tick
        push!(states, tick.state)
        last_time[] = tick.time
    end
    # Measured once the loop is warm: its first frames compile, and compiling holds the
    # thread. A second after `display`, a cold session had presented one frame.
    t = time()
    while scr.frames_presented[] < 3 && time() - t < 120
        sleep(0.1)
    end

    @testset "one tick a frame" begin
        empty!(states)
        f0 = scr.frames_presented[]
        sleep(3.0)
        frames = scr.frames_presented[] - f0
        @test frames > 0
        # A frame is presented after its tick, so a frame in flight at either end of
        # the three seconds is counted on one side only.
        @test abs(length(states) - frames) <= 1
        @test all(==(Makie.RegularRenderTick), states)
        # The time since the first tick, not since 1970.
        @test 0 < last_time[] < time() - shown
    end

    @testset "input polled at its own rate" begin
        # Every frame waits 50 ms, as one waiting for a slow GPU does, so polling once a
        # frame is told apart from polling at the input rate on any device. A sphere at
        # one sample is 150 frames a second on an RTX 4000, faster than input is polled.
        slow = on(_ -> sleep(0.05), events(sc).tick)
        # A poll writes the cursor position whenever Makie holds another one, and NaN
        # is another one than every position: each poll after this overwrites it.
        polls = 0
        t0, f0 = time(), scr.frames_presented[]
        while time() - t0 < 3
            events(sc).mouseposition[] = (NaN, NaN)
            while isnan(events(sc).mouseposition[][1]) && time() - t0 < 3
                sleep(0.001)
            end
            isnan(events(sc).mouseposition[][1]) || (polls += 1)
        end
        seconds, frames = time() - t0, scr.frames_presented[] - f0
        off(slow)
        @test 0 < frames / seconds < 25
        # At the input loop's rate: polled once a frame, this is under 20. Mantle's
        # `test_hostwait.jl` and `test_window_portable.jl` pin the waits that let the
        # input loop run while a frame waits for the GPU, on every device.
        @test polls / seconds > 60
    end

    @testset "a key tap between two frames moves the camera" begin
        # Frames of 0.3 s, and a tap of 0.1 s inside one: the camera times the tap from
        # the key events, not from the ticks, which come once a frame.
        slow = on(_ -> sleep(0.3), events(sc).tick)
        cc = cameracontrols(sc)
        speed = 0.5 * norm(cc.eyeposition[] - cc.lookat[])   # `keyboard_translationspeed`
        f0 = scr.frames_presented[]
        while scr.frames_presented[] == f0
            sleep(0.001)
        end
        lookat = cc.lookat[]
        t0 = time()
        events(sc).keyboardbutton[] = Makie.KeyEvent(Keyboard.w, Keyboard.press)
        t1 = time()
        sleep(0.1)
        t2 = time()
        events(sc).keyboardbutton[] = Makie.KeyEvent(Keyboard.w, Keyboard.release)
        t3 = time()
        f1 = scr.frames_presented[]
        while scr.frames_presented[] < f1 + 2
            sleep(0.001)
        end
        off(slow)
        @test speed * (t2 - t1) <= norm(cc.lookat[] - lookat) <= speed * (t3 - t0)
    end

    scr.stop_renderloop[] = true
    RayMakie.wait_viewer(scr)
end
