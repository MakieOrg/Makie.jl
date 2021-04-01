# hist

```@docs
hist
```

### Examples

```julia
using GLMakie
GLMakie.activate!() # hide
AbstractPlotting.inline!(true) # hide

data = randn(1000)

f = Figure()
hist(f[1, 1], data, bins = 10)
hist(f[1, 2], data, bins = 20, color = :red, strokewidth = 1, strokecolor = :black)
hist(f[2, 1], data, bins = [-5, -2, -1, 0, 1, 2, 5], color = :gray) 
hist(f[2, 2], data, normalization = :pdf)
f
```

