# This file was generated, do not modify it. # hide
__result = begin # hide
  
using CairoMakie

f = Figure(resolution = (800, 800))

Axis(f[1, 1], title = "No grid layout")
Axis(f[2, 1], title = "No grid layout")
Axis(f[3, 1], title = "No grid layout")

Axis(f[1, 2], title = "Inside", alignmode = Inside())
Axis(f[2, 2], title = "Outside", alignmode = Outside())
Axis(f[3, 2], title = "Outside(50)", alignmode = Outside(50))

[Box(f[i, 2], color = :transparent, strokecolor = :red) for i in 1:3]

f

  end # hide
  save(joinpath(@OUTPUT, "example_14920892378540243727.png"), __result) # hide
  
  nothing # hide