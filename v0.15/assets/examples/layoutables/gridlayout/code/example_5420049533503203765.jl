# This file was generated, do not modify it. # hide
__result = begin # hide
  
using CairoMakie

f = Figure()

Axis(f[1, 1:2], title = "[1, 1:2]")
Axis(f[2:4, 1:2], title = "[2:4, 1:2]")
Axis(f[:, 3], title = "[:, 3]")
Axis(f[1:3, 4], title = "[1:3, 4]")
Axis(f[end, end], title = "[end, end]")

f

  end # hide
  save(joinpath(@OUTPUT, "example_5420049533503203765.png"), __result) # hide
  
  nothing # hide