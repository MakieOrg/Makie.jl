function initialize_block!(t::Tabs)
    blockscene = t.blockscene
    t.subfigures = Subfigure[]

    headerheight = Observable(0.0; ignore_equal_values = true)
    hovered = Observable(0; ignore_equal_values = true)

    # A single continuous separator line under the header that detours up and
    # around the active tab — its left/top/right edges replace the straight
    # line, so the active tab visually connects to the content area below.
    sep_path = Observable(Point2f[])
    sep_plot = lines!(
        blockscene, sep_path;
        color = t.separator_color, linewidth = t.separator_thickness, inspectable = false
    )
    # raise above the tab polys (z = 0) so the line isn't covered along their
    # shared bottom edge
    translate!(sep_plot, 0, 0, 2)

    # per-tab header primitives, indexed alongside t.subfigures
    tab_rects = Observable{Rect2f}[]
    tab_bgcolors = Observable{RGBAf}[]
    tab_labelpositions = Observable{Point2f}[]
    tab_labelcolors = Observable{RGBAf}[]
    tab_labelbbs = Observable[]
    # close-button state
    close_segments = Observable{Vector{Point2f}}[]  # 4 points per tab (two diagonals)
    close_colors = Observable{RGBAf}[]
    close_rects = Observable{Rect2f}[]  # hit-test region, slightly larger than the glyph
    close_hovered = Observable(0; ignore_equal_values = true)
    # Resolved label-font metrics (in EM units, multiply by fontsize for pixels).
    # Updated once the first label plot resolves its font; defaults are sane for
    # most sans-serif fonts so the very first frame doesn't draw at (0, 0).
    font_metrics = Observable((asc = 0.95f0, des = -0.21f0, xh = 0.52f0))

    content_area = lift(blockscene, t.layoutobservables.computedbbox, headerheight) do cbb, hh
        return round_to_IRect2D(BBox(left(cbb), right(cbb), bottom(cbb), top(cbb) - hh))
    end

    function recompute_layout!()
        n = length(t.labels[])
        n == 0 && return
        pad = t.tabpadding[]
        gap = t.tabgap[]
        fs = Float32(t.fontsize[])
        fm = font_metrics[]
        x_height_px = fm.xh * fs
        closable = t.closable[]
        close_w = closable ? x_height_px : 0.0f0
        close_gap = closable ? x_height_px * 1.6f0 : 0.0f0
        widths_ = Vector{Float32}(undef, n)
        labelws = Vector{Float32}(undef, n)
        hmax = 0.0
        for i in 1:n
            bbs = tab_labelbbs[i][]
            w = isempty(bbs) ? 0.0 : width(bbs[1])
            h = isempty(bbs) ? 0.0 : height(bbs[1])
            labelws[i] = w
            hmax = max(hmax, h)
            widths_[i] = w + pad[1] + pad[2] + close_w + close_gap
        end
        th = t.tabheight[]
        headerheight[] = th === automatic ? hmax + pad[3] + pad[4] : Float64(th)

        cbb = t.layoutobservables.computedbbox[]
        hh = headerheight[]
        l, top_ = left(cbb), top(cbb)
        active = t.active[]
        hov = hovered[]
        chov = close_hovered[]
        x = l
        for i in 1:n
            x0 = x
            x1 = x + widths_[i]
            tab_rects[i][] = BBox(x0, x1, top_ - hh, top_)
            # label sits left-aligned in the tab, centered vertically
            tab_labelpositions[i][] = Point2f(x0 + pad[1] + labelws[i] / 2, top_ - hh / 2)
            # close button sits to the right of the label; its width is the
            # measured glyph width so pad[2] on its right matches pad[1] on
            # the label's left.
            # The × is drawn as two diagonal line segments, baseline-aligned
            # with the label (so it sits where a lowercase 'x' would) and
            # sized to the font's x-height.
            close_cx = x0 + pad[1] + labelws[i] + close_gap + close_w / 2
            baseline_y = top_ - hh / 2 - (fm.asc + fm.des) / 2 * fs
            half = x_height_px / 2
            y_top = baseline_y + x_height_px
            y_bot = baseline_y
            close_segments[i][] = Point2f[
                Point2f(close_cx - half, y_top), Point2f(close_cx + half, y_bot),  # \
                Point2f(close_cx + half, y_top), Point2f(close_cx - half, y_bot),  # /
            ]
            # hit-test region a bit larger than the glyph, centred on the tab
            hit_half = max(close_w, fs) / 2 + 2
            close_rects[i][] = Rect2f(close_cx - hit_half, top_ - hh / 2 - hit_half, 2hit_half, 2hit_half)
            close_colors[i][] = to_color(i == chov ? t.closecolor_hover[] : t.closecolor[])

            tab_bgcolors[i][] = to_color(
                i == active ? t.tabcolor_active[] :
                    i == hov ? t.tabcolor_hover[] : t.tabcolor_inactive[]
            )
            tab_labelcolors[i][] = to_color(i == active ? t.labelcolor_active[] : t.labelcolor_inactive[])
            x = x1 + gap
        end

        # Separator path: a horizontal line under the header that detours up
        # and over the active tab so the active tab "merges" into the panel.
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

    function add_subfigure!(i)
        is_active = lift(a -> a == i, blockscene, t.active)
        sf = Subfigure(
            blockscene;
            bbox = content_area,
            isolate_events = true,
            visible = is_active,
            contentpadding = t.contentpadding,
        )
        push!(t.subfigures, sf)
        return sf
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

        # The first label resolves the font we'll use for the close glyph
        # too; capture its metrics so the × is sized to the x-height and
        # sits on the label's baseline.
        if i == 1
            on(blockscene, labelplot.selected_font; update = true) do f
                try
                    asc = Float32(Makie.FreeTypeAbstraction.ascender(f))
                    des = Float32(Makie.FreeTypeAbstraction.descender(f))
                    ext = Makie.FreeTypeAbstraction.get_extent(f, 'x')
                    bb = Makie.FreeTypeAbstraction.inkboundingbox(ext)
                    xh = Float32(widths(bb)[2])
                    font_metrics[] = (asc = asc, des = des, xh = xh)
                catch
                    # keep defaults
                end
                return
            end
        end

        # Close "×" drawn as two diagonal line segments, sized to x-height.
        segs = Observable(Point2f[])
        close_color = Observable(to_color(t.closecolor[]))
        close_rect = Observable(Rect2f(0, 0, 0, 0))
        push!(close_segments, segs)
        push!(close_colors, close_color)
        push!(close_rects, close_rect)
        close_visible = lift((c, ls) -> c && i <= length(ls), blockscene, t.closable, t.labels)
        close_lw = lift(fs -> max(1.0f0, Float32(fs) * 0.08f0), blockscene, t.fontsize)
        close_plot = linesegments!(
            blockscene, segs;
            color = close_color, linewidth = close_lw, visible = close_visible,
            inspectable = false,
        )
        translate!(close_plot, 0, 0, 1)
        return
    end

    on(blockscene, t.labels; update = true) do labels
        n = length(labels)
        # grow if more labels
        while length(t.subfigures) < n
            add_subfigure!(length(t.subfigures) + 1)
            add_header!(length(t.subfigures))
        end
        # clamp active onto the new range so it doesn't point at a removed tab
        if !isempty(labels) && t.active[] > n
            t.active[] = clamp(t.active[], 1, n)
        end
        # extra subfigures stay around (their `visible` is bound to
        # `active == i` so they're already hidden), but their headers shouldn't
        # render. Move the leftover tab rects off-screen and the labels are
        # already empty strings via `get(ls, i, "")`.
        for i in (n + 1):length(t.subfigures)
            tab_rects[i][] = Rect2f(0, 0, 0, 0)
        end
        recompute_layout!()
        return
    end

    onany(
        blockscene, t.layoutobservables.computedbbox, t.active, hovered, close_hovered,
        t.tabheight, t.tabpadding, t.tabgap, t.tabcolor_active, t.tabcolor_inactive,
        t.tabcolor_hover, t.labelcolor_active, t.labelcolor_inactive,
        t.closable, t.closecolor, t.closecolor_hover, font_metrics,
    ) do args...
        recompute_layout!()
    end

    function close_at(pos)
        t.closable[] || return 0
        p = Point2f(pos)
        for i in 1:length(t.labels[])
            p in close_rects[i][] && return i
        end
        return 0
    end

    function tab_at(pos)
        p = Point2f(pos)
        for i in 1:length(t.labels[])
            p in tab_rects[i][] && return i
        end
        return 0
    end

    on(blockscene, blockscene.events.mouseposition) do pos
        hovered[] = tab_at(pos)
        close_hovered[] = close_at(pos)
        return Consume(false)
    end

    on(blockscene, blockscene.events.mousebutton; priority = 60) do ev
        if ev.button == Mouse.left && ev.action == Mouse.press
            pos = blockscene.events.mouseposition[]
            # Close button takes precedence over the tab body click: clicking
            # the × removes the tab without first making it active.
            ci = close_at(pos)
            if ci != 0
                t.labels[] = vcat(t.labels[][1:(ci - 1)], t.labels[][(ci + 1):end])
                return Consume(true)
            end
            i = tab_at(pos)
            if i != 0
                t.active[] = i
                return Consume(true)
            end
        end
        return Consume(false)
    end

    notify(t.layoutobservables.suggestedbbox)
    return
end

Base.getindex(t::Tabs, i::Integer) = t.subfigures[i]

# Generic `Block` indexing would lazy-init a fresh, disconnected `GridLayout`
# on `t.layout` — a silent foot-gun: `Axis(tabs[1, 1])` would create an
# orphan that never displays. Force users to specify which tab.
function Base.getindex(
        ::Tabs,
        ::Union{Integer, Colon, AbstractRange},
        ::Union{Integer, Colon, AbstractRange},
        side = GridLayoutBase.Inner()
    )
    error(
        "`Tabs` doesn't have a top-level grid layout — index into a specific " *
            "tab first: `tabs[i][row, col]` (or `tabs[i].layout[row, col]`)."
    )
end

"""
    content_scene(tabs::Tabs, i::Integer)

Return the content `Scene` of tab `i`, for plotting directly into a tab.
"""
content_scene(t::Tabs, i::Integer) = content_scene(t.subfigures[i])

# Hand pre-display state updates to each tab's Subfigure so blocks placed inside a
# tab (which the Figure can't see because they have a Scene parent, not a
# Figure parent) still get e.g. auto axis limits.
function update_state_before_display!(t::Tabs)
    for sf in t.subfigures
        update_state_before_display!(sf)
    end
    return
end
