# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str # hide
__result = begin # hide
    using CairoMakie
CairoMakie.activate!() # hide


xs = [1, 1, 2, 2, 3, 3]
ys = rand(6)
ymins = ys .- 1
ymaxs = ys .+ 1
dodge = [1, 2, 1, 2, 1, 2]

crossbar(xs, ys, ymins, ymaxs, dodge = dodge, show_notch = true)
end # hide
save(joinpath(@OUTPUT, "example_12782073539260587544.png"), __result; ) # hide

nothing # hide