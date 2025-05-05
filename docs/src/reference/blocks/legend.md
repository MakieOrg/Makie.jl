

# Legend

## Creating A Legend From Elements

You can create a basic Legend by passing a vector of legend entries and a vector of labels, plus an optional title as the third argument.

The elements in the vector of legend entries can either be plot objects or LegendElements like LineElement, MarkerElement and PolyElement.
Or they can be vectors of such objects that will be layered together as one.

### Legend element attributes

The standard plot objects like `Scatter` or `Lines` have predefined conversions to `MarkerElement`s and `LineElement`s that copy the relevant plot attributes to the legend element.
If an attribute has a vector-like value, it falls back to the scalar default of the legend.
The legend defaults themselves are by default inherited from the main theme.
For example, `polystrokewidth` of the legend falls back to `patchstrokewidth` of the main theme.
In the following example, you can see that the legend for `sca2` copies the `:rect` marker but not the vector-valued color.

```@figure

f = Figure()

Axis(f[1, 1])

xs = 0:0.5:10
ys = sin.(xs)
lin = lines!(xs, ys, color = :blue)
sca = scatter!(xs, ys, color = :red)
sca2 = scatter!(xs, ys .+ 0.5, color = 1:length(xs), marker = :rect)

Legend(f[1, 2],
    [lin, sca, [lin, sca], sca2],
    ["a line", "some dots", "both together", "rect markers"])

f
```

## Creating A Legend From An Axis

You can also create a Legend by passing it an axis object, like `Axis`, `LScene` or `Scene`.
All plots that have a `label` attribute set will be put into the legend, in the order that they appear in the axis, and you can optionally pass a title as the third argument.

```@figure

f = Figure()

ax = f[1, 1] = Axis(f)

lines!(0..15, sin, label = "sin", color = :blue)
lines!(0..15, cos, label = "cos", color = :red)
lines!(0..15, x -> -cos(x), label = "-cos", color = :green)

f[1, 2] = Legend(f, ax, "Trig Functions", framevisible = false)

f
```

With the keywords `merge` and `unique` you can control how plot objects with the same labels are treated.
If `merge` is `true`, all plot objects with the same label will be layered on top of each other into one legend entry.
If `unique` is `true`, all plot objects with the same plot type and label will be reduced to one occurrence.

```@figure

f = Figure()

traces = cumsum(randn(10, 5), dims = 1)

for (i, (merge, unique)) in enumerate(
        Iterators.product([false, true], [false true]))

    axis = Axis(f[fldmod1(i, 2)...],
        title = "merge = $merge, unique = $unique")

    for trace in eachcol(traces)
        lines!(trace, label = "single", color = (:black, 0.2))
    end

    mu = vec(sum(traces, dims = 2) ./ 5)
    lines!(mu, label = "mean")
    scatter!(mu, label = "mean")

    axislegend(axis, merge = merge, unique = unique)

end

f
```


## Legend Inside An Axis

The `axislegend` function is a quick way to add a legend to an Axis.
You can pass a selected axis plus arguments which are forwarded to the `Legend` constructor, or the current axis is used by default.
If you pass only a string, it's used as the title with the current axis.

The position can be set via a shortcut symbol, first halign (l, r, c) then valign (b, t, c), such as :lt for left, top and :cb for center bottom.
Or you can set position with tuple (halign, valign) with elements from 0 to 1:
`position = (0.1, 0.9)`
```@figure

f = Figure()

ax = Axis(f[1, 1])

sc1 = scatter!(randn(10, 2), color = :red, label = "Red Dots")
sc2 = scatter!(randn(10, 2), color = :blue, label = "Blue Dots")
scatter!(randn(10, 2), color = :orange, label = "Orange Dots")
scatter!(randn(10, 2), color = :cyan, label = "Cyan Dots")

axislegend()

axislegend("Titled Legend", position = :lb)

axislegend(ax, [sc1, sc2], ["One", "Two"], "Selected Dots", position = :rb,
    orientation = :horizontal)

f
```

Alternatively, you can simply add a Legend to the same layout slot
that an axis lives in. As long as the axis is bigger than the legend you can
set the legend's `tellheight` and `tellwidth` to `false` and position it using the align
variables. You can use the margin keyword to keep the legend from touching the axis
spines.

