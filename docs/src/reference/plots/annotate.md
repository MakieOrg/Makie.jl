# annotate

```@shortdocs; canonical=false
annotate
```

### Automatic label placement

If only target points are specified, text labels are automatically optimized for less overlap with their data points or each other.

```@figure
f = Figure()
ax = Axis(f[1, 1], limits = (-3, 1.5, -3, 3), title = "annotate")

points = [(-2.15, -0.19), (-1.66, 0.78), (-1.56, 0.87), (-0.97, -1.91), (-0.96, -0.25), (-0.79, 2.6), (-0.74, 1.68), (-0.56, -0.44), (-0.36, -0.63), (-0.32, 0.67), (-0.15, -1.11), (-0.07, 1.23), (0.3, 0.73), (0.72, -1.48), (0.8, 1.12)]

fruit = ["Apple", "Banana", "Cherry", "Date", "Elderberry", "Fig", "Grape", "Honeydew",
          "Indian Fig", "Jackfruit", "Kiwi", "Lychee", "Mango", "Nectarine", "Orange"]

scatter!(ax, points)
annotate!(ax, points, text = fruit)

ax2 = Axis(f[1, 2], limits = (-3, 1.5, -3, 3), title = "text")

scatter!(ax2, points)
text!(ax2, points, text = fruit)

hidedecorations!.([ax, ax2])

f
```

## Attributes

```@attrdocs
Annotate
```