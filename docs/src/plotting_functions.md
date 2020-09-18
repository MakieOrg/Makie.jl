# Plotting Functions

On this page, the basic plotting functions are listed together with examples of their usage and available attributes.

## `band`

```@docs
band
```

### Examples

```@example
using Makie

xs = 1:0.2:10
ys_low = -0.2 .* sin.(xs) .- 0.25
ys_high = 0.2 .* sin.(xs) .+ 0.25

scene = band(xs, ys_low, ys_high)
band!(scene, xs, ys_low .- 1, ys_high .-1, color = :red)
```

## `barplot`

```@docs
barplot
```

### Examples

```@example
using Makie

xs = 1:0.2:10
ys = 0.5 .* sin.(xs)

scene = barplot(xs, ys, color = :red, strokecolor = :black, strokewidth = 1)
barplot!(scene, xs, ys .- 1, fillto = -1, color = xs, strokecolor = :black, strokewidth = 1)
```

## `contour`

```@docs
contour
```

### Examples

```@example
using Makie

xs = LinRange(0, 10, 100)
ys = LinRange(0, 15, 100)
zs = [cos(x) * sin(y) for x in xs, y in ys]

contour(xs, ys, zs)
```

## `heatmap`

```@docs
heatmap
```

### Examples

```@example
using Makie

xs = LinRange(0, 10, 100)
ys = LinRange(0, 15, 100)
zs = [cos(x) * sin(y) for x in xs, y in ys]

heatmap(xs, ys, zs)
```

## `image`

```@docs
image
```

### Examples

```@example
using Makie
using FileIO

img = rotr90(load("../assets/cow.png"))

image(img)
```


## `lines`

```@docs
lines
```

### Examples

```@example
using Makie

xs = 0:0.01:10
ys = 0.5 .* sin.(xs)

scene = lines(xs, ys)
lines!(scene, xs, ys .- 1, linewidth = 5)
lines!(scene, xs, ys .- 2, linewidth = 5, color = ys)
lines!(scene, xs, ys .- 3, linestyle = :dash)
```

## `linesegments`

```@docs
linesegments
```

### Examples

```@example
using Makie

xs = 1:0.2:10
ys = sin.(xs)

scene = linesegments(xs, ys)
linesegments!(scene, xs, ys .- 1, linewidth = 5)
linesegments!(scene, xs, ys .- 2, linewidth = LinRange(1, 10, length(xs)))
linesegments!(scene, xs, ys .- 3, linewidth = 5, color = LinRange(1, 5, length(xs)))
```



## `meshscatter`

```@docs
meshscatter
```

### Examples

```@example
using Makie

xs = cos.(1:0.5:20)
ys = sin.(1:0.5:20)
zs = LinRange(0, 3, length(xs))

meshscatter(xs, ys, zs, markersize = 0.1, color = zs)
```


## `poly`

```@docs
poly
```

### Examples

```@example
using Makie

p1 = Point2f0(0, 0)
p2 = Point2f0(2, 0)
p3 = Point2f0(3, 1)
p4 = Point2f0(1, 1)

poly([p1, p2, p3, p4], color = :red, strokecolor = :black, strokewidth = 1)
```


## `scatter`

```@docs
scatter
```

### Examples

```@example
using Makie

xs = LinRange(0, 10, 20)
ys = 0.5 .* sin.(xs)

scene = scatter(xs, ys, color = :red)
scatter!(scene, xs, ys .- 1, color = xs)
scatter!(scene, xs, ys .- 2, markersize = LinRange(5, 30, 20))
scatter!(scene, xs, ys .- 3, marker = 'a':'t', strokewidth = 0, color = :black)
scene
```


## `surface`

```@docs
surface
```

### Examples

```@example
using Makie

xs = LinRange(0, 10, 100)
ys = LinRange(0, 15, 100)
zs = [cos(x) * sin(y) for x in xs, y in ys]

surface(xs, ys, zs)
```

## `text`

```@docs
text
```

### Examples

```@example
using Makie

scene = Scene(camera = campixel!, show_axis = false)

text!(scene, "AbstractPlotting", position = Point2f0(300, 600),
    textsize = 30, align = (:left, :bottom), show_axis = false)
text!(scene, "AbstractPlotting", position = Point2f0(300, 500),
    color = :red, textsize = 30, align = (:right, :center), show_axis = false)
text!(scene, "AbstractPlotting\nMakie", position = Point2f0(300, 400),
    color = :blue, textsize = 30, align = (:center, :top), show_axis = false)
```