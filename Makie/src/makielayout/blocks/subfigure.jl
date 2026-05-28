function initialize_block!(sf::Subfigure; isolate_events::Bool = false)
    blockscene = sf.blockscene

    content_area = lift(round_to_IRect2D, blockscene, sf.layoutobservables.computedbbox)

    # Unwrap the Compute graph node into a plain Observable{Bool} for the
    # parts of the API that expect one (Scene's `visible`, `forward_events!`).
    active = lift(identity, blockscene, sf.active)

    scene = if isolate_events
        Scene(
            blockscene; events = Events(), camera = campixel!,
            viewport = content_area, visible = active, clear = false
        )
    else
        Scene(blockscene; camera = campixel!, viewport = content_area, visible = active, clear = false)
    end
    if isolate_events
        forward_events!(scene, blockscene; active = active)
    end
    sf.scene = scene

    poly!(
        blockscene, content_area;
        color = sf.backgroundcolor, visible = active, inspectable = false
    )

    sf.scroll = Observable(Vec2f(0, 0); ignore_equal_values = true)
    sf.contentsize = Observable(Vec2f(0, 0); ignore_equal_values = true)

    layout_bbox = Observable(Rect2f(0, 0, 1, 1); ignore_equal_values = true)
    layout = GridLayout(; bbox = layout_bbox)
    layout.parent = scene
    sf.layout = layout

    on(blockscene, sf.contentpadding; update = true) do pad
        sides = pad isa Number ? (pad, pad, pad, pad) : pad
        layout.alignmode[] = Outside(to_rectsides(sides))
        GridLayoutBase.update!(layout)
        return
    end

    # Scrollbar primitives drawn in the parent's blockscene so they sit above
    # the content area; sized in `update_scrollbars!`.
    vbar_rect = Observable(Rect2f(0, 0, 0, 0))
    vthumb_rect = Observable(Rect2f(0, 0, 0, 0))
    vthumb_color = Observable(to_color(sf.scrollbar_thumb_color[]))
    vvis = Observable(false; ignore_equal_values = true)
    hbar_rect = Observable(Rect2f(0, 0, 0, 0))
    hthumb_rect = Observable(Rect2f(0, 0, 0, 0))
    hthumb_color = Observable(to_color(sf.scrollbar_thumb_color[]))
    hvis = Observable(false; ignore_equal_values = true)
    poly!(blockscene, vbar_rect; color = sf.scrollbar_color, visible = lift(&, active, vvis), inspectable = false)
    poly!(blockscene, vthumb_rect; color = vthumb_color, visible = lift(&, active, vvis), inspectable = false)
    poly!(blockscene, hbar_rect; color = sf.scrollbar_color, visible = lift(&, active, hvis), inspectable = false)
    poly!(blockscene, hthumb_rect; color = hthumb_color, visible = lift(&, active, hvis), inspectable = false)

    function update_scrollbars!()
        ca = scene.viewport[]
        cs = sf.contentsize[]
        sc = sf.scroll[]
        sbsize = Float32(sf.scrollbar_size[])
        vw, vh = Float32.(widths(ca))
        cw, ch = max(cs[1], vw), max(cs[2], vh)
        max_sx, max_sy = max(0.0f0, cw - vw), max(0.0f0, ch - vh)
        vvis[] = max_sy > 0
        hvis[] = max_sx > 0
        if max_sy > 0
            tx = right(ca) - sbsize
            vbar_rect[] = Rect2f((tx, bottom(ca)), (sbsize, vh))
            thumb_h = max(20.0f0, vh * vh / ch)
            usable = vh - thumb_h
            ty = top(ca) - thumb_h - (sc[2] / max_sy) * usable
            vthumb_rect[] = Rect2f((tx, ty), (sbsize, thumb_h))
        end
        if max_sx > 0
            by = bottom(ca)
            hbar_rect[] = Rect2f((left(ca), by), (vw, sbsize))
            thumb_w = max(20.0f0, vw * vw / cw)
            usable = vw - thumb_w
            tx = left(ca) + (sc[1] / max_sx) * usable
            hthumb_rect[] = Rect2f((tx, by), (thumb_w, sbsize))
        end
        return
    end

    onany(blockscene, content_area, sf.scroll, sf.contentsize) do ca, sc, cs
        vw, vh = Float32.(widths(ca))
        cw, ch = max(cs[1], vw), max(cs[2], vh)
        max_sx, max_sy = max(0.0f0, cw - vw), max(0.0f0, ch - vh)
        sx = clamp(sc[1], 0.0f0, max_sx)
        sy = clamp(sc[2], 0.0f0, max_sy)
        if sx != sc[1] || sy != sc[2]
            sf.scroll[] = Vec2f(sx, sy)
            return
        end
        top_edge = top(ca) + sy
        left_edge = left(ca) - sx
        layout_bbox[] = Rect2f(Point2f(left_edge, top_edge - ch), Vec2f(cw, ch))
        update_scrollbars!()
        return
    end

    on(blockscene, layout.layoutobservables.computedbbox) do _
        dw = GridLayoutBase.determinedirsize(layout, GridLayoutBase.Col())
        dh = GridLayoutBase.determinedirsize(layout, GridLayoutBase.Row())
        cw = dw === nothing ? 0.0f0 : Float32(dw)
        ch = dh === nothing ? 0.0f0 : Float32(dh)
        sf.contentsize[] = Vec2f(cw, ch)
        return
    end

    # Wheel scrolling runs below the default priority so an inner block (e.g.
    # an Axis zoom-on-scroll handler at priority 0) gets the event first; the
    # subfigure only scrolls when nothing else consumed.
    on(blockscene, scene.events.scroll; priority = -1) do (dx, dy)
        sf.scrollable[] || return Consume(false)
        cs = sf.contentsize[]
        ca = scene.viewport[]
        vw, vh = Float32.(widths(ca))
        cw, ch = max(cs[1], vw), max(cs[2], vh)
        (cw <= vw && ch <= vh) && return Consume(false)
        step = Float32(sf.scroll_speed[])
        sf.scroll[] = Vec2f(sf.scroll[][1] + step * dx, sf.scroll[][2] - step * dy)
        return Consume(true)
    end

    drag_state = Ref{Tuple{Symbol, Float32, Vec2f}}((:none, 0.0f0, Vec2f(0, 0)))
    function bar_at(pos)
        active[] || return :none
        pt = Point2f(pos)
        if vvis[]
            pt in vthumb_rect[] && return :vthumb
            pt in vbar_rect[] && return :vtrack
        end
        if hvis[]
            pt in hthumb_rect[] && return :hthumb
            pt in hbar_rect[] && return :htrack
        end
        return :none
    end

    on(blockscene, blockscene.events.mouseposition) do pos
        kind = bar_at(pos)
        st = drag_state[][1]
        v_active = st === :vdrag || kind in (:vthumb, :vtrack)
        h_active = st === :hdrag || kind in (:hthumb, :htrack)
        vthumb_color[] = to_color(v_active ? sf.scrollbar_thumb_color_active[] : sf.scrollbar_thumb_color[])
        hthumb_color[] = to_color(h_active ? sf.scrollbar_thumb_color_active[] : sf.scrollbar_thumb_color[])

        st, anchor, anchor_scroll = drag_state[]
        if st === :vdrag
            ca = scene.viewport[]
            vh = Float32(widths(ca)[2])
            ch = max(sf.contentsize[][2], vh)
            max_sy = max(0.0f0, ch - vh)
            max_sy == 0 && return Consume(false)
            thumb_h = max(20.0f0, vh * vh / ch)
            usable = vh - thumb_h
            dy = anchor - Float32(pos[2])
            new_sy = clamp(anchor_scroll[2] + dy * max_sy / usable, 0.0f0, max_sy)
            sf.scroll[] = Vec2f(sf.scroll[][1], new_sy)
            return Consume(true)
        elseif st === :hdrag
            ca = scene.viewport[]
            vw = Float32(widths(ca)[1])
            cw = max(sf.contentsize[][1], vw)
            max_sx = max(0.0f0, cw - vw)
            max_sx == 0 && return Consume(false)
            thumb_w = max(20.0f0, vw * vw / cw)
            usable = vw - thumb_w
            dx = Float32(pos[1]) - anchor
            new_sx = clamp(anchor_scroll[1] + dx * max_sx / usable, 0.0f0, max_sx)
            sf.scroll[] = Vec2f(new_sx, sf.scroll[][2])
            return Consume(true)
        end
        return Consume(false)
    end

    on(blockscene, blockscene.events.mousebutton; priority = 60) do ev
        active[] || return Consume(false)
        if ev.button == Mouse.left && ev.action == Mouse.press
            pos = blockscene.events.mouseposition[]
            kind = bar_at(pos)
            if kind === :vthumb
                drag_state[] = (:vdrag, Float32(pos[2]), sf.scroll[])
                return Consume(true)
            elseif kind === :hthumb
                drag_state[] = (:hdrag, Float32(pos[1]), sf.scroll[])
                return Consume(true)
            elseif kind === :vtrack
                vh = Float32(widths(scene.viewport[])[2])
                dir = Float32(pos[2]) < (vthumb_rect[].origin[2] + vthumb_rect[].widths[2] / 2) ? 1 : -1
                sf.scroll[] = Vec2f(sf.scroll[][1], sf.scroll[][2] + dir * vh)
                return Consume(true)
            elseif kind === :htrack
                vw = Float32(widths(scene.viewport[])[1])
                dir = Float32(pos[1]) > (hthumb_rect[].origin[1] + hthumb_rect[].widths[1] / 2) ? 1 : -1
                sf.scroll[] = Vec2f(sf.scroll[][1] + dir * vw, sf.scroll[][2])
                return Consume(true)
            end
        elseif ev.button == Mouse.left && ev.action == Mouse.release
            drag_state[] = (:none, 0.0f0, Vec2f(0, 0))
        end
        return Consume(false)
    end

    notify(sf.layoutobservables.suggestedbbox)
    return
end

content_scene(sf::Subfigure) = sf.scene

# `unhide!` force-sets `b.scene.visible[] = true` (intended for blocks like Axis
# that initialise it `false`), which would override the reactive binding from
# `active`. Subfigure's scene visibility is driven by `active`, so don't touch
# `sf.scene.visible` here — just unhide the blockscene like the default would.
function unhide!(sf::Subfigure)
    sf.blockscene.visible[] || (sf.blockscene.visible[] = true)
    return
end

# Recurse into the subfigure's layout so blocks placed inside get their
# pre-display updates (auto axis limits etc.).
function update_state_before_display!(sf::Subfigure)
    return update_state_before_display!(sf.layout)
end
