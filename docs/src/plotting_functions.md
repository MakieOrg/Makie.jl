# Plotting Functions

On this page, the basic plotting functions are listed together with examples of their usage and available attributes.

## `contour`

```@docs
contour
```

### Examples

```@example
using Makie
Makie.AbstractPlotting.inline!(true) # hide

xs = LinRange(0, 10, 100)
ys = LinRange(0, 20, 100)
zs = [cos(x) * sin(y) for x in xs, y in ys]

contour(xs, ys, zs)
```


## `lines`

```@docs
lines
```

### Examples

```@example
using Makie
Makie.AbstractPlotting.inline!(true) # hide

xs = 0:0.01:10
ys = 0.5 .* sin.(xs)

scene = lines(xs, ys)
lines!(scene, xs, ys .- 1, linewidth = 5)
lines!(scene, xs, ys .- 2, color = ys)
lines!(scene, xs, ys .- 3, linestyle = :dash)
```

## `linesegments`

```@docs
linesegments
```

### Examples

```@example
using Makie
Makie.AbstractPlotting.inline!(true) # hide

xs = 1:0.5:10
ys = sin.(xs)

linesegments(xs, ys)
```

## `scatter`

```@docs
scatter
```

### Examples

```@example
using Makie
Makie.AbstractPlotting.inline!(true) # hide

xs = LinRange(0, 10, 20)
ys = 0.5 .* sin.(xs)

scene = scatter(xs, ys, color = :red)
scatter!(scene, xs, ys .- 1, color = xs)
scatter!(scene, xs, ys .- 2, markersize = LinRange(5, 30, 20))
scatter!(scene, xs, ys .- 3, marker = 'a':'t', strokewidth = 0, color = :black)
scene
```