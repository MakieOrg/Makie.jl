block_kwargs(::Type{Tabs}) = Set([:closable])

function initialize_block!(t::Tabs, labels::AbstractVector = ["Tab 1", "Tab 2"]; closable = true)
    blockscene = t.blockscene

    t.tabs = TabData[]
    t.hovered = Observable(0; ignore_equal_values = true)
    t.close_hovered = Observable(0; ignore_equal_values = true)
    t.headerheight = Observable(0.0; ignore_equal_values = true)
    t.separator_path = Observable(Point2f[])
    # Defaults are sane for most sans-serif fonts so the first frame doesn't draw
    # the × at (0, 0); replaced once a label plot resolves its font.
    t.font_metrics = Observable(TabFontMetrics(0.95f0, -0.21f0, 0.52f0))
    t.font_metrics_captured = false

    t.content_area = lift(blockscene, t.layoutobservables.computedbbox, t.headerheight) do cbb, hh
        return round_to_IRect2D(BBox(left(cbb), right(cbb), bottom(cbb), top(cbb) - hh))
    end

    # A single continuous separator line under the header that detours up and
    # around the active tab — its left/top/right edges replace the straight
    # line, so the active tab visually connects to the content area below.
    sep_plot = lines!(
        blockscene, t.separator_path;
        color = t.separator_color, linewidth = t.separator_thickness, inspectable = false
    )
    # raise above the tab polys (z = 0) so the line isn't covered along their
    # shared bottom edge
    translate!(sep_plot, 0, 0, 2)

    closable_for(i) = closable isa AbstractVector ? (1 <= i <= length(closable) && Bool(closable[i])) : Bool(closable)
    for (i, label) in enumerate(labels)
        add_tab!(t, label; closable = closable_for(i))
    end

    onany(
        blockscene, t.layoutobservables.computedbbox, t.active, t.hovered, t.close_hovered,
        t.tabheight, t.tabpadding, t.tabgap, t.tabcolor_active, t.tabcolor_inactive,
        t.tabcolor_hover, t.labelcolor_active, t.labelcolor_inactive,
        t.closecolor, t.closecolor_hover, t.font_metrics,
    ) do args...
        recompute_layout!(t)
    end

    on(_ -> refresh_visibility!(t), blockscene, t.active)

    on(blockscene, blockscene.events.mouseposition) do pos
        t.hovered[] = tab_at(t, pos)
        t.close_hovered[] = close_at(t, pos)
        return Consume(false)
    end

    on(blockscene, blockscene.events.mousebutton; priority = 60) do ev
        if ev.button == Mouse.left && ev.action == Mouse.press
            pos = blockscene.events.mouseposition[]
            # Close button takes precedence over the tab body click: clicking
            # the × removes the tab without first making it active.
            ci = close_at(t, pos)
            if ci != 0
                remove_tab!(t, ci)
                return Consume(true)
            end
            i = tab_at(t, pos)
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

