
# IntervalSlider {#IntervalSlider}

The interval slider selects an interval (low, high) from the supplied attribute `range`. The (approximate) start values can be set with `startvalues`.

The currently selected interval is in the attribute `interval` and is a Tuple of `(low, high)`. Don&#39;t change this value manually, but use the function `set_close_to!(intslider, v1, v2)`. This is necessary to ensure the values are actually present in the `range` attribute.

You can click anywhere outside of the currently selected range and the closer interval edge will jump to the point. You can then drag the edge around. When hovering over the slider, the larger button indicates the edge that will react.

If the mouse hovers over the central area of the interval and both buttons are enlarged, clicking and dragging shifts the interval around as a whole.

You can double-click the slider to reset it to the values present in `startvalues`. If `startvalues === Makie.automatic`, the full interval will be selected (this is the default).

If you set the attribute `snap = false`, the slider will move continuously while dragging and only jump to the closest available values when releasing the mouse.

```julia
using GLMakie

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
```

<video autoplay loop muted playsinline src="./intervalslider_example.mp4" width="600"/>


## Attributes {#Attributes}

### alignmode {#alignmode}

Defaults to `Inside()`

The align mode of the slider in its parent GridLayout.

### color_active {#color_active}

Defaults to `COLOR_ACCENT[]`

The color of the slider when the mouse clicks and drags the slider.

### color_active_dimmed {#color_active_dimmed}

Defaults to `COLOR_ACCENT_DIMMED[]`

The color of the slider when the mouse hovers over it.

### color_inactive {#color_inactive}

Defaults to `RGBf(0.94, 0.94, 0.94)`

The color of the slider when it is not interacted with.

### halign {#halign}

Defaults to `:center`

The horizontal alignment of the slider in its suggested bounding box.

### height {#height}

Defaults to `Auto()`

The height setting of the slider.

### horizontal {#horizontal}

Defaults to `true`

Controls if the slider has a horizontal orientation or not.

### interval {#interval}

Defaults to `(0, 0)`

The current interval of the slider. Don&#39;t set this manually, use the function `set_close_to!`.

### linewidth {#linewidth}

Defaults to `10.0`

The width of the slider line

### range {#range}

Defaults to `0:0.01:10`

The range of values that the slider can pick from.

### snap {#snap}

Defaults to `true`

Controls if the buttons snap to valid positions or move freely

### startvalues {#startvalues}

Defaults to `Makie.automatic`

The start values of the slider or the values that are closest in the slider range.

### tellheight {#tellheight}

Defaults to `true`

Controls if the parent layout can adjust to this element&#39;s height

### tellwidth {#tellwidth}

Defaults to `true`

Controls if the parent layout can adjust to this element&#39;s width

### valign {#valign}

Defaults to `:center`

The vertical alignment of the slider in its suggested bounding box.

### width {#width}

Defaults to `Auto()`

The width setting of the slider.
