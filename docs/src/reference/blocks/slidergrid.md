# SliderGrid

By default, `SliderGrid` stacks horizontal sliders in rows (name label | slider | value label).
Set `horizontal = false` for a vertical grid: one column per slider with the name on top,
a vertical `Slider`, and the value below.

The value-label size is automatically fixed so the layout does not jitter when values change.
For a horizontal grid this is a column width; for a vertical grid it is a row height.
The size is chosen by setting each slider to a few values and recording the maximum label
extent. Alternatively, set it manually with `value_column_width` (width when horizontal,
height when vertical).

```@example slidergrid
using GLMakie
GLMakie.activate!() # hide


fig = Figure()

ax = Axis(fig[1, 1])

sg = SliderGrid(
    fig[1, 2],
    (label = "Voltage", range = 0:0.1:10, format = "{:.1f}V", startvalue = 5.3),
    (label = "Current", range = 0:0.1:20, format = "{:.1f}A", startvalue = 10.2),
    (label = "Resistance", range = 0:0.1:30, format = "{:.1f}Ω", startvalue = 15.9),
    width = 350,
    tellheight = false)

sliderobservables = [s.value for s in sg.sliders]
bars = lift(sliderobservables...) do slvalues...
    [slvalues...]
end

barplot!(ax, bars, color = [:yellow, :orange, :red])
ylims!(ax, 0, 30)

fig
nothing # hide
```

```@setup slidergrid
using ..FakeInteraction

events = [
    Wait(0.5),
    Lazy() do fig
        MouseTo(relative_pos(sg.sliders[1], (0.1, 0.5)))
    end,
    LeftDown(),
    Wait(0.2),
    Lazy() do fig
        MouseTo(relative_pos(sg.sliders[1], (0.8, 0.5)))
    end,
    Wait(0.2),
    LeftUp(),
    Wait(0.5),
    Lazy() do fig
        MouseTo(relative_pos(sg.sliders[3], (0.5, 0.5)))
    end,
    LeftDown(),
    Wait(0.3),
    Lazy() do fig
        MouseTo(relative_pos(sg.sliders[3], (1, 0.6)))
    end,
    Wait(0.3),
    Lazy() do fig
        MouseTo(relative_pos(sg.sliders[3], (0.1, 0.3)))
    end,
    Wait(0.5),
]

interaction_record(fig, "slidergrid_example.mp4", events)
```

```@raw html
<video autoplay loop muted playsinline src="./slidergrid_example.mp4" width="600"/>
```

## Vertical slider grid

```@example slidergrid-vertical
using CairoMakie

fig = Figure(size = (500, 350))

ax = Axis(fig[1, 1])

sg = SliderGrid(
    fig[1, 2],
    (label = "X", range = 0:0.01:10, startvalue = 3),
    (label = "Y", range = 0:0.01:10, startvalue = 6);
    horizontal = false,
    height = 250,
    tellwidth = false,
)

point = lift(sg.sliders[1].value, sg.sliders[2].value) do x, y
    Point2f(x, y)
end

scatter!(ax, point, color = :red, markersize = 20)
limits!(ax, 0, 10, 0, 10)

fig
```

## Attributes

```@attrdocs
SliderGrid
```
