# This file was generated, do not modify it. # hide
__result = begin # hide
  

using CairoMakie

x = range(0, 10, length=100)
y1 = sin.(x)
y2 = cos.(x)

lines(x, y1, color = :red, label = "sin")
lines!(x, y2, color = :blue, label = "cos")
axislegend()
current_figure()

  end # hide
  save(joinpath(@OUTPUT, "example_2618343872335953557.png"), __result) # hide
  save(joinpath(@OUTPUT, "example_2618343872335953557.svg"), __result) # hide
  nothing # hide