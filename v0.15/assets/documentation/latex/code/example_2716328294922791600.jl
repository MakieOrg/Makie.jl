# This file was generated, do not modify it. # hide
__result = begin # hide
  
using CairoMakie
CairoMakie.activate!() # hide

f = Figure(fontsize = 18)

Axis(f[1, 1], title = L"\frac{x + y}{\sin(k^2)}")
ax2 = Axis(f[1, 2])
ax2.title = L"\frac{x + y}{\sin(k^2)}"

f

  end # hide
  save(joinpath(@OUTPUT, "example_2716328294922791600.png"), __result) # hide
  save(joinpath(@OUTPUT, "example_2716328294922791600.svg"), __result) # hide
  nothing # hide