# This file was generated, do not modify it. # hide
__result = begin # hide
  

using CairoMakie

fig = Figure()
ax1, l1 = lines(fig[1, 1], 0..10, sin, color = :red)
ax2, l2 = lines(fig[2, 1], 0..10, cos, color = :blue)
Legend(fig[1:2, 2], [l1, l2], ["sin", "cos"])
fig

  end # hide
  save(joinpath(@OUTPUT, "example_16508636194737698766.png"), __result) # hide
  save(joinpath(@OUTPUT, "example_16508636194737698766.svg"), __result) # hide
  nothing # hide