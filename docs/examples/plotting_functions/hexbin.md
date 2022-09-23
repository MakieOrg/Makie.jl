# hexbin

{{doc hexbin}}

## Examples

### Setting the number of bins

Due to the way that hexagonal grids work, one "bin" is understood as one step from a hexagon center to an adjacent hexagon center, which means two hexagons, not one.

Setting `bins` to an integer sets the number of bins to this value for both x and y.

\begin{examplefigure}{svg = true}
```julia
using CairoMakie
CairoMakie.activate!() # hide
Makie.inline!(true) # hide
using Random
Random.seed!(1234)

f = Figure(resolution = (800, 800))

x = rand(300)
y = rand(300)

for i in 1:4
    ax = Axis(f[fldmod1(i, 2)...], title = "bins = $i", aspect = DataAspect())
    hexbin!(ax, x, y, bins = i)
    wireframe!(ax, Rect2f(Point2f.(x, y)), color = :red)
    scatter!(ax, x, y, color = :red, markersize = 5)
end

f
```
\end{examplefigure}

You can also pass a tuple of integers to control x and y separately.

\begin{examplefigure}{svg = true}
```julia
using CairoMakie
CairoMakie.activate!() # hide
Makie.inline!(true) # hide
using Random
Random.seed!(1234)

f = Figure(resolution = (800, 800))

x = rand(300)
y = rand(300)

for i in 1:4
    ax = Axis(f[fldmod1(i, 2)...], title = "bins = (3, $i)", aspect = DataAspect())
    hexbin!(ax, x, y, bins = (3, i))
    wireframe!(ax, Rect2f(Point2f.(x, y)), color = :red)
    scatter!(ax, x, y, color = :red, markersize = 5)
end

f
```
\end{examplefigure}

### Setting the size of bins

You can also control the bin size directly by setting the `binsize` keyword.
In this case, the `bins` setting is ignored.

In a hexagonal grid, the step size from hexagon center to adjacent hexagon center is not the same in x and y direction.
This is why setting the same size for x and y will result in uneven hexagons.

\begin{examplefigure}{svg = true}
```julia
using CairoMakie
CairoMakie.activate!() # hide
Makie.inline!(true) # hide
using Random
Random.seed!(1234)

f = Figure(resolution = (800, 800))

x = rand(300)
y = rand(300)

for (i, binsize) in enumerate([0.1, 0.15, 0.2, 0.25])
    ax = Axis(f[fldmod1(i, 2)...], title = "binsize = ($binsize, $binsize)", aspect = DataAspect())
    hexbin!(ax, x, y, binsize = (binsize, binsize))
    wireframe!(ax, Rect2f(Point2f.(x, y)), color = :red)
    scatter!(ax, x, y, color = :red, markersize = 5)
end

f
```
\end{examplefigure}

To get evenly sized hexagons, set the bin size to a single number.
This number defines the step size in x, the y step size will be computed as `2 * step_x / sqrt(3)`.
Note that the visual appearance of the hexagons will only be even if the x and y axis have the same scaling, which is why we use `aspect = DataAspect()` in these examples.

Note how the x dimension in the following example is neatly split into ten steps for `binsize = 0.1`, five steps for `binsize = 0.2` and four steps for `binsize = 0.25` because those numbers all divide 1.
For `binsize = 0.15`, the coverage in x is not perfect.
The coverage in y is never perfect because of the `sqrt(3)` division.

\begin{examplefigure}{svg = true}
```julia
using CairoMakie
CairoMakie.activate!() # hide
Makie.inline!(true) # hide
using Random
Random.seed!(1234)

f = Figure(resolution = (800, 800))

x = rand(300)
y = rand(300)

for (i, binsize) in enumerate([0.1, 0.15, 0.2, 0.25])
    ax = Axis(f[fldmod1(i, 2)...], title = "binsize = $binsize", aspect = DataAspect())
    hexbin!(ax, x, y, binsize = binsize)
    wireframe!(ax, Rect2f(Point2f.(x, y)), color = :red)
    scatter!(ax, x, y, color = :red, markersize = 5)
end

f
```
\end{examplefigure}

### Hiding hexagons with low counts

All hexagons with a count lower than `threshold` will be removed:

\begin{examplefigure}{svg = true}
```julia
using CairoMakie
CairoMakie.activate!() # hide
Makie.inline!(true) # hide
using Random
Random.seed!(1234)

f = Figure(resolution = (800, 800))

x = randn(100000)
y = randn(100000)

for (i, threshold) in enumerate([1, 10, 100, 500])
    ax = Axis(f[fldmod1(i, 2)...], title = "threshold = $threshold", aspect = DataAspect())
    hexbin!(ax, x, y, binsize = 0.4, threshold = threshold)
end
f
```
\end{examplefigure}


### Changing the scale of the number of observations in a bin

You can pass a scale function to via the `scale` keyword, which will be applied to the bin counts before plotting.

\begin{examplefigure}{svg = true}
```julia
using CairoMakie
CairoMakie.activate!() # hide
Makie.inline!(true) # hide
using Random
Random.seed!(1234)

x = randn(100000)
y = randn(100000)

f = Figure()
hexbin(f[1, 1], x, y, bins = 40,
    axis = (aspect = DataAspect(), title = "scale = identity"))
hexbin(f[1, 2], x, y, bins = 40, scale=log10,
    axis = (aspect = DataAspect(), title = "scale = log10"))
f
```
\end{examplefigure}
