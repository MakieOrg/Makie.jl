# This file was generated, do not modify it. # hide
__result = begin # hide
  
using CairoMakie

f = Figure()

Axis(f[1, 1], title = "My column has size Fixed(400)")
Axis(f[1, 2], title = "My column has size Auto()")

colsize!(f.layout, 1, Fixed(400))
# colsize!(f.layout, 1, 400) would also work

f

  end # hide
  save(joinpath(@OUTPUT, "example_5222526469543594363.png"), __result) # hide
  
  nothing # hide