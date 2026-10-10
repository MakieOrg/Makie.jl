# This file was generated, do not modify it. # hide
__result = begin # hide
  
using CairoMakie

fig = Figure()

fig[1:2, 1:3] = [Axis(fig) for _ in 1:6]

supertitle = Label(fig[0, :], "Six plots", textsize = 30)

sideinfo = Label(fig[2:3, 0], "This text is vertical", rotation = pi/2)

fig

  end # hide
  save(joinpath(@OUTPUT, "example_2248901998374657593.png"), __result) # hide
  
  nothing # hide