"""
    add_tab!(tabs::Tabs, label = "Tab N"; activate = false, kwargs...) -> Subfigure

Append a tab to `tabs` and return its [`Subfigure`](@ref). Plot into it via
`tabs[end][row, col] = Axis(...)` or `content_scene(tabs, length(tabs))`. Pass
`activate = true` to switch to the new tab immediately. The first tab added to an
empty `Tabs` becomes active automatically.

`label` accepts anything `text!` does — a plain `String`, a `rich(...)` for
colored / styled spans, or a `LaTeXString` (`L"..."`). Any further keywords
(e.g. `closable`) are forwarded to [`set_tab!`](@ref) to set the new tab's
properties.
"""
function add_tab!(
        t::Tabs, label = "Tab $(length(t.tabs) + 1)";
        activate::Bool = false, kwargs...
    )
    blockscene = t.blockscene

    visible = Observable(false; ignore_equal_values = true)
    # An inactive tab is hidden (`visible = false`), and the scene-stacking
    # event router (`receives_events`, honored by `is_mouseinside` /
    # `addmouseevents!`) keeps hidden subtrees inert — so the shared-events
    # Subfigure needs nothing extra to isolate a tab's input.
    sf = Subfigure(
        blockscene;
        bbox = t.content_area,
        visible = visible, contentpadding = t.contentpadding,
    )

    label_obs = Observable{Any}(label)
    closable_obs = Observable(true)
    rect = Observable(Rect2f(0, 0, 0, 0))
    bgcolor = Observable(to_color(t.tabcolor_inactive[]))
    labelpos = Observable(Point2f(0, 0))
    labelcolor = Observable(to_color(t.labelcolor_inactive[]))
    close_segments = Observable(Point2f[])
    close_color = Observable(to_color(t.closecolor[]))
    close_rect = Observable(Rect2f(0, 0, 0, 0))
    close_visible = Observable(false)

    poly_pts = lift(roundedrectvertices, blockscene, rect, t.cornerradius, t.cornersegments)
    polyplot = poly!(blockscene, poly_pts; color = bgcolor, inspectable = false)
    labelplot = text!(
        blockscene, labelpos; text = label_obs, fontsize = t.fontsize, font = t.font,
        color = labelcolor, align = (:center, :center), markerspace = :data, inspectable = false
    )
    translate!(labelplot, 0, 0, 1)
    labelboundingboxes = fast_string_boundingboxes_obs(labelplot)

    # Close "×" drawn as two diagonal line segments, sized to x-height.
    close_lw = lift(fs -> max(1.0f0, Float32(fs) * 0.08f0), blockscene, t.fontsize)
    closeplot = linesegments!(
        blockscene, close_segments;
        color = close_color, linewidth = close_lw, visible = close_visible, inspectable = false,
    )
    translate!(closeplot, 0, 0, 1)

    td = TabData(
        sf, label_obs, closable_obs, visible, rect, bgcolor, labelpos, labelcolor,
        labelboundingboxes, close_segments, close_color, close_rect, close_visible,
        (polyplot, labelplot, closeplot),
    )
    push!(t.tabs, td)

    # Changing the label text (→ new measured size) or the closability needs a
    # relayout; binding the text plot to `label_obs` already redraws the glyphs.
    on(_ -> recompute_layout!(t), blockscene, labelboundingboxes)
    on(_ -> recompute_layout!(t), blockscene, closable_obs)

    # Capture the resolved label font's metrics once, so the × is sized to the
    # x-height and sits on the label's baseline.
    if !t.font_metrics_captured
        t.font_metrics_captured = true
        on(blockscene, labelplot.selected_font; update = true) do f
            try
                asc = Float32(Makie.FreeTypeAbstraction.ascender(f))
                des = Float32(Makie.FreeTypeAbstraction.descender(f))
                ext = Makie.FreeTypeAbstraction.get_extent(f, 'x')
                bb = Makie.FreeTypeAbstraction.inkboundingbox(ext)
                xh = Float32(widths(bb)[2])
                t.font_metrics[] = TabFontMetrics(asc, des, xh)
            catch
                # keep defaults
            end
            return
        end
    end

    isempty(kwargs) || set_tab!(t, length(t.tabs); kwargs...)

    if activate || t.active[] < 1
        t.active[] = length(t.tabs)
    end
    refresh_visibility!(t)
    recompute_layout!(t)
    return sf
end

"""
    remove_tab!(tabs::Tabs, i::Integer)

Remove tab `i`, freeing its [`Subfigure`](@ref) content and header plots. The
remaining tabs shift down and `active` is updated to keep pointing at the same
tab (or its neighbour if the active tab itself was removed).
"""
function remove_tab!(t::Tabs, i::Integer)
    n = length(t.tabs)
    (1 <= i <= n) || return

    td = t.tabs[i]
    delete!(td.subfigure)
    for p in td.plots
        delete!(t.blockscene, p)
    end
    deleteat!(t.tabs, i)

    new_n = n - 1
    old_active = t.active[]
    new_active = if new_n == 0
        0
    elseif old_active < i
        old_active
    elseif old_active == i
        min(i, new_n)
    else
        old_active - 1
    end
    t.active[] = new_active
    refresh_visibility!(t)
    recompute_layout!(t)
    return
end

"""
    set_tab!(tabs::Tabs, i::Integer; label, closable)

Change properties of tab `i`. Omitted keywords are left unchanged: `label`
sets the tab's text, `closable` whether it shows a close (×) button.
"""
function set_tab!(t::Tabs, i::Integer; label = nothing, closable = nothing)
    td = t.tabs[i]
    label === nothing || (td.label[] = label)
    closable === nothing || (td.closable[] = Bool(closable))
    return
end

function refresh_visibility!(t::Tabs)
    a = t.active[]
    for (i, td) in enumerate(t.tabs)
        td.visible[] = (i == a)
    end
    return
end

function tab_at(t::Tabs, pos)
    p = Point2f(pos)
    for (i, td) in enumerate(t.tabs)
        p in td.rect[] && return i
    end
    return 0
end

function close_at(t::Tabs, pos)
    p = Point2f(pos)
    for (i, td) in enumerate(t.tabs)
        td.closable[] || continue
        p in td.close_rect[] && return i
    end
    return 0
end

