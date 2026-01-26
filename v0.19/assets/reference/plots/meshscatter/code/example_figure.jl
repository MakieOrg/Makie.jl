# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str # hide
__result = begin # hide
    using GLMakie
GLMakie.activate!() # hide


xs = cos.(1:0.5:20)
ys = sin.(1:0.5:20)
zs = LinRange(0, 3, length(xs))

meshscatter(xs, ys, zs, markersize = 0.1, color = zs)
end # hide
save(joinpath(@OUTPUT, "example_7900654464093817663.png"), __result; ) # hide

nothing # hide