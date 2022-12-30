using Makie: MouseButtonEvent, KeyEvent

macro print_error(expr)
    return quote
        try
            $(esc(expr))
        catch e
            println(stderr, "Error in callback:")
            # TODO is it fine to call catch_backtrace inside C call?
            Base.showerror(stderr, e, Base.catch_backtrace())
            println(stderr)
        end
    end
end

"""
Returns a signal, which is true as long as the window is open.
returns `Observable{Bool}`
[GLFW Docs](http://www.glfw.org/docs/latest/group__window.html#gaade9264e79fae52bdb78e2df11ee8d6a)
"""
Makie.window_open(scene::Scene, screen) = window_open(scene, to_native(screen))

function Makie.window_open(scene::Scene, window::GLFW.Window)
    event = scene.events.window_open
    function windowclose(win)
        @print_error begin
            event[] = false
        end
    end
    disconnect!(window, window_open)
    event[] = isopen(window)
    GLFW.SetWindowCloseCallback(window, windowclose)
end

function Makie.disconnect!(window::GLFW.Window, ::typeof(window_open))
    GLFW.SetWindowCloseCallback(window, nothing)
end

function window_position(window::GLFW.Window)
    xy = GLFW.GetWindowPos(window)
    (xy.x, xy.y)
end

struct WindowAreaUpdater
    screen::Screen
    dpi::Observable{Float64}
    area::Observable{GeometryBasics.HyperRectangle{2, Int64}}
end

function (x::WindowAreaUpdater)(::Nothing)
    nw = to_native(x.screen)
    ShaderAbstractions.switch_context!(nw)
    rect = x.area[]
    # TODO put back window position, but right now it makes more trouble than it helps#
    # x, y = GLFW.GetWindowPos(nw)
    # if minimum(rect) != Vec(x, y)
    #     event[] = Recti(x, y, framebuffer_size(window))
    # end
    w, h = round.(Int, windowsize(nw) ./ x.screen.px_per_unit[])
    if Vec(w, h) != widths(rect)
        monitor = GLFW.GetPrimaryMonitor()
        props = MonitorProperties(monitor)
        # dpi of a monitor should be the same in x y direction.
        # if not, minimum seems to be a fair default
        x.dpi[] = minimum(props.dpi)
        x.area[] = Recti(minimum(rect), w, h)
    end
    return
end

function Makie.window_area(scene::Scene, screen::Screen)
    disconnect!(screen, window_area)

    updater = WindowAreaUpdater(
        screen, scene.events.window_dpi, scene.events.window_area
    )
    on(updater, screen.render_tick)

    return
end

function Makie.disconnect!(screen::Screen, ::typeof(window_area))
    filter!(p -> !isa(p[2], WindowAreaUpdater), screen.render_tick.listeners)
    return
end
function Makie.disconnect!(::GLFW.Window, ::typeof(window_area))
    error("disconnect!(::Screen, ::window_area) should be called instead of disconnect!(::GLFW.Window, ::window_area)!")
    return
end


"""
Registers a callback for the mouse buttons + modifiers
returns `Observable{NTuple{4, Int}}`
[GLFW Docs](http://www.glfw.org/docs/latest/group__input.html#ga1e008c7a8751cea648c8f42cc91104cf)
"""
Makie.mouse_buttons(scene::Scene, screen) = mouse_buttons(scene, to_native(screen))
function Makie.mouse_buttons(scene::Scene, window::GLFW.Window)
    event = scene.events.mousebutton
    function mousebuttons(window, button, action, mods)
        @print_error begin
            event[] = MouseButtonEvent(Mouse.Button(Int(button)), Mouse.Action(Int(action)))
        end
    end
    disconnect!(window, mouse_buttons)
    GLFW.SetMouseButtonCallback(window, mousebuttons)
end
function Makie.disconnect!(window::GLFW.Window, ::typeof(mouse_buttons))
    GLFW.SetMouseButtonCallback(window, nothing)
end
Makie.keyboard_buttons(scene::Scene, screen) = keyboard_buttons(scene, to_native(screen))
function Makie.keyboard_buttons(scene::Scene, window::GLFW.Window)
    event = scene.events.keyboardbutton
    function keyoardbuttons(window, button, scancode::Cint, action, mods::Cint)
        @print_error begin
            event[] = KeyEvent(Keyboard.Button(Int(button)), Keyboard.Action(Int(action)))
        end
    end
    disconnect!(window, keyboard_buttons)
    GLFW.SetKeyCallback(window, keyoardbuttons)
end

function Makie.disconnect!(window::GLFW.Window, ::typeof(keyboard_buttons))
    GLFW.SetKeyCallback(window, nothing)
end

"""
Registers a callback for drag and drop of files.
returns `Observable{Vector{String}}`, which are absolute file paths
[GLFW Docs](http://www.glfw.org/docs/latest/group__input.html#gacc95e259ad21d4f666faa6280d4018fd)
"""
Makie.dropped_files(scene::Scene, screen) = dropped_files(scene, to_native(screen))
function Makie.dropped_files(scene::Scene, window::GLFW.Window)
    event = scene.events.dropped_files
    function droppedfiles(window, files)
        @print_error begin
            event[] = String.(files)
        end
    end
    disconnect!(window, dropped_files)
    event[] = String[]
    GLFW.SetDropCallback(window, droppedfiles)
