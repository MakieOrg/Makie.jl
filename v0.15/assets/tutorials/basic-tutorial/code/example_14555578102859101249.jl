# This file was generated, do not modify it. # hide
__result = begin # hide
  

using CairoMakie

x = LinRange(0, 10, 100)
y = sin.(x)

fig = Figure()
lines(fig[1, 1], x, y, color = :red)
lines(fig[1, 2], x, y, color = :blue)
lines(fig[2, 1:2], x, y, color = :green)

fig

  end # hide
  save(joinpath(@OUTPUT, "example_14555578102859101249.png"), __result) # hide
  save(joinpath(@OUTPUT, "example_14555578102859101249.svg"), __result) # hide
  nothing # hide