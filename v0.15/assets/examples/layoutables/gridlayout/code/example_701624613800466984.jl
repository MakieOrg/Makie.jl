# This file was generated, do not modify it. # hide
__result = begin # hide
  
using CairoMakie

fig = Figure()

axs = [Axis(fig[i, j]) for i in 1:3, j in 1:3]
axs[1, 1].title = "Group A"
axs[1, 2].title = "Group B.1"
axs[1, 3].title = "Group B.2"

hidedecorations!.(axs, grid=false)

colgap!(fig.layout, 1, Relative(0.15))

fig

  end # hide
  save(joinpath(@OUTPUT, "example_701624613800466984.png"), __result) # hide
  
  nothing # hide