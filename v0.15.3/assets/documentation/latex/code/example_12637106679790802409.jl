# This file was generated, do not modify it. # hide
__result = begin # hide
  
using CairoMakie
CairoMakie.activate!() # hide

f = Figure(fontsize = 18)

Axis(f[1, 1],
    title = L"\frac{x + y}{\sin(k^2)}",
    xlabel = L"\sum_a^b{xy}",
    ylabel = L"\sqrt{\frac{a}{b}}"
)

f

  end # hide
  save(joinpath(@OUTPUT, "example_12637106679790802409.png"), __result) # hide
  save(joinpath(@OUTPUT, "example_12637106679790802409.svg"), __result) # hide
  nothing # hide