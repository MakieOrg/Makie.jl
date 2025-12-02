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
        return @print_error begin
            @debug("Closing event from GLFW")
            event[] = false
        end
    end
    disconnect!(window, window_open)
    event[] = isopen(window)
    return GLFW.SetWindowCloseCallback(window, windowclose)
end

function Makie.disconnect!(window::GLFW.Window, ::typeof(window_open))
    return GLFW.SetWindowCloseCallback(window, nothing)
end

function Makie.window_area(scene::Scene, screen::Screen)
    disconnect!(screen, window_area)

    # TODO: Figure out which monitor the window is on and react to DPI changes
    monitor = GLFW.GetPrimaryMonitor()
    props = MonitorProperties(monitor)
    scene.events.window_dpi[] = minimum(props.dpi)

    function windowsizecb(window, width::Cint, height::Cint)
        area = scene.events.window_area
        winscale = screen.scalefactor[]

        gl_switch_context!(window)
        if GLFW.GetPlatform() in (GLFW.PLATFORM_COCOA, GLFW.PLATFORM_WAYLAND)
            winscale /= scale_factor(window)
        end
        winw, winh = round.(Int, (width, height) ./ winscale)
        if Vec(winw, winh) != widths(area[])
            area[] = Recti(minimum(area[]), winw, winh)
        end
        return
    end
    # TODO put back window position, but right now it makes more trouble than it helps
    #function windowposcb(window, x::Cint, y::Cint)
    #    area = scene.events.window_area
    #    gl_switch_context!(window)
    #    winscale = screen.scalefactor[] / (@static Sys.isapple() ? scale_factor(window) : 1)
    #    xs, ys = round.(Int, (x, y) ./ winscale)
    #    if Vec(xs, ys) != minimum(area[])
    #        area[] = Recti(xs, ys, widths(area[]))
    #    end
    #    return
    #end

    window = to_native(screen)
    GLFW.SetWindowSizeCallback(window, (win, w, h) -> windowsizecb(win, w, h))
    #GLFW.SetWindowPosCallback(window, (win, x, y) -> windowposcb(win, x, y))

    windowsizecb(window, Cint.(window_size(window))...)
    return
end

function Makie.disconnect!(screen::Screen, ::typeof(window_area))
    window = to_native(screen)
    #GLFW.SetWindowPosCallback(window, nothing)
    GLFW.SetWindowSizeCallback(window, nothing)
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
        return @print_error begin
            event[] = MouseButtonEvent(Mouse.Button(Int(button)), Mouse.Action(Int(action)))
        end
    end
    disconnect!(window, mouse_buttons)
    return GLFW.SetMouseButtonCallback(window, mousebuttons)
end
function Makie.disconnect!(window::GLFW.Window, ::typeof(mouse_buttons))
    return GLFW.SetMouseButtonCallback(window, nothing)
end
Makie.keyboard_buttons(scene::Scene, screen) = keyboard_buttons(scene, to_native(screen))
function Makie.keyboard_buttons(scene::Scene, window::GLFW.Window)
    event = scene.events.keyboardbutton
    function keyoardbuttons(window, button, scancode::Cint, action, mods::Cint)
        return @print_error begin
            event[] = KeyEvent(Keyboard.Button(Int(button)), Keyboard.Action(Int(action)))
        end
    end
    disconnect!(window, keyboard_buttons)
    return GLFW.SetKeyCallback(window, keyoardbuttons)
end

function Makie.disconnect!(window::GLFW.Window, ::typeof(keyboard_buttons))
    return GLFW.SetKeyCallback(window, nothing)
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
        return @print_error begin
            event[] = String.(files)
        end
    end
    disconnect!(window, dropped_files)
    event[] = String[]
    return GLFW.SetDropCallback(window, droppedfiles)
end
function Makie.disconnect!(window::GLFW.Window, ::typeof(dropped_files))
    return GLFW.SetDropCallback(window, nothing)
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
        return @print_error begin
            event[] = c
        end
    end
    disconnect!(window, unicode_input)
    # x = Char[]; sizehint!(x, 1)
    # event[] = x
    return GLFW.SetCharCallback(window, unicodeinput)
