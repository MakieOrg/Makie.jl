# This file was generated, do not modify it. # hide
__result = begin # hide
  
using CairoMakie

f = Figure()

subgl_left = GridLayout()
subgl_left[1:2, 1:2] = [Axis(f) for i in 1:2, j in 1:2]

subgl_right = GridLayout()
subgl_right[1:3, 1] = [Axis(f) for i in 1:3]

f.layout[1, 1] = subgl_left
f.layout[1, 2] = subgl_right

f

  end # hide
  save(joinpath(@OUTPUT, "example_2813727490192073800.png"), __result) # hide
  
  nothing # hide