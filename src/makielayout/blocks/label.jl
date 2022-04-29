Label(x, text; kwargs...) = Label(x; text = text, kwargs...)

function initialize_block!(l::Label)

    topscene = l.blockscene
    layoutobservables = l.layoutobservables

    textpos = Observable(Point3f(0, 0, 0))

    t = text!(topscene, l.text, position = textpos, textsize = l.textsize, font = l.font, color = l.color,
        visible = l.visible, align = (:center, :em_center), rotation = l.rotation, markerspace = :data,
        justification = l.justification,
        lineheight = l.lineheight,
        inspectable = false)

    textbb = Ref(BBox(0, 1, 0, 1))

    onany(l.text, l.textsize, l.font, l.rotation, l.padding) do text, textsize, font, rotation, padding
        textbb[] = Rect2f(boundingbox(t))
        autowidth = width(textbb[]) + padding[1] + padding[2]
        autoheight = height(textbb[]) + padding[3] + padding[4]
        layoutobservables.autosize[] = (autowidth, autoheight)
    end

    onany(layoutobservables.computedbbox, l.padding) do bbox, padding

        tw = width(textbb[])
        th = height(textbb[])

        box = bbox.origin[1]
        boy = bbox.origin[2]

        tx = box + padding[1] + 0.5 * tw
        ty = boy + padding[3] + 0.5 * th

        textpos[] = Point3f(tx, ty, 0)
    end


    # trigger first update, otherwise bounds are wrong somehow
    notify(l.text)
    # trigger bbox
    layoutobservables.suggestedbbox[] = layoutobservables.suggestedbbox[]

    l
end
