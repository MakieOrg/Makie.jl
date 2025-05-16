
# Checkbox {#Checkbox}

```julia
using GLMakie


f = Figure()

gl = GridLayout(f[2, 1], tellwidth = false)
subgl = GridLayout(gl[1, 1])

cb1 = Checkbox(subgl[1, 1], checked = false)
cb2 = Checkbox(subgl[2, 1], checked = true)
cb3 = Checkbox(subgl[3, 1], checked = true)

Label(subgl[1, 2], "Dataset A", halign = :left)
Label(subgl[2, 2], "Dataset B", halign = :left)
Label(subgl[3, 2], "Dataset C", halign = :left)
rowgap!(subgl, 8)
colgap!(subgl, 8)

ax = Axis(f[1, 1])

for cb in [cb1, cb2, cb3]
    lines!(ax, cumsum(randn(1000)), alpha = @lift($(cb.checked) ? 1.0 : 0.1))
end

f
```

<video autoplay loop muted playsinline src="./checkbox_example.mp4" width="600"/>


## Attributes {#Attributes}

### alignmode {#alignmode}

Defaults to `Inside()`

The align mode of the checkbox in its parent GridLayout.

### checkboxcolor_checked {#checkboxcolor_checked}

Defaults to `COLOR_ACCENT[]`

The color of the checkbox background when checked.

### checkboxcolor_unchecked {#checkboxcolor_unchecked}

Defaults to `@inherit :backgroundcolor :white`

The color of the checkbox background when unchecked.

### checkboxstrokecolor_checked {#checkboxstrokecolor_checked}

Defaults to `COLOR_ACCENT[]`

The strokecolor of the checkbox background when checked.

### checkboxstrokecolor_unchecked {#checkboxstrokecolor_unchecked}

Defaults to `COLOR_ACCENT[]`

The strokecolor of the checkbox background when unchecked.

### checkboxstrokewidth {#checkboxstrokewidth}

Defaults to `1.5`

The strokewidth of the checkbox poly.

### checked {#checked}

Defaults to `false`

If the checkbox is currently checked. This value should not be modified directly.

### checkmark {#checkmark}

Defaults to `CHECKMARK_BEZIER`

The checkmark marker symbol. Anything that `scatter` can use.

### checkmarkcolor_checked {#checkmarkcolor_checked}

Defaults to `:white`

The color of the checkmark when the mouse clicks the checkbox.

### checkmarkcolor_unchecked {#checkmarkcolor_unchecked}

Defaults to `:transparent`

The color of the checkmark when unchecked.

### checkmarksize {#checkmarksize}

Defaults to `0.85`

The size of the checkmark, relative to the size.

### halign {#halign}

Defaults to `:center`

The horizontal alignment of the checkbox in its suggested boundingbox

### height {#height}

Defaults to `Auto()`

The height setting of the checkbox.

### onchange {#onchange}

Defaults to `!`

A function that is called when the user clicks to check or uncheck. The function is passed the current status as a `Bool` and needs to return a `Bool` that decides the checked status after the click. Intended for implementation of radio buttons.

### roundness {#roundness}

Defaults to `0.15`

Roundness of the checkbox poly, 0 is square, 1 is circular.

### size {#size}

Defaults to `11`

The size (width/height) of the checkbox

### tellheight {#tellheight}

Defaults to `true`

Controls if the parent layout can adjust to this element&#39;s height

### tellwidth {#tellwidth}

Defaults to `true`

Controls if the parent layout can adjust to this element&#39;s width

### valign {#valign}

Defaults to `:center`

The vertical alignment of the checkbox in its suggested boundingbox

### width {#width}

Defaults to `Auto()`

The width setting of the checkbox.
