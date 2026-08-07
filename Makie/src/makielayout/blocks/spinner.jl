function initialize_block!(sp::Spinner)
    topscene = sp.blockscene
    layoutobservables = sp.layoutobservables

    frame_idx = Observable(1)
    displayed = lift(
        topscene, frame_idx, sp.message, sp.frames, sp.running
    ) do i, msg, frames, running
        running || return ""
        return "$(frames[mod1(i, length(frames))])  $msg"
    end

    textpos = Observable(Point3f(0, 0, 0))
    t = text!(
        topscene, textpos; text = displayed, fontsize = sp.fontsize,
        color = sp.color, visible = sp.visible,
        align = (:center, :center), markerspace = :data,
        inspectable = false
    )

    textbb = Ref(BBox(0, 1, 0, 1))
    onany(topscene, displayed, sp.fontsize) do _, _
        textbb[] = Rect2f(boundingbox(t, :data))
        layoutobservables.autosize[] = (width(textbb[]), height(textbb[]))
        return
    end

    onany(topscene, layoutobservables.computedbbox) do bbox
        tw = width(textbb[])
        th = height(textbb[])
        tx = bbox.origin[1] + 0.5 * width(bbox)
        ty = bbox.origin[2] + 0.5 * height(bbox)
        if all(isfinite, (tx, ty))
            textpos[] = Point3f(tx, ty, 0)
        end
        return
    end

    # Each `running = true` bumps `gen`; the loop reads its own captured
    # generation and exits when a newer animator takes over, so rapid
    # true/false/true toggles can't leave overlapping tasks running.
    gen = Ref(0)
    start_animator! = () -> begin
        gen[] += 1
        my_gen = gen[]
        @async while sp.running[] && gen[] == my_gen
            sp.visible[] && (frame_idx[] = frame_idx[] + 1)
            sleep(sp.frame_interval[])
        end
    end
    on(r -> r && start_animator!(), sp.running)
    sp.running[] && start_animator!()

    notify(displayed)
    layoutobservables.suggestedbbox[] = layoutobservables.suggestedbbox[]
    return sp
end
