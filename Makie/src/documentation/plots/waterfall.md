# waterfall

## Examples

### Basic Waterfall Plot

```@figure
y = [6, 4, 2, -8, 3, 5, 1, -2, -3, 7]

waterfall(y)
```

### Waterfall Plot with Direction Markers

```@figure
y = [6, 4, 2, -8, 3, 5, 1, -2, -3, 7]

waterfall(y, show_direction=true)
```

### Waterfall Plot with Custom Direction Markers

```@figure
y = [6, 4, 2, -8, 3, 5, 1, -2, -3, 7]

waterfall(y, show_direction=true, marker_pos=:cross, marker_neg=:hline, direction_color=:gold)
```

### Grouped Waterfall Plot with Dodge

```@figure
colors = Makie.wong_colors()
x = repeat(1:2, inner=5)
y = [6, 4, 2, -8, 3, 5, 1, -2, -3, 7]
group = repeat(1:5, outer=2)

waterfall(x, y, dodge=group, color=colors[group])
```

### Grouped Waterfall Plot with Final Bars in Background

```@figure
colors = Makie.wong_colors()
x = repeat(1:2, inner=5)
y = [6, 4, 2, -8, 3, 5, 1, -2, -3, 7]
group = repeat(1:5, outer=2)

waterfall(x, y, dodge=group, color=colors[group], show_direction=true, show_final=true)
```

### Grouped Waterfall Plot with Custom Final Bar Color

```@figure
colors = Makie.wong_colors()
x = repeat(1:2, inner=5)
y = [6, 4, 2, -8, 3, 5, 1, -2, -3, 7]
group = repeat(1:5, outer=2)

waterfall(x, y, dodge=group, color=colors[group], show_final=true, final_color=(colors[6], 1//3))
```

### Grouped Waterfall Plot Stacked by X

```@figure
colors = Makie.wong_colors()
x = repeat(1:5, outer=2)
y = [6, 4, 2, -8, 3, 5, 1, -2, -3, 7]
group = repeat(1:2, inner=5)

waterfall(x, y, dodge=group, color=colors[group], show_direction=true, stack=:x)
```
