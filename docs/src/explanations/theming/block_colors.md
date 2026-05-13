# Block colors

The interactive `Block` widgets (`Button`, `Checkbox`, `Toggle`, `Slider`,
`IntervalSlider`, `Menu`, `Textbox`) all read their fill, border, and text
colors from a small set of named roles in the theme. This means you can
recolour every widget at once by adjusting one nested theme block, instead of
overriding individual attributes on each Block.

## The `colors` theme block

`MAKIE_DEFAULT_THEME[:colors]` is a nested `Attributes` block — like
`fonts` — containing nine role tokens:

| Role | Where it shows up |
|---|---|
| `background` | Canvas background, unchecked Checkbox fill |
| `surface` | Idle interactive fills (Button, Slider track, Toggle frame) |
| `surface_subtle` | Menu dropdown rows |
| `border` | Idle Textbox border |
| `text` | Default text (Labels, Axis titles, Button label) |
| `text_muted` | Placeholder text, dropdown arrow |
| `text_on_accent` | Text rendered over an accent-coloured fill |
| `accent` | Active, checked, focused, pressed states |
| `accent_subtle` | Hover states |

State conventions across all interactive Blocks are uniform: idle = `surface`,
hover = `accent_subtle`, active/checked/focused = `accent`.

## Deriving a scheme from a few colours

In practice, you don't set all nine roles by hand. The helper
[`derive_colors`](@ref) takes three inputs — an accent colour, a
"contrast pole" gray, and the background — and computes the full nine-role
scheme so every neutral and accent step is consistent with your choices.

```julia
Makie.derive_colors(; accent, gray = automatic, background = :white)
```

- `accent` — the primary accent colour, used for active/checked/focused states.
- `gray` — the colour that gets mixed with `background` to produce neutrals.
  `automatic` picks pure black on light backgrounds and pure white on dark
  ones; pass a tinted near-black (or near-white) to bias every neutral towards
  that hue.
- `background` — the canvas background; its luminance also selects the default
  contrast pole when `gray = automatic`.

With default inputs the function reproduces Makie's traditional Block defaults
within rounding, so existing figures don't shift.

## Applying a scheme

Wrap the derived scheme into `set_theme!` (or `with_theme`). Setting
`backgroundcolor` and `textcolor` at the top level keeps the rest of Makie
(figure background, axis titles, plot text) in sync with the widget scheme.

## A light, warm-brown theme

```@example block_colors
using CairoMakie
CairoMakie.activate!(type = "svg") # hide

function widget_showcase()
    fig = Figure(size = (760, 580))
    Label(fig[0, 1:3], "Block showcase", fontsize = 18, tellwidth = false)

    btn = Button(fig[1, 1], label = "Idle")
    Button(fig[1, 2], label = "Hover preview", buttoncolor = btn.buttoncolor_hover)
    Button(fig[1, 3], label = "Active preview",
        buttoncolor = btn.buttoncolor_active,
        labelcolor = btn.labelcolor_active)

    Checkbox(fig[2, 1], checked = false)
    Checkbox(fig[2, 2], checked = true)
    Label(fig[2, 3], "Checkboxes", tellwidth = false)

    Toggle(fig[3, 1], active = false)
    Toggle(fig[3, 2], active = true)
    Label(fig[3, 3], "Toggles", tellwidth = false)

    Slider(fig[4, 1:3], range = 0:0.1:10, startvalue = 5)
    IntervalSlider(fig[5, 1:3], range = 0:0.1:10, startvalues = (2, 7))

    Menu(fig[6, 1], options = ["alpha", "beta", "gamma"], width = 100)
    Textbox(fig[6, 2], placeholder = "type here")
    Textbox(fig[6, 3], stored_string = "with text")

    rowsize!(fig.layout, 6, 36)
    fig
end

bg   = RGBf(0.96, 0.92, 0.84)        # cream
warm = RGBf(0.20, 0.13, 0.08)        # warm dark pole
acc  = RGBf(0.70, 0.36, 0.18)        # terracotta

with_theme(
    backgroundcolor = bg,
    textcolor = warm,
    colors = Makie.derive_colors(accent = acc, gray = warm, background = bg),
) do
    widget_showcase()
end
```

Because `gray` is set to a brown-leaning near-black, every derived neutral
(`surface`, `surface_subtle`, `border`, `text_muted`) is also brown-tinted —
the whole UI carries the warmth, not just the accent.

## A dark, greenish theme

```@example block_colors
bg    = RGBf(0.08, 0.11, 0.09)       # near-black, slight green tint
light = RGBf(0.86, 0.96, 0.87)       # light pole, slightly green
acc   = RGBf(0.40, 0.85, 0.55)       # vibrant green accent

with_theme(
    backgroundcolor = bg,
    textcolor = light,
    colors = Makie.derive_colors(accent = acc, gray = light, background = bg),
) do
    widget_showcase()
end
```

When the background is dark, `gray = automatic` already picks a near-white
contrast pole; here we override it to a pale green so the neutral steps pull
slightly green rather than pure gray.

## Overriding a single role

You can target an individual role instead of swapping the whole scheme:

```julia
set_theme!(colors = (text = :navy,))
```

Only `text` changes; the other eight roles stay at their current values. This
also works inside `with_theme(...)` and `update_theme!`.
