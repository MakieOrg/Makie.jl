# This file was generated, do not modify it. # hide
__result = begin # hide
  
using GLMakie
using CairoMakie # hide
CairoMakie.activate!() # hide

f = Figure()
Textbox(f[1, 1], placeholder = "Enter a string...")
Textbox(f[2, 1], width = 300)

f

  end # hide
  save(joinpath(@OUTPUT, "example_18092993162462081559.png"), __result) # hide
  
  nothing # hide