# This file was generated, do not modify it. # hide
__result = begin # hide
  
using CairoMakie
CairoMakie.activate!() # hide
Makie.inline!(true) # hide

lines(0..20, sin, axis = (xticks = MultiplesTicks(4, pi, "π"),))

  end # hide
  save(joinpath(@OUTPUT, "example_11338119643795288532.png"), __result) # hide
  save(joinpath(@OUTPUT, "example_11338119643795288532.svg"), __result) # hide
  nothing # hide