```@figure

haligns = [:left, :right, :center]
valigns = [:top, :bottom, :center]

f = Figure()

Axis(f[1, 1])

xs = 0:0.1:10
lins = [lines!(xs, sin.(xs .* i), color = color)
    for (i, color) in zip(1:3, [:red, :blue, :green])]

for (j, ha, va) in zip(1:3, haligns, valigns)
    Legend(
        f[1, 1], lins, ["Line $i" for i in 1:3],
        "$ha & $va",
        tellheight = false,
        tellwidth = false,
        margin = (10, 10, 10, 10),
        halign = ha, valign = va, orientation = :horizontal
    )
end

f
```

## Creating Legend Entries Manually

Sometimes you might want to construct legend entries from scratch to have maximum
control. So far you can use `LineElement`s, `MarkerElement`s or `PolyElement`s.
The attributes for these elements are the following (the `[]` parts can be left out when constructing these elements directly, but have to be fully written out for the attributes that the legend holds):

```julia
# LineElement
[line]points, [line]color, linestyle, linewidth

# MarkerElement
[marker]points, marker, markersize, [marker]color,
[marker]strokewidth, [marker]strokecolor

# PolyElement
[poly]points, [poly]color, [poly]strokewidth, [poly]strokecolor
```

The attributes `linepoints`, `markerpoints` and `polypoints` decide where in the legend entry patch rectangle the plot objects are placed.
These values should be normalized to a 1 by 1 rectangle, and the final shape depends on the `patchsize` of the legend.
For example, if you want wider line and poly markers, you could set the `patchsize` of the legend to `(50, 30)`.

```@figure

f = Figure()

Axis(f[1, 1])

elem_1 = [LineElement(color = :red, linestyle = nothing),
          MarkerElement(color = :blue, marker = 'x', markersize = 15,
          strokecolor = :black)]

elem_2 = [PolyElement(color = :red, strokecolor = :blue, strokewidth = 1),
          LineElement(color = :black, linestyle = :dash)]

elem_3 = LineElement(color = :green, linestyle = nothing,
        points = Point2f[(0, 0), (0, 1), (1, 0), (1, 1)])

elem_4 = MarkerElement(color = :blue, marker = 'π', markersize = 15,
        points = Point2f[(0.2, 0.2), (0.5, 0.8), (0.8, 0.2)])

elem_5 = PolyElement(color = :green, strokecolor = :black, strokewidth = 2,
        points = Point2f[(0, 0), (1, 0), (0, 1)])

Legend(f[1, 2],
    [elem_1, elem_2, elem_3, elem_4, elem_5],
    ["Line & Marker", "Poly & Line", "Line", "Marker", "Poly"],
    patchsize = (35, 35), rowgap = 10)

f
```


## Overriding legend entry attributes

By default, legends inherit the visual attributes of the plots they belong to.
Sometimes, it is necessary to override some of these attributes to make the legend more legible.
You can pair a key-value object like a `NamedTuple` or a `Dict{Symbol}` to a plot's `label` to override its automatic legend entry, for example to increase the marker size of a `Scatter`:

```@figure
f, ax, sc = scatter(
    cos.(range(0, 7pi, 100)),
    color = :black,
    markersize = 8,
    label = "cos" => (; markersize = 15)
)
scatter!(
    sin.(range(0, 7pi, 100)),
    color = :black,
    marker = :utriangle,
    markersize = 8,
    label = "sin" => (; markersize = 15)
)
Legend(f[1, 2], ax)
f
```

These are the attributes you can override (note that some of them have convenience aliases like `color` which applies to all elements while `polycolor` only applies to `PolyElement`s):

- `MarkerElement`
  - `[marker]points`, `markersize`, `[marker]strokewidth`, `[marker]color`, `[marker]strokecolor`, `[marker]colorrange`, `[marker]colormap`
- `LineElement`
  - `[line]points`, `linewidth`, `[line]color`, `linestyle`, `[line]colorrange`, `[line]colormap`
- `PolyElement`
  - `[poly]points`, `[poly]strokewidth`, `[poly]color`, `[poly]strokecolor`, `[poly]colorrange`, `[poly]colormap`
- `MeshElement`
  - `mesh`, `color`, `colormap`, `colorrange`, `uv_transform`
- `ImageElement`
  - `limits`, `data`, `colormap`, `colorrange`, `interpolate`
- `MeshScatterElement`
  - `position`, `color`, `marker`, `markersize`, `rotation`, `colormap`, `colorrange`

Another common case is when you want to create a legend for a plot with a categorical colormap.
By passing a vector of labels paired with overrides, you can create multiple entries with the correct colors:

```@figure
f, ax, bp = barplot(
    1:5,
    [1, 3, 2, 5, 4],
    color = 1:5,
    colorrange = (1, 5),
    colormap = :Set1_5,
    label = [label => (; color = i)
        for (i, label) in enumerate(["red", "blue", "green", "purple", "orange"])]
)
Legend(f[1, 2], ax)
f
```

