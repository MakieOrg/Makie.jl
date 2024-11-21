function initialize_block!(t::Toggle)

    topscene = t.blockscene

    onany(topscene, t.orientation, t.length, t.markersize) do or, len, ms
        theta = or == :horizontal ? 0 : or == :vertical ? pi/2 : or
        t.width[] = (len - ms) * cos(theta) + ms
        t.height[] = (len - ms)  * sin(theta) + ms
    end

    button_endpoint_inactive = lift(topscene, t.markersize, t.layoutobservables.computedbbox) do ms, bbox

        Point2f(left(bbox) + ms / 2, bottom(bbox) + ms / 2)
    end

    button_endpoint_active = lift(topscene, t.markersize, t.layoutobservables.computedbbox) do ms, bbox
        Point2f(right(bbox) - ms / 2, top(bbox) - ms / 2)
    end

    buttonvertices = lift(topscene, t.length, t.markersize, t.cornersegments) do len, ms, cs
        rect0 = GeometryBasics.HyperRectangle(-ms/2, -ms/2, len, ms)
        return roundedrectvertices(rect0, ms * 0.499, cs)
    end

    # trigger bbox
    notify(t.length)
    notify(t.layoutobservables.suggestedbbox)

    framecolor = Observable{Any}(t.active[] ? t.framecolor_active[] : t.framecolor_inactive[])
    frame = poly!(topscene, buttonvertices, color = framecolor, inspectable = false)

    onany(topscene, t.markersize, t.orientation, t.layoutobservables.computedbbox, update = true) do ms, or, bbox
        theta = or == :horizontal ? 0 : or == :vertical ? pi/2 : or
        rotate!(frame, theta)
        translate!(frame, origin(bbox) .+ ms/2)
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

    button = scatter!(topscene, buttonpos, markersize = buttonsize,
        color = t.buttoncolor, strokewidth = 0, inspectable = false, marker = Circle)

    mouseevents = addmouseevents!(topscene, t.layoutobservables.computedbbox)

    updatefunc = Ref{Any}(nothing)

    onmouseleftclick(mouseevents) do event
        if animating[]
            return Consume(true)
        end
        animating[] = true

        anim_posfrac = Animations.Animation(
            [0, t.toggleduration[]],
            t.active[] ? [1.0, 0.0] : [0.0, 1.0],
            Animations.sineio())

        coloranim = Animations.Animation(
            [0, t.toggleduration[]],
            t.active[] ? [t.framecolor_active[], t.framecolor_inactive[]] : [t.framecolor_inactive[], t.framecolor_active[]],
            Animations.sineio())

        t.active[] = !t.active[]

        tstart = topscene.events.tick[].time

        updatefunc[] = on(topscene.events.tick) do tick
            dt = tick.time - tstart
            # request endpoint values in every frame if the layout changes during
            # the animation
            buttonpos[] = [Animations.linear_interpolate(anim_posfrac(dt),
                button_endpoint_inactive[], button_endpoint_active[])]
            framecolor[] = coloranim(dt)
            if dt >= t.toggleduration[]
                Observables.off(updatefunc[])
                updatefunc[] = nothing
                animating[] = false
            end
        end

        return Consume(true)
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
