
# Button {#Button}

```julia
using GLMakie

fig = Figure()

ax = Axis(fig[1, 1])
fig[2, 1] = buttongrid = GridLayout(tellwidth = false)

counts = Observable([1, 4, 3, 7, 2])

buttonlabels = [lift(x -> "Count: $(x[i])", counts) for i in 1:5]

buttons = buttongrid[1, 1:5] = [Button(fig, label = l) for l in buttonlabels]

for i in 1:5
    on(buttons[i].clicks) do n
        counts[][i] += 1
        notify(counts)
    end
end

barplot!(counts, color = cgrad(:Spectral)[LinRange(0, 1, 5)])
ylims!(ax, 0, 20)

fig
```

<video autoplay loop muted playsinline src="./button_example.mp4" width="600"/>


## Attributes {#Attributes}

### alignmode {#alignmode}

Defaults to `Inside()`

The align mode of the button in its parent GridLayout.

### buttoncolor {#buttoncolor}

Defaults to `RGBf(0.94, 0.94, 0.94)`

The color of the button.

### buttoncolor_active {#buttoncolor_active}

Defaults to `COLOR_ACCENT[]`

The color of the button when the mouse clicks the button.

### buttoncolor_hover {#buttoncolor_hover}

Defaults to `COLOR_ACCENT_DIMMED[]`

The color of the button when the mouse hovers over the button.

### clicks {#clicks}

Defaults to `0`

The number of clicks that have been registered by the button.

### cornerradius {#cornerradius}

Defaults to `4`

The radius of the rounded corners of the button.

### cornersegments {#cornersegments}

Defaults to `10`

The number of poly segments used for each rounded corner.

### font {#font}

Defaults to `:regular`

The font family of the button label.

### fontsize {#fontsize}

Defaults to `@inherit :fontsize 16.0f0`

The font size of the button label.

### halign {#halign}

Defaults to `:center`

The horizontal alignment of the button in its suggested boundingbox

### height {#height}

Defaults to `Auto()`

The height setting of the button.

### label {#label}

Defaults to `"Button"`

The text of the button label.

### labelcolor {#labelcolor}

Defaults to `@inherit :textcolor :black`

The color of the label.

### labelcolor_active {#labelcolor_active}

Defaults to `:white`

The color of the label when the mouse clicks the button.

### labelcolor_hover {#labelcolor_hover}

Defaults to `:black`

The color of the label when the mouse hovers over the button.

### padding {#padding}

Defaults to `(8.0f0, 8.0f0, 8.0f0, 8.0f0)`

The extra space added to the sides of the button label&#39;s boundingbox.

### strokecolor {#strokecolor}

Defaults to `:transparent`

The color of the button border.

### strokewidth {#strokewidth}

Defaults to `2.0`

The line width of the button border.

### tellheight {#tellheight}

Defaults to `true`

Controls if the parent layout can adjust to this element&#39;s height

### tellwidth {#tellwidth}

Defaults to `true`

Controls if the parent layout can adjust to this element&#39;s width

### valign {#valign}

Defaults to `:center`

The vertical alignment of the button in its suggested boundingbox

### width {#width}

Defaults to `Auto()`

The width setting of the button.
