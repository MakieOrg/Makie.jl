# Standalone Vulkan viewer for RayMakie.
# Opens a GLFW window, starts an async render loop on the Screen.
# Returns the Screen — supports close(screen), colorbuffer(screen), wait(screen).

import GLFW
# DELETED in phase 1.5: see Mantle/docs/mantle-owns-it.md

# Connect GLFW events to Makie's event system.
# Mirrors GLMakie's event.jl — mouse Y is flipped (GLFW top-down → Makie bottom-up),
# window_open is tracked, entered_window/unicode_input/dropped_files are forwarded.
"""
    unitsize(window, ppu) -> (w, h)

The window in Makie UNITS: its DRAWABLE in pixels, divided by `px_per_unit`.

One unit is one drawable pixel over `px_per_unit` — that is the definition every
viewport in `collect_overlay_robjs` is sized by, so it is the one the event
system has to report in. A GLFW POINT is not a unit and the two only coincide by
accident: on a Retina panel the drawable is the content scale times the window in
points, and on X11 with a scaled desktop `GetFramebufferSize == GetWindowSize`
while the content scale is still 1.45. Taking the window in points for units was
right on the first and wrong on the second, where it laid a 800x600 figure out at
1158x869 units and then the renderer multiplied every viewport by 1.45 again —
the whole GUI drawn 1.45x too large, anchored at a scaled origin.
"""
function unitsize(window::GLFW.Window, ppu::Real)
    fbw, fbh = GLFW.GetFramebufferSize(window)
    return (round(Int, fbw / ppu), round(Int, fbh / ppu))
end

"""
    unitscale(window, ppu) -> Float64

Makie units per GLFW point, for the one thing GLFW reports in points and Makie
wants in units: the cursor. Drawable pixels per point, over `px_per_unit`.
"""
function unitscale(window::GLFW.Window, ppu::Real)
    fbw, _ = GLFW.GetFramebufferSize(window)
    winw, _ = GLFW.GetWindowSize(window)
    return winw > 0 ? (Float64(fbw) / winw) / ppu : 1.0 / ppu
end

function connect_glfw_events!(screen, scene::Makie.Scene, window::GLFW.Window,
                              stop_ref::Threads.Atomic{Bool})
    events = scene.events

    # Mouse buttons
    GLFW.SetMouseButtonCallback(window, (_, button, action, _mods) -> begin
        events.mousebutton[] = Makie.MouseButtonEvent(
            Makie.Mouse.Button(Int(button)), Makie.Mouse.Action(Int(action)))
    end)

    # Keyboard
    GLFW.SetKeyCallback(window, (_, key, _scancode, action, _mods) -> begin
        key == GLFW.KEY_ESCAPE && action == GLFW.PRESS && (stop_ref[] = true)
        events.keyboardbutton[] = Makie.KeyEvent(
            Makie.Keyboard.Button(Int(key)), Makie.Keyboard.Action(Int(action)))
    end)

    # Unicode text input
    GLFW.SetCharCallback(window, (_, c) -> begin
        events.unicode_input[] = c
    end)

    # Scroll
    GLFW.SetScrollCallback(window, (_, xoff, yoff) -> begin
        events.scroll[] = (Float64(xoff), Float64(yoff))
    end)

    # Focus
    GLFW.SetWindowFocusCallback(window, (_, focused) -> begin
        events.hasfocus[] = focused
    end)
    events.hasfocus[] = GLFW.GetWindowAttrib(window, GLFW.FOCUSED)

    # Mouse enter/leave
    GLFW.SetCursorEnterCallback(window, (_, entered) -> begin
        events.entered_window[] = entered
    end)

    # Window close
    GLFW.SetWindowCloseCallback(window, (_) -> begin
        stop_ref[] = true
        events.window_open[] = false
    end)
    events.window_open[] = true

    # Drag & drop
    GLFW.SetDropCallback(window, (_, files) -> begin
        events.dropped_files[] = String.(files)
    end)

    # Window resize. UNITS, like the poll — see `unitsize`. The callback's own
    # `w, h` are points and are deliberately not used.
    GLFW.SetWindowSizeCallback(window, (_, _w, _h) -> begin
        uw, uh = unitsize(window, screen.px_per_unit)
        area = Makie.Recti(0, 0, uw, uh)
        area != events.window_area[] && (events.window_area[] = area)
    end)
end

function poll_glfw_events!(screen, scene::Makie.Scene, window::GLFW.Window,
                          frame_count::Int, last_time::Float64)
    events = scene.events

    # Both in UNITS, which is what Makie lays a figure out in. GLFW reports the
    # window in points and the cursor in points; [`unitsize`](@ref) and
    # [`unitscale`](@ref) are the two conversions, and they go through the
    # DRAWABLE rather than assuming a point is a unit.
    #
    # This used to mix three spaces: `window_area` came from `GetFramebufferSize`
    # (PIXELS) while the cursor was flipped with `GetWindowSize` (POINTS), so on
    # a Retina panel every position Makie saw was half of where the pointer was;
    # then both were made points, which is right only where the drawable is the
    # content scale times the window.
    ppu = screen.px_per_unit
    uw, uh = unitsize(window, ppu)
    area = Makie.Recti(0, 0, uw, uh)
    area != events.window_area[] && (events.window_area[] = area)

    # Y flips from GLFW (top-down) to Makie (bottom-up), in units.
    s = unitscale(window, ppu)
    x, y = GLFW.GetCursorPos(window)
    mp = (Float64(x) * s, uh - Float64(y) * s)
    mp != events.mouseposition[] && (events.mouseposition[] = mp)

    # Frame tick
    now = time()
    events.tick[] = Makie.Tick(Makie.RegularRenderTick, frame_count, now, Float64(now - last_time))
    return now
end

"""
    vulkan_viewer(scene; kwargs...) -> Screen

Deprecated. Use `display(scene; backend=RayMakie)` instead (opens a window automatically
when `visible=true`, which is the default).
"""
function vulkan_viewer(fig::Makie.FigureLike; kwargs...)
    return vulkan_viewer(Makie.get_scene(fig); kwargs...)
end

function vulkan_viewer(root_scene::Makie.Scene; kwargs...)
    @warn "vulkan_viewer is deprecated. Use `display(scene; backend=RayMakie)` instead." maxlog=1
    return Base.display(RayMakie.Screen(root_scene; kwargs...), root_scene)
end

"""
    wait_viewer(screen::Screen)

Block until the viewer window is closed. Polls GLFW events on the main thread
(required by GLFW — event processing must happen on the main thread).
Use this instead of `wait(screen)` for interactive windows.
"""
function wait_viewer(screen::Screen)
    win = screen.window
    (win === nothing || !renderloop_running(screen)) && return
    root_scene = screen.scene
    frame_count = 0
    last_time = time()
    while renderloop_running(screen)
        GLFW.PollEvents()
        if !isopen(win)
            screen.stop_renderloop[] = true
            break
        end
        frame_count += 1
        last_time = poll_glfw_events!(screen, root_scene, win.handle, frame_count, last_time)
        sleep(1/120)
    end
end
