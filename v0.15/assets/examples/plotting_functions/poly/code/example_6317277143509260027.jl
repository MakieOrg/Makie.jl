# This file was generated, do not modify it. # hide
__result = begin # hide
  
using CairoMakie
CairoMakie.activate!() # hide
using Makie.GeometryBasics
Makie.inline!(true) # hide

f = Figure()
Axis(f[1, 1])

# polygon with hole
p = Polygon(
    Point2f[(0, 0), (2, 0), (3, 1), (1, 1)],
    [Point2f[(0.75, 0.25), (1.75, 0.25), (2.25, 0.75), (1.25, 0.75)]]
)

poly!(p, color = :blue)

f

  end # hide
  save(joinpath(@OUTPUT, "example_6317277143509260027.png"), __result) # hide
  
  nothing # hide