function initialize_block!(b::Button)

    scene = b.blockscene

    textpos = Observable(Point2f(0, 0))

    subarea = lift(scene, b.layoutobservables.computedbbox) do bbox
        round_to_IRect2D(bbox)
    end
    subscene = Scene(scene, subarea, camera=campixel!)

    # buttonrect is without the left bottom offset of the bbox
    buttonrect = lift(scene, b.layoutobservables.computedbbox) do bbox
        BBox(0, width(bbox), 0, height(bbox))
    end

    on(scene, buttonrect) do rect
        textpos[] = Point2f(left(rect) + 0.5f0 * width(rect), bottom(rect) + 0.5f0 * height(rect))
    end

    roundedrectpoints = lift(roundedrectvertices, scene, buttonrect, b.cornerradius, b.cornersegments)

    mousestate = Observable(:out)

    bcolors = (; out = b.buttoncolor, active = b.buttoncolor_active, hover = b.buttoncolor_hover)
    bcolor = Observable{RGBColors}()
    map!((s, _...) -> to_color(bcolors[s][]), scene, bcolor, mousestate, values(bcolors)...)

    button = poly!(subscene, roundedrectpoints, strokewidth = b.strokewidth, strokecolor = b.strokecolor,
        color = bcolor, inspectable = false)

    lcolors = (; out = b.labelcolor, active = b.labelcolor_active, hover = b.labelcolor_hover)
    lcolor = Observable{RGBColors}()
    map!((s, _...) -> to_color(lcolors[s][]), scene, lcolor, mousestate, values(lcolors)...)

    labeltext = text!(subscene, textpos, text = b.label, fontsize = b.fontsize, font = b.font,
        color = lcolor, align = (:center, :center), markerspace = :data, inspectable = false)

    # move text in front of background to be sure it's not occluded
    translate!(labeltext, 0, 0, 1)

    onany(scene, b.label, b.fontsize, b.font, b.padding) do label, fontsize, font, padding
        textbb = Rect2f(boundingbox(labeltext, :data))
        autowidth = width(textbb) + padding[1] + padding[2]
        autoheight = height(textbb) + padding[3] + padding[4]
        b.layoutobservables.autosize[] = (autowidth, autoheight)
    end

    # tooltip
    ttposition = lift(b.tooltip_placement, b.layoutobservables.computedbbox) do placement, bbox
        if placement == :above
            bbox.origin + Point2f((bbox.widths[1]/2, bbox.widths[2]))
        elseif placement == :below
            bbox.origin + Point2f((bbox.widths[1]/2, 0))
        elseif placement == :left
            bbox.origin + Point2f((0, bbox.widths[2]/2))
        elseif placement == :right
            bbox.origin + Point2f((bbox.widths[1], bbox.widths[2]/2))
        else
            placement == :center || warn("invalid value for tooltip_placement, using :center")
            bbox.origin + Point2f((bbox.widths[1]/2, bbox.widths[2]/2))
        end
    end
    ttvisible = lift((x,y)->x && y==:hover, b.tooltip_enable, mousestate)
    tt = tooltip!(scene, ttposition, b.tooltip_text,
                  visible=ttvisible, placement=b.tooltip_placement;
                  b.tooltip_kwargs[]...)
    translate!(tt, 0, 0, b.tooltip_depth[])

    mouseevents = addmouseevents!(scene, b.layoutobservables.computedbbox)

    onmouseover(mouseevents) do _
        mousestate[] = :hover
        return Consume(false)
    end

    onmouseout(mouseevents) do _
        mousestate[] = :out
        return Consume(false)
    end

    onmouseleftup(mouseevents) do _
        mousestate[] = :hover
        return Consume(true)
    end

    onmouseleftdown(mouseevents) do _
        mousestate[] = :active
        return Consume(true)
    end

    onmouseleftclick(mouseevents) do _
        b.clicks[] = b.clicks[] + 1
        return Consume(true)
    end

    notify(b.label)
    # trigger bbox
    notify(b.layoutobservables.suggestedbbox)

    return
end
