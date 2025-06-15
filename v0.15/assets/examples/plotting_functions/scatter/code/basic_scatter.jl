# This file was generated, do not modify it. # hide
__result = begin # hide
  
using CairoMakie
CairoMakie.activate!() # hide
Makie.inline!(true) # hide

f = Figure()
Axis(f[1, 1])

xs = LinRange(0, 10, 20)
ys = 0.5 .* sin.(xs)

scatter!(xs, ys, color = :red)
scatter!(xs, ys .- 1, color = xs)
scatter!(xs, ys .- 2, markersize = LinRange(5, 30, 20))
scatter!(xs, ys .- 3, marker = 'a':'t', strokewidth = 0, color = :black)

f

  end # hide
  save(joinpath(@OUTPUT, "basic_scatter.png"), __result) # hide
  save(joinpath(@OUTPUT, "basic_scatter.svg"), __result) # hide
  nothing # hide