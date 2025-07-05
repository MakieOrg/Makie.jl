# This file was generated, do not modify it. # hide
__result = begin # hide
  
using CairoMakie
CairoMakie.activate!() # hide
Makie.inline!(true) # hide

f = Figure()

ax1 = Axis(f[1, 1], title = "Axis 1")
ax2 = Axis(f[1, 2], title = "Axis 2")

hidespines!(ax1)
hidespines!(ax2, :t, :r) # only top and right

f

  end # hide
  save(joinpath(@OUTPUT, "example_5057962070469521878.png"), __result) # hide
  save(joinpath(@OUTPUT, "example_5057962070469521878.svg"), __result) # hide
  nothing # hide