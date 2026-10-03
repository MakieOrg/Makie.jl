# This file was generated, do not modify it. # hide
__result = begin # hide
  

using CairoMakie

x = range(0, 10, length=100)
y1 = sin.(x)
y2 = cos.(x)

scatter(x, y1, color = :red, markersize = 5)
scatter!(x, y2, color = :blue, markersize = 10)
current_figure()

  end # hide
  save(joinpath(@OUTPUT, "example_14348472925365601418.png"), __result) # hide
  save(joinpath(@OUTPUT, "example_14348472925365601418.svg"), __result) # hide
  nothing # hide