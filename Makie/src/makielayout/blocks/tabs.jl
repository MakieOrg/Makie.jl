function initialize_block!(t::Tabs)
    blockscene = t.blockscene
    t.scenes = Scene[]
    t.layouts = GridLayout[]
    t.scrolls = Observable{Vec2f}[]
    t.contentsizes = Observable{Vec2f}[]

    headerheight = Observable(0.0; ignore_equal_values = true)
    hovered = Observable(0; ignore_equal_values = true)

    # A single continuous separator line under the header that leads up and
    # around the active tab — its left/top/right edges replace the straight
    # line, so the active tab visually connects to the content area below
    # without any inactive tabs needing a different background color.
    sep_path = Observable(Point2f[])
    sep_plot = lines!(
        blockscene, sep_path;
        color = t.separator_color, linewidth = t.separator_thickness, inspectable = false
    )
    # raise above the tab polys (which sit at z=0) so the line isn't covered
    # where it runs along their shared bottom edge
    translate!(sep_plot, 0, 0, 2)

    # per-tab header primitives, indexed alongside t.scenes / t.layouts
    tab_rects = Observable{Rect2f}[]
    tab_bgcolors = Observable{RGBAf}[]
    tab_labelpositions = Observable{Point2f}[]
    tab_labelcolors = Observable{RGBAf}[]
    tab_labelbbs = Observable[]

    # per-tab scrollbar state (drawn in blockscene, gated by overflow)
    vbar_rect = Observable{Rect2f}[]            # vertical track rect (per tab)
    vthumb_rect = Observable{Rect2f}[]
    vthumb_color = Observable{RGBAf}[]
    hbar_rect = Observable{Rect2f}[]
    hthumb_rect = Observable{Rect2f}[]
    hthumb_color = Observable{RGBAf}[]
    vbar_visible = Observable{Bool}[]
    hbar_visible = Observable{Bool}[]
    # interactive scrollbar state shared across tabs (only one drag at a time)
    drag_state = Ref{Tuple{Symbol, Int, Float32, Vec2f}}((:none, 0, 0.0f0, Vec2f(0, 0)))

    content_area = lift(blockscene, t.layoutobservables.computedbbox, headerheight) do cbb, hh
        return round_to_IRect2D(BBox(left(cbb), right(cbb), bottom(cbb), top(cbb) - hh))
    end

    function recompute_layout!()
        n = length(t.scenes)
        n == 0 && return
        pad = t.tabpadding[]
        gap = t.tabgap[]
        widths_ = Vector{Float32}(undef, n)
        hmax = 0.0
        for i in 1:n
            bbs = tab_labelbbs[i][]
            w = isempty(bbs) ? 0.0 : width(bbs[1])
            h = isempty(bbs) ? 0.0 : height(bbs[1])
            widths_[i] = w + pad[1] + pad[2]
            hmax = max(hmax, h)
        end
        th = t.tabheight[]
        headerheight[] = th === automatic ? hmax + pad[3] + pad[4] : Float64(th)

        cbb = t.layoutobservables.computedbbox[]
        hh = headerheight[]
        l, top_ = left(cbb), top(cbb)
        active = t.active[]
        hov = hovered[]
        x = l
        for i in 1:n
            x0 = x
            x1 = x + widths_[i]
            tab_rects[i][] = BBox(x0, x1, top_ - hh, top_)
            tab_labelpositions[i][] = Point2f((x0 + x1) / 2, top_ - hh / 2)
            tab_bgcolors[i][] = to_color(
                i == active ? t.tabcolor_active[] :
                    i == hov ? t.tabcolor_hover[] : t.tabcolor_inactive[]
            )
            tab_labelcolors[i][] = to_color(i == active ? t.labelcolor_active[] : t.labelcolor_inactive[])
            x = x1 + gap
        end

        # Separator path: a horizontal line under the header that detours up and
        # over the active tab so the active tab "merges" into the content area.
        sep_y = Float32(top_ - hh)
        if 1 <= active <= n
            ar = tab_rects[active][]
            ax0, ax1 = left(ar), right(ar)
            aytop = top(ar)
            sep_path[] = Point2f[
                (Float32(l), sep_y),
                (ax0, sep_y),
                (ax0, aytop),
                (ax1, aytop),
                (ax1, sep_y),
                (Float32(right(cbb)), sep_y),
            ]
        else
            sep_path[] = Point2f[(Float32(l), sep_y), (Float32(right(cbb)), sep_y)]
        end
        return
    end

    function update_scrollbars!(i)
        ca = t.scenes[i].viewport[]
        cs = t.contentsizes[i][]
        sc = t.scrolls[i][]
        sbsize = Float32(t.scrollbar_size[])
        vw, vh = Float32.(widths(ca))
        cw, ch = max(cs[1], vw), max(cs[2], vh)
        max_sx, max_sy = max(0.0f0, cw - vw), max(0.0f0, ch - vh)

        vbar_visible[i][] = max_sy > 0
        hbar_visible[i][] = max_sx > 0

        if max_sy > 0
            tx = right(ca) - sbsize
            vbar_rect[i][] = Rect2f((tx, bottom(ca)), (sbsize, vh))
            thumb_h = max(20.0f0, vh * vh / ch)
            usable = vh - thumb_h
            ty = top(ca) - thumb_h - (sc[2] / max_sy) * usable
            vthumb_rect[i][] = Rect2f((tx, ty), (sbsize, thumb_h))
        end
        if max_sx > 0
            by = bottom(ca)
            hbar_rect[i][] = Rect2f((left(ca), by), (vw, sbsize))
            thumb_w = max(20.0f0, vw * vw / cw)
            usable = vw - thumb_w
            tx = left(ca) + (sc[1] / max_sx) * usable
            hthumb_rect[i][] = Rect2f((tx, by), (thumb_w, sbsize))
        end
        return
    end

    function add_tab!(i)
        is_active = lift(a -> a == i, blockscene, t.active)
        # `clip` clips to the visible content area and isolates input events
        # for this tab. Direct content_scene(t, i) plotting goes here, so users
        # plot in tab-local pixel coordinates (origin at content-area corner).
        clip = Scene(
            blockscene; events = Events(), camera = campixel!,
            viewport = content_area, visible = is_active, clear = false
        )
        forward_events!(clip, blockscene; active = is_active)
        # Inner scene uses the root figure's viewport so that Blocks placed via
        # the GridLayout — whose decoration code positions things in absolute
        # window pixels — render at the right place. The clipping comes from
        # `clip` being an ancestor via the effective-viewport scissor.
        root_viewport = root(blockscene).viewport
        inner = Scene(clip; viewport = root_viewport, camera = campixel!, clear = false)

        scroll = Observable(Vec2f(0, 0); ignore_equal_values = true)
        contentsize = Observable(Vec2f(0, 0); ignore_equal_values = true)
        layout_bbox = Observable(Rect2f(0, 0, 1, 1); ignore_equal_values = true)
        layout = GridLayout(; bbox = layout_bbox)
        layout.parent = inner

        push!(t.scenes, clip)
        push!(t.layouts, layout)
        push!(t.scrolls, scroll)
        push!(t.contentsizes, contentsize)

        # Offset the layout's bbox by the scroll, sizing it to fit at least the
        # viewport and stretching to content size if it's larger.
        onany(blockscene, content_area, scroll, contentsize) do ca, sc, cs
            vw, vh = Float32.(widths(ca))
            cw, ch = max(cs[1], vw), max(cs[2], vh)
            max_sx, max_sy = max(0.0f0, cw - vw), max(0.0f0, ch - vh)
            sx = clamp(sc[1], 0.0f0, max_sx)
            sy = clamp(sc[2], 0.0f0, max_sy)
            if sx != sc[1] || sy != sc[2]
                scroll[] = Vec2f(sx, sy)
                return
            end
            top_edge = top(ca) + sy
            left_edge = left(ca) - sx
            layout_bbox[] = Rect2f(Point2f(left_edge, top_edge - ch), Vec2f(cw, ch))
            update_scrollbars!(i)
            return
        end

        # Outside padding keeps block protrusions (axis titles, ticklabels) inside
        # the clipped content area instead of overflowing and getting cut off.
        on(blockscene, t.contentpadding; update = true) do pad
            sides = pad isa Number ? (pad, pad, pad, pad) : pad
            layout.alignmode[] = Outside(to_rectsides(sides))
            GridLayoutBase.update!(layout)
            return
        end

        # After every layout pass, remeasure the determinable content size so
        # scroll bounds and scrollbars react to fixed row/col sizes the user
        # sets via `colsize!`/`rowsize!`/`width=`/`height=`.
        on(blockscene, layout.layoutobservables.computedbbox) do _
            dw = GridLayoutBase.determinedirsize(layout, GridLayoutBase.Col())
            dh = GridLayoutBase.determinedirsize(layout, GridLayoutBase.Row())
            cw = dw === nothing ? 0.0f0 : Float32(dw)
            ch = dh === nothing ? 0.0f0 : Float32(dh)
            contentsize[] = Vec2f(cw, ch)
            return
        end

        # Wheel/trackpad scrolling. Uses the tab's isolated events, so only the
        # active tab sees the scroll.
        # Container scrolling runs at a priority below the default so inner
        # blocks (e.g. an Axis zoom-on-scroll handler at priority 0) get the
        # event first; we only scroll the container if nothing consumed it.
        on(blockscene, clip.events.scroll; priority = -1) do (dx, dy)
            cs = contentsize[]
            ca = clip.viewport[]
            vw, vh = Float32.(widths(ca))
            cw, ch = max(cs[1], vw), max(cs[2], vh)
            (cw <= vw && ch <= vh) && return Consume(false)
            step = Float32(t.scroll_speed[])
            scroll[] = Vec2f(scroll[][1] + step * dx, scroll[][2] - step * dy)
            return Consume(true)
        end

        # scrollbar primitives (drawn in blockscene so they sit above content)
        vbar_r = Observable(Rect2f(0, 0, 0, 0))
        vth_r = Observable(Rect2f(0, 0, 0, 0))
        vth_c = Observable(to_color(t.scrollbar_thumb_color[]))
        vvis = Observable(false; ignore_equal_values = true)
        hbar_r = Observable(Rect2f(0, 0, 0, 0))
        hth_r = Observable(Rect2f(0, 0, 0, 0))
        hth_c = Observable(to_color(t.scrollbar_thumb_color[]))
        hvis = Observable(false; ignore_equal_values = true)
        push!(vbar_rect, vbar_r)
        push!(vthumb_rect, vth_r)
        push!(vthumb_color, vth_c)
        push!(hbar_rect, hbar_r)
        push!(hthumb_rect, hth_r)
        push!(hthumb_color, hth_c)
        push!(vbar_visible, vvis)
        push!(hbar_visible, hvis)
        poly!(blockscene, vbar_r; color = t.scrollbar_color, visible = lift(&, is_active, vvis), inspectable = false)
        poly!(blockscene, vth_r; color = vth_c, visible = lift(&, is_active, vvis), inspectable = false)
        poly!(blockscene, hbar_r; color = t.scrollbar_color, visible = lift(&, is_active, hvis), inspectable = false)
        poly!(blockscene, hth_r; color = hth_c, visible = lift(&, is_active, hvis), inspectable = false)
        return
    end

    function add_header!(i)
        rect = Observable(Rect2f(0, 0, 0, 0))
        bgcolor = Observable(to_color(t.tabcolor_inactive[]))
        labelpos = Observable(Point2f(0, 0))
        labelcolor = Observable(to_color(t.labelcolor_inactive[]))
        push!(tab_rects, rect)
        push!(tab_bgcolors, bgcolor)
        push!(tab_labelpositions, labelpos)
        push!(tab_labelcolors, labelcolor)

        poly_pts = lift(roundedrectvertices, blockscene, rect, t.cornerradius, t.cornersegments)
        poly!(blockscene, poly_pts; color = bgcolor, inspectable = false)
        labelstr = lift(ls -> get(ls, i, ""), blockscene, t.labels)
        labelplot = text!(
            blockscene, labelpos; text = labelstr, fontsize = t.fontsize, font = t.font,
            color = labelcolor, align = (:center, :center), markerspace = :data, inspectable = false
        )
        translate!(labelplot, 0, 0, 1)
        bbs = fast_string_boundingboxes_obs(labelplot)
        push!(tab_labelbbs, bbs)
        on(_ -> recompute_layout!(), blockscene, bbs)
        return
    end

    on(blockscene, t.labels; update = true) do labels
        while length(t.scenes) < length(labels)
            i = length(t.scenes) + 1
            add_tab!(i)
            add_header!(i)
        end
        recompute_layout!()
        return
    end

    onany(
        blockscene, t.layoutobservables.computedbbox, t.active, hovered, t.tabheight,
        t.tabpadding, t.tabgap, t.tabcolor_active, t.tabcolor_inactive, t.tabcolor_hover,
        t.labelcolor_active, t.labelcolor_inactive
    ) do args...
        recompute_layout!()
    end

    function tab_at(pos)
        p = Point2f(pos)
        for i in 1:length(t.scenes)
            p in tab_rects[i][] && return i
        end
        return 0
    end

    # Returns (:vthumb | :vtrack | :hthumb | :htrack | :none, tab_index) at pos.
    # We only look at the currently active tab, since inactive scrollbars are hidden.
    function scrollbar_at(pos)
        i = t.active[]
        i == 0 && return :none, 0
        p = Point2f(pos)
        vvis = i <= length(vbar_visible) && vbar_visible[i][]
        hvis = i <= length(hbar_visible) && hbar_visible[i][]
        if vvis
            p in vthumb_rect[i][] && return :vthumb, i
            p in vbar_rect[i][] && return :vtrack, i
        end
        if hvis
            p in hthumb_rect[i][] && return :hthumb, i
            p in hbar_rect[i][] && return :htrack, i
        end
        return :none, 0
    end

    on(blockscene, blockscene.events.mouseposition) do pos
        hovered[] = tab_at(pos)
        kind, i = scrollbar_at(pos)
        st, di, _, _ = drag_state[]
        for j in 1:length(t.scenes)
            # Keep the dragged thumb highlighted regardless of mouse position,
            # otherwise dragging "off" the thumb visibly drops the active state.
            v_active = (st === :vdrag && di == j) || (kind in (:vthumb, :vtrack) && j == i)
            h_active = (st === :hdrag && di == j) || (kind in (:hthumb, :htrack) && j == i)
            vthumb_color[j][] = to_color(v_active ? t.scrollbar_thumb_color_active[] : t.scrollbar_thumb_color[])
            hthumb_color[j][] = to_color(h_active ? t.scrollbar_thumb_color_active[] : t.scrollbar_thumb_color[])
        end
        # handle ongoing drag
        anchor = drag_state[][3]
        anchor_scroll = drag_state[][4]
        if st === :vdrag && di > 0
            ca = t.scenes[di].viewport[]
            vh = Float32(widths(ca)[2])
            ch = max(t.contentsizes[di][][2], vh)
            max_sy = max(0.0f0, ch - vh)
            max_sy == 0 && return Consume(false)
            thumb_h = max(20.0f0, vh * vh / ch)
            usable = vh - thumb_h
            # pos.y vs anchor.y: dragging DOWN (y decreases in window coords) → scroll down (scroll_y increases)
            dy = anchor - Float32(pos[2])
            new_sy = clamp(anchor_scroll[2] + dy * max_sy / usable, 0.0f0, max_sy)
            t.scrolls[di][] = Vec2f(t.scrolls[di][][1], new_sy)
            return Consume(true)
        elseif st === :hdrag && di > 0
            ca = t.scenes[di].viewport[]
            vw = Float32(widths(ca)[1])
            cw = max(t.contentsizes[di][][1], vw)
            max_sx = max(0.0f0, cw - vw)
            max_sx == 0 && return Consume(false)
            thumb_w = max(20.0f0, vw * vw / cw)
            usable = vw - thumb_w
            dx = Float32(pos[1]) - anchor
            new_sx = clamp(anchor_scroll[1] + dx * max_sx / usable, 0.0f0, max_sx)
            t.scrolls[di][] = Vec2f(new_sx, t.scrolls[di][][2])
            return Consume(true)
        end
        return Consume(false)
    end

    on(blockscene, blockscene.events.mousebutton; priority = 60) do ev
        if ev.button == Mouse.left && ev.action == Mouse.press
            pos = blockscene.events.mouseposition[]
            kind, i = scrollbar_at(pos)
            if kind === :vthumb
                drag_state[] = (:vdrag, i, Float32(pos[2]), t.scrolls[i][])
                return Consume(true)
            elseif kind === :hthumb
                drag_state[] = (:hdrag, i, Float32(pos[1]), t.scrolls[i][])
                return Consume(true)
            elseif kind === :vtrack
                # page scroll: jump by viewport height
                ca = t.scenes[i].viewport[]
                vh = Float32(widths(ca)[2])
                dir = Float32(pos[2]) < (vthumb_rect[i][].origin[2] + vthumb_rect[i][].widths[2] / 2) ? 1 : -1
                t.scrolls[i][] = Vec2f(t.scrolls[i][][1], t.scrolls[i][][2] + dir * vh)
                return Consume(true)
            elseif kind === :htrack
                ca = t.scenes[i].viewport[]
                vw = Float32(widths(ca)[1])
                dir = Float32(pos[1]) > (hthumb_rect[i][].origin[1] + hthumb_rect[i][].widths[1] / 2) ? 1 : -1
                t.scrolls[i][] = Vec2f(t.scrolls[i][][1] + dir * vw, t.scrolls[i][][2])
                return Consume(true)
            else
                # tab header click
                ti = tab_at(pos)
                if ti != 0
                    t.active[] = ti
                    return Consume(true)
                end
            end
        elseif ev.button == Mouse.left && ev.action == Mouse.release
            drag_state[] = (:none, 0, 0.0f0, Vec2f(0, 0))
        end
        return Consume(false)
    end

    notify(t.layoutobservables.suggestedbbox)
    return
end

Base.getindex(t::Tabs, i::Integer) = t.layouts[i]

"""
    content_scene(tabs::Tabs, i::Integer)

Return the content `Scene` of tab `i`, for plotting directly into a tab.
"""
content_scene(t::Tabs, i::Integer) = t.scenes[i]

# Blocks placed inside a tab's GridLayout aren't in `fig.content` (they're
# created with a Scene parent, so `register_in_figure!` is skipped). Hand the
# pre-display updates down to each tab's layout so auto axis limits etc. run.
function update_state_before_display!(t::Tabs)
    for layout in t.layouts
        update_state_before_display!(layout)
    end
    return
end
