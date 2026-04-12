# Standalone Vulkan viewer for RayMakie.
# Opens a GLFW window, starts an async render loop on the Screen.
# Returns the Screen — supports close(screen), colorbuffer(screen), wait(screen).

import GLFW
import Lava

# Connect GLFW events to Makie's event system.
# Mirrors GLMakie's event.jl — mouse Y is flipped (GLFW top-down → Makie bottom-up),
# window_open is tracked, entered_window/unicode_input/dropped_files are forwarded.
function connect_glfw_events!(scene::Makie.Scene, window::GLFW.Window, stop_ref::Threads.Atomic{Bool})
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

    # Window resize
    GLFW.SetWindowSizeCallback(window, (_, w, h) -> begin
        area = Makie.Recti(0, 0, Int(w), Int(h))
        area != events.window_area[] && (events.window_area[] = area)
    end)
end

function poll_glfw_events!(scene::Makie.Scene, window::GLFW.Window, frame_count::Int, last_time::Float64)
    events = scene.events

    # Mouse position — flip Y from GLFW (top-down) to Makie (bottom-up)
    x, y = GLFW.GetCursorPos(window)
    _, winh = GLFW.GetWindowSize(window)
    mp = (Float64(x), Float64(winh - y))
    mp != events.mouseposition[] && (events.mouseposition[] = mp)

    # Window area (framebuffer may differ from window size on HiDPI)
    w, h = GLFW.GetFramebufferSize(window)
    area = Makie.Recti(0, 0, w, h)
    area != events.window_area[] && (events.window_area[] = area)

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
        last_time = poll_glfw_events!(root_scene, win.handle, frame_count, last_time)
        sleep(1/120)
    end
end
