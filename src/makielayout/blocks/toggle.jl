function initialize_block!(t::Toggle)

    topscene = t.blockscene

    markersize = lift(topscene, t.layoutobservables.computedbbox) do bbox
        min(width(bbox), height(bbox))
    end

    button_endpoint_inactive = lift(topscene, markersize) do ms
        bbox = t.layoutobservables.computedbbox[]
        Point2f(left(bbox) + ms / 2, bottom(bbox) + ms / 2)
    end

    button_endpoint_active = lift(topscene, markersize) do ms
        bbox = t.layoutobservables.computedbbox[]
        Point2f(right(bbox) - ms / 2, bottom(bbox) + ms / 2)
    end

    buttonvertices = lift(topscene, markersize, t.cornersegments) do ms, cs
        roundedrectvertices(t.layoutobservables.computedbbox[], ms * 0.499, cs)
    end

    # trigger bbox
    notify(t.layoutobservables.suggestedbbox)

    framecolor = Observable{Any}(t.active[] ? t.framecolor_active[] : t.framecolor_inactive[])
    frame = poly!(topscene, buttonvertices, color = framecolor, inspectable = false)

    animating = Observable(false)
    buttonpos = Observable(t.active[] ? [button_endpoint_active[]] : [button_endpoint_inactive[]])

    # make the button stay in the correct place (and start there)
    on(topscene, t.layoutobservables.computedbbox) do bbox
        if !animating[]
            buttonpos[] = t.active[] ? [button_endpoint_active[]] : [button_endpoint_inactive[]]
        end
    end

    hovering = Observable(false)
    setfield!(t, :hovering, hovering)

    buttonfactor = Observable(1.0)
    buttonsize = lift(topscene, markersize, t.rimfraction, buttonfactor) do ms, rf, bf
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
        hovering[] = true
        return Consume(false)
    end

    onmouseout(mouseevents) do event
        buttonfactor[] = 1.0
        hovering[] = false
        return Consume(false)
    end

    return
end
