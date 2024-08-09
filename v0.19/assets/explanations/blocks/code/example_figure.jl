# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str # hide
__result = begin # hide
    using CairoMakie
CairoMakie.activate!() # hide


f = Figure()
Axis(f, bbox = BBox(100, 300, 100, 500), title = "Axis 1")
Axis(f, bbox = BBox(400, 700, 200, 400), title = "Axis 2")
f
end # hide
save(joinpath(@OUTPUT, "example_237270886359832607.png"), __result; ) # hide

nothing # hide