function recompute_layout!(t::Tabs)
    n = length(t.tabs)
    if n == 0
        t.headerheight[] = 0.0
        t.separator_path[] = Point2f[]
        return
    end

    pad = t.tabpadding[]
    gap = t.tabgap[]
    fs = Float32(t.fontsize[])
    fm = t.font_metrics[]
    x_height_px = fm.x_height * fs
    widths_ = Vector{Float32}(undef, n)
    labelws = Vector{Float32}(undef, n)
    close_ws = Vector{Float32}(undef, n)
    close_gaps = Vector{Float32}(undef, n)
    hmax = 0.0
    for (i, td) in enumerate(t.tabs)
        bbs = td.labelboundingboxes[]
        w = isempty(bbs) ? 0.0 : width(bbs[1])
        h = isempty(bbs) ? 0.0 : height(bbs[1])
        labelws[i] = w
        hmax = max(hmax, h)
        cl = td.closable[]
        close_ws[i] = cl ? x_height_px : 0.0f0
        close_gaps[i] = cl ? x_height_px * 1.6f0 : 0.0f0
        widths_[i] = w + pad[1] + pad[2] + close_ws[i] + close_gaps[i]
    end
    th = t.tabheight[]
    t.headerheight[] = th === automatic ? hmax + pad[3] + pad[4] : Float64(th)

    cbb = t.layoutobservables.computedbbox[]
    hh = t.headerheight[]
    l, top_ = left(cbb), top(cbb)
    active = t.active[]
    hov = t.hovered[]
    chov = t.close_hovered[]
    x = l
    for (i, td) in enumerate(t.tabs)
        x0 = x
        x1 = x + widths_[i]
        td.rect[] = BBox(x0, x1, top_ - hh, top_)
        # label sits left-aligned in the tab, centered vertically
        td.labelpos[] = Point2f(x0 + pad[1] + labelws[i] / 2, top_ - hh / 2)
        # The × is drawn as two diagonal line segments, baseline-aligned with
        # the label (so it sits where a lowercase 'x' would) and sized to the
        # font's x-height. Non-closable tabs get empty segments and a zero-size
        # hit rect so nothing draws or hit-tests.
        td.close_visible[] = close_ws[i] > 0
        if close_ws[i] > 0
            close_cx = x0 + pad[1] + labelws[i] + close_gaps[i] + close_ws[i] / 2
            baseline_y = top_ - hh / 2 - (fm.ascent + fm.descent) / 2 * fs
            half = x_height_px / 2
            y_top = baseline_y + x_height_px
            y_bot = baseline_y
            td.close_segments[] = Point2f[
                Point2f(close_cx - half, y_top), Point2f(close_cx + half, y_bot),  # \
                Point2f(close_cx + half, y_top), Point2f(close_cx - half, y_bot),  # /
            ]
            # hit-test region a bit larger than the glyph, centred on the tab
            hit_half = max(close_ws[i], fs) / 2 + 2
            td.close_rect[] = Rect2f(close_cx - hit_half, top_ - hh / 2 - hit_half, 2hit_half, 2hit_half)
            td.close_color[] = to_color(i == chov ? t.closecolor_hover[] : t.closecolor[])
        else
            td.close_segments[] = Point2f[]
            td.close_rect[] = Rect2f(0, 0, 0, 0)
        end

        td.bgcolor[] = to_color(
            i == active ? t.tabcolor_active[] :
                i == hov ? t.tabcolor_hover[] : t.tabcolor_inactive[]
        )
        td.labelcolor[] = to_color(i == active ? t.labelcolor_active[] : t.labelcolor_inactive[])
        x = x1 + gap
    end

    # Separator path: a horizontal line under the header that detours up and
    # over the active tab so the active tab "merges" into the panel.
    sep_y = Float32(top_ - hh)
    if 1 <= active <= n
        ar = t.tabs[active].rect[]
        ax0, ax1 = left(ar), right(ar)
        aytop = top(ar)
        t.separator_path[] = Point2f[
            (Float32(l), sep_y),
            (ax0, sep_y),
            (ax0, aytop),
            (ax1, aytop),
            (ax1, sep_y),
            (Float32(right(cbb)), sep_y),
        ]
    else
        t.separator_path[] = Point2f[(Float32(l), sep_y), (Float32(right(cbb)), sep_y)]
    end
    return
end

Base.getindex(t::Tabs, i::Integer) = t.tabs[i].subfigure
Base.length(t::Tabs) = length(t.tabs)

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
content_scene(t::Tabs, i::Integer) = content_scene(t.tabs[i].subfigure)

# Hand pre-display state updates to each tab's Subfigure so blocks placed inside a
# tab (which the Figure can't see because they have a Scene parent, not a
# Figure parent) still get e.g. auto axis limits.
function update_state_before_display!(t::Tabs)
    for td in t.tabs
        update_state_before_display!(td.subfigure)
    end
    return
end
