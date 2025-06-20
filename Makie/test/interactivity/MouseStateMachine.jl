@testset "mouse state machine" begin
    scene = Scene(size = (800, 600))
    e = events(scene)
    bbox = Observable(Rect2(200, 200, 400, 300))
    msm = addmouseevents!(scene, bbox, priority = typemax(Int))
    eventlog = MouseEvent[]
    on(
        x -> begin
            push!(eventlog, x); false
        end, msm.obs
    )

    e.mouseposition[] = (0, 200)
    @test isempty(eventlog)

    # move inside
    e.mouseposition[] = (300, 200)
    @test length(eventlog) == 1
    @test eventlog[1].type == MouseEventTypes.enter
    @test eventlog[1].px == Point2f(300, 200)
    @test eventlog[1].prev_px == Point2f(0, 200)
    empty!(eventlog)

    # over
    e.mouseposition[] = (300, 300)
    @test length(eventlog) == 1
    @test eventlog[1].type == MouseEventTypes.over
    @test eventlog[1].px == Point2f(300, 300)
    @test eventlog[1].prev_px == Point2f(300, 200)
    empty!(eventlog)

    for button in (:left, :middle, :right)
        # click
        e.mousebutton[] = MouseButtonEvent(getfield(Mouse, button), Mouse.press)
        e.mouseposition[] = (301, 301) # small mouse deviations with pressed button shouldn't register as a drag and prohibit a click
        e.mouseposition[] = (300, 300)
        e.mousebutton[] = MouseButtonEvent(getfield(Mouse, button), Mouse.release)
        @test length(eventlog) == 3
        for (i, t) in enumerate(
                (
                    getfield(MouseEventTypes, Symbol(button, :down)),
                    getfield(MouseEventTypes, Symbol(button, :click)),
                    getfield(MouseEventTypes, Symbol(button, :up)),
                )
            )
            @test eventlog[i].type == t
            @test eventlog[i].px == Point2f(300, 300)
            @test eventlog[i].prev_px == Point2f(300, 300)
        end
        empty!(eventlog)

        # doubleclick
        e.mousebutton[] = MouseButtonEvent(getfield(Mouse, button), Mouse.press)
        e.mousebutton[] = MouseButtonEvent(getfield(Mouse, button), Mouse.release)
        @test length(eventlog) == 3
        for (i, t) in enumerate(
                (
                    getfield(MouseEventTypes, Symbol(button, :down)),
                    getfield(MouseEventTypes, Symbol(button, :doubleclick)),
                    getfield(MouseEventTypes, Symbol(button, :up)),
                )
            )
            @test eventlog[i].type == t
            @test eventlog[i].px == Point2f(300, 300)
            @test eventlog[i].prev_px == Point2f(300, 300)
        end
        empty!(eventlog)

        # triple click = click
        e.mousebutton[] = MouseButtonEvent(getfield(Mouse, button), Mouse.press)
        e.mousebutton[] = MouseButtonEvent(getfield(Mouse, button), Mouse.release)
        @test length(eventlog) == 3
        for (i, t) in enumerate(
                (
                    getfield(MouseEventTypes, Symbol(button, :down)),
                    getfield(MouseEventTypes, Symbol(button, :click)),
                    getfield(MouseEventTypes, Symbol(button, :up)),
                )
            )
            @test eventlog[i].type == t
            @test eventlog[i].px == Point2f(300, 300)
            @test eventlog[i].prev_px == Point2f(300, 300)
        end
        empty!(eventlog)

        # drag
        e.mousebutton[] = MouseButtonEvent(getfield(Mouse, button), Mouse.press)
        e.mouseposition[] = (500, 300)
        e.mouseposition[] = (700, 200)
        e.mousebutton[] = MouseButtonEvent(getfield(Mouse, button), Mouse.release)
        @test length(eventlog) == 6
        prev_px = Point2f[(300, 300), (300, 300), (300, 300), (500, 300), (700, 200), (700, 200)]
        px = Point2f[(300, 300), (500, 300), (500, 300), (700, 200), (700, 200), (700, 200)]
        for (i, t) in enumerate(
                (
                    getfield(MouseEventTypes, Symbol(button, :down)),
                    getfield(MouseEventTypes, Symbol(button, :dragstart)),
                    getfield(MouseEventTypes, Symbol(button, :drag)),
                    getfield(MouseEventTypes, Symbol(button, :drag)),
                    getfield(MouseEventTypes, Symbol(button, :dragstop)),
                    getfield(MouseEventTypes, :out),
                    # TODO this is kinda missing an "up outside"
                )
            )
            @test eventlog[i].type == t
            @test eventlog[i].px == px[i]
            @test eventlog[i].prev_px == prev_px[i]
        end
        e.mouseposition[] = (300, 300)
        empty!(eventlog)
    end

    # TODO: This should probably produce:
    # left down > right down > right click > right up > left up
    e.mousebutton[] = MouseButtonEvent(Mouse.left, Mouse.press)
    e.mousebutton[] = MouseButtonEvent(Mouse.right, Mouse.press)
    e.mousebutton[] = MouseButtonEvent(Mouse.right, Mouse.release)
    e.mousebutton[] = MouseButtonEvent(Mouse.left, Mouse.release)
    @test length(eventlog) == 3
    @test eventlog[1].type == MouseEventTypes.leftdown
    @test eventlog[2].type == MouseEventTypes.leftclick
    @test eventlog[3].type == MouseEventTypes.leftup
    empty!(eventlog)

    # double left up? :(
    e.mousebutton[] = MouseButtonEvent(Mouse.left, Mouse.press)
    e.mousebutton[] = MouseButtonEvent(Mouse.right, Mouse.press)
    e.mousebutton[] = MouseButtonEvent(Mouse.left, Mouse.release)
    e.mousebutton[] = MouseButtonEvent(Mouse.right, Mouse.release)
    @test length(eventlog) == 4
    @test eventlog[1].type == MouseEventTypes.leftdown
    @test eventlog[2].type == MouseEventTypes.leftdoubleclick
    @test eventlog[3].type == MouseEventTypes.leftup
    @test eventlog[4].type == MouseEventTypes.leftup
    empty!(eventlog)

    # This should probably produce a leftdragstop on right down instead of left up
    e.mouseposition[] = (300, 300)
    empty!(eventlog)
    e.mousebutton[] = MouseButtonEvent(Mouse.left, Mouse.press)
    e.mouseposition[] = (350, 350)
    e.mousebutton[] = MouseButtonEvent(Mouse.right, Mouse.press)
    e.mouseposition[] = (350, 400)
    e.mousebutton[] = MouseButtonEvent(Mouse.right, Mouse.release)
    e.mouseposition[] = (400, 400)
    e.mousebutton[] = MouseButtonEvent(Mouse.left, Mouse.release)
    @test length(eventlog) == 7
    @test eventlog[1].type == MouseEventTypes.leftdown
    @test eventlog[2].type == MouseEventTypes.leftdragstart
    @test eventlog[3].type == MouseEventTypes.leftdrag
    @test eventlog[4].type == MouseEventTypes.leftdrag
    @test eventlog[5].type == MouseEventTypes.over
    @test eventlog[6].type == MouseEventTypes.leftdragstop
    @test eventlog[7].type == MouseEventTypes.leftup
    @test eventlog[1].px == Point2f(300, 300)
    @test eventlog[2].px == Point2f(350, 350)
    @test eventlog[3].px == Point2f(350, 350)
    @test eventlog[4].px == Point2f(350, 400)
    @test eventlog[5].px == Point2f(400, 400)
    @test eventlog[6].px == Point2f(400, 400)
    @test eventlog[7].px == Point2f(400, 400)
    empty!(eventlog)
end
