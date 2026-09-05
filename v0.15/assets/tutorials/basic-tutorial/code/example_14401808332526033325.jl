# This file was generated, do not modify it. # hide
__result = begin # hide
  

using CairoMakie

x = range(0, 10, length=100)
y1 = sin.(x)
y2 = cos.(x)

lines(x, y1)
lines!(x, y2)
current_figure()

  end # hide
  save(joinpath(@OUTPUT, "example_14401808332526033325.png"), __result) # hide
  save(joinpath(@OUTPUT, "example_14401808332526033325.svg"), __result) # hide
  nothing # hide