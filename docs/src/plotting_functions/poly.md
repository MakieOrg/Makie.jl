# poly

```@docs
poly
```

### Examples

```@example
using CairoMakie
CairoMakie.activate!() # hide
using AbstractPlotting.GeometryBasics
AbstractPlotting.inline!(true) # hide

f = Figure(resolution = (800, 600))
Axis(f[1, 1])

poly!(Point2f0[(0, 0), (2, 0), (3, 1), (1, 1)], color = :red, strokecolor = :black, strokewidth = 1)

f
save("example_poly_1.svg", f); nothing # hide
```

![example_poly_1](example_poly_1.svg)



```@example
using CairoMakie
CairoMakie.activate!() # hide
using AbstractPlotting.GeometryBasics
AbstractPlotting.inline!(true) # hide

f = Figure(resolution = (800, 600))
Axis(f[1, 1])

# polygon with hole
p = Polygon(
    Point2f0[(0, 0), (2, 0), (3, 1), (1, 1)],
    [Point2f0[(0.75, 0.25), (1.75, 0.25), (2.25, 0.75), (1.25, 0.75)]]
)

poly!(p, color = :blue)

f
save("example_poly_2_.svg", f); nothing # hide
```

![example_poly_2_](example_poly_2_.svg)

```@example
using CairoMakie
CairoMakie.activate!() # hide
using AbstractPlotting.GeometryBasics
AbstractPlotting.inline!(true) # hide

f = Figure(resolution = (800, 600))
Axis(f[1, 1])

# vector of shapes
poly!(
    [Rect(i, j, 0.75, 0.5) for i in 1:5 for j in 1:3],
    color = 1:15,
    colormap = :heat
)

f
save("example_poly_3.svg", f); nothing # hide
```

![example_poly_3](example_poly_3.svg)



```@example
using CairoMakie
CairoMakie.activate!() # hide
using AbstractPlotting.GeometryBasics
AbstractPlotting.inline!(true) # hide

f = Figure(resolution = (800, 600))
Axis(f[1, 1], aspect = DataAspect())

# shape decomposition
poly!(Circle(Point2f0(0, 0), 15f0), color = :pink)

f
save("example_poly_4.svg", f); nothing # hide
```

![example_poly_4](example_poly_4.svg)

```@example
using CairoMakie
CairoMakie.activate!() # hide
using AbstractPlotting.GeometryBasics
AbstractPlotting.inline!(true) # hide

f = Figure(resolution = (800, 600))
Axis(f[1, 1])

# vector of polygons
ps = [Polygon(rand(Point2f0, 3) .+ Point2f0(i, j))
    for i in 1:5 for j in 1:10]

poly!(ps, color = rand(RGBf0, length(ps)),
    axis = (backgroundcolor = :gray15,))

f
save("example_poly_5.svg", f); nothing # hide
```

![example_poly_5](example_poly_5.svg)
