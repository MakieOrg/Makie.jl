# This file was generated, do not modify it. # hide
__result = begin # hide
  

using CairoMakie

x = range(0, 10, length=100)
y1 = sin.(x)
y2 = cos.(x)

lines(x, y1, color = :red)
lines!(x, y2, color = :blue)
current_figure()

  end # hide
  save(joinpath(@OUTPUT, "example_16104267023422442261.png"), __result) # hide
  save(joinpath(@OUTPUT, "example_16104267023422442261.svg"), __result) # hide
  nothing # hide