function LButton(scene::Scene; bbox = nothing, kwargs...)

    attrs = merge!(Attributes(kwargs), default_attributes(LButton))

    @extract attrs (padding, textsize, label, font, halign, valign, cornerradius,
        cornersegments, strokewidth, strokecolor, buttoncolor,
        labelcolor, labelcolor_hover, labelcolor_active,
        buttoncolor_active, buttoncolor_hover, clicks)

    decorations = Dict{Symbol, Any}()

    layoutobservables = LayoutObservables(LButton, attrs.width, attrs.height,
        halign, valign; suggestedbbox = bbox)

    textpos = Node(Point2f0(0, 0))

    subarea = lift(layoutobservables.computedbbox) do bbox
        IRect2D_rounded(bbox)
    end
    subscene = Scene(scene, subarea, camera=campixel!)

    lcolor = Node{Any}(labelcolor[])
    labeltext = text!(subscene, label, position = textpos, textsize = textsize, font = font,
        color = lcolor, align = (:center, :center), raw = true)[end]

    buttonwidth = Node{Optional{Float32}}(nothing)
    buttonheight = Node{Optional{Float32}}(nothing)

    onany(label, textsize, font, padding) do label, textsize, font, padding
        textbb = FRect2D(boundingbox(labeltext))
        autowidth = width(textbb) + padding[1] + padding[2]
        autoheight = height(textbb) + padding[3] + padding[4]
        layoutobservables.autosize[] = (autowidth, autoheight)
    end

    # buttonrect is without the left bottom offset of the bbox
    buttonrect = lift(layoutobservables.computedbbox) do bbox
        BBox(0, width(bbox), 0, height(bbox))
    end

    on(buttonrect) do rect
        textpos[] = Point2f0(left(rect) + 0.5f0 * width(rect), bottom(rect) + 0.5f0 * height(rect))
    end

    roundedrectpoints = lift(roundedrectvertices, buttonrect, cornerradius, cornersegments)

    bcolor = Node{Any}(buttoncolor[])
    button = poly!(subscene, roundedrectpoints, strokewidth = strokewidth, strokecolor = strokecolor,
        color = bcolor, raw = true)[end]
    decorations[:button] = button
    # put button in front so the text doesn't block the mouse
    reverse!(subscene.plots)

    mousestate = addmousestate!(scene, button, labeltext)

    onmouseover(mousestate) do state
        bcolor[] = buttoncolor_hover[]
        lcolor[] = labelcolor_hover[]
    end

    onmouseout(mousestate) do state
        bcolor[] = buttoncolor[]
        lcolor[] = labelcolor[]
    end

    onmouseleftdown(mousestate) do state
        bcolor[] = buttoncolor_active[]
        lcolor[] = labelcolor_active[]
    end

    onmouseleftclick(mousestate) do state
        clicks[] = clicks[] + 1
    end

    label[] = label[]
    # trigger bbox
    layoutobservables.suggestedbbox[] = layoutobservables.suggestedbbox[]

    LButton(scene, layoutobservables, attrs, decorations)
end
