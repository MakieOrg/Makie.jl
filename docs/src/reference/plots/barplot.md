# barplot

```@shortdocs; canonical=false
barplot
```

## Examples

```@figure
f = Figure()
Axis(f[1, 1])

xs = 1:0.2:10
ys = 0.5 .* sin.(xs)

barplot!(xs, ys, color = :red, strokecolor = :black, strokewidth = 1)
barplot!(xs, ys .- 1, fillto = -1, color = xs, strokecolor = :black, strokewidth = 1)

f
```

```@figure
xs = 1:0.2:10
ys = 0.5 .* sin.(xs)

barplot(xs, ys, gap = 0, color = :gray85, strokecolor = :black, strokewidth = 1)
```

### Grouping

The first argument of `barplot` can double as a category or group identifier.
All height values passed through the second that have the same category value will be combined into one bar.

```@figure barplot
tbl = (cat = [1, 1, 1, 2, 2, 2, 3, 3, 3],
       height = 0.1:0.1:0.9,
       grp = [1, 2, 3, 1, 2, 3, 1, 2, 3],
       grp1 = [1, 2, 2, 1, 1, 2, 1, 1, 2],
       grp2 = [1, 1, 2, 1, 2, 1, 1, 2, 1]
       )

barplot(tbl.cat, tbl.height, color = tbl.grp,
        axis = (xticks = (1:3, ["left", "middle", "right"]),
                title = "Stacked bars"),
        )
```

Within a category, values can be further separated into sub groups using `stack` and/or `dodge`.
In the `tbl` above, `grp` marks the values in each category as the first, second and third value of the respective category.
Passing this to `stack` will separate the category bars into 3 smaller stacking bars.
Each of them represents one height value, with group 1 at the bottom and 3 at the top.

```@figure barplot
barplot(tbl.cat, tbl.height,
        stack = tbl.grp,
        color = tbl.grp,
        axis = (xticks = (1:3, ["left", "middle", "right"]),
                title = "Stacked bars"),
        )
```

Passing `grp` to `dodge` will instead draw the individual height values as separate bars side by side.
Here 1 is the left most and 3 the right most bar.
The gap between dodged bars can be adjusted with `dodge_gap`.

```@figure barplot
barplot(tbl.cat, tbl.height,
        dodge = tbl.grp,
        color = tbl.grp,
        axis = (xticks = (1:3, ["left", "middle", "right"]),
                title = "Dodged bars"),
        )
```

Note that `dodge` will create slots based on the maximum group value.
If we replaced 3 with 4 in `grp` a gap would be drawn between bars of group 2 and group 4.

```@figure barplot
barplot(tbl.cat, tbl.height,
        dodge = [1, 2, 4, 1, 2, 4, 1, 2, 4],
        color = [1, 2, 4, 1, 2, 4, 1, 2, 4],
        axis = (xticks = (1:3, ["left", "middle", "right"]),
                title = "Dodged bars"),
        )
```

Dodging and stacking can also be combined.
Multiple values that belong to the same dodge group can be further separated using a different stack group:

```@figure barplot
barplot(tbl.cat, tbl.height,
        dodge = tbl.grp1,
        stack = tbl.grp2,
        color = tbl.grp,
        axis = (xticks = (1:3, ["left", "middle", "right"]),
                title = "Dodged and stacked bars"),
        )
```

```@figure barplot
colors = Makie.wong_colors()

# Figure and Axis
fig = Figure()
ax = Axis(fig[1,1], xticks = (1:3, ["left", "middle", "right"]),
        title = "Dodged bars with legend")

# Plot
barplot!(ax, tbl.cat, tbl.height,
        dodge = tbl.grp,
        color = colors[tbl.grp])

# Legend
labels = ["group 1", "group 2", "group 3"]
elements = [PolyElement(polycolor = colors[i]) for i in 1:length(labels)]
title = "Groups"

Legend(fig[1,2], elements, labels, title)

fig
```

```@figure barplot
barplot(
    tbl.cat, tbl.height,
    dodge = tbl.grp,
    color = tbl.grp,
    bar_labels = :y,
    axis = (xticks = (1:3, ["left", "middle", "right"]),
            title = "Dodged bars horizontal with labels"),
    colormap = [:red, :green, :blue],
    color_over_background=:red,
    color_over_bar=:white,
    flip_labels_at=0.85,
    direction=:x,
)
```

```@figure
barplot([-1, -0.5, 0.5, 1],
    bar_labels = :y,
    axis = (title="Fonts + flip_labels_at",),
    label_size = 20,
    flip_labels_at=(-0.8, 0.8),
    label_color=[:white, :green, :black, :white],
    label_formatter = x-> "Flip at $(x)?",
    label_offset = 10
)
```

```@figure
gantt = (
    machine = [1, 2, 1, 2],
    job = [1, 1, 2, 3],
    task = [1, 2, 3, 3],
    start = [1, 3, 3.5, 5],
    stop = [3, 4, 5, 6]
)

fig = Figure()
ax = Axis(
    fig[2,1],
    yticks = (1:2, ["A","B"]),
    ylabel = "Machine",
    xlabel = "Time"
)
xlims!(ax, 0, maximum(gantt.stop))

cmap = Makie.to_colormap(:tab10)

barplot!(
    gantt.machine,
    gantt.stop,
    fillto = gantt.start,
    direction = :x,
    color = gantt.job,
    colormap = cmap,
    colorrange = (1, length(cmap)),
    gap = 0.5,
    bar_labels = ["task #$i" for i in gantt.task],
    label_position = :center,
    label_color = :white,
    label = ["job #$i" => (; color = i) for i in unique(gantt.job)]
)

Legend(fig[1,1], ax, "Jobs", orientation=:horizontal, tellwidth = false, tellheight = true)

fig
```

## Attributes

```@attrdocs
BarPlot
```
