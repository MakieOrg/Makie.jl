# This file was generated, do not modify it. # hide
__result = begin # hide
  
using CairoMakie
CairoMakie.activate!() # hide
Makie.inline!(true) # hide

scene, layout = layoutscene()
ax = layout[1, 1] = Axis(scene)
scene

  end # hide
  save(joinpath(@OUTPUT, "example_11104805234404999596.png"), __result) # hide
  
  nothing # hide