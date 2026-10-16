# This file was generated, do not modify it. # hide
__result = begin # hide
  

using CairoMakie

x = range(0, 10, length=100)
y1 = sin.(x)
y2 = cos.(x)

scatter(x, y1, color = :red, markersize = 5)
sc = scatter!(x, y2, color = :blue, markersize = 10)
sc.color = :green
sc.markersize = 20
current_figure()

  end # hide
  save(joinpath(@OUTPUT, "example_17613010744264748378.png"), __result) # hide
  save(joinpath(@OUTPUT, "example_17613010744264748378.svg"), __result) # hide
  nothing # hide