# Standalone Vulkan viewer for RayMakie.
# Opens a GLFW window, starts an async render loop on the Screen.
# Returns the Screen — supports close(screen), colorbuffer(screen), wait(screen).

import GLFW
import Lava

function connect_glfw_events!(scene::Makie.Scene, window::GLFW.Window, stop_ref::Threads.Atomic{Bool})
    events = scene.events
    GLFW.SetMouseButtonCallback(window, (_, button, action, _mods) -> begin
        events.mousebutton[] = Makie.MouseButtonEvent(
            Makie.Mouse.Button(Int(button)), Makie.Mouse.Action(Int(action)))
    end)
    GLFW.SetKeyCallback(window, (_, key, _scancode, action, _mods) -> begin
        key == GLFW.KEY_ESCAPE && action == GLFW.PRESS && (stop_ref[] = true)
        events.keyboardbutton[] = Makie.KeyEvent(
            Makie.Keyboard.Button(Int(key)), Makie.Keyboard.Action(Int(action)))
    end)
    GLFW.SetScrollCallback(window, (_, xoff, yoff) -> begin
        events.scroll[] = (Float64(xoff), Float64(yoff))
    end)
    GLFW.SetWindowFocusCallback(window, (_, focused) -> begin
        events.hasfocus[] = focused
    end)
    GLFW.SetWindowCloseCallback(window, (_) -> begin
        stop_ref[] = true
    end)
end

function poll_glfw_events!(scene::Makie.Scene, window::GLFW.Window, frame_count::Int, last_time::Float64)
    events = scene.events
    x, y = GLFW.GetCursorPos(window)
    mp = (Float64(x), Float64(y))
    mp != events.mouseposition[] && (events.mouseposition[] = mp)
    w, h = GLFW.GetFramebufferSize(window)
    area = Makie.Recti(0, 0, w, h)
    area != events.window_area[] && (events.window_area[] = area)
    now = time()
    events.tick[] = Makie.Tick(Makie.RegularRenderTick, frame_count, now, Float64(now - last_time))
    return now
end

"""
    vulkan_viewer(scene; kwargs...) -> Screen

Open a standalone Vulkan window with an async render loop.
Returns the `Screen`. Use `close(screen)` to stop, `colorbuffer(screen)` to grab a frame,
`wait(screen)` to block until the window is closed.
"""
function vulkan_viewer(fig::Makie.FigureLike; kwargs...)
    return vulkan_viewer(Makie.get_scene(fig); kwargs...)
end

function vulkan_viewer(root_scene::Makie.Scene;
                       device=nothing,
                       integrator=Hikari.VolPath(samples=1, max_depth=8, hw_accel=true),
                       exposure=1.0f0, tonemap=:aces, gamma=1.0f0,
                       sensor=nothing, vsync=true,
                       title="RayMakie",
                       max_frames::Int=0)

    device === nothing && (device = Lava.LavaBackend())
    config = ScreenConfig(integrator, Float32(exposure), tonemap, Float32(gamma), sensor, device)
    screen = Screen(nothing, nothing, config)

    # Create window BEFORE display — GPU buffers allocated during display must
    # coexist with the swapchain (window creation changes device resource state).
    w, h = size(root_scene)
    win = Lava.RenderWindow(w, h; title, vsync)
    screen.window = win
    connect_glfw_events!(root_scene, win.handle, screen.stop_renderloop)

    Base.display(screen, root_scene)

    # Per-scene camera tracking — only for RT scenes.
    # We track the Hikari camera parameters (derived from Makie's projectionview)
    # rather than the projectionview observable directly, because Makie fires
    # projectionview notifications on window_area changes even when the 3D camera
    # hasn't moved (e.g. zooming a 2D scatter in another panel).
    for ss in screen.scene_states
        ss.overlay_only && continue
        makie_scene = ss.makie_scene
        last_pv = Ref(copy(makie_scene.camera.projectionview[]))
        on(root_scene, makie_scene.camera.projectionview) do pv
            if !isapprox(pv, last_pv[])
                last_pv[] = copy(pv)
                ss.needs_film_clear = true
            end
        end
    end

    screen.stop_renderloop[] = false
    ctx = Lava.vk_context()
    present_bq = Lava.allocate_batch_queue!()

    screen.rendertask = @async begin
        yield()  # Return control to caller so vulkan_viewer() returns immediately
        frame_count = 0
        last_time = time()
        try
            while !screen.stop_renderloop[] && (max_frames <= 0 || frame_count < max_frames)
                GLFW.PollEvents()
                screen.stop_renderloop[] && break
                !isopen(win) && break
                frame_count += 1
                last_time = poll_glfw_events!(root_scene, win.handle, frame_count, last_time)

                cur_w, cur_h = size(win)
                if (cur_w, cur_h) != (w, h)
                    w, h = cur_w, cur_h
                    resize!(screen, w, h)
                end

                for ss in screen.scene_states
                    screen.state = ss
                    render!(screen)
                end
                # Flush RT dispatches to prevent GPU timeout from large batches
                Lava.vk_flush!()

                screen.stop_renderloop[] && break

                postprocess_and_composite_gpu!(screen)

                Lava.vk_flush!()
                Lava.Vulkan.device_wait_idle(ctx.device)

                screen.stop_renderloop[] && break

                # Blit RGBA output_buffer to window, then render overlays on top
                Lava.acquire_next_image!(win)
                Lava.blit!(present_bq, Lava.WindowTarget(win), screen.output_buffer; clear=false)

                # Render overlays (scatter, lines, text) directly onto the window
                win_target = Lava.WindowTarget(win)
                for ss in screen.scene_states
                    screen.state = ss
                    poll_all_plots(screen, ss.makie_scene)
                    render_overlays!(screen, present_bq, win_target)
                end

                Lava.present_frame!(present_bq, win)
                Lava.Vulkan.device_wait_idle(ctx.device)

                yield()
            end
        catch e
            if !(e isa EOFError || e isa Base.IOError)
                @error "Render loop error" exception=(e, catch_backtrace())
            end
        finally
            screen.stop_renderloop[] = true
            try
                Lava.Vulkan.device_wait_idle(ctx.device)
            catch; end
            isopen(win) && close(win)
            screen.rendertask = nothing
        end
    end

    return screen
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
