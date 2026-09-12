# This file was generated, do not modify it. # hide
__result = begin # hide
  
using CairoMakie
CairoMakie.activate!() # hide
Makie.inline!(true) # hide

f = Figure()
Axis(f[1, 1])

xs = LinRange(0, 4pi, 30)

stem!(xs, sin.(xs))

f

  end # hide
  save(joinpath(@OUTPUT, "example_960554178538446865.png"), __result) # hide
  
  nothing # hide