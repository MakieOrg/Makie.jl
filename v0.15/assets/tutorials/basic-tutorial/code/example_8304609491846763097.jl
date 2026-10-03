# This file was generated, do not modify it. # hide
__result = begin # hide
  

using CairoMakie

x = range(0, 10, length=100)
y = sin.(x)
scatter(x, y)

  end # hide
  save(joinpath(@OUTPUT, "example_8304609491846763097.png"), __result) # hide
  save(joinpath(@OUTPUT, "example_8304609491846763097.svg"), __result) # hide
  nothing # hide