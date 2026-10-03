# This file was generated, do not modify it. # hide
__result = begin # hide
  

using CairoMakie

x = range(0, 10, length=100)
y1 = sin.(x)
y2 = cos.(x)

scatter(x, y1, color = :red, markersize = range(5, 15, length=100))
sc = scatter!(x, y2, color = range(0, 1, length=100), colormap = :thermal)

current_figure()

  end # hide
  save(joinpath(@OUTPUT, "example_10357445111122165713.png"), __result) # hide
  save(joinpath(@OUTPUT, "example_10357445111122165713.svg"), __result) # hide
  nothing # hide