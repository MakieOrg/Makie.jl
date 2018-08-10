
function addbuttons(scene::Scene, name, button, action, ::Type{ButtonEnum}) where ButtonEnum
    event = getfield(scene.events, name)
    set = event[]
    button_enum = ButtonEnum(Int(button))
    if button != GLFW.KEY_UNKNOWN
        if action == GLFW.PRESS
            push!(set, button_enum)
        elseif action == GLFW.RELEASE
            delete!(set, button_enum)
        elseif action == GLFW.REPEAT
            # nothing needs to be done, besides returning the same set of keys
        else
            error("Unrecognized enum value for GLFW button press action: $action")
        end
    end
    event[] = set # trigger setfield event!
    return
end

"""
Returns a signal, which is true as long as the window is open.
returns `Node{Bool}`
[GLFW Docs](http://www.glfw.org/docs/latest/group__window.html#gaade9264e79fae52bdb78e2df11ee8d6a)
"""
function window_open(scene::Scene, window::GLFW.Window)
    event = scene.events.window_open
    function windowclose(win)
        event[] = false
    end
    disconnect!(event)
    event[] = isopen(window)
    GLFW.SetWindowCloseCallback(window, windowclose)
end

import AbstractPlotting: disconnect!
function disconnect!(window::GLFW.Window, ::typeof(window_open))
    GLFW.SetWindowCloseCallback(window, nothing)
end


function window_area(scene::Scene, window)
    event = scene.events.window_area
    dpievent = scene.events.window_dpi
    function windowposition(window, x::Cint, y::Cint)
        rect = event[]
        if minimum(rect) != Vec(x, y)
            event[] = IRect(x, y, widths(rect))
        end
    end
    function windowsize(window, w::Cint, h::Cint)
        rect = event[]
        if Vec(w, h) != widths(rect)
            monitor = GLFW.GetPrimaryMonitor()
            props = MonitorProperties(monitor)
            # dpi of a monitor should be the same in x y direction.
            # if not, minimum seems to be a fair default
            dpievent[] = minimum(props.dpi)
            event[] = IRect(minimum(rect), w, h)
        end
    end
    event[] = IRect(GLFW.GetWindowPos(window), GLFW.GetFramebufferSize(window))
    disconnect!(event); disconnect!(window, window_area)

    monitor = GLFW.GetPrimaryMonitor()
    props = MonitorProperties(monitor)
    dpievent[] = minimum(props.dpi)

    GLFW.SetFramebufferSizeCallback(window, windowsize)
    GLFW.SetWindowPosCallback(window, windowposition)
    return
end

function disconnect!(window::GLFW.Window, ::typeof(window_area))
    GLFW.SetWindowPosCallback(window, nothing)
    GLFW.SetFramebufferSizeCallback(window, nothing)
end


"""
Registers a callback for the mouse buttons + modifiers
returns `Node{NTuple{4, Int}}`
[GLFW Docs](http://www.glfw.org/docs/latest/group__input.html#ga1e008c7a8751cea648c8f42cc91104cf)
"""
function mouse_buttons(scene::Scene, window::GLFW.Window)
    event = scene.events.mousebuttons
    function mousebuttons(window, button, action, mods)
        addbuttons(scene, :mousebuttons, button, action, Mouse.Button)
    end
    disconnect!(event); disconnect!(window, mouse_buttons)
    GLFW.SetMouseButtonCallback(window, mousebuttons)
end
function disconnect!(window::GLFW.Window, ::typeof(mouse_buttons))
    GLFW.SetMouseButtonCallback(window, nothing)
end
function keyboard_buttons(scene::Scene, window::GLFW.Window)
    event = scene.events.keyboardbuttons
    function keyoardbuttons(window, button, scancode::Cint, action, mods::Cint)
        addbuttons(scene, :keyboardbuttons, button, action, Keyboard.Button)
    end
    disconnect!(event); disconnect!(window, keyboard_buttons)
    GLFW.SetKeyCallback(window, keyoardbuttons)
end

function disconnect!(window::GLFW.Window, ::typeof(keyboard_buttons))
    GLFW.SetKeyCallback(window, nothing)
end

"""
Registers a callback for drag and drop of files.
returns `Node{Vector{String}}`, which are absolute file paths
[GLFW Docs](http://www.glfw.org/docs/latest/group__input.html#gacc95e259ad21d4f666faa6280d4018fd)
"""
function dropped_files(scene::Scene, window::GLFW.Window)
    event = scene.events.dropped_files
    function droppedfiles(window, files)
        event[] = String.(files)
    end
    disconnect!(event); disconnect!(window, dropped_files)
    event[] = String[]
    GLFW.SetDropCallback(window, droppedfiles)
end
function disconnect!(window::GLFW.Window, ::typeof(dropped_files))
    GLFW.SetDropCallback(window, nothing)
