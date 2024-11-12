# IntervalSlider

The interval slider selects an interval (low, high) from the supplied attribute `range`.
The (approximate) start values can be set with `startvalues`.

The currently selected interval is in the attribute `interval` and is a Tuple of `(low, high)`.
Don't change this value manually, but use the function `set_close_to!(intslider, v1, v2)`.
This is necessary to ensure the values are actually present in the `range` attribute.

You can click anywhere outside of the currently selected range and the closer interval edge will jump to the point.
You can then drag the edge around.
When hovering over the slider, the larger button indicates the edge that will react.

If the mouse hovers over the central area of the interval and both buttons are enlarged, clicking and dragging shifts the interval around as a whole.

You can double-click the slider to reset it to the values present in `startvalues`.
If `startvalues === Makie.automatic`, the full interval will be selected (this is the default).

If you set the attribute `snap = false`, the slider will move continuously while dragging and only jump to the closest available values when releasing the mouse.

```@example intervalslider
using GLMakie
GLMakie.activate!() # hide

f = Figure()
Axis(f[1, 1], limits = (0, 1, 0, 1))

rs_h = IntervalSlider(f[2, 1], range = LinRange(0, 1, 1000),
    startvalues = (0.2, 0.8))
rs_v = IntervalSlider(f[1, 2], range = LinRange(0, 1, 1000),
    startvalues = (0.4, 0.9), horizontal = false)

labeltext1 = lift(rs_h.interval) do int
    string(round.(int, digits = 2))
end
Label(f[3, 1], labeltext1, tellwidth = false)
labeltext2 = lift(rs_v.interval) do int
    string(round.(int, digits = 2))
end
Label(f[1, 3], labeltext2,
    tellheight = false, rotation = pi/2)

points = rand(Point2f, 300)

# color points differently if they are within the two intervals
colors = lift(rs_h.interval, rs_v.interval) do h_int, v_int
    map(points) do p
        (h_int[1] < p[1] < h_int[2]) && (v_int[1] < p[2] < v_int[2])
    end
end

scatter!(points, color = colors, colormap = [:gray90, :dodgerblue], strokewidth = 0)

f
nothing # hide
```

```@setup intervalslider
using ..FakeInteraction

events = [
    Wait(1),
    Lazy() do fig
        MouseTo(relative_pos(rs_h, (0.2, 0.5)))
    end,
    Wait(0.2),
    LeftDown(),
    Wait(0.3),
    Lazy() do fig
        MouseTo(relative_pos(rs_h, (0.5, 0.6)))
    end,
    Wait(0.2),
    LeftUp(),
    Wait(0.5),
    Lazy() do fig
        MouseTo(relative_pos(rs_h, (0.625, 0.4)))
    end,
    Wait(0.2),
    LeftDown(),
    Wait(0.3),
    Lazy() do fig
        MouseTo(relative_pos(rs_h, (0.375, 0.5)))
    end,
    Wait(0.5),
    Lazy() do fig
        MouseTo(relative_pos(rs_h, (0.8, 0.5)))
    end,
    LeftUp(),
    Wait(0.5),
    Lazy() do fig
        MouseTo(relative_pos(rs_v, (0.5, 0.66)))
    end,
    Wait(0.3),
    LeftDown(),
    Lazy() do fig
        MouseTo(relative_pos(rs_v, (0.5, 0.33)))
    end,
    LeftUp(),
    Wait(0.5),
    Lazy() do fig
        MouseTo(relative_pos(rs_v, (0.5, 0.8)))
    end,
    Wait(0.3),
    LeftClick(),
    Wait(2),
]

interaction_record(f, "intervalslider_example.mp4", events)
```

```@raw html
<video autoplay loop muted playsinline src="./intervalslider_example.mp4" width="600"/>
```

## Attributes

```@attrdocs
IntervalSlider
```