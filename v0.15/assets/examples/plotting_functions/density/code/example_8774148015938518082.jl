# This file was generated, do not modify it. # hide
__result = begin # hide
  
using CairoMakie
CairoMakie.activate!() # hide
Makie.inline!(true) # hide

f = Figure()
Axis(f[1, 1])

density!(randn(200), direction = :y, npoints = 10)

f

  end # hide
  save(joinpath(@OUTPUT, "example_8774148015938518082.png"), __result) # hide
  
  nothing # hide