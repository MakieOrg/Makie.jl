# This file was generated, do not modify it. # hide
__result = begin # hide
  
using CairoMakie

f = Figure()

ax = Axis(f[1, 1])

sc1 = scatter!(randn(10, 2), color = :red, label = "Red Dots")
sc2 = scatter!(randn(10, 2), color = :blue, label = "Blue Dots")
scatter!(randn(10, 2), color = :orange, label = "Orange Dots")
scatter!(randn(10, 2), color = :cyan, label = "Cyan Dots")

axislegend()

axislegend("Titled Legend", position = :lb)

axislegend(ax, [sc1, sc2], ["One", "Two"], "Selected Dots", position = :rb,
    orientation = :horizontal)

f

  end # hide
  save(joinpath(@OUTPUT, "example_8079969162601109406.png"), __result) # hide
  save(joinpath(@OUTPUT, "example_8079969162601109406.svg"), __result) # hide
  nothing # hide