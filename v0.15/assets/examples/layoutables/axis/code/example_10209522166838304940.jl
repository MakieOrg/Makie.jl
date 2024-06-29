# This file was generated, do not modify it. # hide
__result = begin # hide
  
using CairoMakie
CairoMakie.activate!() # hide
Makie.inline!(true) # hide

f = Figure(resolution = (800, 700))

lines(f[1, 1], -100:0.1:100, axis = (
    yscale = Makie.pseudolog10,
    title = "Pseudolog scale",
    yticks = [-100, -10, -1, 0, 1, 10, 100]))

lines(f[2, 1], -100:0.1:100, axis = (
    yscale = Makie.Symlog10(10.0),
    title = "Symlog10 with linear scaling between -10 and 10",
    yticks = [-100, -10, 0, 10, 100]))

f

  end # hide
  save(joinpath(@OUTPUT, "example_10209522166838304940.png"), __result) # hide
  save(joinpath(@OUTPUT, "example_10209522166838304940.svg"), __result) # hide
  nothing # hide