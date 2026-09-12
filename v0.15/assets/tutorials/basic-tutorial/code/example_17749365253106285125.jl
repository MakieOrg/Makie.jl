# This file was generated, do not modify it. # hide
__result = begin # hide
  

lines!(ax1, 0..10, sin)
lines!(ax2, 0..10, cos)
lines!(ax3, 0..10, sqrt)
fig

  end # hide
  save(joinpath(@OUTPUT, "example_17749365253106285125.png"), __result) # hide
  save(joinpath(@OUTPUT, "example_17749365253106285125.svg"), __result) # hide
  nothing # hide