# This file was generated, do not modify it. # hide
__result = begin # hide
  
using CairoMakie

f = Figure()

ax = Axis(f[1, 1], xlabel = "x label", ylabel = "y label",
    title = "Title")

f

  end # hide
  save(joinpath(@OUTPUT, "example_3360942468698197528.png"), __result) # hide
  save(joinpath(@OUTPUT, "example_3360942468698197528.svg"), __result) # hide
  nothing # hide