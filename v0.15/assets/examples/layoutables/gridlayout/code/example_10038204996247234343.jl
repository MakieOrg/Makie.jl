# This file was generated, do not modify it. # hide
__result = begin # hide
  
using CairoMakie

f = Figure()

Axis(f[1, 1], title = "My column infers my width\nof 200 units")
Axis(f[1, 2], title = "My column gets 1/3rd\nof the remaining space")
Axis(f[1, 3], title = "My column gets 2/3rds\nof the remaining space")

colsize!(f.layout, 2, Auto(1)) # equivalent to Auto(true, 1)
colsize!(f.layout, 3, Auto(2)) # equivalent to Auto(true, 2)

f

  end # hide
  save(joinpath(@OUTPUT, "example_10038204996247234343.png"), __result) # hide
  
  nothing # hide