# density

```@docs
density
```

### Examples

```@example
using CairoMakie
CairoMakie.activate!() # hide
AbstractPlotting.inline!(true) # hide

f = Figure(resolution = (800, 600))
Axis(f[1, 1])

density!(randn(200))

f
save("example_density_1.svg", f); nothing # hide
```

![example_density_1](example_density_1.svg)




```@example
using CairoMakie
CairoMakie.activate!() # hide
AbstractPlotting.inline!(true) # hide

f = Figure(resolution = (800, 600))
Axis(f[1, 1])

density!(randn(200), direction = :y, npoints = 10)

f
save("example_density_2_.svg", f); nothing # hide
```

![example_density_2_](example_density_2_.svg)




```@example
using CairoMakie
CairoMakie.activate!() # hide
AbstractPlotting.inline!(true) # hide

f = Figure(resolution = (800, 600))
Axis(f[1, 1])

density!(randn(200), color = (:red, 0.3),
    strokecolor = :red, strokewidth = 3, strokearound = true)

f
save("example_density_3.svg", f); nothing # hide
```

![example_density_3](example_density_3.svg)




```@example
using CairoMakie
CairoMakie.activate!() # hide
AbstractPlotting.inline!(true) # hide

f = Figure(resolution = (800, 600))
Axis(f[1, 1])

vectors = [randn(1000) .+ i/2 for i in 0:5]

for (i, vector) in enumerate(vectors)
    density!(vector, offset = -i/4, color = (:slategray, 0.4),
        bandwidth = 0.1)
end

f
save("example_density_4_.svg", f); nothing # hide
```

![example_density_4_](example_density_4_.svg)

