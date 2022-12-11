# This file was generated, do not modify it. # hide
__result = begin # hide
  
using CairoMakie
CairoMakie.activate!() # hide
Makie.inline!(true) # hide

xs = rand(1:3, 1000)
ys = randn(1000)

violin(xs, ys)

  end # hide
  save(joinpath(@OUTPUT, "example_3496663565570473096.png"), __result) # hide
  
  nothing # hide