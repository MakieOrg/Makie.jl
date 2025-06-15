Label(x, text; kwargs...) = Label(x; text = text, kwargs...)

function initialize_block!(l::Label)

    topscene = l.blockscene
    layoutobservables = l.layoutobservables

    textpos = Observable(Point3f(0, 0, 0))
    word_wrap_width = Observable(-1.0f0)
    t = text!(
        topscene, textpos, text = l.text, fontsize = l.fontsize, font = l.font, color = l.color,
        visible = l.visible, align = (:center, :center), rotation = l.rotation, markerspace = :data,
        justification = l.justification, lineheight = l.lineheight, word_wrap_width = word_wrap_width,
        inspectable = false
    )

    textbb = Ref(BBox(0, 1, 0, 1))

    onany(
        topscene, l.text, l.fontsize, l.font, l.rotation, word_wrap_width,
        l.padding
    ) do _, _, _, _, _, pad
        padding = to_lrbt_padding(pad)
        textbb[] = Rect2f(boundingbox(t, :data))
        autowidth = width(textbb[]) + padding[1] + padding[2]
        autoheight = height(textbb[]) + padding[3] + padding[4]
        if l.word_wrap[]
            layoutobservables.autosize[] = (nothing, autoheight)
        else
            layoutobservables.autosize[] = (autowidth, autoheight)
        end
        return
    end

    onany(topscene, layoutobservables.computedbbox, l.padding) do bbox, pad
        padding = to_lrbt_padding(pad)
        if l.word_wrap[]
            tw = width(bbox) - padding[1] - padding[2]
        else
            tw = width(textbb[])
        end
        th = height(textbb[])

        box = bbox.origin[1]
        boy = bbox.origin[2]

        tx = box + padding[1] + 0.5 * tw
        ty = boy + padding[3] + 0.5 * th

        textpos[] = Point3f(tx, ty, 0)

        if l.word_wrap[] && (word_wrap_width[] != tw)
            word_wrap_width[] = tw
        end

        return
    end


    # trigger first update, otherwise bounds are wrong somehow
    notify(l.text)
    # trigger bbox
    layoutobservables.suggestedbbox[] = layoutobservables.suggestedbbox[]

    return l
end
