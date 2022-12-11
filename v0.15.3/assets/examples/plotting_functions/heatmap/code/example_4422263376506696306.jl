# This file was generated, do not modify it. # hide
__result = begin # hide
  
using CairoMakie
CairoMakie.activate!() # hide
Makie.inline!(true) # hide


xs = range(0, 10, length = 25)
ys = range(0, 15, length = 25)
zs = [cos(x) * sin(y) for x in xs, y in ys]

heatmap(xs, ys, zs)

  end # hide
  save(joinpath(@OUTPUT, "example_4422263376506696306.png"), __result) # hide
  
  nothing # hide