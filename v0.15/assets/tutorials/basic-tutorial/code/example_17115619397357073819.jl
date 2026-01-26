# This file was generated, do not modify it. # hide
__result = begin # hide
  

using CairoMakie

fig = Figure()
ax1 = Axis(fig[1, 1])
ax2 = Axis(fig[1, 2])
ax3 = Axis(fig[2, 1:2])
fig

  end # hide
  save(joinpath(@OUTPUT, "example_17115619397357073819.png"), __result) # hide
  save(joinpath(@OUTPUT, "example_17115619397357073819.svg"), __result) # hide
  nothing # hide