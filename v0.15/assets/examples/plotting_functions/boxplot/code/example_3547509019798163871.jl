# This file was generated, do not modify it. # hide
__result = begin # hide
  
using CairoMakie
CairoMakie.activate!() # hide
Makie.inline!(true) # hide

xs = rand(1:3, 1000)
ys = randn(1000)

boxplot(xs, ys)

  end # hide
  save(joinpath(@OUTPUT, "example_3547509019798163871.png"), __result) # hide
  
  nothing # hide