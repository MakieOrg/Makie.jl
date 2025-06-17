module MouseEventTypes
    @enum MouseEventType begin
        out
        enter
        over

        leftdown
        rightdown
        middledown

        leftup
        rightup
        middleup

        leftdragstart
        rightdragstart
        middledragstart

        leftdrag
        rightdrag
        middledrag

        leftdragstop
        rightdragstop
        middledragstop

        leftclick
        rightclick
        middleclick

        leftdoubleclick
        rightdoubleclick
        middledoubleclick

        downoutside
    end
    export MouseEventType
end

using .MouseEventTypes

"""
    MouseEvent

Describes a mouse state change.
Fields:
- `type`: MouseEventType
- `t`: Time of the event
- `data`: Mouse position in data coordinates
- `px`: Mouse position in px relative to scene origin
- `prev_t`: Time of previous event
- `prev_data`: Previous mouse position in data coordinates
- `prev_px`: Previous mouse position in data coordinates
"""
struct MouseEvent
    type::MouseEventType
    t::Float64
    data::Point2d
    px::Point2f
    prev_t::Float64
    prev_data::Point2d
    prev_px::Point2f
end

struct MouseEventHandle
    obs::Observable{MouseEvent}
    observerfuncs::Vector{<:Observables.ObserverFunction}
end

"""
    clear!(handle::MouseEventHandle)

Cut observable connections to the scene and remove any listeners to the mouse events.
"""
function clear!(handle::MouseEventHandle)
    foreach(Observables.off, handle.observerfuncs)
    empty!(handle.observerfuncs)
    empty!(handle.obs.listeners)
    return nothing
end


for eventtype in instances(MouseEventType)
    onfunctionname = Symbol("onmouse" * String(Symbol(eventtype)))
    @eval begin

        """
        Executes the function f whenever the `MouseEventHandle`'s observable is set to
        a MouseEvent with `event.type === $($eventtype)`.
        """
        function $onfunctionname(f, mev::MouseEventHandle; priority = 0)
            return on(mev.obs, priority = priority) do event
                if event.type === $eventtype
                    return f(event)
                end
                return Consume(false)
            end
        end
        export $onfunctionname
    end
end


"""
    addmouseevents!(scene, elements...)

Returns a `MouseEventHandle` with an observable inside which is triggered by all mouse
interactions with the `scene` and optionally restricted to all given
plot objects in `elements`.

To react to mouse events, use the onmouse... handlers.

Example:

```julia
mouseevents = addmouseevents!(scene, scatterplot)

onmouseleftclick(mouseevents) do event
    # do something with the mouseevent
end
```
"""
function addmouseevents!(scene, elements...; priority = 1)
    is_mouse_over_relevant_area() = isempty(elements) ? Makie.is_mouseinside(scene) : mouseover(scene, elements...)
    return _addmouseevents!(scene, is_mouse_over_relevant_area, priority)
end
function addmouseevents!(scene, bbox::Observables.AbstractObservable{<:Rect2}; priority = 1)
    is_mouse_over_relevant_area() = Makie.mouseposition_px(scene) in bbox[]
    return _addmouseevents!(scene, is_mouse_over_relevant_area, priority)
end


# don't react to buttons beyond the first three
_isstandardmousebutton(b) = (b == Mouse.left || b == Mouse.middle || b == Mouse.right)

# TODO
# Make these enums so we can just do `Mouse.left & Mouse.drag`

function to_drag_event(b::Mouse.Button)
    b === Mouse.left && return MouseEventTypes.leftdrag
    b === Mouse.right && return MouseEventTypes.rightdrag
    b === Mouse.middle && return MouseEventTypes.middledrag
    error("No recognized mouse button $b")
end

function to_drag_start_event(b::Mouse.Button)
    b === Mouse.left && return MouseEventTypes.leftdragstart
    b === Mouse.right && return MouseEventTypes.rightdragstart
    b === Mouse.middle && return MouseEventTypes.middledragstart
    return error("No recognized mouse button $b")
end

function to_drag_stop_event(b::Mouse.Button)
    b === Mouse.left && return MouseEventTypes.leftdragstop
    b === Mouse.right && return MouseEventTypes.rightdragstop
    b === Mouse.middle && return MouseEventTypes.middledragstop
    return error("No recognized mouse button $b")
end

function to_down_event(b::Mouse.Button)
    b === Mouse.left && return MouseEventTypes.leftdown
    b === Mouse.right && return MouseEventTypes.rightdown
    b === Mouse.middle && return MouseEventTypes.middledown
    return error("No recognized mouse button $b")
