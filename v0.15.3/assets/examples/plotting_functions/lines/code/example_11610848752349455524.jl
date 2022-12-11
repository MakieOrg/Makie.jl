# This file was generated, do not modify it. # hide
__result = begin # hide
  
using CairoMakie
CairoMakie.activate!() # hide
Makie.inline!(true) # hide

f = Figure()
Axis(f[1, 1])

xs = 0:0.01:10
ys = 0.5 .* sin.(xs)

lines!(xs, ys)
lines!(xs, ys .- 1, linewidth = 5)
lines!(xs, ys .- 2, linewidth = 5, color = ys)
lines!(xs, ys .- 3, linestyle = :dash)

f

  end # hide
  save(joinpath(@OUTPUT, "example_11610848752349455524.png"), __result) # hide
  save(joinpath(@OUTPUT, "example_11610848752349455524.svg"), __result) # hide
  nothing # hide