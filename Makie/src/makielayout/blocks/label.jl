function initialize_block!(l::Label, text; kwargs...)
    if text isa AbstractObservable
        on(str -> l.text = str, text, update = true)
    else
        l.text = text
    end
    initialize_block!(l; kwargs...)
    return
end

function initialize_block!(l::Label)

    topscene = l.blockscene
    layoutobservables = l.layoutobservables

    textpos = Observable(Point3f(0, 0, 0))
    word_wrap_width = Observable(-1.0f0)

    # A word-wrapped Label fills the width it is given, so its text is centred
    # inside that width. `justification` then only aligns the wrapped lines
    # against each other and the block as a whole still floats in the middle,
    # which makes a left-justified paragraph look mis-indented next to
    # unwrapped labels in the same column. Anchor the block when justification
    # names a side; `automatic` keeps the centred default.
    text_side = lift(topscene, l.justification, l.word_wrap) do j, ww
        (ww && j in (:left, :right)) ? j : :center
    end
    text_align = lift(s -> (s, :center), topscene, text_side)
    t = text!(
        topscene, textpos, text = l.text, fontsize = l.fontsize, font = l.font, color = l.color,
        visible = l.visible, align = text_align, rotation = l.rotation, markerspace = :data,
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

    onany(topscene, layoutobservables.computedbbox, l.padding, text_side) do bbox, pad, side
        padding = to_lrbt_padding(pad)
        if l.word_wrap[]
            tw = width(bbox) - padding[1] - padding[2]
        else
            tw = width(textbb[])
        end
        th = height(textbb[])

        box = bbox.origin[1]
        boy = bbox.origin[2]

        tx = box + padding[1] + (side === :left ? 0.0 :
                                 side === :right ? tw : 0.5 * tw)
        ty = boy + padding[3] + 0.5 * th
        # only update if finite to avoid propagating NaNs
        # Which happens for a "" label, which can't be recovered from.
        if all(isfinite, (tx, ty))
            textpos[] = Point3f(tx, ty, 0)
        end

        if l.word_wrap[] && (word_wrap_width[] != tw)
            word_wrap_width[] = tw
        end

        return
    end


    # trigger first update, otherwise bounds are wrong somehow
    notify(ComputePipeline.get_observable!(l.text))
    # trigger bbox
    layoutobservables.suggestedbbox[] = layoutobservables.suggestedbbox[]

    return l
end