end


"""
Registers a callback for keyboard unicode input.
returns an `Node{Vector{Char}}`,
containing the pressed char. Is empty, if no key is pressed.
[GLFW Docs](http://www.glfw.org/docs/latest/group__input.html#ga1e008c7a8751cea648c8f42cc91104cf)
"""
function unicode_input(scene::Scene, window::GLFW.Window)
    event = scene.events.unicode_input
    function unicodeinput(window, c::Char)
        vals = event[]
        push!(vals, c)
        event[] = vals
        empty!(vals)
        event[] = vals
    end
    disconnect!(event); disconnect!(window, unicode_input)
    x = Char[]; sizehint!(x, 1)
    event[] = x
    GLFW.SetCharCallback(window, unicodeinput)
end
function disconnect!(window::GLFW.Window, ::typeof(unicode_input))
    GLFW.SetCharCallback(window, nothing)
end

# TODO memoise? Or to bug ridden for the small performance gain?
function retina_scaling_factor(w, fb)
    (w[1] == 0 || w[2] == 0) && return (1.0, 1.0)
    fb ./ w
end
function retina_scaling_factor(window::GLFW.Window)
    w, fb = GLFW.GetWindowSize(window), GLFW.GetFramebufferSize(window)
    retina_scaling_factor(w, fb)
end

function correct_mouse(window::GLFW.Window, w, h)
    ws, fb = GLFW.GetWindowSize(window), GLFW.GetFramebufferSize(window)
    s = retina_scaling_factor(ws, fb)
    (w * s[1], fb[2] - (h * s[2]))
end

"""
Registers a callback for the mouse cursor position.
returns an `Node{Vec{2, Float64}}`,
which is not in scene coordinates, with the upper left window corner being 0
[GLFW Docs](http://www.glfw.org/docs/latest/group__input.html#ga1e008c7a8751cea648c8f42cc91104cf)
"""
function mouse_position(scene::Scene, window::GLFW.Window)
    event = scene.events.mouseposition
    function cursorposition(window, w::Cdouble, h::Cdouble)
        event[] = correct_mouse(window, w, h)
    end
    disconnect!(event); disconnect!(window, mouse_position)
    event[] = correct_mouse(window, GLFW.GetCursorPos(window)...)
    GLFW.SetCursorPosCallback(window, cursorposition)
end
function disconnect!(window::GLFW.Window, ::typeof(mouse_position))
    GLFW.SetCursorPosCallback(window, nothing)
end

"""
Registers a callback for the mouse scroll.
returns an `Node{Vec{2, Float64}}`,
which is an x and y offset.
[GLFW Docs](http://www.glfw.org/docs/latest/group__input.html#gacc95e259ad21d4f666faa6280d4018fd)
"""
function scroll(scene::Scene, window::GLFW.Window)
    event = scene.events.scroll
    function scrollcb(window, w::Cdouble, h::Cdouble)
        event[] = (w, h)
        event[] = (0.0, 0.0)
    end
    disconnect!(event); disconnect!(window, scroll)
    event[] = (0.0, 0.0)
    GLFW.SetScrollCallback(window, scrollcb)
end
function disconnect!(window::GLFW.Window, ::typeof(scroll))
    GLFW.SetScrollCallback(window, nothing)
end

"""
Registers a callback for the focus of a window.
returns an `Node{Bool}`,
which is true whenever the window has focus.
[GLFW Docs](http://www.glfw.org/docs/latest/group__window.html#ga6b5f973531ea91663ad707ba4f2ac104)
"""
function hasfocus(scene::Scene, window::GLFW.Window)
    event = scene.events.hasfocus
    function hasfocuscb(window, focus::Bool)
        event[] = focus
    end
    disconnect!(event); disconnect!(window, hasfocus)
    event[] = false
    GLFW.SetWindowFocusCallback(window, hasfocuscb)
end
function disconnect!(window::GLFW.Window, ::typeof(hasfocus))
    GLFW.SetWindowFocusCallback(window, nothing)
end

"""
Registers a callback for if the mouse has entered the window.
returns an `Node{Bool}`,
which is true whenever the cursor enters the window.
[GLFW Docs](http://www.glfw.org/docs/latest/group__input.html#ga762d898d9b0241d7e3e3b767c6cf318f)
"""
function entered_window(scene::Scene, window::GLFW.Window)
    event = scene.events.entered_window
    function enteredwindowcb(window, focus::Bool)
        event[] = focus
    end
    disconnect!(event); disconnect!(window, entered_window)
    event[] = false
    GLFW.SetCursorEnterCallback(window, enteredwindowcb)
end

function disconnect!(window::GLFW.Window, ::typeof(entered_window))
    GLFW.SetCursorEnterCallback(window, nothing)
end
