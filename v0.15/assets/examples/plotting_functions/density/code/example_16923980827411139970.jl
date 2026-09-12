# This file was generated, do not modify it. # hide
__result = begin # hide
  
using CairoMakie
CairoMakie.activate!() # hide
Makie.inline!(true) # hide

f = Figure()
Axis(f[1, 1])

density!(randn(200))

f

  end # hide
  save(joinpath(@OUTPUT, "example_16923980827411139970.png"), __result) # hide
  
  nothing # hide