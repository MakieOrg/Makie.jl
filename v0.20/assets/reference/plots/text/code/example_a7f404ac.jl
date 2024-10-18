# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    using CairoMakie
CairoMakie.activate!() # hide


f = Figure()

horsepower = [52, 78, 80, 112, 140]
cars = ["Kia", "Mini", "Honda", "Mercedes", "Ferrari"]

ax = Axis(f[1, 1], xlabel = "horse power")
tightlimits!(ax, Left())
hideydecorations!(ax)

barplot!(horsepower, direction = :x)
text!(Point.(horsepower, 1:5), text = cars, align = (:right, :center),
    offset = (-20, 0), color = :white)

f
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_a7f404ac_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_a7f404ac.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
save(joinpath(@OUTPUT, "example_a7f404ac.svg"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
nothing # hide