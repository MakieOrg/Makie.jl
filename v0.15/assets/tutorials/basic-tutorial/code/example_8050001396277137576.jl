# This file was generated, do not modify it. # hide
__result = begin # hide
  

using CairoMakie

fig, ax, hm = heatmap(randn(20, 20))
Colorbar(fig[1, 2], hm)
fig

  end # hide
  save(joinpath(@OUTPUT, "example_8050001396277137576.png"), __result) # hide
  save(joinpath(@OUTPUT, "example_8050001396277137576.svg"), __result) # hide
  nothing # hide