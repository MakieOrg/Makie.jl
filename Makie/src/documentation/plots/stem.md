# stem

## Examples

### Basic Stem Plot

```@figure
f = Figure()
Axis(f[1, 1])

xs = LinRange(0, 4pi, 30)

stem!(xs, sin.(xs))

f
```

### Stem Plot with Custom Colors and Markers

```@figure
f = Figure()
Axis(f[1, 1])

xs = LinRange(0, 4pi, 30)

stem!(xs, sin,
    offset = 0.5, trunkcolor = :blue, marker = :rect,
    stemcolor = :red, color = :orange,
    markersize = 15, strokecolor = :red, strokewidth = 3,
    trunklinestyle = :dash, stemlinestyle = :dashdot)

f
```

### Stem Plot with Varying Offset and Colors

```@figure
f = Figure()
Axis(f[1, 1])

xs = LinRange(0, 4pi, 30)

stem!(xs, sin.(xs),
    offset = LinRange(-0.5, 0.5, 30),
    color = LinRange(0, 1, 30), colorrange = (0, 0.5),
    trunkcolor = LinRange(0, 1, 30), trunkwidth = 5)

f
```

### 3D Stem Plot

```@figure backend=GLMakie
f = Figure()

xs = LinRange(0, 4pi, 30)

stem(f[1, 1], 0.5xs, 2 .* sin.(xs), 2 .* cos.(xs),
    offset = Point3f.(0.5xs, sin.(xs), cos.(xs)),
    stemcolor = LinRange(0, 1, 30), stemcolormap = :Spectral, stemcolorrange = (0, 0.5))

f
```
