function initialize_block!(t::Toggle)

    topscene = t.blockscene

    onany(topscene, t.orientation, t.length, t.markersize) do or, len, ms
        theta = or == :horizontal ? 0 : or == :vertical ? pi / 2 : or
        y, x = sincos(theta)
        autowidth = (len - ms) * abs(x) + ms
        autoheight = (len - ms) * abs(y) + ms
        t.layoutobservables.autosize[] = (autowidth, autoheight)
    end

    xfun(x, bbox, ms) = x > 0 ? left(bbox) + ms / 2 : right(bbox) - ms / 2
    yfun(y, bbox, ms) = y > 0 ? bottom(bbox) + ms / 2 : top(bbox) - ms / 2

    button_endpoint_inactive = lift(topscene, t.orientation, t.markersize, t.layoutobservables.computedbbox) do or, ms, bbox
        theta = or == :horizontal ? 0 : or == :vertical ? pi / 2 : or
        y, x = sincos(theta)
        Point2f(xfun(x, bbox, ms), yfun(y, bbox, ms))
    end

    button_endpoint_active = lift(topscene, t.orientation, t.markersize, t.layoutobservables.computedbbox) do or, ms, bbox
        theta = or == :horizontal ? 0 : or == :vertical ? pi / 2 : or
        y, x = sincos(theta)
        Point2f(xfun(-x, bbox, ms), yfun(-y, bbox, ms))
    end

    buttonvertices = lift(topscene, t.length, t.markersize, t.cornersegments) do len, ms, cs
        rect0 = GeometryBasics.HyperRectangle(-ms / 2, -ms / 2, len, ms)
        return roundedrectvertices(rect0, ms * 0.499, cs)
    end

    # trigger bbox
    notify(t.length)
    notify(t.layoutobservables.suggestedbbox)

    framecolor = Observable{Any}(t.active[] ? t.framecolor_active[] : t.framecolor_inactive[])
    frame = poly!(topscene, buttonvertices, color = framecolor, inspectable = false)

    onany(topscene, t.markersize, t.orientation, t.layoutobservables.computedbbox, update = true) do ms, or, bbox
        theta = or == :horizontal ? 0 : or == :vertical ? pi / 2 : or
        rotate!(frame, theta)
        y, x = sincos(theta)
        tx = x > 0 ? origin(bbox)[1] + ms / 2 : origin(bbox)[1] + widths(bbox)[1] - ms / 2
        ty = y > 0 ? origin(bbox)[2] + ms / 2 : origin(bbox)[2] + widths(bbox)[2] - ms / 2
        translate!(frame, Point2f(tx, ty))
    end

    animating = Observable(false)
    buttonpos = Observable(t.active[] ? [button_endpoint_active[]] : [button_endpoint_inactive[]])

    # make the button stay in the correct place (and start there)
    on(topscene, t.layoutobservables.computedbbox) do bbox
        if !animating[]
            buttonpos[] = t.active[] ? [button_endpoint_active[]] : [button_endpoint_inactive[]]
        end
    end

    buttonfactor = Observable(1.0)
    buttonsize = lift(topscene, t.markersize, t.rimfraction, buttonfactor) do ms, rf, bf
        ms * (1 - rf) * bf
    end

    button = scatter!(
        topscene, buttonpos, markersize = buttonsize,
        color = t.buttoncolor, strokewidth = 0, inspectable = false, marker = Circle
    )

    mouseevents = addmouseevents!(topscene, t.layoutobservables.computedbbox)

    updatefunc = Ref{Any}(nothing)

    function perform_toggle_animation()
        if animating[]
            return
        end
        animating[] = true

        anim_posfrac = Animations.Animation(
            [0, t.toggleduration[]],
            !t.active[] ? [1.0, 0.0] : [0.0, 1.0],
            Animations.sineio()
        )

        coloranim = Animations.Animation(
            [0, t.toggleduration[]],
            !t.active[] ? [t.framecolor_active[], t.framecolor_inactive[]] : [t.framecolor_inactive[], t.framecolor_active[]],
            Animations.sineio()
        )

        tstart = topscene.events.tick[].time

        updatefunc[] = on(topscene.events.tick) do tick
            dt = tick.time - tstart
            # request endpoint values in every frame if the layout changes during
            # the animation
            buttonpos[] = [
                Animations.linear_interpolate(
                    anim_posfrac(dt),
                    button_endpoint_inactive[], button_endpoint_active[]
                ),
            ]
            framecolor[] = coloranim(dt)
            if dt >= t.toggleduration[]
                Observables.off(updatefunc[])
                updatefunc[] = nothing
                animating[] = false
            end
        end
        return
    end

    onmouseleftclick(mouseevents) do event
        t.active[] = !t.active[]
        return Consume(true)
    end

    on(t.active) do active
        perform_toggle_animation()
    end

    onmouseover(mouseevents) do event
        buttonfactor[] = 1.15
        return Consume(false)
    end

    onmouseout(mouseevents) do event
        buttonfactor[] = 1.0
        return Consume(false)
    end

    return
end
