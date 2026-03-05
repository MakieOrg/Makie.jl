# This file was generated, do not modify it. # hide
__result = begin # hide
  
using CairoMakie
CairoMakie.activate!() # hide
Makie.inline!(true) # hide


using Makie.KernelDensity

k = kde([randn() + rand([0, 5]) for i in 1:10000, j in 1:2])

f = Figure(resolution = (800, 500))

Axis(f[1, 1], title = "Relative mode, drop lowest 10%")
contourf!(k, levels = 0.1:0.1:1, mode = :relative)

Axis(f[1, 2], title = "Normal mode")
contourf!(k, levels = 10)

f

  end # hide
  save(joinpath(@OUTPUT, "example_10462394763136043265.png"), __result) # hide
  
  nothing # hide