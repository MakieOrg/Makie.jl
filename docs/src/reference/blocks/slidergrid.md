# SliderGrid

The column with the value labels is automatically set to a fixed width, so that the layout doesn't jitter when sliders are dragged and the value labels change their widths.
This width is chosen by setting each slider to a few values and recording the maximum label width.
Alternatively, you can set the width manually with attribute `value_column_width`.

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

## Attributes

```@attrdocs
SliderGrid
```