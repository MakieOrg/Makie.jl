# This file was generated, do not modify it. # hide
__result = begin # hide
  
using CairoMakie
CairoMakie.activate!() # hide
Makie.inline!(true) # hide

xs = LinRange(0, 10, 100)
ys = LinRange(0, 10, 100)
zs = [cos(x) * sin(y) for x in xs, y in ys]

f = Figure()
Axis(f[1, 1])

co = contourf!(xs, ys, zs, levels = 10)

Colorbar(f[1, 2], co)

f

  end # hide
  save(joinpath(@OUTPUT, "example_12354956969698130536.png"), __result) # hide
  
  nothing # hide