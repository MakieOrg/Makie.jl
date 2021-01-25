```@eval
using CairoMakie
CairoMakie.activate!()
```

# Layoutables & Widgets

!!! note
    All examples here are presented as CairoMakie svg's for clarity of visuals, but keep in mind that CairoMakie is not interactive. Use GLMakie for interactive widgets, WGLMakie currently doesn't have picking implemented which is needed for them.

```@contents
Pages = ["layoutables_examples.md"]
Depth = 2
```

## Colorbar

A Colorbar needs a colormap and a tuple of low/high limits.
The colormap's axis will then span from low to high along the visual representation of the colormap.
You can set ticks in a similar way to `Axis`.

Here's how you can create Colorbars manually.

```@example
using CairoMakie

fig = Figure(resolution = (1200, 900))

Axis(fig[1, 1])

# vertical colorbars
Colorbar(fig[1, 2], width = 25, limits = (0, 10), colormap = :viridis,
    flipaxisposition = false, ticklabelalign = (:right, :center))
Colorbar(fig[1, 3], width = 25, limits = (0, 5),
colormap = cgrad(:Spectral, 5, categorical = true))
Colorbar(fig[1, 4], width = 25, limits = (-1, 1), colormap = :heat,
    highclip = :cyan, lowclip = :red, label = "Temperature")

# horizontal colorbars
Colorbar(fig[2, 1], height = 25, limits = (0, 10), colormap = :viridis,
    vertical = false, ticklabelalign = (:center, :bottom))
Colorbar(fig[3, 1], height = 25, limits = (0, 5),
    colormap = cgrad(:Spectral, 5, categorical = true), vertical = false,
    ticklabelalign = (:center, :bottom))
Colorbar(fig[4, 1], height = 25, limits = (-1, 1), colormap = :heat,
    label = "Temperature", vertical = false, flipaxisposition = false,
    ticklabelalign = (:center, :top), highclip = :cyan, lowclip = :red)

fig

save("example_colorbar.svg", fig); nothing # hide
```

![example colorbar](example_colorbar.svg)

You can also automatically choose colormap and limits for certain plot objects by passing them as the second argument.

```@example
using CairoMakie

xs = LinRange(0, 20, 50)
ys = LinRange(0, 15, 50)
zs = [cos(x) * sin(y) for x in xs, y in ys]

fig = Figure(resolution = (1200, 900))

ax, hm = heatmap(fig[1, 1][1, 1], xs, ys, zs)
Colorbar(fig[1, 1][1, 2], hm, width = 20)

ax, hm = heatmap(fig[1, 2][1, 1], xs, ys, zs, colormap = :grays,
    colorrange = (-0.75, 0.75), highclip = :red, lowclip = :blue)
Colorbar(fig[1, 2][1, 2], hm, width = 20)

ax, hm = contourf(fig[2, 1][1, 1], xs, ys, zs,
    levels = -1:0.25:1, colormap = :heat)
Colorbar(fig[2, 1][1, 2], hm, width = 20, ticks = -1:0.25:1)

ax, hm = contourf(fig[2, 2][1, 1], xs, ys, zs,
    colormap = :Spectral, levels = [-1, -0.5, -0.25, 0, 0.25, 0.5, 1])
Colorbar(fig[2, 2][1, 2], hm, width = 20, ticks = -1:0.25:1)

fig
save("example_colorbar_2.svg", fig); nothing # hide
```

![example colorbar 2](example_colorbar_2.svg)

## Slider

A simple slider without a label. You can create a label using a `Label` object,
for example. You need to specify a range that constrains the slider's possible values.
You can then lift the `value` observable to make interactive plots.

```@example
using CairoMakie

fig = Figure(resolution = (1200, 900))

Axis(fig[1, 1])
sl1 = Slider(fig[2, 1], range = 0:0.01:10, startvalue = 3)
sl2 = Slider(fig[3, 1], range = 0:0.01:10, startvalue = 5)
sl3 = Slider(fig[4, 1], range = 0:0.01:10, startvalue = 7)

sl4 = Slider(fig[:, 2], range = 0:0.01:10, horizontal = false,
    tellwidth = true, height = nothing, width = Auto())

save("example_lslider.svg", fig); nothing # hide
```

![example lslider](example_lslider.svg)

To create a horizontal layout containing a label, a slider, and a value label, use the convenience function [`AbstractPlotting.MakieLayout.labelslider!`](@ref), or, if you need multiple aligned rows of sliders, use [`AbstractPlotting.MakieLayout.labelslidergrid!`](@ref).

```@example
using CairoMakie
fig = Figure(resolution = (1200, 900))

Axis(fig[1, 1])

lsgrid = labelslidergrid!(
    fig,
    ["Voltage", "Current", "Resistance"],
    # use Ref for the same range for every slider via internal broadcasting
    Ref(LinRange(0:0.1:1000));
    formats = [x -> "$(round(x, digits = 1))$s" for s in ["V", "A", "Ω"]],
    width = 350,
    tellheight = false)
    
fig[1, 2] = lsgrid.layout

set_close_to!(lsgrid.sliders[1], 230.3)
set_close_to!(lsgrid.sliders[2], 628.4)
set_close_to!(lsgrid.sliders[3], 15.9)

save("example_labelslidergrid.svg", fig); nothing # hide
```

