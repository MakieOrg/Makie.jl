# This file was generated, do not modify it. # hide
__result = begin # hide
  
using CairoMakie
CairoMakie.activate!() # hide

f = Figure(fontsize = 18)

Axis(f[1,1], title=L"Some text and some math: $\frac{2\alpha+1}{y}$")

f

  end # hide
  save(joinpath(@OUTPUT, "example_9460569774413783119.png"), __result) # hide
  save(joinpath(@OUTPUT, "example_9460569774413783119.svg"), __result) # hide
  nothing # hide