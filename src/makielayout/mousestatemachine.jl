abstract type AbstractMouseState end

"""
    MouseState{T<:AbstractMouseState}

Describes a mouse state change.
Fields:
- `typ`: Symbol describing the mouse state
- `t`: Time of the event
- `pos`: Mouse position
- `tprev`: Time of previous event
- `prev`: Previous mouse position
"""
struct MouseState{T<:AbstractMouseState}
    typ::T
    t::Float64
    pos::Point2f0
    tprev::Float64
    prev::Point2f0
end

mousestates = (:MouseOut, :MouseEnter, :MouseOver,
    :MouseLeftDown, :MouseRightDown, :MouseMiddleDown,
    :MouseLeftUp, :MouseRightUp, :MouseMiddleUp,
    :MouseLeftDragStart, :MouseRightDragStart, :MouseMiddleDragStart,
    :MouseLeftDrag, :MouseRightDrag, :MouseMiddleDrag,
    :MouseLeftDragStop, :MouseRightDragStop, :MouseMiddleDragStop,
    :MouseLeftClick, :MouseRightClick, :MouseMiddleClick,
    :MouseLeftDoubleclick, :MouseRightDoubleclick, :MouseMiddleDoubleclick,
    :MouseDownOutside
    )

for statetype in mousestates
    onfunctionname = Symbol("on" * lowercase(String(statetype)))
    @eval begin
        struct $statetype <: AbstractMouseState end

        """
        Executes the function f whenever the `Node{MouseState}` statenode transitions
        to `$($statetype)`.
        """
        function $onfunctionname(f, statenode::Node{MouseState})
            on(statenode) do state
                if state.typ isa $statetype
                    f(state)
                end
            end
        end
        export $onfunctionname
    end
end


function Base.show(io::IO, ms::MouseState{T}) where T
    print(io, "$T(t: $(ms.t), pos: $(ms.pos[1]), $(ms.pos[2]), tprev: $(ms.tprev), prev: $(ms.prev[1]), $(ms.prev[2]))")
end

"""
    addmousestate!(scene, elements...)

Returns an `Observable{MouseState}` which is triggered by all mouse
interactions with the `scene` and optionally restricted to all given
plot objects in `elements`.

To react to mouse events, use the onmouse... handlers.

Example:

```
mousestate = addmousestate!(scene, scatterplot)

onmouseleftclick(mousestate) do state
    # do something with the mousestate
end
```
"""
function addmousestate!(scene, elements...)

    Mouse = AbstractPlotting.Mouse
    dblclick_max_interval = 0.2    

    mousestate = Node{MouseState}(MouseState(MouseOut(), 0.0, Point2f0(0, 0), 0.0, Point2f0(0, 0)))

    is_mouse_over_relevant_area() = isempty(elements) ? AbstractPlotting.is_mouseinside(scene) : mouseover(scene, elements...)


    # initialize state variables
    last_mousestate = Ref{Mouse.DragEnum}(events(scene).mousedrag[])
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
        if last_mousestate[] == Mouse.pressed
            # must have been a registered drag (otherwise could have come from outside)
            if drag_ongoing[]
                event = @match mouse_downed_button[] begin
                    Mouse.left => MouseLeftDrag()
                    Mouse.right => MouseRightDrag()
                    Mouse.middle => MouseMiddleDrag()
                    x => error("No recognized mouse button $x")
                end
                mousestate[] = MouseState(event, t, pos, tprev[], prev[])
            end
        # mouse moved while just having been pressed down
        elseif last_mousestate[] == Mouse.down
            # mouse must have been downed inside
            # that means a drag started
            if mouse_downed_inside[]
                drag_ongoing[] = true
                event = @match mouse_downed_button[] begin
                    Mouse.left => MouseLeftDragStart()
                    Mouse.right => MouseRightDragStart()
                    Mouse.middle => MouseMiddleDragStart()
                    x => error("No recognized mouse button $x")
                end
                mousestate[] = MouseState(event, t, pos, tprev[], prev[])

                event = @match mouse_downed_button[] begin
                    Mouse.left => MouseLeftDrag()
                    Mouse.right => MouseRightDrag()
                    Mouse.middle => MouseMiddleDrag()
                    x => error("No recognized mouse button $x")
                end
                mousestate[] = MouseState(event, t, pos, tprev[], prev[])
            end
        else
            if mouse_inside
                if mouse_was_inside[]
                    mousestate[] = MouseState(MouseOver(), t, pos, tprev[], prev[])
                else
                    mousestate[] = MouseState(MouseEnter(), t, pos, tprev[], prev[])
                end
            else
                if mouse_was_inside[]
                    mousestate[] = MouseState(MouseOut(), t, pos, tprev[], prev[])
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
                        Mouse.left => MouseLeftDown()
                        Mouse.right => MouseRightDown()
                        Mouse.middle => MouseMiddleDown()
                        x => error("No recognized mouse button $x")
                    end
                    mousestate[] = MouseState(event, t, pos, tprev[], prev[])
                    mouse_downed_inside[] = true
                else
                    mouse_downed_inside[] = false
                    mousestate[] = MouseState(MouseDownOutside(), t, pos, tprev[], prev[])
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
                        Mouse.left => MouseLeftDragStop()
                        Mouse.right => MouseRightDragStop()
                        Mouse.middle => MouseMiddleDragStop()
                        x => error("No recognized mouse button $x")
                    end
                    mousestate[] = MouseState(event, t, pos, tprev[], prev[])
                    drag_ongoing[] = false

                    if mouse_was_inside[]
                        # up after drag done over element
                        event = @match mouse_downed_button[] begin
                            Mouse.left => MouseLeftUp()
                            Mouse.right => MouseRightUp()
                            Mouse.middle => MouseMiddleUp()
                            x => error("No recognized mouse button $x")
                        end

                        mousestate[] = MouseState(event, t, pos, tprev[], prev[])
                    else
                        # mouse could be not over elements after drag is over
                        mousestate[] = MouseState(MouseOut(), t, pos, tprev[], prev[])
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
                                    Mouse.left => MouseLeftDoubleclick()
                                    Mouse.right => MouseRightDoubleclick()
                                    Mouse.middle => MouseMiddleDoubleclick()
                                    x => error("No recognized mouse button $x")
                                end
                                mousestate[] = MouseState(event, t, pos, tprev[], prev[])
                                last_click_was_double[] = true
                            else
                                event = @match mouse_downed_button[] begin
                                    Mouse.left => MouseLeftClick()
                                    Mouse.right => MouseRightClick()
                                    Mouse.middle => MouseMiddleClick()
                                    x => error("No recognized mouse button $x")
                                end
                                mousestate[] = MouseState(event, t, pos, tprev[], prev[])
                                last_click_was_double[] = false
                            end
                            # save what type the last downed button was
                            b_last_click[] = mouse_downed_button[]
                        end
                        mouse_downed_inside[] = false

                        # up after click
                        event = @match mouse_downed_button[] begin
                            Mouse.left => MouseLeftUp()
                            Mouse.right => MouseRightUp()
                            Mouse.middle => MouseMiddleUp()
                            x => error("No recognized mouse button $x")
                        end

                        mousestate[] = MouseState(event, t, pos, tprev[], prev[])
                    end
                end

                
            end
        end
            

        last_mousestate[] = mousedrag
        tprev[] = t
    end

    mousestate
end
