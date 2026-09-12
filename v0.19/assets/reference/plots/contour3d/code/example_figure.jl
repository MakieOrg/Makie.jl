# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str # hide
__result = begin # hide
    using CairoMakie
CairoMakie.activate!() # hide


f = Figure()
Axis3(f[1, 1], aspect=(0.5,0.5,1), perspectiveness=0.75)

xs = ys = LinRange(-0.5, 0.5, 100)
zs = [sqrt(x^2+y^2) for x in xs, y in ys]

contour3d!(-zs, levels=-(.025:0.05:.475), linewidth=2, color=:blue2)
contour3d!(+zs, levels=  .025:0.05:.475,  linewidth=2, color=:red2)

f
end # hide
save(joinpath(@OUTPUT, "example_13327946343266074808.png"), __result; ) # hide

nothing # hide