end
function Makie.disconnect!(window::GLFW.Window, ::typeof(dropped_files))
    GLFW.SetDropCallback(window, nothing)
end

"""
Registers a callback for keyboard unicode input.
returns an `Observable{Vector{Char}}`,
containing the pressed char. Is empty, if no key is pressed.
[GLFW Docs](http://www.glfw.org/docs/latest/group__input.html#ga1e008c7a8751cea648c8f42cc91104cf)
"""
Makie.unicode_input(scene::Scene, screen) = unicode_input(scene, to_native(screen))
function Makie.unicode_input(scene::Scene, window::GLFW.Window)
    event = scene.events.unicode_input
    function unicodeinput(window, c::Char)
        @print_error begin
            event[] = c
        end
    end
    disconnect!(window, unicode_input)
    # x = Char[]; sizehint!(x, 1)
    # event[] = x
    GLFW.SetCharCallback(window, unicodeinput)
end
function Makie.disconnect!(window::GLFW.Window, ::typeof(unicode_input))
    GLFW.SetCharCallback(window, nothing)
end

function correct_mouse(screen::Screen, w, h)
    sf = screen.px_per_unit[]
    _, wh = windowsize(to_native(screen))
    return (w / sf, (wh - h) / sf)
end

struct MousePositionUpdater
    screen::Screen
    mouseposition::Observable{Tuple{Float64, Float64}}
    hasfocus::Observable{Bool}
end

function (p::MousePositionUpdater)(::Nothing)
    !p.hasfocus[] && return
    nw = to_native(p.screen)
    x, y = GLFW.GetCursorPos(nw)
    pos = correct_mouse(p.screen, x, y)
    if pos != p.mouseposition[]
        @print_error p.mouseposition[] = pos
        # notify!(e.mouseposition)
    end
    return
end

"""
Registers a callback for the mouse cursor position.
returns an `Observable{Vec{2, Float64}}`,
which is not in scene coordinates, with the upper left window corner being 0
[GLFW Docs](http://www.glfw.org/docs/latest/group__input.html#ga1e008c7a8751cea648c8f42cc91104cf)
"""
function Makie.mouse_position(scene::Scene, screen::Screen)
    disconnect!(screen, mouse_position)
    updater = MousePositionUpdater(
        screen, scene.events.mouseposition, scene.events.hasfocus
    )
    on(updater, screen.render_tick)
    return
end
function Makie.disconnect!(screen::Screen, ::typeof(mouse_position))
    filter!(p -> !isa(p[2], MousePositionUpdater), screen.render_tick.listeners)
    return
end
function Makie.disconnect!(window::GLFW.Window, ::typeof(mouse_position))
    error("disconnect!(::Screen, ::mouse_position) should be called instead of disconnect!(::GLFW.Window, ::mouseposition)!")
    nothing
end

"""
Registers a callback for the mouse scroll.
returns an `Observable{Vec{2, Float64}}`,
which is an x and y offset.
[GLFW Docs](http://www.glfw.org/docs/latest/group__input.html#gacc95e259ad21d4f666faa6280d4018fd)
"""
Makie.scroll(scene::Scene, screen) = scroll(scene, to_native(screen))
function Makie.scroll(scene::Scene, window::GLFW.Window)
    event = scene.events.scroll
    function scrollcb(window, w::Cdouble, h::Cdouble)
        @print_error begin
            event[] = (w, h)
        end
    end
    disconnect!(window, scroll)
    GLFW.SetScrollCallback(window, scrollcb)
end
function Makie.disconnect!(window::GLFW.Window, ::typeof(scroll))
    GLFW.SetScrollCallback(window, nothing)
end

"""
Registers a callback for the focus of a window.
returns an `Observable{Bool}`,
which is true whenever the window has focus.
[GLFW Docs](http://www.glfw.org/docs/latest/group__window.html#ga6b5f973531ea91663ad707ba4f2ac104)
"""
Makie.hasfocus(scene::Scene, screen) = hasfocus(scene, to_native(screen))
function Makie.hasfocus(scene::Scene, window::GLFW.Window)
    event = scene.events.hasfocus
    function hasfocuscb(window, focus::Bool)
        @print_error begin
            event[] = focus
        end
    end
    disconnect!(window, hasfocus)
    GLFW.SetWindowFocusCallback(window, hasfocuscb)
    event[] = GLFW.GetWindowAttrib(window, GLFW.FOCUSED)
    nothing
end
function Makie.disconnect!(window::GLFW.Window, ::typeof(hasfocus))
    GLFW.SetWindowFocusCallback(window, nothing)
end

"""
Registers a callback for if the mouse has entered the window.
returns an `Observable{Bool}`,
which is true whenever the cursor enters the window.
[GLFW Docs](http://www.glfw.org/docs/latest/group__input.html#ga762d898d9b0241d7e3e3b767c6cf318f)
"""
Makie.entered_window(scene::Scene, screen) = entered_window(scene, to_native(screen))
function Makie.entered_window(scene::Scene, window::GLFW.Window)
    event = scene.events.entered_window
    function enteredwindowcb(window, entered::Bool)
        @print_error begin
            event[] = entered
        end
    end
    disconnect!(window, entered_window)
    GLFW.SetCursorEnterCallback(window, enteredwindowcb)
end

function Makie.disconnect!(window::GLFW.Window, ::typeof(entered_window))
    GLFW.SetCursorEnterCallback(window, nothing)
end
