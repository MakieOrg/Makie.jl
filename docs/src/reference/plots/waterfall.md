# waterfall

```@shortdocs; canonical=false
waterfall
```


## Examples

```@figure
y = [6, 4, 2, -8, 3, 5, 1, -2, -3, 7]

waterfall(y)
```

The direction of the bars might be easier to parse with some visual support.

```@figure
y = [6, 4, 2, -8, 3, 5, 1, -2, -3, 7]

waterfall(y, show_direction=true)
```

You can customize the markers that indicate the bar directions.

```@figure
y = [6, 4, 2, -8, 3, 5, 1, -2, -3, 7]

waterfall(y, show_direction=true, marker_pos=:cross, marker_neg=:hline, direction_color=:gold)
```

If the `dodge` attribute is provided, bars are stacked by `dodge`.

```@figure
colors = Makie.wong_colors()
x = repeat(1:2, inner=5)
y = [6, 4, 2, -8, 3, 5, 1, -2, -3, 7]
group = repeat(1:5, outer=2)

waterfall(x, y, dodge=group, color=colors[group])
```

It can be easier to compare final results of different groups if they are shown in the background.

```@figure
colors = Makie.wong_colors()
x = repeat(1:2, inner=5)
y = [6, 4, 2, -8, 3, 5, 1, -2, -3, 7]
group = repeat(1:5, outer=2)

waterfall(x, y, dodge=group, color=colors[group], show_direction=true, show_final=true)
```

The color of the final bars in the background can be modified.

```@figure
colors = Makie.wong_colors()
x = repeat(1:2, inner=5)
y = [6, 4, 2, -8, 3, 5, 1, -2, -3, 7]
group = repeat(1:5, outer=2)

waterfall(x, y, dodge=group, color=colors[group], show_final=true, final_color=(colors[6], 1//3))
```

You can also specify to stack grouped waterfall plots by `x`.

```@figure
colors = Makie.wong_colors()
x = repeat(1:5, outer=2)
y = [6, 4, 2, -8, 3, 5, 1, -2, -3, 7]
group = repeat(1:2, inner=5)

waterfall(x, y, dodge=group, color=colors[group], show_direction=true, stack=:x)
```

## Attributes

```@attrdocs
Waterfall
```
