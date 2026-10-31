function initialize_block!(sa::ScrollArea)
    blockscene = sa.blockscene

    content_area = lift(round_to_IRect2D, blockscene, sa.layoutobservables.computedbbox)

    # Unwrap the Compute graph node into a plain Observable{Bool} for the
    # parts of the API that expect one (Scene's `visible`).
    is_visible = lift(identity, blockscene, sa.visible)

    # Share the parent's `Events`: the scene-stacking event router
    # (`receives_events`, honored by `is_mouseinside`/`addmouseevents!`) keeps
    # hidden subtrees inert, so no separate `Events`/event forwarding is needed.
    scene = Scene(blockscene; camera = campixel!, viewport = content_area, visible = is_visible, clear = false)
    sa.scene = scene

    poly!(
        blockscene, content_area;
        color = sa.backgroundcolor, visible = is_visible, inspectable = false
    )

    sa.scroll = Observable(Vec2f(0, 0); ignore_equal_values = true)
    sa.contentsize = Observable(Vec2f(0, 0); ignore_equal_values = true)

    layout_bbox = Observable(Rect2f(0, 0, 1, 1); ignore_equal_values = true)
    layout = GridLayout(; bbox = layout_bbox)
    layout.parent = scene
    sa.layout = layout

    on(blockscene, sa.contentpadding; update = true) do pad
        sides = pad isa Number ? (pad, pad, pad, pad) : pad
        layout.alignmode[] = Outside(to_rectsides(sides))
        GridLayoutBase.update!(layout)
        return
    end

    # Scrollbar primitives drawn in the parent's blockscene so they sit above
    # the content area; sized in `update_scrollbars!`.
    vbar_rect = Observable(Rect2f(0, 0, 0, 0))
    vthumb_rect = Observable(Rect2f(0, 0, 0, 0))
    vthumb_color = Observable(to_color(sa.scrollbar_thumb_color[]))
    vvis = Observable(false; ignore_equal_values = true)
    hbar_rect = Observable(Rect2f(0, 0, 0, 0))
    hthumb_rect = Observable(Rect2f(0, 0, 0, 0))
    hthumb_color = Observable(to_color(sa.scrollbar_thumb_color[]))
    hvis = Observable(false; ignore_equal_values = true)
    # Rounded thumbs (capsule-shaped) computed from the bar rects. The track
    # rectangles aren't drawn — `sa.scrollbar_color` is exposed for users who
    # want a track, but the default is transparent.
    poly!(blockscene, vbar_rect; color = sa.scrollbar_color, visible = lift(&, is_visible, vvis), inspectable = false)
    poly!(blockscene, hbar_rect; color = sa.scrollbar_color, visible = lift(&, is_visible, hvis), inspectable = false)
    vthumb_poly = lift(blockscene, vthumb_rect) do r
        roundedrectvertices(r, min(widths(r)...) / 2, 8)
    end
    hthumb_poly = lift(blockscene, hthumb_rect) do r
        roundedrectvertices(r, min(widths(r)...) / 2, 8)
    end
    poly!(blockscene, vthumb_poly; color = vthumb_color, visible = lift(&, is_visible, vvis), inspectable = false)
    poly!(blockscene, hthumb_poly; color = hthumb_color, visible = lift(&, is_visible, hvis), inspectable = false)

    function update_scrollbars!()
        ca = scene.viewport[]
        cs = sa.contentsize[]
        sc = sa.scroll[]
        sbsize = Float32(sa.scrollbar_size[])
        vw, vh = Float32.(widths(ca))
        cw, ch = max(cs[1], vw), max(cs[2], vh)
        max_sx, max_sy = max(0.0f0, cw - vw), max(0.0f0, ch - vh)
        # With `scrollable = false` the area still clips its content, but shows
        # no scrollbars and takes no scroll input — a plain clipped panel.
        scrollable = sa.scrollable[]
        vvis[] = scrollable && max_sy > 0
        hvis[] = scrollable && max_sx > 0
        if vvis[]
            tx = right(ca) - sbsize
            vbar_rect[] = Rect2f((tx, bottom(ca)), (sbsize, vh))
            thumb_h = max(20.0f0, vh * vh / ch)
            usable = vh - thumb_h
            ty = top(ca) - thumb_h - (sc[2] / max_sy) * usable
            vthumb_rect[] = Rect2f((tx, ty), (sbsize, thumb_h))
        end
        if hvis[]
            by = bottom(ca)
            hbar_rect[] = Rect2f((left(ca), by), (vw, sbsize))
            thumb_w = max(20.0f0, vw * vw / cw)
            usable = vw - thumb_w
            tx = left(ca) + (sc[1] / max_sx) * usable
            hthumb_rect[] = Rect2f((tx, by), (thumb_w, sbsize))
        end
        return
    end

    onany(blockscene, content_area, sa.scroll, sa.contentsize, sa.scrollable) do ca, sc, cs, _scrollable
        vw, vh = Float32.(widths(ca))
        cw, ch = max(cs[1], vw), max(cs[2], vh)
        max_sx, max_sy = max(0.0f0, cw - vw), max(0.0f0, ch - vh)
        sx = clamp(sc[1], 0.0f0, max_sx)
        sy = clamp(sc[2], 0.0f0, max_sy)
        if sx != sc[1] || sy != sc[2]
            sa.scroll[] = Vec2f(sx, sy)
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
        sa.contentsize[] = Vec2f(cw, ch)
        return
    end

    # Wheel scrolling runs below the default priority so an inner block (e.g.
    # an Axis zoom-on-scroll handler at priority 0) gets the event first; the
    # area only scrolls when nothing else consumed. Since the events are shared
    # with the parent, it also checks `is_mouseinside(scene)` so stacked areas
    # don't all scroll on every wheel event.
    on(blockscene, scene.events.scroll; priority = -1) do (dx, dy)
        sa.scrollable[] || return Consume(false)
        is_mouseinside(scene) || return Consume(false)
        cs = sa.contentsize[]
        ca = scene.viewport[]
        vw, vh = Float32.(widths(ca))
        cw, ch = max(cs[1], vw), max(cs[2], vh)
        (cw <= vw && ch <= vh) && return Consume(false)
        step = Float32(sa.scroll_speed[])
        sa.scroll[] = Vec2f(sa.scroll[][1] + step * dx, sa.scroll[][2] - step * dy)
        return Consume(true)
    end

    drag_state = Ref{Tuple{Symbol, Float32, Vec2f}}((:none, 0.0f0, Vec2f(0, 0)))
    # If the area becomes invisible mid-drag (e.g. a Tab switch), or the backend
    # ever drops the mouse-release, the drag must be cleared so the next
    # mouse-move doesn't keep scrolling.
    on(blockscene, is_visible) do v
        v || (drag_state[] = (:none, 0.0f0, Vec2f(0, 0)))
        return
    end
    # When this area becomes visible (e.g. a hidden tab is activated), unhide any
    # child blocks whose `scene.visible` was kept `false` because `unhide!` saw
    # the parent scene as invisible during block construction.
    on(blockscene, is_visible) do v
        v || return
        for block in flatten_layout_content(sa.layout)
            unhide!(block)
        end
        return
    end
    on(blockscene, blockscene.events.mousebutton) do ev
        if ev.action == Mouse.release && drag_state[][1] !== :none
            drag_state[] = (:none, 0.0f0, Vec2f(0, 0))
        end
        return Consume(false)
    end
    function bar_at(pos)
        (is_visible[] && sa.scrollable[]) || return :none
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

    on(blockscene, blockscene.events.mouseposition; priority = 60) do pos
        is_visible[] || return Consume(false)
        kind = bar_at(pos)
        st = drag_state[][1]
        v_highlight = st === :vdrag || kind in (:vthumb, :vtrack)
        h_highlight = st === :hdrag || kind in (:hthumb, :htrack)
        vthumb_color[] = to_color(v_highlight ? sa.scrollbar_thumb_color_active[] : sa.scrollbar_thumb_color[])
        hthumb_color[] = to_color(h_highlight ? sa.scrollbar_thumb_color_active[] : sa.scrollbar_thumb_color[])

        st, anchor, anchor_scroll = drag_state[]
        if st === :vdrag
            ca = scene.viewport[]
            vh = Float32(widths(ca)[2])
            ch = max(sa.contentsize[][2], vh)
            max_sy = max(0.0f0, ch - vh)
            max_sy == 0 && return Consume(false)
            thumb_h = max(20.0f0, vh * vh / ch)
            usable = vh - thumb_h
            dy = anchor - Float32(pos[2])
            new_sy = clamp(anchor_scroll[2] + dy * max_sy / usable, 0.0f0, max_sy)
            sa.scroll[] = Vec2f(sa.scroll[][1], new_sy)
            return Consume(true)
        elseif st === :hdrag
            ca = scene.viewport[]
            vw = Float32(widths(ca)[1])
            cw = max(sa.contentsize[][1], vw)
            max_sx = max(0.0f0, cw - vw)
            max_sx == 0 && return Consume(false)
            thumb_w = max(20.0f0, vw * vw / cw)
            usable = vw - thumb_w
            dx = Float32(pos[1]) - anchor
            new_sx = clamp(anchor_scroll[1] + dx * max_sx / usable, 0.0f0, max_sx)
            sa.scroll[] = Vec2f(new_sx, sa.scroll[][2])
            return Consume(true)
        end
        return Consume(false)
    end

    on(blockscene, blockscene.events.mousebutton; priority = 60) do ev
        is_visible[] || return Consume(false)
        if ev.button == Mouse.left && ev.action == Mouse.press
            pos = blockscene.events.mouseposition[]
            kind = bar_at(pos)
            if kind === :vthumb
                drag_state[] = (:vdrag, Float32(pos[2]), sa.scroll[])
                return Consume(true)
            elseif kind === :hthumb
                drag_state[] = (:hdrag, Float32(pos[1]), sa.scroll[])
                return Consume(true)
            elseif kind === :vtrack
                vh = Float32(widths(scene.viewport[])[2])
                dir = Float32(pos[2]) < (vthumb_rect[].origin[2] + vthumb_rect[].widths[2] / 2) ? 1 : -1
                sa.scroll[] = Vec2f(sa.scroll[][1], sa.scroll[][2] + dir * vh)
                return Consume(true)
            elseif kind === :htrack
                vw = Float32(widths(scene.viewport[])[1])
                dir = Float32(pos[1]) > (hthumb_rect[].origin[1] + hthumb_rect[].widths[1] / 2) ? 1 : -1
                sa.scroll[] = Vec2f(sa.scroll[][1] + dir * vw, sa.scroll[][2])
                return Consume(true)
            end
        elseif ev.button == Mouse.left && ev.action == Mouse.release
            drag_state[] = (:none, 0.0f0, Vec2f(0, 0))
        end
        return Consume(false)
    end

    notify(sa.layoutobservables.suggestedbbox)
    return
end

content_scene(sa::ScrollArea) = sa.scene

# `unhide!` force-sets `b.scene.visible[] = true` (intended for blocks like Axis
# that initialise it `false`), which would override the reactive binding from
# `sa.visible`. ScrollArea's scene visibility follows `sa.visible`, so don't touch
# `sa.scene.visible` here — just unhide the blockscene like the default would.
function unhide!(sa::ScrollArea)
    sa.blockscene.visible[] || (sa.blockscene.visible[] = true)
    return
end

# Recurse into the area's layout so blocks placed inside get their pre-display
# updates (auto axis limits etc.).
function update_state_before_display!(sa::ScrollArea)
    return update_state_before_display!(sa.layout)
end
