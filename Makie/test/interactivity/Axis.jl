# TODO: test more?
@testset "Axis Interactions" begin
    Makie.PICK_TRACKING[] = true
    init = Makie._PICK_COUNTER[]

    @testset "Axis Interaction Interface" begin
        f = Figure(size = (400, 400))
        a = Axis(f[1, 1])
        e = events(f)

        names = (:rectanglezoom, :dragpan, :limitreset, :scrollzoom)
        @test keys(a.interactions) == Set(names)

        types = (Makie.RectangleZoom, Makie.DragPan, Makie.LimitReset, Makie.ScrollZoom)
        for (name, type) in zip(names, types)
            @test a.interactions[name][1] == true
            @test a.interactions[name][2] isa type
        end

        blocked = Observable(true)
        on(x -> blocked[] = false, e.scroll, priority = typemin(Int))

        @assert !is_mouseinside(a.scene)
        e.scroll[] = (0.0, 0.0)
        @test !blocked[]
        blocked[] = true
        e.scroll[] = (0.0, 1.0)
        @test !blocked[]

        blocked[] = true
        e.mouseposition[] = (200, 200)
        e.scroll[] = (0.0, 0.0)
        @test blocked[] # TODO: should it block?
        blocked[] = true
        e.scroll[] = (0.0, 1.0)
        @test blocked[]

        deactivate_interaction!.((a,), names)

        blocked[] = true
        e.scroll[] = (0.0, 0.0)
        @test !blocked[]
        blocked[] = true
        e.scroll[] = (0.0, 1.0)
        @test !blocked[]
    end

    @test init == Makie._PICK_COUNTER[]

    function cleanaxes()
        fig = Figure()
        ax = Axis(fig[1, 1])
        axbox = viewport(ax.scene)[]
        lim = ax.finallimits[]
        e = events(ax)
        return ax, axbox, lim, e
    end

    @testset "Axis zoom interactions" begin
        ax, axbox, lim, e = cleanaxes()

        @testset "Center zoom" begin
            e.mouseposition[] = Tuple(axbox.origin + axbox.widths / 2)

            # zoom in
            e.scroll[] = (0.0, 1.0)
            newlim = ax.finallimits[]
            @test newlim.widths ≈ 0.9 * lim.widths
            @test newlim.origin ≈ lim.origin + (lim.widths - newlim.widths) / 2

            # zoom out restores original position
            e.scroll[] = (0.0, -1.0)
            newlim = ax.finallimits[]
            @test newlim.widths ≈ lim.widths
            @test all(abs.(newlim.origin - lim.origin) .< 1.0e-7 * lim.widths)
        end

        @test init == Makie._PICK_COUNTER[]
        ax.finallimits[] = lim

        @testset "Corner zoom" begin
            e.mouseposition[] = Tuple(axbox.origin)

            # zoom in
            e.scroll[] = (0.0, 1.0)
            newlim = ax.finallimits[]
            @test newlim.widths ≈ 0.9 * lim.widths
            @test all(abs.(newlim.origin - lim.origin) .< 1.0e-7 * lim.widths)

            # zoom out
            e.scroll[] = (0.0, -1.0)
            newlim = ax.finallimits[]
            @test newlim.widths ≈ lim.widths
            @test all(abs.(newlim.origin - lim.origin) .< 1.0e-7 * lim.widths)
        end

        @test init == Makie._PICK_COUNTER[]
        ax.finallimits[] = lim

        # Zoom only x or y
        for (lockname, idx, zoomkey) in ((:xzoomlock, 1, :yzoomkey), (:yzoomlock, 2, :xzoomkey))
            ax, axbox, lim, e = cleanaxes()

            @testset "$lockname" begin
                lock = getproperty(ax, lockname)
                @test !lock[]

                # Zoom with lock
                lock[] = true
                e.mouseposition[] = Tuple(axbox.origin + axbox.widths / 2)
                e.scroll[] = (0.0, 1.0)
                newlim = ax.finallimits[]
                @test newlim.widths[idx] == lim.widths[idx]
                @test newlim.widths[3 - idx] ≈ 0.9 * lim.widths[3 - idx]
                @test newlim.origin[idx] == lim.origin[idx]
                @test newlim.origin[3 - idx] ≈ lim.origin[3 - idx] + (lim.widths[3 - idx] - newlim.widths[3 - idx]) / 2

                # Revert zoom
                e.scroll[] = (0.0, -1.0)
                newlim = ax.finallimits[]
                @test newlim.widths ≈ lim.widths
                @test all(abs.(newlim.origin - lim.origin) .< 1.0e-7 * lim.widths)
                ax.finallimits[] = lim
                lock[] = false
            end

            @testset "$zoomkey" begin
                @test isempty(e.keyboardstate)
                e.keyboardbutton[] = KeyEvent(getproperty(ax, zoomkey)[], Keyboard.press)

                # zoom with restriction
                e.scroll[] = (0.0, 1.0)
                newlim = ax.finallimits[]
                @test newlim.widths[idx] == lim.widths[idx]
                @test newlim.widths[3 - idx] ≈ 0.9 * lim.widths[3 - idx]
                @test newlim.origin[idx] == lim.origin[idx]
                @test newlim.origin[3 - idx] ≈ lim.origin[3 - idx] + (lim.widths[3 - idx] - newlim.widths[3 - idx]) / 2

                # Revert zoom
                e.scroll[] = (0.0, -1.0)
                newlim = ax.finallimits[]
                @test newlim.widths ≈ lim.widths
                @test all(abs.(newlim.origin - lim.origin) .< 1.0e-7 * lim.widths)
            end
        end

        @test init == Makie._PICK_COUNTER[]

        # Rubber band selection
        fig = Figure()
        ax = Axis(fig[1, 1])
        plot!(ax, [10, 15, 20])
        Makie.update_state_before_display!(fig)
        axbox = viewport(ax.scene)[]
        lim = ax.finallimits[]
        e = events(ax)

        @testset "Selection Rectangle" begin
            e.mouseposition[] = Tuple(axbox.origin)
            e.mousebutton[] = MouseButtonEvent(Mouse.left, Mouse.press)
            e.mouseposition[] = Tuple(axbox.origin + axbox.widths ./ Vec2(2, 3))
            e.mousebutton[] = MouseButtonEvent(Mouse.left, Mouse.release)
            newlim = ax.finallimits[]
            @test newlim.origin ≈ lim.origin atol = 1.0e-6
            @test newlim.widths ≈ lim.widths ./ Vec2(2, 3) atol = 1.0e-6
        end

        @testset "Log-scale selection rectangle" begin
            fig = Figure()
            log_axis = Axis(fig[1, 1]; yscale = log10, limits = (-20, 30, 1.0e-28, 2.0e6))
            x = range(0, 10; length = 500)
            lines!(log_axis, x, 1.0e-8 .* exp.(1.5 .* x))
            Makie.update_state_before_display!(fig)

            axbox = viewport(log_axis.scene)[]
            original_limits = log_axis.targetlimits[]
            log_events = events(log_axis)

            function select_rectangle!(from, to)
                log_events.mouseposition[] = Tuple(from)
                log_events.mousebutton[] = MouseButtonEvent(Mouse.left, Mouse.press)
                log_events.mouseposition[] = Tuple(to)
                log_events.mousebutton[] = MouseButtonEvent(Mouse.left, Mouse.release)
                return log_axis.targetlimits[]
            end

            above = axbox.origin + axbox.widths .* Vec2(0.25, 0.85)
            below = axbox.origin + axbox.widths .* Vec2(0.75, 0.25)
            above_to_below = select_rectangle!(above, below)

            log_axis.targetlimits[] = original_limits
            below_to_above = select_rectangle!(below, above)

            @test above_to_below ≈ below_to_above
            @test all(isfinite, minimum(above_to_below))
            @test all(isfinite, maximum(above_to_below))
            @test all(>(0), widths(above_to_below))
            @test Makie.validate_limits_for_scale(
                (minimum(above_to_below)[2], maximum(above_to_below)[2]), log10
            )

            rectanglezoom = log_axis.interactions[:rectanglezoom][2]
            crosses_lower_domain = Makie._clamp_rectanglezoom_limits(
                Rect2(0, 0, 1, 1.5e6), log_axis.finallimits[]
            )
            @test minimum(crosses_lower_domain)[2] == minimum(log_axis.finallimits[])[2]
            @test_logs min_level = Base.CoreLogging.Warn rectanglezoom.callback(crosses_lower_domain)
            @test log_axis.targetlimits[] == crosses_lower_domain

            @test_logs (:warn, r"Rectangle zoom ignored") rectanglezoom.callback(Rect2(0, 0, 1, 0))
            @test log_axis.targetlimits[] == crosses_lower_domain

            transform = Makie.transform_func(log_axis)
            inverse_transform = Makie.inverse_transform(transform)
            normalized = Makie._rectanglezoom_data_position(
                log_axis, Point2(0, -Inf), transform, inverse_transform
            )
            @test all(isfinite, normalized)
            @test normalized[2] in Makie.defined_interval(log10)
            @test log_axis.targetlimits[] == crosses_lower_domain
        end

        @testset "Log-scale scroll zoom limits" begin
            fig = Figure()
            scroll_axis = Axis(fig[1, 1]; yscale = log10)
            lines!(scroll_axis, 0:1, [1.0, 2.0])
            Makie.update_state_before_display!(fig)

            scroll_axis.targetlimits[] = Rect2(-20, 1.0e-318, 50, 1.0e245)
            original_limits = scroll_axis.targetlimits[]
            axis_box = viewport(scroll_axis.scene)[]
            events(scroll_axis).mouseposition[] = Tuple(axis_box.origin + axis_box.widths / 2)
            scrollzoom = scroll_axis.interactions[:scrollzoom][2]

            @test_logs min_level = Base.CoreLogging.Warn Makie.process_interaction(
                scrollzoom, ScrollEvent(0, -1), scroll_axis
            )
            @test scroll_axis.targetlimits[] == original_limits
        end

        @testset "Log-scale pan limits" begin
            fig = Figure()
            pan_axis = Axis(fig[1, 1]; yscale = log10)
            lines!(pan_axis, 0:1, [1.0, 2.0])
            Makie.update_state_before_display!(fig)

            # This range is still valid for log10, but a full-height pan makes
            # its transformed lower bound underflow on inverse transformation.
            pan_axis.targetlimits[] = Rect2(-20, 1.0e-318, 50, 1.0e245)
            original_limits = pan_axis.targetlimits[]
            axis_box = viewport(pan_axis.scene)[]
            drag_event = MouseEvent(
                Makie.to_drag_event(pan_axis.panbutton[]),
                1.0,
                Point2d(0, 0),
                Point2f(axis_box.origin + axis_box.widths),
                0.0,
                Point2d(0, 0),
                Point2f(axis_box.origin),
            )
            dragpan = pan_axis.interactions[:dragpan][2]

            @test_nowarn Makie.process_interaction(dragpan, drag_event, pan_axis)
            @test pan_axis.targetlimits[] == original_limits
        end

        @test init == Makie._PICK_COUNTER[]

        # Ctrl-click to restore
        @testset "Axis Reset" begin
            @test isempty(e.keyboardstate)
            e.keyboardbutton[] = KeyEvent(Keyboard.left_control, Keyboard.press)
            @test isempty(e.mousebuttonstate)
            e.mousebutton[] = MouseButtonEvent(Mouse.left, Mouse.press)
            e.mousebutton[] = MouseButtonEvent(Mouse.left, Mouse.release)
            e.keyboardbutton[] = KeyEvent(Keyboard.left_control, Keyboard.release)
            newlim = ax.finallimits[]
            @test lim ≈ newlim
        end

        @test init == Makie._PICK_COUNTER[]
    end

    @test init == Makie._PICK_COUNTER[]

    @testset "Axis Translation (pan)" begin
        ax, axbox, lim, e = cleanaxes()

        # Test default
        e.mouseposition[] = Tuple(axbox.origin + axbox.widths / 2)
        e.scroll[] = (0.0, 1.0)
        newlim = ax.finallimits[]

        e.mouseposition[] = Tuple(axbox.origin)
        e.mousebutton[] = MouseButtonEvent(ax.panbutton[], Mouse.press)
        e.mouseposition[] = Tuple(axbox.origin + axbox.widths / 10)
        e.mousebutton[] = MouseButtonEvent(ax.panbutton[], Mouse.release)

        panlim = ax.finallimits[]
        @test ax.panbutton[] == Mouse.right
        @test panlim.widths == newlim.widths
        @test (5 / 4) * panlim.origin ≈ -newlim.origin atol = 1.0e-6

        # Test new button disables old button
        ax, axbox, lim, e = cleanaxes()

        ax.panbutton[] = Mouse.middle
        e.mouseposition[] = Tuple(axbox.origin + axbox.widths / 2)
        e.scroll[] = (0.0, 1.0)
        newlim = ax.finallimits[]

        e.mouseposition[] = Tuple(axbox.origin)
        e.mousebutton[] = MouseButtonEvent(Mouse.right, Mouse.press)
        e.mouseposition[] = Tuple(axbox.origin + axbox.widths / 10)
        e.mousebutton[] = MouseButtonEvent(Mouse.right, Mouse.release)

        @test ax.finallimits[] == newlim

        # ... and enables new button
        e.mouseposition[] = Tuple(axbox.origin)
        e.mousebutton[] = MouseButtonEvent(Mouse.middle, Mouse.press)
        e.mouseposition[] = Tuple(axbox.origin + axbox.widths / 10)
        e.mousebutton[] = MouseButtonEvent(Mouse.middle, Mouse.release)

        panlim = ax.finallimits[]
        @test panlim.widths == newlim.widths
        @test (5 / 4) * panlim.origin ≈ -newlim.origin atol = 1.0e-6
    end

    @test init == Makie._PICK_COUNTER[]
end
