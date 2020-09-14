```@eval
using CairoMakie
CairoMakie.activate!()
```

## Creating a legend

```@example
using AbstractPlotting.MakieLayout
using AbstractPlotting
using AbstractPlotting: px

scene, layout = layoutscene(resolution = (1400, 900))

ax = layout[1, 1] = LAxis(scene)

xs = 0:0.5:10
ys = sin.(xs)
lin = lines!(ax, xs, ys, color = :blue)
sca = scatter!(ax, xs, ys, color = :red, markersize = 15px)

leg = LLegend(scene, [lin, sca, [lin, sca]], ["a line", "some dots", "both together"])
layout[1, 2] = leg

save("example_legend.svg", scene); nothing # hide
```

![example legend](example_legend.svg)


## Multi-bank legend

You can control the number of banks with the `nbanks` attribute. Banks are columns
when in vertical mode, and rows when in horizontal mode.

```@example
using AbstractPlotting.MakieLayout
using AbstractPlotting
using AbstractPlotting: px

scene, layout = layoutscene(resolution = (1400, 900))

ax = layout[1, 1] = LAxis(scene)

xs = 0:0.1:10
lins = [lines!(ax, xs, sin.(xs .+ 3v), color = RGBf0(v, 0, 1-v)) for v in 0:0.1:1]

leg = LLegend(scene, lins, string.(1:length(lins)), nbanks = 3)
layout[1, 2] = leg


save("example_legend_ncols.svg", scene); nothing # hide
```

![example legend ncols](example_legend_ncols.svg)



## Legend inside an axis

To place a legend inside an axis you can simply add it to the same layout slot
that the axis lives in. As long as the axis is bigger than the legend you can
set the legend's `tellheight` and `tellwidth` to `false` and position it using the align
variables. You can use the margin keyword to keep the legend from touching the axis
spines.

```@example
using AbstractPlotting.MakieLayout
using AbstractPlotting

haligns = [:left, :right, :center]
valigns = [:top, :bottom, :center]

scene, layout = layoutscene(resolution = (1400, 900))

ax = layout[1, 1] = LAxis(scene)

xs = 0:0.1:10
lins = [lines!(ax, xs, sin.(xs .* i), color = color)
    for (i, color) in zip(1:3, [:red, :blue, :green])]

legends = [LLegend(
        scene, lins, ["Line $i" for i in 1:3],
        "$ha & $va",
        tellheight = false,
        tellwidth = false,
        margin = (10, 10, 10, 10),
        halign = ha, valign = va, orientation = :horizontal
    ) for (j, ha, va) in zip(1:3, haligns, valigns)]


for leg in legends
    layout[1, 1] = leg
end

save("example_legend_alignment.svg", scene); nothing # hide
```

![example legend alignment](example_legend_alignment.svg)


## Creating legend entries manually

Sometimes you might want to construct legend entries from scratch to have maximum
control. So far you can use `LineElement`s, `MarkerElement`s or `PolyElement`s.
Some attributes that can't have a meaningful preset and would usually be inherited
from plot objects (like color) have to be explicitly specified. Others are
inherited from the legend if they are not specified. These include marker
arrangement for `MarkerElement`s or poly shape for `PolyElement`s. You can check
the list using this function:

```@example
using AbstractPlotting.MakieLayout
MakieLayout.attributenames(LegendEntry)
```


```@example
using AbstractPlotting.MakieLayout
using AbstractPlotting
using AbstractPlotting: px

scene, layout = layoutscene(resolution = (1400, 900))

ax = layout[1, 1] = LAxis(scene)


elem_1 = [LineElement(color = :red, linestyle = nothing),
          MarkerElement(color = :blue, marker = 'x', strokecolor = :black)]

elem_2 = [PolyElement(color = :red, strokecolor = :blue),
          LineElement(color = :black, linestyle = :dash)]

elem_3 = LineElement(color = :green, linestyle = nothing,
        linepoints = Point2f0[(0, 0), (0, 1), (1, 0), (1, 1)])

elem_4 = MarkerElement(color = :blue, marker = 'π',
        strokecolor = :transparent,
        markerpoints = Point2f0[(0.2, 0.2), (0.5, 0.8), (0.8, 0.2)])

elem_5 = PolyElement(color = :green, strokecolor = :black,
        polypoints = Point2f0[(0, 0), (1, 0), (0, 1)])


leg = layout[1, 2] = LLegend(scene,
    [elem_1, elem_2, elem_3, elem_4, elem_5],
    ["Line & Marker", "Poly & Line", "Line", "Marker", "Poly"],
    patchsize = (35, 35))

save("example_legend_entries.svg", scene); nothing # hide
```

![example legend entries](example_legend_entries.svg)


## Horizontal legend

In case you want the legend entries to be listed horizontally, set the `orientation`
attribute to `:horizontal`. In this case the `nbanks` attribute refers to the
number of rows instead of columns. To keep an adjacent axis from potentially shrinking to
the width of the horizontal legend, set `tellwidth = false` and `tellheight = true`
if you place the legend below or above the axis.



```@example
using AbstractPlotting.MakieLayout
using AbstractPlotting
using AbstractPlotting: px

scene, layout = layoutscene(resolution = (1400, 900))

ax = layout[1, 1] = LAxis(scene)

xs = 0:0.5:10
ys = sin.(xs)
lin = lines!(ax, xs, ys, color = :blue)
sca = scatter!(ax, xs, ys, color = :red, markersize = 15px)

leg = LLegend(scene, [lin, sca, lin], ["a line", "some dots", "line again"])
layout[1, 2] = leg

leg_horizontal = LLegend(scene, [lin, sca, lin], ["a line", "some dots", "line again"],
    orientation = :horizontal, tellwidth = false, tellheight = true)
layout[2, 1] = leg_horizontal


save("example_legend_horizontal.svg", scene); nothing # hide
```

![example legend horizontal](example_legend_horizontal.svg)


## Multi-group legends

Sometimes a legend consists of multiple groups, for example in a plot where both
marker size and color are varied and those properties need to be visualized
separately, but still together in one legend. Each group's content is given as
an array of elements and an array of labels, each within one collective array.
You can shift the position of the titles relative to each group with the
`titleposition` attribute, either `:left` or `:top`.

```@example
using AbstractPlotting.MakieLayout
using AbstractPlotting
using AbstractPlotting: px

scene, layout = layoutscene(resolution = (1400, 900))

ax = layout[1, 1] = LAxis(scene)

markersizes = [5, 10, 15, 20]
colors = [:red, :green, :blue, :orange]

for ms in markersizes, color in colors
    scatter!(ax, randn(5, 2), markersize = ms * px, color = color)
end

group_size = [MarkerElement(marker = :circle, color = :black, strokecolor = :transparent,
    markersize = ms * px) for ms in markersizes]

group_color = [PolyElement(color = color, strokecolor = :transparent)
    for color in colors]

legends = [LLegend(scene,
    [group_size, group_color],
    [string.(markersizes), string.(colors)],
    ["Size", "Color"]) for _ in 1:6]

layout[1, 2:4] = legends[1:3]
layout[2:4, 1] = legends[4:6]

for l in legends[4:6]
    l.orientation = :horizontal
    l.tellheight = true
    l.tellwidth = false
end

legends[2].titleposition = :left
legends[5].titleposition = :left

legends[3].nbanks = 2
legends[5].nbanks = 2
legends[6].nbanks = 2

scene

save("example_multilegend.svg", scene); nothing # hide
```

![example multilegend](example_multilegend.svg)

```@eval
using GLMakie
GLMakie.activate!()
```