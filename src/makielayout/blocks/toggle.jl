function initialize_block!(t::Toggle)

    topscene = t.blockscene

    markersize = lift(t.layoutobservables.computedbbox) do bbox
        min(width(bbox), height(bbox))
    end

    button_endpoint_inactive = lift(markersize) do ms
        bbox = t.layoutobservables.computedbbox[]
        Point2f(left(bbox) + ms / 2, bottom(bbox) + ms / 2)
    end

    button_endpoint_active = lift(markersize) do ms
        bbox = t.layoutobservables.computedbbox[]
        Point2f(right(bbox) - ms / 2, bottom(bbox) + ms / 2)
    end

    buttonvertices = lift(markersize, t.cornersegments) do ms, cs
        roundedrectvertices(t.layoutobservables.computedbbox[], ms * 0.499, cs)
    end

    # trigger bbox
    notify(t.layoutobservables.suggestedbbox)

    framecolor = Observable{Any}(t.active[] ? t.framecolor_active[] : t.framecolor_inactive[])
    frame = poly!(topscene, buttonvertices, color = framecolor, inspectable = false)

    animating = Observable(false)
    buttonpos = Observable(t.active[] ? [button_endpoint_active[]] : [button_endpoint_inactive[]])

    # make the button stay in the correct place (and start there)
    on(t.layoutobservables.computedbbox) do bbox
        if !animating[]
            buttonpos[] = t.active[] ? [button_endpoint_active[]] : [button_endpoint_inactive[]]
        end
    end

    buttonfactor = Observable(1.0)
    buttonsize = lift(markersize, t.rimfraction, buttonfactor) do ms, rf, bf
        ms * (1 - rf) * bf
    end

    button = scatter!(topscene, buttonpos, markersize = buttonsize,
        color = t.buttoncolor, strokewidth = 0, inspectable = false)

    mouseevents = addmouseevents!(topscene, t.layoutobservables.computedbbox)

    onmouseleftdown(mouseevents) do event
        if animating[]
            return Consume(true)
        end
        animating[] = true

        tstart = time()

        anim_posfrac = Animations.Animation(
            [0, t.toggleduration[]],
            t.active[] ? [1.0, 0.0] : [0.0, 1.0],
            Animations.sineio())
        coloranim = Animations.Animation(
            [0, t.toggleduration[]],
            t.active[] ? [t.framecolor_active[], t.framecolor_inactive[]] : [t.framecolor_inactive[], t.framecolor_active[]],
            Animations.sineio())

        t.active[] = !t.active[]
        @async while true
            tim = time() - tstart
            # request endpoint values in every frame if the layout changes during
            # the animation
            buttonpos[] = [Animations.linear_interpolate(anim_posfrac(tim),
                button_endpoint_inactive[], button_endpoint_active[])]
            framecolor[] = coloranim(tim)
            if tim >= t.toggleduration[]
                animating[] = false
                break
            end
            sleep(1/FPS[])
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
