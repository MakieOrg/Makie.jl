# This file was generated, do not modify it. # hide
__result = begin # hide
  

using CairoMakie

fig = Figure()
ax = Axis(fig[1, 1])
hm = heatmap!(ax, randn(20, 20))
Colorbar(fig[1, 2], hm)
fig

  end # hide
  save(joinpath(@OUTPUT, "example_6225888241151240853.png"), __result) # hide
  save(joinpath(@OUTPUT, "example_6225888241151240853.svg"), __result) # hide
  nothing # hide