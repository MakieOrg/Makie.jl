# This file was generated, do not modify it. # hide
__result = begin # hide
  
using CairoMakie
CairoMakie.activate!() # hide
Makie.inline!(true) # hide

f = Figure()
ax = Axis(f[1, 1])
f

  end # hide
  save(joinpath(@OUTPUT, "example_14570449147267962022.png"), __result) # hide
  
  nothing # hide