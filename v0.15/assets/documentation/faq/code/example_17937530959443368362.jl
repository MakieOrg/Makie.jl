# This file was generated, do not modify it. # hide
__result = begin # hide
  
using CairoMakie
CairoMakie.activate!() # hide

f = Figure()

ax1 = Axis(f, title = "Squashed")
ax2 = Axis(f[1, 1], title = "Placed in Layout")
ax3 = Axis(f, bbox = BBox(200, 600, 100, 500),
  title = "Placed at BBox(200, 600, 100, 500)")

f

  end # hide
  save(joinpath(@OUTPUT, "example_17937530959443368362.png"), __result) # hide
  
  nothing # hide