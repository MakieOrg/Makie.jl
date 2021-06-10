# boxplot

```@docs
boxplot
```

### Examples

```@example
using CairoMakie
CairoMakie.activate!() # hide
Makie.inline!(true) # hide

xs = rand(1:3, 1000)
ys = randn(1000)

boxplot(xs, ys)
```

```@example
using CairoMakie
CairoMakie.activate!() # hide
Makie.inline!(true) # hide

xs = rand(1:3, 1000)
ys = randn(1000)
dodge = rand(1:2, 1000)

boxplot(xs, ys, dodge = dodge, show_notch = true, color = dodge)
```

Colors are customizable. The `color` attribute refers to the color of the boxes, whereas
`outliercolor` refers to the color of the outliers. If not scalars (e.g. `:red`), these attributes
must have the length of the data. If `outliercolor` is not provided, outliers will have the
same color as their box, as shown above.

!!! note
    For all indices corresponding to points within the same box, `color` (but not `outliercolor`)
    must have the same value.

```@example
using CairoMakie
CairoMakie.activate!() # hide
Makie.inline!(true) # hide

xs = rand(1:3, 1000)
ys = randn(1000)
dodge = rand(1:2, 1000)

boxplot(xs, ys, dodge = dodge, show_notch = true, color = map(d->d==1 ? :blue : :red, dodge) , outliercolor = rand([:red, :green, :blue, :black, :yellow], 1000))
```
