# This file was generated, do not modify it. # hide
__result = begin # hide
  
using CairoMakie

f = Figure()

Axis(f[1, 1], title = "I'm square and aligned")
Box(f[1, 2], color = (:blue, 0.1), strokecolor = :transparent)
Axis(f[1, 2], aspect = AxisAspect(1),
    title = "I'm square but break the layout.\nMy actual cell is the blue rect.")
Axis(f[2, 1])
Axis(f[2, 2])

rowsize!(f.layout, 2, Relative(2/3))
colsize!(f.layout, 1, Aspect(1, 1))

f

  end # hide
  save(joinpath(@OUTPUT, "example_17530907837569725910.png"), __result) # hide
  
  nothing # hide