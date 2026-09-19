# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str # hide
__result = begin # hide
    using CairoMakie
using DelimitedFiles
CairoMakie.activate!() # hide


volcano = readdlm(Makie.assetpath("volcano.csv"), ',', Float64)

f = Figure(resolution = (800, 400))

Axis(f[1, 1], title = "Relative mode, drop lowest 30%")
contourf!(volcano, levels = 0.3:0.1:1, mode = :relative)

Axis(f[1, 2], title = "Normal mode")
contourf!(volcano, levels = 10)

f
end # hide
save(joinpath(@OUTPUT, "example_17906142951531255981.png"), __result; ) # hide
save(joinpath(@OUTPUT, "example_17906142951531255981.svg"), __result; ) # hide
nothing # hide