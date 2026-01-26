# This file was generated, do not modify it. # hide
__result = begin # hide
  
using CairoMakie
CairoMakie.activate!() # hide
Makie.inline!(true) # hide

fig = Figure()
for (i, n) in enumerate([2, 5, 9])
    lines(fig[i, 1], 0..20, sin, axis = (xticks = LinearTicks(n),))
end
fig

  end # hide
  save(joinpath(@OUTPUT, "example_2188070473603704267.png"), __result) # hide
  save(joinpath(@OUTPUT, "example_2188070473603704267.svg"), __result) # hide
  nothing # hide