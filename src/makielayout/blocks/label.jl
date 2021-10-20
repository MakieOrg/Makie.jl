function initialize_block!(l::Label, text = nothing)

    textpos = Node(Point3f(0, 0, 0))

    # this is just a hack until boundingboxes in Makie are perfect
    alignnode = lift(l.halign, l.rotation) do h, rot
        # left align the text if it's not rotated and left aligned
        if rot == 0 && (h == :left || h == 0.0)
            (:left, :center)
        else
            (:center, :center)
        end
    end

    if text !== nothing
        init_observable!(l, :text, fieldtype(Label, :text), text)
    end

    t = text!(l.blockscene, l.text, position = textpos, textsize = l.textsize, font = l.font, color = l.color,
        visible = l.visible, align = alignnode, rotation = l.rotation, raw = true, space = :data, inspectable = false)

    textbb = Ref(BBox(0, 1, 0, 1))

    onany(l.text, l.textsize, l.font, l.rotation, l.padding) do text, textsize, font, rotation, padding
        textbb[] = Rect2f(boundingbox(t))
        autowidth = width(textbb[]) + padding[1] + padding[2]
        autoheight = height(textbb[]) + padding[3] + padding[4]
        l.layoutobservables.autosize[] = (autowidth, autoheight)
    end

    onany(l.layoutobservables.computedbbox, l.padding) do bbox, padding

        tw = width(textbb[])
        th = height(textbb[])

        box = bbox.origin[1]
        boy = bbox.origin[2]

        # this is also part of the hack to improve left alignment until
        # boundingboxes are perfect
        tx = if l.rotation[] == 0 && (l.halign[] == :left || l.halign[] == 0.0)
            box + padding[1]
        else
            box + padding[1] + 0.5 * tw
        end
        ty = boy + padding[3] + 0.5 * th

        textpos[] = Point3f(tx, ty, 0)
    end


    # trigger first update, otherwise bounds are wrong somehow
    notify(l.text)
    # trigger bbox
    notify(l.layoutobservables.suggestedbbox)
end
