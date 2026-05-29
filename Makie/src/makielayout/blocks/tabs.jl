# Whether tab `i` is closable, given the `closable` attribute value (a single
# `Bool` for all tabs, or a `Vector{Bool}` indexed per tab; out-of-range = not
# closable).
_tab_closable(c::Bool, i) = c
_tab_closable(c::AbstractVector, i) = (1 <= i <= length(c)) && Bool(c[i])

function initialize_block!(t::Tabs)
    blockscene = t.blockscene
    t.subfigures = Subfigure[]

    tab_closable(i) = _tab_closable(t.closable[], i)

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

    # Per-tab state, all kept in lockstep with `t.subfigures` (and with
    # `t.labels`). Header text / close visibility / geometry are driven
    # imperatively from `recompute_layout!` rather than captured per creation
    # index, so closing a tab in the middle (which `deleteat!`s every array)
    # keeps slot i ↔ subfigure i ↔ label i aligned.
    tab_rects = Observable{Rect2f}[]
    tab_bgcolors = Observable{RGBAf}[]
    tab_labelpositions = Observable{Point2f}[]
    tab_labelcolors = Observable{RGBAf}[]
    tab_labeltexts = Observable{String}[]
    tab_labelbbs = Observable[]
    close_segments = Observable{Vector{Point2f}}[]  # 4 points per tab (two diagonals)
    close_colors = Observable{RGBAf}[]
    close_rects = Observable{Rect2f}[]  # hit-test region, slightly larger than the glyph
    close_visibles = Observable{Bool}[]
    subfig_visibles = Observable{Bool}[]
    header_plots = Tuple{Any, Any, Any}[]  # (poly, label, close) per tab, for deletion
    close_hovered = Observable(0; ignore_equal_values = true)
    # Resolved label-font metrics (in EM units, multiply by fontsize for pixels).
    # Updated once a label plot resolves its font; defaults are sane for most
    # sans-serif fonts so the very first frame doesn't draw at (0, 0).
    font_metrics = Observable((asc = 0.95f0, des = -0.21f0, xh = 0.52f0))
    font_metrics_captured = Ref(false)

    content_area = lift(blockscene, t.layoutobservables.computedbbox, headerheight) do cbb, hh
        return round_to_IRect2D(BBox(left(cbb), right(cbb), bottom(cbb), top(cbb) - hh))
    end

    function refresh_visibility!()
        a = t.active[]
        for d in 1:length(subfig_visibles)
            subfig_visibles[d][] = (d == a)
        end
        return
    end

    function recompute_layout!()
        n = length(t.labels[])
        # blank any slots beyond the current label count (can happen if the
        # user sets `labels` to a shorter vector directly rather than closing)
        for i in (n + 1):length(tab_rects)
            tab_rects[i][] = Rect2f(0, 0, 0, 0)
            tab_labeltexts[i][] = ""
            close_visibles[i][] = false
            close_rects[i][] = Rect2f(0, 0, 0, 0)
        end
        n == 0 && return
        pad = t.tabpadding[]
        gap = t.tabgap[]
        fs = Float32(t.fontsize[])
        fm = font_metrics[]
        x_height_px = fm.xh * fs
        widths_ = Vector{Float32}(undef, n)
        labelws = Vector{Float32}(undef, n)
        close_ws = Vector{Float32}(undef, n)
        close_gaps = Vector{Float32}(undef, n)
        hmax = 0.0
        for i in 1:n
            tab_labeltexts[i][] = t.labels[][i]
            bbs = tab_labelbbs[i][]
            w = isempty(bbs) ? 0.0 : width(bbs[1])
            h = isempty(bbs) ? 0.0 : height(bbs[1])
            labelws[i] = w
            hmax = max(hmax, h)
            cl = tab_closable(i)
            close_ws[i] = cl ? x_height_px : 0.0f0
            close_gaps[i] = cl ? x_height_px * 1.6f0 : 0.0f0
            widths_[i] = w + pad[1] + pad[2] + close_ws[i] + close_gaps[i]
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
            # The × is drawn as two diagonal line segments, baseline-aligned
            # with the label (so it sits where a lowercase 'x' would) and sized
            # to the font's x-height. Non-closable tabs get empty segments and
            # a zero-size hit rect so nothing draws or hit-tests.
            close_visibles[i][] = close_ws[i] > 0
            if close_ws[i] > 0
                close_cx = x0 + pad[1] + labelws[i] + close_gaps[i] + close_ws[i] / 2
                baseline_y = top_ - hh / 2 - (fm.asc + fm.des) / 2 * fs
                half = x_height_px / 2
                y_top = baseline_y + x_height_px
                y_bot = baseline_y
                close_segments[i][] = Point2f[
                    Point2f(close_cx - half, y_top), Point2f(close_cx + half, y_bot),  # \
                    Point2f(close_cx + half, y_top), Point2f(close_cx - half, y_bot),  # /
                ]
                # hit-test region a bit larger than the glyph, centred on the tab
                hit_half = max(close_ws[i], fs) / 2 + 2
                close_rects[i][] = Rect2f(close_cx - hit_half, top_ - hh / 2 - hit_half, 2hit_half, 2hit_half)
                close_colors[i][] = to_color(i == chov ? t.closecolor_hover[] : t.closecolor[])
            else
                close_segments[i][] = Point2f[]
                close_rects[i][] = Rect2f(0, 0, 0, 0)
            end

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

    function add_subfigure!()
        vis = Observable(false; ignore_equal_values = true)
        sf = Subfigure(
            blockscene;
            bbox = content_area,
            isolate_events = true,
            visible = vis,
            contentpadding = t.contentpadding,
        )
        push!(t.subfigures, sf)
        push!(subfig_visibles, vis)
        return sf
    end

    function add_header!()
        rect = Observable(Rect2f(0, 0, 0, 0))
        bgcolor = Observable(to_color(t.tabcolor_inactive[]))
        labelpos = Observable(Point2f(0, 0))
        labelcolor = Observable(to_color(t.labelcolor_inactive[]))
        labeltext = Observable("")
        push!(tab_rects, rect)
        push!(tab_bgcolors, bgcolor)
        push!(tab_labelpositions, labelpos)
        push!(tab_labelcolors, labelcolor)
        push!(tab_labeltexts, labeltext)

        poly_pts = lift(roundedrectvertices, blockscene, rect, t.cornerradius, t.cornersegments)
        polyplot = poly!(blockscene, poly_pts; color = bgcolor, inspectable = false)
        labelplot = text!(
            blockscene, labelpos; text = labeltext, fontsize = t.fontsize, font = t.font,
            color = labelcolor, align = (:center, :center), markerspace = :data, inspectable = false
        )
        translate!(labelplot, 0, 0, 1)
        bbs = fast_string_boundingboxes_obs(labelplot)
        push!(tab_labelbbs, bbs)
        on(_ -> recompute_layout!(), blockscene, bbs)

        # Capture the resolved label font's metrics once, so the × is sized to
        # the x-height and sits on the label's baseline.
        if !font_metrics_captured[]
            font_metrics_captured[] = true
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
        close_visible = Observable(false)
        push!(close_segments, segs)
        push!(close_colors, close_color)
        push!(close_rects, close_rect)
        push!(close_visibles, close_visible)
        close_lw = lift(fs -> max(1.0f0, Float32(fs) * 0.08f0), blockscene, t.fontsize)
        closeplot = linesegments!(
            blockscene, segs;
            color = close_color, linewidth = close_lw, visible = close_visible,
            inspectable = false,
        )
        translate!(closeplot, 0, 0, 1)

        push!(header_plots, (polyplot, labelplot, closeplot))
        return
    end

    # Remove tab `ci`: delete its subfigure (freeing its content) and header
    # plots, drop the matching entry from every parallel array, then update
    # `labels` / `closable` / `active` so the remaining tabs stay aligned.
    function remove_tab!(ci)
        n = length(t.labels[])
        (1 <= ci <= n) || return

        delete!(t.subfigures[ci])
        deleteat!(t.subfigures, ci)
        deleteat!(subfig_visibles, ci)

        for p in header_plots[ci]
            delete!(blockscene, p)
        end
        deleteat!(header_plots, ci)
        for arr in (
                tab_rects, tab_bgcolors, tab_labelpositions, tab_labelcolors,
                tab_labeltexts, tab_labelbbs, close_segments, close_colors,
                close_rects, close_visibles,
            )
            deleteat!(arr, ci)
        end

        new_n = n - 1
        old_active = t.active[]
        new_active = if new_n == 0
            0
        elseif old_active < ci
            old_active
        elseif old_active == ci
            min(ci, new_n)
        else
            old_active - 1
        end

        # Order matters: `labels` must be updated first so the recompute it
        # triggers sees `n == new_n`, matching the already-shrunken arrays. The
        # `closable` vector and `active` are corrected immediately after (their
        # recomputes are synchronous, so no stale frame renders in between).
        t.labels[] = vcat(t.labels[][1:(ci - 1)], t.labels[][(ci + 1):end])
        c = t.closable[]
        if c isa AbstractVector && ci <= length(c)
            t.closable[] = vcat(c[1:(ci - 1)], c[(ci + 1):end])
        end
        t.active[] = new_active
        refresh_visibility!()
        recompute_layout!()
        return
    end

    on(blockscene, t.labels; update = true) do labels
        n = length(labels)
        while length(t.subfigures) < n
            add_subfigure!()
            add_header!()
        end
        # clamp active onto the new range so it doesn't point at a removed tab
        if !isempty(labels) && t.active[] > n
            t.active[] = clamp(t.active[], 1, n)
        end
        refresh_visibility!()
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

    on(blockscene, t.active) do _
        refresh_visibility!()
        return
    end

    function close_at(pos)
        p = Point2f(pos)
        for i in 1:length(t.labels[])
            tab_closable(i) || continue
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
                remove_tab!(ci)
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
