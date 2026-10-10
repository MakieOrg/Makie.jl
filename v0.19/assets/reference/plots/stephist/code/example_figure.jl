# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str # hide
__result = begin # hide
    using GLMakie
GLMakie.activate!() # hide


data = randn(1000)

f = Figure()
stephist(f[1, 1], data, bins = 10)
stephist(f[1, 2], data, bins = 20, color = :red, strokewidth = 1, strokecolor = :black)
stephist(f[2, 1], data, bins = [-5, -2, -1, 0, 1, 2, 5], color = :gray)
stephist(f[2, 2], data, normalization = :pdf)
f
end # hide
save(joinpath(@OUTPUT, "example_14681731706312590112.png"), __result; ) # hide

nothing # hide