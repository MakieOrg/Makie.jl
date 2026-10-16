# This file was generated, do not modify it. # hide
__result = begin # hide
  
using CairoMakie
using ColorSchemes

fig = Figure()

rects = fig[1:4, 1:6] = [
    Box(fig, color = c)
    for c in get.(Ref(ColorSchemes.rainbow), (0:23) ./ 23)]

fig

  end # hide
  save(joinpath(@OUTPUT, "example_6619029372363114125.png"), __result) # hide
  
  nothing # hide