# This file was generated, do not modify it. # hide
__result = begin # hide
  
using CairoMakie

f = Figure()

Axis(f[1, 1])

xs = 0:0.1:10
lins = [lines!(xs, sin.(xs .+ 3v), color = RGBf(v, 0, 1-v)) for v in 0:0.1:1]

Legend(f[1, 2], lins, string.(1:length(lins)), nbanks = 3)

f

  end # hide
  save(joinpath(@OUTPUT, "example_3688098932957289413.png"), __result) # hide
  save(joinpath(@OUTPUT, "example_3688098932957289413.svg"), __result) # hide
  nothing # hide