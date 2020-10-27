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
    data::Point2f0
    px::Point2f0
    prev_t::Float64
    prev_data::Point2f0
    prev_px::Point2f0
end



for eventtype in instances(MouseEventType)
    onfunctionname = Symbol("onmouse" * String(Symbol(eventtype)))
    @eval begin

        """
        Executes the function f whenever the `Node{MouseEvent}` statenode transitions
        to `$($eventtype)`.
        """
        function $onfunctionname(f, statenode::Node{MouseEvent})
            on(statenode) do state
                if state.type === $eventtype
                    f(state)
                end
            end
        end
        export $onfunctionname
    end
end


"""
    addmouseevents!(scene, elements...)

Returns an `Observable{MouseEvent}` which is triggered by all mouse
interactions with the `scene` and optionally restricted to all given
plot objects in `elements`.

To react to mouse events, use the onmouse... handlers.

Example:

```
mouseevents = addmouseevents!(scene, scatterplot)

onmouseleftclick(mouseevents) do event
    # do something with the mouseevent
end
```
"""
function addmouseevents!(scene, elements...)

    Mouse = AbstractPlotting.Mouse
    dblclick_max_interval = 0.2    

    mouseevent = Node{MouseEvent}(MouseEvent(MouseEventTypes.out, 0.0, Point2f0(0, 0), Point2f0(0, 0), 0.0, Point2f0(0, 0), Point2f0(0, 0)))

    is_mouse_over_relevant_area() = isempty(elements) ? AbstractPlotting.is_mouseinside(scene) : mouseover(scene, elements...)


    # initialize state variables
    last_mouseevent = Ref{Mouse.DragEnum}(events(scene).mousedrag[])
    prev_data = Ref(mouseposition(scene))
    prev_px = Ref(AbstractPlotting.mouseposition_px(scene))
    mouse_downed_inside = Ref(false)
    mouse_downed_button = Ref{Optional{Mouse.Button}}(nothing)
    drag_ongoing = Ref(false)
    mouse_was_inside = Ref(false)
    prev_t = Ref(0.0)
    t_last_click = Ref(0.0)
    b_last_click = Ref{Optional{Mouse.Button}}(nothing)
    last_click_was_double = Ref(false)


    # react to mouse position changes
    on(events(scene).mouseposition) do mp

        t = time()
        data = mouseposition(scene)
        px = AbstractPlotting.mouseposition_px(scene)
        mouse_inside = is_mouse_over_relevant_area()

        # movement while mouse is pressed
        if last_mouseevent[] == Mouse.pressed
            # must have been a registered drag (otherwise could have come from outside)
            if drag_ongoing[]
                event = @match mouse_downed_button[] begin
                    Mouse.left => MouseEventTypes.leftdrag
                    Mouse.right => MouseEventTypes.rightdrag
                    Mouse.middle => MouseEventTypes.middledrag
                    x => error("No recognized mouse button $x")
                end
                mouseevent[] = MouseEvent(event, t, data, px, prev_t[], prev_data[], prev_px[])
            end
        # mouse moved while just having been pressed down
        elseif last_mouseevent[] == Mouse.down
            # mouse must have been downed inside
            # that means a drag started
            if mouse_downed_inside[]
                drag_ongoing[] = true
                event = @match mouse_downed_button[] begin
                    Mouse.left => MouseEventTypes.leftdragstart
                    Mouse.right => MouseEventTypes.rightdragstart
                    Mouse.middle => MouseEventTypes.middledragstart
                    x => error("No recognized mouse button $x")
                end
                mouseevent[] = MouseEvent(event, t, data, px, prev_t[], prev_data[], prev_px[])

                event = @match mouse_downed_button[] begin
                    Mouse.left => MouseEventTypes.leftdrag
                    Mouse.right => MouseEventTypes.rightdrag
                    Mouse.middle => MouseEventTypes.middledrag
                    x => error("No recognized mouse button $x")
                end
                mouseevent[] = MouseEvent(event, t, data, px, prev_t[], prev_data[], prev_px[])
            end
        else
            if mouse_inside
                if mouse_was_inside[]
                    mouseevent[] = MouseEvent(MouseEventTypes.over, t, data, px, prev_t[], prev_data[], prev_px[])
                else
                    mouseevent[] = MouseEvent(MouseEventTypes.enter, t, data, px, prev_t[], prev_data[], prev_px[])
                end
            else
                if mouse_was_inside[]
                    mouseevent[] = MouseEvent(MouseEventTypes.out, t, data, px, prev_t[], prev_data[], prev_px[])
                end
            end
        end

        mouse_was_inside[] = mouse_inside
        prev_data[] = data
        prev_px[] = px
        prev_t[] = t
    end


    # react to mouse button changes
    on(events(scene).mousedrag) do mousedrag
        
        t = time()
        data = prev_data[]
        px = prev_px[]

        pressed_buttons = events(scene).mousebuttons[]

        # we only need to handle mousedown and mouseup
        # pressed and not pressed are redundant events with mouse position changes
        if mousedrag == Mouse.down
            if length(pressed_buttons) == 1
                button = only(pressed_buttons)
                mouse_downed_button[] = button

                if mouse_was_inside[]
                    event = @match mouse_downed_button[] begin
                        Mouse.left => MouseEventTypes.leftdown
                        Mouse.right => MouseEventTypes.rightdown
                        Mouse.middle => MouseEventTypes.middledown
                        x => error("No recognized mouse button $x")
                    end
                    mouseevent[] = MouseEvent(event, t, data, px, prev_t[], prev_data[], prev_px[])
                    mouse_downed_inside[] = true
                else
                    mouse_downed_inside[] = false
                    mouseevent[] = MouseEvent(MouseEventTypes.downoutside, t, data, px, prev_t[], prev_data[], prev_px[])
                end
            end
        elseif mousedrag == Mouse.up
            # only register up events and clicks if the upped button matches
            # the recorded downed one
            # and it can't be nothing (if the first up event comes from outside)

            downed_button_missing_from_pressed = !(mouse_downed_button[] in pressed_buttons)
            some_mouse_button_had_been_downed = !isnothing(mouse_downed_button[])

            if downed_button_missing_from_pressed && some_mouse_button_had_been_downed

                if drag_ongoing[]
                    event = @match mouse_downed_button[] begin
                        Mouse.left => MouseEventTypes.leftdragstop
                        Mouse.right => MouseEventTypes.rightdragstop
                        Mouse.middle => MouseEventTypes.middledragstop
                        x => error("No recognized mouse button $x")
                    end
                    mouseevent[] = MouseEvent(event, t, data, px, prev_t[], prev_data[], prev_px[])
                    drag_ongoing[] = false

                    if mouse_was_inside[]
                        # up after drag done over element
                        event = @match mouse_downed_button[] begin
                            Mouse.left => MouseEventTypes.leftup
                            Mouse.right => MouseEventTypes.rightup
                            Mouse.middle => MouseEventTypes.middleup
                            x => error("No recognized mouse button $x")
                        end

                        mouseevent[] = MouseEvent(event, t, data, px, prev_t[], prev_data[], prev_px[])
                    else
                        # mouse could be not over elements after drag is over
                        mouseevent[] = MouseEvent(MouseEventTypes.out, t, data, px, prev_t[], prev_data[], prev_px[])
                    end
                else
                    if mouse_was_inside[]
                        dt_last_click = t - t_last_click[]
                        t_last_click[] = t

                        # guard against mouse coming in from outside, then mouse upping
                        if mouse_downed_inside[]
                            if dt_last_click < dblclick_max_interval && !last_click_was_double[] &&
                                    mouse_downed_button[] == b_last_click[]

                                event = @match mouse_downed_button[] begin
                                    Mouse.left => MouseEventTypes.leftdoubleclick
                                    Mouse.right => MouseEventTypes.rightdoubleclick
                                    Mouse.middle => MouseEventTypes.middledoubleclick
                                    x => error("No recognized mouse button $x")
                                end
                                mouseevent[] = MouseEvent(event, t, data, px, prev_t[], prev_data[], prev_px[])
                                last_click_was_double[] = true
                            else
                                event = @match mouse_downed_button[] begin
                                    Mouse.left => MouseEventTypes.leftclick
                                    Mouse.right => MouseEventTypes.rightclick
                                    Mouse.middle => MouseEventTypes.middleclick
                                    x => error("No recognized mouse button $x")
                                end
                                mouseevent[] = MouseEvent(event, t, data, px, prev_t[], prev_data[], prev_px[])
                                last_click_was_double[] = false
                            end
                            # save what type the last downed button was
                            b_last_click[] = mouse_downed_button[]
                        end
                        mouse_downed_inside[] = false

                        # up after click
                        event = @match mouse_downed_button[] begin
                            Mouse.left => MouseEventTypes.leftup
                            Mouse.right => MouseEventTypes.rightup
                            Mouse.middle => MouseEventTypes.middleup
                            x => error("No recognized mouse button $x")
                        end

                        mouseevent[] = MouseEvent(event, t, data, px, prev_t[], prev_data[], prev_px[])
                    end
                end

                
            end
        end
            

        last_mouseevent[] = mousedrag
        prev_t[] = t
    end

    mouseevent
end
