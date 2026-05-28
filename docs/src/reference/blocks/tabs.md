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
    Lazy() do fig
        MouseTo(relative_pos(tabs, (0.18, 0.94)))  # over tab 2 header
    end,
    LeftClick(),
    Wait(1.0),
    Lazy() do fig
        MouseTo(relative_pos(tabs, (0.28, 0.94)))  # over tab 3 header
    end,
    LeftClick(),
    Wait(0.4),
    # grab the vertical scrollbar thumb and drag down
    Lazy() do fig
        MouseTo(vbar_thumb_center(tabs.subfigures[3]))
    end,
    LeftDown(),
    Lazy() do fig
        sf = tabs.subfigures[3]
        ca = sf.scene.viewport[]
        MouseTo(Point2f(right(ca) - 4, bottom(ca) + 60), 1.5)
    end,
    LeftUp(),
    Wait(0.3),
    # grab the thumb at its new lower position and drag back up
    Lazy() do fig
        MouseTo(vbar_thumb_center(tabs.subfigures[3]))
    end,
    LeftDown(),
    Lazy() do fig
        sf = tabs.subfigures[3]
        ca = sf.scene.viewport[]
        MouseTo(Point2f(right(ca) - 4, top(ca) - 12), 1.2)
    end,
    LeftUp(),
    Wait(0.6),
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
