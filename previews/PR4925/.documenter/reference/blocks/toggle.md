
# Toggle {#Toggle}

A toggle with an attribute `active` that can either be true or false, to enable or disable properties of an interactive plot.

```julia
using GLMakie

fig = Figure()

ax = Axis(fig[1, 1], limits = (0, 600, -2, 2))
hidexdecorations!(ax)

t = Observable(0.0)
points = lift(t) do t
    x = range(t-1, t+1, length = 500)
    @. sin(x) * sin(2x) * sin(4x) * sin(23x)
end

lines!(ax, points, color = (1:500) .^ 2, linewidth = 2, colormap = [(:blue, 0.0), :blue])

gl = GridLayout(fig[2, 1], tellwidth = false)
Label(gl[1, 1], "Live Update")
toggle = Toggle(gl[1, 2], active = false)

on(fig.scene.events.tick) do tick
    toggle.active[] || return
    t[] += tick.delta_time
end

fig
```

<video autoplay loop muted playsinline src="./toggle_example.mp4" width="600"/>


## Attributes {#Attributes}

### active {#active}

Defaults to `false`

Indicates if the toggle is active or not.

### alignmode {#alignmode}

Defaults to `Inside()`

The align mode of the toggle in its parent GridLayout.

### buttoncolor {#buttoncolor}

Defaults to `COLOR_ACCENT[]`

The color of the toggle button.

### cornersegments {#cornersegments}

Defaults to `15`

The number of poly segments in each rounded corner.

### framecolor_active {#framecolor_active}

Defaults to `COLOR_ACCENT_DIMMED[]`

The color of the border when the toggle is hovered.

### framecolor_inactive {#framecolor_inactive}

Defaults to `RGBf(0.94, 0.94, 0.94)`

The color of the border when the toggle is inactive.

### halign {#halign}

Defaults to `:center`

The horizontal alignment of the toggle in its suggested bounding box.

### height {#height}

Defaults to `Auto()`

The height of the bounding box.  Use `length` and `markersize` to set the dimensions of the toggle.

### length {#length}

Defaults to `32`

The length of the toggle.

### markersize {#markersize}

Defaults to `18`

The size of the button.

### orientation {#orientation}

Defaults to `:horizontal`

The orientation of the toggle.  Can be :horizontal, :vertical, or -pi to pi.  0 is horizontal with &quot;on&quot; being to the right.

### rimfraction {#rimfraction}

Defaults to `0.33`

The border width as a fraction of the toggle height 

### tellheight {#tellheight}

Defaults to `true`

Controls if the parent layout can adjust to this element&#39;s height

### tellwidth {#tellwidth}

Defaults to `true`

Controls if the parent layout can adjust to this element&#39;s width

### toggleduration {#toggleduration}

Defaults to `0.15`

The duration of the toggle animation.

### valign {#valign}

Defaults to `:center`

The vertical alignment of the toggle in its suggested bounding box.

### width {#width}

Defaults to `Auto()`

The width of the bounding box.  Use `length` and `markersize` to set the dimensions of the toggle.
