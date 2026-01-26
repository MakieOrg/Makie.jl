# This file was generated, do not modify it. # hide
__result = begin # hide
  
using CairoMakie
CairoMakie.activate!() # hide

fig = Figure()
ax = Axis(fig[1, 1])
for i in 1:5
     hist!(ax, randn(1000), scale_to=-0.6, offset=i, direction=:x)
end
fig

  end # hide
  save(joinpath(@OUTPUT, "example_7412694190589125397.png"), __result) # hide
  
  nothing # hide