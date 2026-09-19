# This file was generated, do not modify it. # hide
__result = begin # hide
  
using CairoMakie
CairoMakie.activate!() # hide

fig, ax, pl = scatter(1:4)
abline!(ax, 0, 1)
abline!(ax, 0, 1.5, color = :red, linestyle=:dash, linewidth=2)
fig

  end # hide
  save(joinpath(@OUTPUT, "example_6054295508804353665.png"), __result) # hide
  
  nothing # hide