
# SliderGrid {#SliderGrid}

The column with the value labels is automatically set to a fixed width, so that the layout doesn&#39;t jitter when sliders are dragged and the value labels change their widths. This width is chosen by setting each slider to a few values and recording the maximum label width. Alternatively, you can set the width manually with attribute `value_column_width`.

```julia
using GLMakie


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
```

<video autoplay loop muted playsinline src="./slidergrid_example.mp4" width="600"/>


## Attributes {#Attributes}

### alignmode {#alignmode}

Defaults to `Inside()`

The align mode of the block in its parent GridLayout.

### halign {#halign}

Defaults to `:center`

The horizontal alignment of the block in its suggested bounding box.

### height {#height}

Defaults to `Auto()`

The height setting of the block.

### tellheight {#tellheight}

Defaults to `true`

Controls if the parent layout can adjust to this block&#39;s height

### tellwidth {#tellwidth}

Defaults to `true`

Controls if the parent layout can adjust to this block&#39;s width

### valign {#valign}

Defaults to `:center`

The vertical alignment of the block in its suggested bounding box.

### value_column_width {#value_column_width}

Defaults to `automatic`

The width of the value label column. If `automatic`, the width is determined by sampling a few values from the slider ranges and picking the largest label size found.

### width {#width}

Defaults to `Auto()`

The width setting of the block.
