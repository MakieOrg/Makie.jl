# This file was generated, do not modify it. # hide
__result = begin # hide
  
using CairoMakie
CairoMakie.activate!() # hide

f = Figure()

f[1, 1] = Axis(f, title = "I'm not nested")
f[1, 2][1, 1] = Axis(f, title = "I'm nested")

# plotting into nested positions also works
heatmap(f[1, 2][2, 1], randn(20, 20))

f

  end # hide
  save(joinpath(@OUTPUT, "example_6569738076986683452.png"), __result) # hide
  
  nothing # hide