end

function to_up_event(b::Mouse.Button)
    b === Mouse.left && return MouseEventTypes.leftup
    b === Mouse.right && return MouseEventTypes.rightup
    b === Mouse.middle && return MouseEventTypes.middleup
    return error("No recognized mouse button $b")
end

function to_doubleclick_event(b::Mouse.Button)
    b === Mouse.left && return MouseEventTypes.leftdoubleclick
    b === Mouse.right && return MouseEventTypes.rightdoubleclick
    b === Mouse.middle && return MouseEventTypes.middledoubleclick
    return error("No recognized mouse button $b")
end

function to_click_event(b::Mouse.Button)
    b === Mouse.left && return MouseEventTypes.leftclick
    b === Mouse.right && return MouseEventTypes.rightclick
    b === Mouse.middle && return MouseEventTypes.middleclick
    return error("No recognized mouse button $b")
end

function _addmouseevents!(scene, is_mouse_over_relevant_area, priority)
    Mouse = Makie.Mouse
    dblclick_max_interval = 0.2

    mouseevent = Observable{MouseEvent}(
        MouseEvent(MouseEventTypes.out, 0.0, Point2d(0, 0), Point2f(0, 0), 0.0, Point2d(0, 0), Point2f(0, 0))
    )
    # initialize state variables
    last_mouseevent = Ref{Mouse.Action}(Mouse.release)
    prev_data = Ref(mouseposition(scene))
    prev_px = Ref(Makie.mouseposition_px(scene))
    mouse_downed_inside = Ref(false)
    mouse_downed_button = Ref{Optional{Mouse.Button}}(nothing)
    drag_ongoing = Ref(false)
    mouse_downed_at = Ref(Point2d(0, 0)) # store the position of mouse down so drags only start after some threshold
    drag_threshold = 2.0 # mouse needs to move this distance before a drag starts, otherwise it's easy to drag instead of click on trackpads
    mouse_was_inside = Ref(false)
    prev_t = Ref(0.0)
    t_last_click = Ref(0.0)
    b_last_click = Ref{Optional{Mouse.Button}}(nothing)
    last_click_was_double = Ref(false)

    # react to mouse position changes
    mousepos_observerfunc = on(scene, events(scene).mouseposition; priority = priority) do mp
        consumed = false
        t = time()
        data = mouseposition(scene)
        px = mouseposition_px(scene)
        mouse_inside = is_mouse_over_relevant_area()

        # last_mouseevent can only be up or down

        # mouse moved while being pressed
        # this can mean a new drag started, or a drag continues if it is ongoing.
        # it can also mean that a drag that started outside and isn't related to this
        # object is going across it and should be ignored here
        if last_mouseevent[] == Mouse.press && _isstandardmousebutton(mouse_downed_button[])

            if drag_ongoing[]
                # continue the drag
                event = to_drag_event(mouse_downed_button[])
                x = setindex!(
                    mouseevent,
                    MouseEvent(event, t, data, px, prev_t[], prev_data[], prev_px[])
                )
                consumed = consumed || x
            else
                # mouse was downed inside but no drag is ongoing
                # that means a drag started
                if mouse_downed_inside[] && norm(mouse_downed_at[] - px) >= drag_threshold
                    drag_ongoing[] = true
                    event = to_drag_start_event(mouse_downed_button[])
                    x = setindex!(
                        mouseevent,
                        MouseEvent(event, t, data, px, prev_t[], prev_data[], prev_px[])
                    )
                    consumed = consumed || x

                    event = to_drag_event(mouse_downed_button[])
                    x = setindex!(
                        mouseevent,
                        MouseEvent(event, t, data, px, prev_t[], prev_data[], prev_px[])
                    )
                    consumed = consumed || x
                end
            end
        else
            if mouse_inside
                x = if mouse_was_inside[]
                    setindex!(
                        mouseevent,
                        MouseEvent(MouseEventTypes.over, t, data, px, prev_t[], prev_data[], prev_px[])
                    )
                else
                    setindex!(
                        mouseevent,
                        MouseEvent(MouseEventTypes.enter, t, data, px, prev_t[], prev_data[], prev_px[])
                    )
                end
                consumed = consumed || x
            else
                if mouse_was_inside[]
                    x = setindex!(
                        mouseevent,
                        MouseEvent(MouseEventTypes.out, t, data, px, prev_t[], prev_data[], prev_px[])
                    )
                    consumed = consumed || x
                end
            end
        end

        mouse_was_inside[] = mouse_inside
        prev_data[] = data
        prev_px[] = px
        prev_t[] = t
        return Consume(consumed)
    end


    # react to mouse button changes
    mousedrag_observerfunc = on(scene, events(scene).mousebutton, priority = priority) do event
        consumed = false
        t = time()
        data = prev_data[]
        px = prev_px[]

        # TODO: this could probably be simplified by just using event.button
        # though that would probably change the way this handles a bit
        pressed_buttons = events(scene).mousebuttonstate
        # mouse went down, this can either happen inside or outside the objects of interest
        # we also only react if one button is pressed, because otherwise things go crazy (pressed left button plus clicks from other buttons in between are not allowed, e.g.)
        if event.action == Mouse.press && !isempty(pressed_buttons) && _isstandardmousebutton(first(pressed_buttons))
            if length(pressed_buttons) == 1
                button = first(pressed_buttons)
                mouse_downed_button[] = button

                if mouse_was_inside[]
                    mouse_downed_at[] = px
                    event = to_down_event(mouse_downed_button[])
                    x = setindex!(
                        mouseevent,
                        MouseEvent(event, t, data, px, prev_t[], prev_data[], prev_px[])
                    )
                    consumed = consumed || x
                    mouse_downed_inside[] = true
                else
                    mouse_downed_inside[] = false
                    x = setindex!(
                        mouseevent,
                        MouseEvent(MouseEventTypes.downoutside, t, data, px, prev_t[], prev_data[], prev_px[])
                    )
                    consumed = consumed || x
                end
            end
            last_mouseevent[] = Mouse.press
        elseif event.action == Mouse.release && _isstandardmousebutton(mouse_downed_button[])
            # only register up events and clicks if the upped button matches
            # the recorded downed one
            # and it can't be nothing (if the first up event comes from outside)

            downed_button_missing_from_pressed = !(mouse_downed_button[] in pressed_buttons)
            some_mouse_button_had_been_downed = !isnothing(mouse_downed_button[])

            if downed_button_missing_from_pressed && some_mouse_button_had_been_downed

                if drag_ongoing[]
                    event = to_drag_stop_event(mouse_downed_button[])
                    x = setindex!(
                        mouseevent,
                        MouseEvent(event, t, data, px, prev_t[], prev_data[], prev_px[])
                    )
                    consumed = consumed || x
                    drag_ongoing[] = false

                    if mouse_was_inside[]
                        # up after drag done over element
                        event = to_up_event(mouse_downed_button[])
                        x = setindex!(
                            mouseevent,
                            MouseEvent(event, t, data, px, prev_t[], prev_data[], prev_px[])
                        )
                        consumed = consumed || x
                    else
                        # mouse could be not over elements after drag is over
                        x = setindex!(
                            mouseevent,
                            MouseEvent(MouseEventTypes.out, t, data, px, prev_t[], prev_data[], prev_px[])
                        )
                        consumed = consumed || x
                    end
                else
                    if mouse_was_inside[]
                        dt_last_click = t - t_last_click[]
                        t_last_click[] = t

                        # guard against mouse coming in from outside, then mouse upping
                        if mouse_downed_inside[]
                            if dt_last_click < dblclick_max_interval && !last_click_was_double[] &&
                                    mouse_downed_button[] == b_last_click[]

                                event = to_doubleclick_event(mouse_downed_button[])
                                x = setindex!(
                                    mouseevent,
                                    MouseEvent(event, t, data, px, prev_t[], prev_data[], prev_px[])
                                )
                                consumed = consumed || x
                                last_click_was_double[] = true
                            else
                                event = to_click_event(mouse_downed_button[])
                                x = setindex!(
                                    mouseevent,
                                    MouseEvent(event, t, data, px, prev_t[], prev_data[], prev_px[])
                                )
                                consumed = consumed || x
                                last_click_was_double[] = false
                            end
                            # save what type the last downed button was
                            b_last_click[] = mouse_downed_button[]
                        end
                        mouse_downed_inside[] = false

                        # up after click
                        event = to_up_event(mouse_downed_button[])
                        x = setindex!(
                            mouseevent,
                            MouseEvent(event, t, data, px, prev_t[], prev_data[], prev_px[])
                        )
                        consumed = consumed || x
                    end
                end
            end

            last_mouseevent[] = Mouse.release
        end


        prev_t[] = t
        return Consume(consumed)
    end

    return MouseEventHandle(mouseevent, [mousepos_observerfunc, mousedrag_observerfunc])
end
