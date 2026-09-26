# This file was generated, do not modify it. # hide
__result = begin # hide
  
using CairoMakie
CairoMakie.activate!() # hide
Makie.inline!(true) # hide

lines(1..10, sin, axis = (
    yminorgridvisible = true,
    yminorticksvisible = true,
    yminorticks = -0.9:0.1:0.9,
    yticks = [-1, 1],
))

  end # hide
  save(joinpath(@OUTPUT, "example_15480791407088292735.png"), __result) # hide
  save(joinpath(@OUTPUT, "example_15480791407088292735.svg"), __result) # hide
  nothing # hide