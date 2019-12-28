abstract type AbstractMouseState end

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

function addmousestate!(scene, elements...)

    Mouse = AbstractPlotting.Mouse

    mouse_downed_inside = Ref(false)
    mouse_downed_button = Ref{Optional{Mouse.Button}}(nothing)
    drag_ongoing = Ref(false)
    mouse_was_inside = Ref(false)
    prev = Ref(Point2f0(0, 0))
    tprev = Ref(0.0)
    t_last_click = Ref(0.0)
    b_last_click = Ref{Optional{Mouse.Button}}(nothing)
    dblclick_max_interval = 0.2
    last_click_was_double = Ref(false)

    mousestate = Node{MouseState}(MouseState(MouseOut(), 0.0, Point2f0(0, 0), 0.0, Point2f0(0, 0)))

    is_mouse_over_relevant_area() = isempty(elements) ? AbstractPlotting.is_mouseinside(scene) : mouseover(scene, elements...)

    onany(events(scene).mouseposition, events(scene).mousedrag) do mp, dragstate
        pos = mouseposition(AbstractPlotting.rootparent(scene))
        pressed_buttons = events(scene).mousebuttons[]
        t = time()

        if drag_ongoing[]
            if dragstate == Mouse.pressed
                event = @match mouse_downed_button[] begin
                    Mouse.left => MouseLeftDrag()
                    Mouse.right => MouseRightDrag()
                    Mouse.middle => MouseMiddleDrag()
                    x => error("No recognized mouse button $x")
                end
                mousestate[] = MouseState(event, t, pos, tprev[], prev[])
            else
                event = @match mouse_downed_button[] begin
                    Mouse.left => MouseLeftDragStop()
                    Mouse.right => MouseRightDragStop()
                    Mouse.middle => MouseMiddleDragStop()
                    x => error("No recognized mouse button $x")
                end
                mousestate[] = MouseState(event, t, pos, tprev[], prev[])

                event = @match mouse_downed_button[] begin
                    Mouse.left => MouseLeftUp()
                    Mouse.right => MouseRightUp()
                    Mouse.middle => MouseMiddleUp()
                    x => error("No recognized mouse button $x")
                end
                mousestate[] = MouseState(event, t, pos, tprev[], prev[])
                mouse_downed_inside[] = false
                # check after drag is over if we're also outside of the element now
                if !is_mouse_over_relevant_area()
                    mousestate[] = MouseState(MouseOut(), t, pos, tprev[], prev[])
                    mouse_was_inside[] = false
                else
                    mousestate[] = MouseState(MouseOver(), t, pos, tprev[], prev[])
                end
                drag_ongoing[] = false
            end

        # no dragging already ongoing
        else
            if is_mouse_over_relevant_area()
                # guard against mouse coming in from outside when pressed
                if !mouse_was_inside[] && dragstate != Mouse.pressed
                    mousestate[] = MouseState(MouseEnter(), t, pos, tprev[], prev[])
                    mouse_was_inside[] = true
                end

                if dragstate == Mouse.down
                    # don't do anything if multiple buttons are pressed
                    if length(pressed_buttons) == 1
                        # guard against pressed mouse dragged in from somewhere else

                        b = first(pressed_buttons)
                        if isnothing(b)
                            return
                        end
                        mouse_downed_inside[] = true
                        mouse_downed_button[] = b
                        event = @match b begin
                            Mouse.left => MouseLeftDown()
                            Mouse.right => MouseRightDown()
                            Mouse.middle => MouseMiddleDown()
                            x => error("No recognized mouse button $x")
                        end
                        mousestate[] = MouseState(event, t, pos, tprev[], prev[])
                    end

                elseif dragstate == Mouse.up
                    # only register up events and clicks if the upped button matches
                    # the recorded downed one
                    # and it can't be nothing (if the first up event comes from outside)
                    if !(mouse_downed_button[] in pressed_buttons) && !isnothing(mouse_downed_button[])

                        event = @match mouse_downed_button[] begin
                            Mouse.left => MouseLeftUp()
                            Mouse.right => MouseRightUp()
                            Mouse.middle => MouseMiddleUp()
                            x => error("No recognized mouse button $x")
                        end

                        mousestate[] = MouseState(event, t, pos, tprev[], prev[])
                        t = time()
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

                        if is_mouse_over_relevant_area()
                            # something could have moved after the click
                            mousestate[] = MouseState(MouseOver(), t, pos, tprev[], prev[])
                        else
                            mousestate[] = MouseState(MouseOut(), t, pos, tprev[], prev[])
                            mouse_was_inside[] = false
                        end
                    end

                elseif dragstate == Mouse.pressed && mouse_downed_inside[]
                    event = @match mouse_downed_button[] begin
                        Mouse.left => MouseLeftDragStart()
                        Mouse.right => MouseRightDragStart()
                        Mouse.middle => MouseMiddleDragStart()
                        x => error("No recognized mouse button $x")
                    end
                    mousestate[] = MouseState(event, t, pos, tprev[], prev[])
                    drag_ongoing[] = true
                elseif dragstate == Mouse.notpressed
                    mousestate[] = MouseState(MouseOver(), t, pos, tprev[], prev[])
                end
            else
                if mouse_was_inside[]
                    mousestate[] = MouseState(MouseOut(), t, pos, tprev[], prev[])
                    mouse_was_inside[] = false
                end
            end
        end

        prev[] = pos
        tprev[] = t
    end

    mousestate
end
