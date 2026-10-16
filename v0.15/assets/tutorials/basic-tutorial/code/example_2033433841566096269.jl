# This file was generated, do not modify it. # hide
__result = begin # hide
  

using CairoMakie

x = range(0, 10, length=100)
y = sin.(x)

colors = repeat([:crimson, :dodgerblue, :slateblue1, :sienna1, :orchid1], 20)

scatter(x, y, color = colors, markersize = 20)

  end # hide
  save(joinpath(@OUTPUT, "example_2033433841566096269.png"), __result) # hide
  save(joinpath(@OUTPUT, "example_2033433841566096269.svg"), __result) # hide
  nothing # hide