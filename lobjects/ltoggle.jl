function LToggle(parent::Scene; bbox = nothing, kwargs...)
    attrs = merge!(Attributes(kwargs), default_attributes(LToggle))

    @extract attrs (halign, valign, cornersegments, framecolor_inactive,
        framecolor_active, buttoncolor, active, toggleduration, rimfraction)

    decorations = Dict{Symbol, Any}()

    layoutobservables = LayoutObservables(LToggle, attrs.width, attrs.height,
        halign, valign, attrs.alignmode; suggestedbbox = bbox)

    markersize = lift(layoutobservables.computedbbox) do bbox
        min(width(bbox), height(bbox))
    end

    button_endpoint_inactive = lift(markersize) do ms
        bbox = layoutobservables.computedbbox[]
        Point2f0(left(bbox) + ms / 2, bottom(bbox) + ms / 2)
    end

    button_endpoint_active = lift(markersize) do ms
        bbox = layoutobservables.computedbbox[]
        Point2f0(right(bbox) - ms / 2, bottom(bbox) + ms / 2)
    end

    buttonvertices = lift(markersize, cornersegments) do ms, cs
        roundedrectvertices(layoutobservables.computedbbox[], ms * 0.499, cs)
    end

    # trigger bbox
    layoutobservables.suggestedbbox[] = layoutobservables.suggestedbbox[]

    framecolor = Node{Any}(active[] ? framecolor_active[] : framecolor_inactive[])
    frame = poly!(parent, buttonvertices, color = framecolor, raw = true)[end]

    animating = Node(false)
    buttonpos = Node(active[] ? [button_endpoint_active[]] : [button_endpoint_inactive[]])

    # make the button stay in the correct place (and start there)
    on(layoutobservables.computedbbox) do bbox
        if !animating[]
            buttonpos[] = active[] ? [button_endpoint_active[]] : [button_endpoint_inactive[]]
        end
    end

    buttonsize = lift(markersize, rimfraction) do ms, rf
        ms * (1 - rf)
    end

    button = scatter!(parent, buttonpos, markersize = buttonsize, color = buttoncolor, raw = true)[end]

    buttonstate = addmousestate!(parent, button, frame)

    onmouseleftclick(buttonstate) do state
        if animating[]
            return
        end
        animating[] = true

        tstart = time()

        anim_posfrac = Animations.Animation(
            [0, toggleduration[]],
            active[] ? [1.0, 0.0] : [0.0, 1.0],
            Animations.sineio())
        coloranim = Animations.Animation(
            [0, toggleduration[]],
            active[] ? [framecolor_active[], framecolor_inactive[]] : [framecolor_inactive[], framecolor_active[]],
            Animations.sineio())

        active[] = !active[]
        @async while true
            t = time() - tstart
            # request endpoint values in every frame if the layout changes during
            # the animation
            buttonpos[] = [Animations.linear_interpolate(anim_posfrac(t),
                button_endpoint_inactive[], button_endpoint_active[])]
            framecolor[] = coloranim(t)
            if t >= toggleduration[]
                animating[] = false
                break
            end
            sleep(1/FPS[])
        end
    end

    LToggle(parent, layoutobservables, attrs, decorations)
end

defaultlayout(lt::LToggle) = ProtrusionLayout(lt)

computedsizenode(lt::LToggle) = lt.layoutobservables.computedsize
protrusionnode(lt::LToggle) = lt.layoutobservables.protrusions

function align_to_bbox!(lt::LToggle, bbox)
    lt.layoutobservables.suggestedbbox[] = bbox
end

function Base.getproperty(lt::LToggle, s::Symbol)
    if s in fieldnames(LToggle)
        getfield(lt, s)
    else
        lt.attributes[s]
    end
end

function Base.setproperty!(lt::LToggle, s::Symbol, value)
    if s in fieldnames(LToggle)
        setfield!(lt, s, value)
    else
        lt.attributes[s][] = value
    end
end

function Base.propertynames(lt::LToggle)
    [fieldnames(LToggle)..., keys(lt.attributes)...]
end