![example labelslidergrid](example_labelslidergrid.svg)

If you want to programmatically move the slider, use the function [`AbstractPlotting.MakieLayout.set_close_to!`](@ref).
Don't manipulate the `value` attribute directly, as there is no guarantee that
this value exists in the range underlying the slider, and the slider's displayed value would
not change anyway by changing the slider's output.

## Label

This is just normal text, except it's also layoutable. A text's size is known,
so rows and columns in a GridLayout can shrink to the appropriate width or height.

```@example
using CairoMakie

fig = Figure(resolution = (1200, 900))

fig[1:2, 1:3] = [Axis(fig) for _ in 1:6]

supertitle = Label(fig[0, :], "Six plots", textsize = 30)

sideinfo = Label(fig[2:3, 0], "This text is vertical", rotation = pi/2)

save("example_ltext.svg", fig); nothing # hide
```

![example ltext](example_ltext.svg)

## Button

```@example
using CairoMakie

fig = Figure(resolution = (1200, 900))

Axis(fig[1, 1])
fig[2, 1] = buttongrid = GridLayout(tellwidth = false)

buttons = buttongrid[1, 1:5] = [Button(fig, label = "Button $i") for i in 1:5]

for button in buttons
    on(button.clicks) do n
        println("$(button.label[]) was clicked $n times.")
    end
end

fig

save("example_lbutton.svg", fig); nothing # hide
```

![example lbutton](example_lbutton.svg)


## Box

A simple rectangle poly that is layoutable. This can be useful to make boxes for
facet plots or when a rectangular placeholder is needed.

```@example
using CairoMakie
using ColorSchemes

fig = Figure(resolution = (1200, 900))

rects = fig[1:4, 1:6] = [
    Box(fig, color = c)
    for c in get.(Ref(ColorSchemes.rainbow), (0:23) ./ 23)]

save("example_lrect.svg", fig); nothing # hide
```

![example lrect](example_lrect.svg)

## LScene

If you need a normal Makie scene in a layout, for example for 3D plots, you have
to use `LScene` right now. It's just a wrapper around the normal `Scene` that
makes it layoutable. The underlying Scene is accessible via the `scene` field.
You can plot into the `LScene` directly, though.

You can pass keyword arguments to the underlying `Scene` object to the `scenekw` keyword.
Currently, it can be necessary to pass a couple of attributes explicitly to make sure they
are not inherited from the main scene (which has a pixel camera and no axis, e.g.).

```julia
using CairoMakie

fig = Figure(resolution = (1200, 900))

lscene = LScene(fig[1, 1], scenekw = (camera = cam3d!, raw = false))

# now you can plot into lscene like you're used to
scatter!(lscene, randn(100, 3))
```


## Toggle

A toggle with an attribute `active` that can either be true or false, to enable
or disable properties of an interactive plot.

```@example
using CairoMakie

fig = Figure(resolution = (1200, 900))

ax = Axis(fig[1, 1])

toggles = [Toggle(fig, active = ac) for ac in [true, false]]
labels = [Label(fig, lift(x -> x ? "active" : "inactive", t.active))
    for t in toggles]

fig[1, 2] = grid!(hcat(toggles, labels), tellheight = false)

save("example_ltoggle.svg", fig); nothing # hide
```

![example ltoggle](example_ltoggle.svg)


## Menu

A dropdown menu with `options`, where each element's label is determined with `optionlabel(element)`
and the value with `optionvalue(element)`. The default behavior is to treat a 2-element tuple
as `(label, value)` and any other object as `value`, where `label = string(value)`.

The attribute `selection` is set to `optionvalue(element)` when the element's entry is selected.



```@example
using CairoMakie

fig = Figure(resolution = (1200, 900))

menu = Menu(fig, options = ["viridis", "heat", "blues"])

funcs = [sqrt, x->x^2, sin, cos]

menu2 = Menu(fig, options = zip(["Square Root", "Square", "Sine", "Cosine"], funcs))

fig[1, 1] = vgrid!(
    Label(fig, "Colormap", width = nothing),
    menu,
    Label(fig, "Function", width = nothing),
    menu2;
    tellheight = false, width = 200)

ax = Axis(fig[1, 2])

func = Node{Any}(funcs[1])

ys = @lift($func.(0:0.3:10))
scat = scatter!(ax, ys, markersize = 10px, color = ys)

cb = Colorbar(fig[1, 3], scat, width = 30)

on(menu.selection) do s
    scat.colormap = s
end

on(menu2.selection) do s
    func[] = s
    autolimits!(ax)
end

menu2.is_open = true

save("example_lmenu.svg", fig); nothing # hide
```

![example lmenu](example_lmenu.svg)


## Deleting Layoutables

To remove axes, colorbars and other layoutables from their layout and the figure or scene,
use `delete!(layoutable)`.

```@eval
using GLMakie
GLMakie.activate!()
```
