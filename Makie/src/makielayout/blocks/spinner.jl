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

    # Advance the frame on ticks (matches record framerate; no async).
    accum = Ref(0.0)
    on(events(topscene).tick) do tick
        if sp.running[]
            accum[] += tick.delta_time
            if accum[] >= sp.frame_interval[]
                accum[] = 0.0
                frame_idx[] = frame_idx[] + 1
            end
        else
            accum[] = 0.0
        end
        return
    end

    notify(displayed)
    layoutobservables.suggestedbbox[] = layoutobservables.suggestedbbox[]
    return sp
end