You may also override plots in the `Legend` constructor itself, in this case, you pair the overrides with the plots whose legend entries you want to override:

```@figure
f = Figure()
ax = Axis(f[1, 1])
li = lines!(ax, 1:5, linestyle = :dot)
sc = scatter!(ax, 1:5, markersize = 10)
Legend(
    f[1, 2],
    [
        sc => (; markersize = 20),
        li => (; linewidth = 3),
        [li, sc] => (; color = :red),
        [li => (; linewidth = 3), sc => (; markersize = 20)],
    ],
    ["Scatter", "Line", "Both", "Both 2"],
    patchsize = (40, 20),
)
f
```

## Multi-Group Legends

Sometimes a legend consists of multiple groups, for example in a plot where both
marker size and color are varied and those properties need to be visualized
separately, but still together in one legend. Each group's content is given as
an array of elements and an array of labels, each within one collective array.
You can shift the position of the titles relative to each group with the
`titleposition` attribute, either `:left` or `:top`.

```@figure

f = Figure()

markersizes = [5, 10, 15, 20]
colors = [:red, :green, :blue, :orange]

group_size = [MarkerElement(marker = :circle, color = :black,
    strokecolor = :transparent,
    markersize = ms) for ms in markersizes]

group_color = [PolyElement(color = color, strokecolor = :transparent)
    for color in colors]

legends = [Legend(f,
    [group_size, group_color],
    [string.(markersizes), string.(colors)],
    ["Size", "Color"], tellheight = true) for _ in 1:4]

f[1, 1:2] = legends[1:2]
f[2, :] = legends[3]
f[3, :] = legends[4]

for l in legends[3:4]
    l.orientation = :horizontal
    l.tellheight = true
    l.tellwidth = false
end

legends[2].titleposition = :left
legends[4].titleposition = :left

legends[1].nbanks = 2
legends[4].nbanks = 2

Label(f[1, 1, Left()], "titleposition = :top\norientation = :vertical\nnbanks = 2", font = :italic, padding = (0, 10, 0, 0))
Label(f[1, 2, Right()], "titleposition = :left\norientation = :vertical\nnbanks = 1", font = :italic, padding = (10, 0, 0, 0))
Label(f[2, 1:2, Top()], "titleposition = :top, orientation = :horizontal\nnbanks = 1", font = :italic)
Label(f[3, 1:2, Top()], "titleposition = :left, orientation = :horizontal\nnbanks = 2", font = :italic)

f
```

## Legend Interactivity

The Legend can be interacted with to show or hide connected plots.
A left click on a specific element will toggle the visibility of the connected plots.
A right click anywhere in the Legend will toggle the visibility of all plots associated with every element.
A middle click will toggle all plots if they have the same visibility state or make all visible if they do not.
Note that if you construct elements (MarkerElement, PolyElement, etc.) yourself, you need to also pass a plot or vector of plots as the first argument to enable these interactions.

```@example legend_interaction
using GLMakie
GLMakie.activate!() # hide

fig = Figure(size = (600, 450))
ax = Axis(fig[1, 1])
lines!(ax, Rect2f(-1,-1,2,2), linewidth = 5, color = RGBf(0.3, 0.5, 1), label = "blue line")
scatter!(ax, Rect2f(-1,-1,2,2), markersize = 30, color = :orange, label = "orange scatter")
lines!(ax, Circle(Point2f(0), 1), linewidth = 5, color = :darkgreen, label = "green circle")
leg = axislegend(ax, position = (:center, :center))
fig
nothing # hide
```

```@setup legend_interaction
using ..FakeInteraction

_events = [
    Wait(0.5),
    Lazy() do fig
        MouseTo(relative_pos(leg, (0.6, 0.8)))
    end,
    Wait(0.2), LeftClick(),
    Wait(1.5),
    Lazy() do fig
        MouseTo(relative_pos(leg, (0.6, 0.5)))
    end,
    Wait(0.2), LeftClick(),
    Wait(1.5),
    RightClick(),
    Wait(1.5),
    Lazy() do fig
        MouseTo(relative_pos(leg, (0.6, 0.7)))
    end,
    Wait(0.2), LeftClick(),
    Wait(1.5),
    MiddleClick(),
    Wait(1.5)
]

interaction_record(fig, "legend_interaction_example.mp4", _events)
```

```@raw html
<video autoplay loop muted playsinline src="./legend_interaction_example.mp4" width="600"/>
```

## Attributes

```@attrdocs
Legend
```
