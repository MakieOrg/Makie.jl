function click(events::Events, pos::VecTypes{2}, button::Mouse.Button = Mouse.left)
    events.mouseposition[] = pos
    events.mousebutton[] = Makie.MouseButtonEvent(button, Mouse.press)
    return events.mousebutton[] = Makie.MouseButtonEvent(button, Mouse.release)
end
click(events::Events, x, y, button::Mouse.Button = Mouse.left) = click(events, (x, y), button)

function send(events::Events, key::Keyboard.Button)
    events.keyboardbutton[] = Makie.KeyEvent(key, Keyboard.press)
    return events.keyboardbutton[] = Makie.KeyEvent(key, Keyboard.release)
end
function send(events::Events, pos::VecTypes{2}, key::Keyboard.Button)
    events.mouseposition[] = pos
    return send(events, key)
end
send(events::Events, x, y, key::Keyboard.Button) = click(events, (x, y), key)


if isdefined(Main, :WGLMakie)
    using WGLMakie.Bonito: wait_for
else
    function wait_for(callback; timeout = 60)
        t0 = time()
        while time() - t0 < timeout
            if callback()
                return :success
            end
            sleep(0.001)
        end
        return :timed_out
    end
end

function wait_for_data_inspector(action, fig, inspector, visible = nothing, timeout = 60)
    # WGLMakie: check for change in the picked plot element
    # GLMakie: force re-render via colorbuffer()
    last_plot_element = inspector.last_plot_element
    action()
    notify(events(fig).tick)
    colorbuffer(fig)
    status = wait_for(timeout = timeout) do
        # notify(events(fig).tick)
        has_switched = inspector.last_plot_element != last_plot_element
        check_visible = visible === nothing ? true : (inspector.dynamic_tooltip.visible[] == visible)
        return has_switched && check_visible
    end
    if status != :success
        @warn "Failed wait_for with status $status"
        return false
    end
    # WGLMakie also needs time to render?
    isdefined(Main, :WGLMakie) && sleep(10 / 30)
    return true
end
