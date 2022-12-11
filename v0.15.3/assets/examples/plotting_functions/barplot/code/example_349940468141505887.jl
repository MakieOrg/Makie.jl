# This file was generated, do not modify it. # hide
__result = begin # hide
  
using CairoMakie
CairoMakie.activate!() # hide
Makie.inline!(true) # hide

xs = 1:0.2:10
ys = 0.5 .* sin.(xs)

barplot(xs, ys, width = step(xs), color = :gray85, strokecolor = :black, strokewidth = 1)

  end # hide
  save(joinpath(@OUTPUT, "example_349940468141505887.png"), __result) # hide
  
  nothing # hide