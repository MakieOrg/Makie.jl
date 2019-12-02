abstract type AbstractMouseState end

struct MouseState{T<:AbstractMouseState}
    typ::T
    t::Float64
    pos::Point2f0
    tprev::Float64
    prev::Point2f0
end

mousestates = (:MouseOut, :MouseEnter, :MouseOver, :MouseLeave, :MouseDown,
    :MouseUp, :MouseDragStart, :MouseDrag, :MouseDragStop,
    :MouseClick, :MouseDoubleclick)
    
for statetype in mousestates
    onfunctionname = Symbol("on" * lowercase(String(statetype)))
    @eval begin
        struct $statetype <: AbstractMouseState end

        function $onfunctionname(f, statenode::Node{MouseState})
            on(statenode) do state
                if state.typ isa $statetype
                    f(state)
                end
            end
        end
    end
end
# struct MouseOut <: AbstractMouseState end
# struct MouseEnter <: AbstractMouseState end
# struct MouseOver <: AbstractMouseState end
# struct MouseLeave <: AbstractMouseState end
# struct MouseDown <: AbstractMouseState end
# struct MouseUp <: AbstractMouseState end
# struct MouseDragStart <: AbstractMouseState end
# struct MouseDrag <: AbstractMouseState end
# struct MouseDragStop <: AbstractMouseState end
# struct MouseClick <: AbstractMouseState end
# struct MouseDoubleclick <: AbstractMouseState end

function Base.show(io::IO, ms::MouseState{T}) where T
    print(io, "$T(t: $(ms.t), pos: $(ms.pos[1]), $(ms.pos[2]), tprev: $(ms.tprev), prev: $(ms.prev[1]), $(ms.prev[2]))")
end

function addmousestate!(scene, element)

    Mouse = AbstractPlotting.Mouse

    mouse_downed_inside = Ref(false)
    drag_ongoing = Ref(false)
    mouse_was_inside = Ref(false)
    prev = Ref(Point2f0(0, 0))
    tprev = Ref(0.0)
    t_last_click = Ref(0.0)
    dblclick_max_interval = 0.2
    last_click_was_double = Ref(false)

    mousestate = Node{MouseState}(MouseState(MouseOut(), 0.0, Point2f0(0, 0), 0.0, Point2f0(0, 0)))

    onany(events(scene).mouseposition, events(scene).mousedrag) do mp, dragstate
        pos = mouseposition(AbstractPlotting.rootparent(scene))
        t = time()

        if drag_ongoing[]
            if dragstate == Mouse.pressed
                mousestate[] = MouseState(MouseDrag(), t, pos, tprev[], prev[])
            else
                # one last drag event
                mousestate[] = MouseState(MouseDrag(), t, pos, tprev[], prev[])
                mousestate[] = MouseState(MouseDragStop(), t, pos, tprev[], prev[])
                mousestate[] = MouseState(MouseUp(), t, pos, tprev[], prev[])
                mouse_downed_inside[] = false
                # check after drag is over if we're also outside of the element now
                if !mouseover(scene, element)
                    mousestate[] = MouseState(MouseLeave(), t, pos, tprev[], prev[])
                    mousestate[] = MouseState(MouseOut(), t, pos, tprev[], prev[])
                    mouse_was_inside[] = false
                else
                    mousestate[] = MouseState(MouseOver(), t, pos, tprev[], prev[])
                end
                drag_ongoing[] = false
            end
        # no dragging already ongoing
        else
            if mouseover(scene, element)
                # guard against mouse coming in from outside when pressed
                if !mouse_was_inside[] && dragstate != Mouse.pressed
                    mousestate[] = MouseState(MouseEnter(), t, pos, tprev[], prev[])
                    mouse_was_inside[] = true
                end

                if dragstate == Mouse.down
                    # guard against pressed mouse dragged in from somewhere else
                    mouse_downed_inside[] = true
                    mousestate[] = MouseState(MouseDown(), t, pos, tprev[], prev[])
                elseif dragstate == Mouse.up

                    mousestate[] = MouseState(MouseUp(), t, pos, tprev[], prev[])
                    t = time()
                    dt_last_click = t - t_last_click[]
                    t_last_click[] = t
                    # guard against mouse coming in from outside, then mouse upping
                    if mouse_downed_inside[]
                        if dt_last_click < dblclick_max_interval && !last_click_was_double[]
                            mousestate[] = MouseState(MouseDoubleclick(), t, pos, tprev[], prev[])
                            last_click_was_double[] = true
                        else
                            mousestate[] = MouseState(MouseClick(), t, pos, tprev[], prev[])
                            last_click_was_double[] = false
                        end
                    end
                    mouse_downed_inside[] = false
                    # trigger mouseposition event to determine what happens after the click
                    # the item might have moved?
                    events(scene).mouseposition[] = events(scene).mouseposition[]
                elseif dragstate == Mouse.pressed && mouse_downed_inside[]
                    mousestate[] = MouseState(MouseDragStart(), t, pos, tprev[], prev[])
                    drag_ongoing[] = true
                elseif dragstate == Mouse.notpressed
                    mousestate[] = MouseState(MouseOver(), t, pos, tprev[], prev[])
                end
            else
                if mouse_was_inside[]
                    mousestate[] = MouseState(MouseLeave(), t, pos, tprev[], prev[])
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
