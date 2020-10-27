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
- `pos`: Mouse position
- `tprev`: Time of previous event
- `prev`: Previous mouse position
"""
struct MouseEvent
    type::MouseEventType
    t::Float64
    pos::Point2f0
    tprev::Float64
    prev::Point2f0
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

    mouseevent = Node{MouseEvent}(MouseEvent(MouseEventTypes.out, 0.0, Point2f0(0, 0), 0.0, Point2f0(0, 0)))

    is_mouse_over_relevant_area() = isempty(elements) ? AbstractPlotting.is_mouseinside(scene) : mouseover(scene, elements...)


    # initialize state variables
    last_mouseevent = Ref{Mouse.DragEnum}(events(scene).mousedrag[])
    prev = Ref(mouseposition(AbstractPlotting.rootparent(scene)))
    mouse_downed_inside = Ref(false)
    mouse_downed_button = Ref{Optional{Mouse.Button}}(nothing)
    drag_ongoing = Ref(false)
    mouse_was_inside = Ref(false)
    tprev = Ref(0.0)
    t_last_click = Ref(0.0)
    b_last_click = Ref{Optional{Mouse.Button}}(nothing)
    last_click_was_double = Ref(false)


    # react to mouse position changes
    on(events(scene).mouseposition) do mp

        t = time()
        pos = mouseposition(AbstractPlotting.rootparent(scene))
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
                mouseevent[] = MouseEvent(event, t, pos, tprev[], prev[])
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
                mouseevent[] = MouseEvent(event, t, pos, tprev[], prev[])

                event = @match mouse_downed_button[] begin
                    Mouse.left => MouseEventTypes.leftdrag
                    Mouse.right => MouseEventTypes.rightdrag
                    Mouse.middle => MouseEventTypes.middledrag
                    x => error("No recognized mouse button $x")
                end
                mouseevent[] = MouseEvent(event, t, pos, tprev[], prev[])
            end
        else
            if mouse_inside
                if mouse_was_inside[]
                    mouseevent[] = MouseEvent(MouseEventTypes.over, t, pos, tprev[], prev[])
                else
                    mouseevent[] = MouseEvent(MouseEventTypes.enter, t, pos, tprev[], prev[])
                end
            else
                if mouse_was_inside[]
                    mouseevent[] = MouseEvent(MouseEventTypes.out, t, pos, tprev[], prev[])
                end
            end
        end

        mouse_was_inside[] = mouse_inside
        prev[] = pos
        tprev[] = t
    end


    # react to mouse button changes
    on(events(scene).mousedrag) do mousedrag
        
        t = time()
        pos = prev[]

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
                    mouseevent[] = MouseEvent(event, t, pos, tprev[], prev[])
                    mouse_downed_inside[] = true
                else
                    mouse_downed_inside[] = false
                    mouseevent[] = MouseEvent(MouseEventTypes.downoutside, t, pos, tprev[], prev[])
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
                    mouseevent[] = MouseEvent(event, t, pos, tprev[], prev[])
                    drag_ongoing[] = false

                    if mouse_was_inside[]
                        # up after drag done over element
                        event = @match mouse_downed_button[] begin
                            Mouse.left => MouseEventTypes.leftup
                            Mouse.right => MouseEventTypes.rightup
                            Mouse.middle => MouseEventTypes.middleup
                            x => error("No recognized mouse button $x")
                        end

                        mouseevent[] = MouseEvent(event, t, pos, tprev[], prev[])
                    else
                        # mouse could be not over elements after drag is over
                        mouseevent[] = MouseEvent(MouseEventTypes.out, t, pos, tprev[], prev[])
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
                                mouseevent[] = MouseEvent(event, t, pos, tprev[], prev[])
                                last_click_was_double[] = true
                            else
                                event = @match mouse_downed_button[] begin
                                    Mouse.left => MouseEventTypes.leftclick
                                    Mouse.right => MouseEventTypes.rightclick
                                    Mouse.middle => MouseEventTypes.middleclick
                                    x => error("No recognized mouse button $x")
                                end
                                mouseevent[] = MouseEvent(event, t, pos, tprev[], prev[])
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

                        mouseevent[] = MouseEvent(event, t, pos, tprev[], prev[])
                    end
                end

                
            end
        end
            

        last_mouseevent[] = mousedrag
        tprev[] = t
    end

    mouseevent
end
