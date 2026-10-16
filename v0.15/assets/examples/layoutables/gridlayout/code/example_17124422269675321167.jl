# This file was generated, do not modify it. # hide
__result = begin # hide
  
using CairoMakie

f = Figure()

Axis(f[1, 1], title = "My column has size Relative(2/3)")
Axis(f[1, 2], title = "My column has size Auto()")
Colorbar(f[1, 3])

colsize!(f.layout, 1, Relative(2/3))

f

  end # hide
  save(joinpath(@OUTPUT, "example_17124422269675321167.png"), __result) # hide
  
  nothing # hide