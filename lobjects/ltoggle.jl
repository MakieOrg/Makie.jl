function LToggle(parent::Scene; bbox = nothing, kwargs...)
    attrs = merge!(Attributes(kwargs), default_attributes(LToggle))

    @extract attrs (halign, valign, cornersegments, framecolor_inactive,
        framecolor_active, buttoncolor, active, toggleduration, rimfraction)

    decorations = Dict{Symbol, Any}()

    sizeattrs = sizenode!(attrs.width, attrs.height)
    alignment = lift(tuple, halign, valign)

    suggestedbbox = create_suggested_bboxnode(bbox)

    computedsize = computedsizenode!(sizeattrs)

    finalbbox = alignedbboxnode!(suggestedbbox, computedsize, alignment, sizeattrs)

    markersize = lift(finalbbox) do bbox
        min(width(bbox), height(bbox))
    end

    button_endpoint_inactive = lift(markersize) do ms
        bbox = finalbbox[]
        Point2f0(left(bbox) + ms / 2, bottom(bbox) + ms / 2)
    end

    button_endpoint_active = lift(markersize) do ms
        bbox = finalbbox[]
        Point2f0(right(bbox) - ms / 2, bottom(bbox) + ms / 2)
    end

    buttonvertices = lift(markersize, cornersegments) do ms, cs
        roundedrectvertices(finalbbox[], ms * 0.499, cs)
    end

    # trigger bbox
    suggestedbbox[] = suggestedbbox[]

    framecolor = Node{Any}(framecolor_inactive[])
    frame = poly!(parent, buttonvertices, color = framecolor, raw = true)[end]

    animating = Node(false)
    buttonpos = Node(active[] ? [button_endpoint_active[]] : [button_endpoint_inactive[]])

    # make the button stay in the correct place (and start there)
    on(finalbbox) do bbox
        if !animating[]
            buttonpos[] = active[] ? [button_endpoint_active[]] : [button_endpoint_inactive[]]
        end
    end

    buttonsize = lift(markersize, rimfraction) do ms, rf
        ms * (1 - rf)
    end

    button = scatter!(parent, buttonpos, markersize = buttonsize, color = buttoncolor, raw = true)[end]

    buttonstate = addmousestate!(parent, button, frame)

    onmouseclick(buttonstate) do state
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

    # no protrusions
    protrusions = Node(RectSides(0f0, 0f0, 0f0, 0f0))

    layoutnodes = LayoutNodes(suggestedbbox, protrusions, computedsize, finalbbox)

    LToggle(parent, layoutnodes, attrs, decorations)
end

defaultlayout(lt::LToggle) = ProtrusionLayout(lt)

computedsizenode(lt::LToggle) = lt.layoutnodes.computedsize
protrusionnode(lt::LToggle) = lt.layoutnodes.protrusions

function align_to_bbox!(lt::LToggle, bbox)
    lt.layoutnodes.suggestedbbox[] = bbox
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
