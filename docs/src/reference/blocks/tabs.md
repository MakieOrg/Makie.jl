# Tabs

A tabbed container. Each tab is backed by a [`Subfigure`](@ref) with isolated
events: only the active tab is visible, and only the active tab receives
mouse and keyboard input. Place blocks with `tabs[i][row, col] = Axis(...)`
or plot directly into `content_scene(tabs, i)`. Content larger than the
visible area scrolls vertically and horizontally; scrollbars appear only when
there is overflow.

```@example tabs
using GLMakie
import Makie.GridLayoutBase as GLB
GLMakie.activate!() # hide

fig = Figure(size = (700, 450))

tabs = Tabs(fig[1, 1]; labels = ["Single axis", "Wide", "Tall"])

# Tab 1 — a single axis
scatter!(
    Axis(tabs[1][1, 1], title = "Drag to pan, scroll to zoom"),
    randn(150), randn(150), color = 1:150, colormap = :viridis
)

# Tab 2 — three Fixed-width axes side by side → horizontal scroll
for (col, sym) in enumerate((:tomato, :steelblue, :seagreen))
    ax = Axis(tabs[2][1, col], title = "col $col")
    scatter!(ax, randn(60), randn(60), color = sym)
end
GLB.colsize!(tabs[2].layout, 1, GLB.Fixed(300))
GLB.colsize!(tabs[2].layout, 2, GLB.Fixed(300))
GLB.colsize!(tabs[2].layout, 3, GLB.Fixed(300))

# Tab 3 — three Fixed-height axes stacked → vertical scroll
for (row, sym) in enumerate((:tomato, :steelblue, :seagreen))
    ax = Axis(tabs[3][row, 1], title = "row $row")
    lines!(ax, 1:50, cumsum(randn(50)), color = sym)
end
GLB.rowsize!(tabs[3].layout, 1, GLB.Fixed(180))
GLB.rowsize!(tabs[3].layout, 2, GLB.Fixed(180))
GLB.rowsize!(tabs[3].layout, 3, GLB.Fixed(180))

fig
nothing # hide
```

```@setup tabs
using ..FakeInteraction

# Find a tab's label center and close-button center by inspecting the plots
# that `Tabs` adds to its blockscene (one `Text` per label, one `LineSegments`
# per close ×, in tab order). This stays in sync with the actual rendered
# layout without poking new fields into `Tabs`.
function tab_label_center(tabs, i)
    plots = filter(p -> p isa Makie.Text, tabs.blockscene.plots)
    return Point2f(plots[i].positions[][1])
end
function tab_close_center(tabs, i)
    plots = filter(p -> p isa Makie.LineSegments, tabs.blockscene.plots)
    seg = plots[i].positions[]
    return Point2f(sum(p -> p[1], seg) / length(seg), sum(p -> p[2], seg) / length(seg))
end

function vbar_thumb_center(sf)
    ca = sf.scene.viewport[]
    cs = sf.contentsize[][2]
    vh = widths(ca)[2]
    ch = max(cs, vh)
    thumb_h = max(20.0, vh^2 / ch)
    max_sy = max(0.0, ch - vh)
    usable = vh - thumb_h
    sc_y = sf.scroll[][2]
    ty = top(ca) - thumb_h - (sc_y / max_sy) * usable
    return Point2f(right(ca) - 4, ty + thumb_h / 2)
end

events = [
    Wait(1.0),
    Lazy() do fig MouseTo(tab_label_center(tabs, 2)) end,    # over tab 2 ("Wide")
    LeftClick(),
    Wait(1.0),
    Lazy() do fig MouseTo(tab_label_center(tabs, 3)) end,    # over tab 3 ("Tall")
    LeftClick(),
    Wait(0.4),
    # Grab the vertical scrollbar thumb and drag it down.
    Lazy() do fig MouseTo(vbar_thumb_center(tabs.subfigures[3])) end,
    LeftDown(),
    Lazy() do fig
        sf = tabs.subfigures[3]
        ca = sf.scene.viewport[]
        MouseTo(Point2f(right(ca) - 4, bottom(ca) + 60), 1.5)
    end,
    LeftUp(),
    Wait(0.5),
    # Move into the (now-visible) bottom row's axis and zoom it with the
    # wheel — Tabs lets the axis consume scroll first when the cursor is
    # inside, so this demonstrates per-tab interactivity.
    Lazy() do fig
        sf = tabs.subfigures[3]
        ca = sf.scene.viewport[]
        MouseTo(Point2f(left(ca) + 0.45 * widths(ca)[1], bottom(ca) + 0.2 * widths(ca)[2]))
    end,
    Scroll((0.0, -3.0); duration = 0.5),             # zoom in
    Wait(0.5),
    # Close the "Wide" tab via its × button. Small pause after landing so
    # the click doesn't feel instantaneous.
    Lazy() do fig MouseTo(tab_close_center(tabs, 2)) end,
    Wait(0.3),
    LeftClick(),
    Wait(1.5),
]

interaction_record(fig, "tabs_example.mp4", events)
```

```@raw html
<video autoplay loop muted playsinline src="./tabs_example.mp4" width="700"/>
```


## Attributes

```@attrdocs
Tabs
```