end
function Makie.disconnect!(window::GLFW.Window, ::typeof(unicode_input))
    return GLFW.SetCharCallback(window, nothing)
end

function correct_mouse(screen::Screen, w, h)
    nw = to_native(screen)
    _, winh = window_size(nw)
    sf = screen.scalefactor[]
    if GLFW.GetPlatform() in (GLFW.PLATFORM_COCOA, GLFW.PLATFORM_WAYLAND)
        sf /= scale_factor(nw)
    end
    return w / sf, (winh - h) / sf
end

struct MousePositionUpdater
    screen::Screen
    mouseposition::Observable{Tuple{Float64, Float64}}
    hasfocus::Observable{Bool}
end

function (p::MousePositionUpdater)(::Makie.TickState)
    !p.hasfocus[] && return
    nw = to_native(p.screen)
    x, y = GLFW.GetCursorPos(nw)
    pos = correct_mouse(p.screen, x, y)
    if pos != p.mouseposition[]
        @print_error p.mouseposition[] = pos
        # notify!(e.mouseposition)
    end
    return Consume(false)
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
    on(updater, scene, screen.render_tick, priority = typemax(Int))
    return
end
function Makie.disconnect!(screen::Screen, ::typeof(mouse_position))
    filter!(p -> !isa(p[2], MousePositionUpdater), screen.render_tick.listeners)
    return
end
function Makie.disconnect!(window::GLFW.Window, ::typeof(mouse_position))
    error("disconnect!(::Screen, ::mouse_position) should be called instead of disconnect!(::GLFW.Window, ::mouseposition)!")
    return nothing
end

"""
Registers a callback for the mouse scroll.
returns an `Observable{Vec{2, Float64}}`,
which is an x and y offset.
[GLFW Docs](http://www.glfw.org/docs/latest/group__input.html#gacc95e259ad21d4f666faa6280d4018fd)
"""
Makie.scroll(scene::Scene, screen) = scroll(scene, to_native(screen))
mutable struct ScrollUpdater <: Function
    event::Observable{Tuple{Float64, Float64}}
    integer_scroll::Bool
end
function (sc::ScrollUpdater)(window, w::Cdouble, h::Cdouble)
    @static if Sys.isapple()
        sc.integer_scroll = sc.integer_scroll && isinteger(w) && isinteger(h)
        w, h = ifelse(sc.integer_scroll, 1.0, 0.067) .* (w, h)
    end
    @print_error begin
        sc.event[] = (w, h)
    end
    return
end
function Makie.scroll(scene::Scene, window::GLFW.Window)
    updater = ScrollUpdater(scene.events.scroll, true)
    disconnect!(window, scroll)
    return GLFW.SetScrollCallback(window, updater)
end
function Makie.disconnect!(window::GLFW.Window, ::typeof(scroll))
    return GLFW.SetScrollCallback(window, nothing)
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
        return @print_error begin
            event[] = focus
        end
    end
    disconnect!(window, hasfocus)
    GLFW.SetWindowFocusCallback(window, hasfocuscb)
    event[] = GLFW.GetWindowAttrib(window, GLFW.FOCUSED)
    return nothing
end
function Makie.disconnect!(window::GLFW.Window, ::typeof(hasfocus))
    return GLFW.SetWindowFocusCallback(window, nothing)
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
        return @print_error begin
            event[] = entered
        end
    end
    disconnect!(window, entered_window)
    return GLFW.SetCursorEnterCallback(window, enteredwindowcb)
end

function Makie.disconnect!(window::GLFW.Window, ::typeof(entered_window))
    return GLFW.SetCursorEnterCallback(window, nothing)
end

function Makie.frame_tick(scene::Scene, screen::Screen)
    # Separating screen ticks from event ticks allows us to sanitize:
    # Internal on-tick event updates happen first (mouseposition),
    # consuming in event.tick listeners doesn't affect backend ticks,
    # more control/consistent order
    return on(Makie.TickCallback(scene), scene, screen.render_tick, priority = typemin(Int))
end
function Makie.disconnect!(screen::Screen, ::typeof(Makie.frame_tick))
    connections = filter(x -> x[2] isa Makie.TickCallback, screen.render_tick.listeners)
    return foreach(x -> off(screen.render_tick, x[2]), connections)
end
