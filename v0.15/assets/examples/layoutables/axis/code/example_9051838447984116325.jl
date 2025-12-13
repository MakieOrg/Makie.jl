# This file was generated, do not modify it. # hide
__result = begin # hide
  
using CairoMakie
CairoMakie.activate!() # hide
Makie.inline!(true) # hide

f = Figure()

lines(f[1, 1], 0..10, sin)
lines(f[1, 2], 0..10, sin, axis = (limits = (0, 10, -1, 1),))

f

  end # hide
  save(joinpath(@OUTPUT, "example_9051838447984116325.png"), __result) # hide
  save(joinpath(@OUTPUT, "example_9051838447984116325.svg"), __result) # hide
  nothing # hide