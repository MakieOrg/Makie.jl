# Tabs

A tabbed container. Each tab hosts a clipped content area: only the active tab
is visible, and only the active tab receives mouse and keyboard input. Place
blocks with `tabs[i][row, col] = Axis(...)` or plot directly into
`content_scene(tabs, i)`. Tab content is clipped to the tab but does not scroll
by default — nest a [`ScrollArea`](@ref) in a tab for a scrollable region.

```@example tabs
using GLMakie
GLMakie.activate!() # hide

fig = Figure(size = (700, 450))

tabs = Tabs(fig[1, 1], ["Scatter", "Lines", "Heatmap"])

scatter!(
    Axis(tabs[1][1, 1], title = "Drag to pan, scroll to zoom"),
    randn(150), randn(150), color = 1:150, colormap = :viridis
)

lines!(Axis(tabs[2][1, 1], title = "A random walk"), cumsum(randn(400)), color = :tomato)

heatmap!(Axis(tabs[3][1, 1], title = "Noise"), randn(30, 30), colormap = :thermal)

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

events = [
    Wait(1.0),
    Lazy() do fig MouseTo(tab_label_center(tabs, 2)) end,    # over tab 2 ("Lines")
    LeftClick(),
    Wait(1.0),
    Lazy() do fig MouseTo(tab_label_center(tabs, 3)) end,    # over tab 3 ("Heatmap")
    LeftClick(),
    Wait(0.6),
    Lazy() do fig MouseTo(tab_label_center(tabs, 1)) end,    # back to tab 1
    LeftClick(),
    Wait(0.4),
    # Zoom the scatter axis with the wheel — only the active tab reacts.
    Lazy() do fig
        ca = tabs[1].scene.viewport[]
        MouseTo(Point2f(left(ca) + 0.5 * widths(ca)[1], bottom(ca) + 0.5 * widths(ca)[2]))
    end,
    Scroll((0.0, -3.0); duration = 0.5),             # zoom in
    Wait(0.5),
    # Close the "Lines" tab via its × button.
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


## Scrollable tab content

Tabs clip but do not scroll on their own. To make a tab's content scrollable,
put it inside a [`ScrollArea`](@ref):

```julia
tabs = Tabs(fig[1, 1], ["Long form"])
area = ScrollArea(tabs[1][1, 1])
for i in 1:30
    Label(area[i, 1], "param $i"; halign = :right, tellwidth = false)
    Slider(area[i, 2]; range = 0:100, width = 150)
end
```


## Modifying tabs at runtime

Change the set of tabs with `add_tab!`, `remove_tab!` and `set_tab!`, and switch
the visible tab with the `active` attribute.

```@example tabs_runtime
using GLMakie
GLMakie.activate!() # hide

fig = Figure(size = (700, 300))
tabs = Tabs(fig[1, 1], ["First"])
lines(tabs[1][1, 1], cumsum(randn(100)))

# `add_tab!` returns the new tab's content ScrollArea, so you can plot into it.
area = add_tab!(tabs, "Second"; activate = true)
scatter(area[1, 1], randn(50), randn(50))

# A third tab, populated via the `tabs[i]` accessor instead.
add_tab!(tabs, "Third")
heatmap(tabs[3][1, 1], randn(20, 20))

# Change properties of an existing tab; omitted keywords are left unchanged.
set_tab!(tabs, 1; label = "Renamed", closable = false)

# Remove a tab; `active` reindexes to a neighbour automatically.
remove_tab!(tabs, 2)

tabs.active[] = 1
fig
```

In an interactive window these are typically wired to widgets — e.g. an "add
view" `Button` whose callback calls `add_tab!` — or driven by your application
logic. Closing a tab through its `×` button calls `remove_tab!` for you.


## Attributes

```@attrdocs
Tabs
```
