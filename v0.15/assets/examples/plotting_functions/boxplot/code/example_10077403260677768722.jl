# This file was generated, do not modify it. # hide
__result = begin # hide
  
using CairoMakie
CairoMakie.activate!() # hide
Makie.inline!(true) # hide

xs = rand(1:3, 1000)
ys = randn(1000)
dodge = rand(1:2, 1000)

boxplot(xs, ys, dodge = dodge, show_notch = true, color = dodge)

  end # hide
  save(joinpath(@OUTPUT, "example_10077403260677768722.png"), __result) # hide
  
  nothing # hide