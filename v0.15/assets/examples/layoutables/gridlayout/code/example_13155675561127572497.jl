# This file was generated, do not modify it. # hide
__result = begin # hide
  
using CairoMakie

f = Figure()

ax1 = Axis(f[1, 1], title = "Axis 1")
ax2 = Axis(f[1, 2], title = "Axis 2")

f

  end # hide
  save(joinpath(@OUTPUT, "example_13155675561127572497.png"), __result) # hide
  
  nothing # hide