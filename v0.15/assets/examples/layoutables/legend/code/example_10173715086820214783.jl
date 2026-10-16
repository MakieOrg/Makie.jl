# This file was generated, do not modify it. # hide
__result = begin # hide
  
using CairoMakie

f = Figure()

Axis(f[1, 1])

xs = 0:0.5:10
ys = sin.(xs)
lin = lines!(xs, ys, color = :blue)
sca = scatter!(xs, ys, color = :red, markersize = 15)

Legend(f[1, 2], [lin, sca, lin], ["a line", "some dots", "line again"])

Legend(f[2, 1], [lin, sca, lin], ["a line", "some dots", "line again"],
    orientation = :horizontal, tellwidth = false, tellheight = true)

f

  end # hide
  save(joinpath(@OUTPUT, "example_10173715086820214783.png"), __result) # hide
  save(joinpath(@OUTPUT, "example_10173715086820214783.svg"), __result) # hide
  nothing # hide