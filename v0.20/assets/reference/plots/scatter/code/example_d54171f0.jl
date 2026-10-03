# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    using CairoMakie
CairoMakie.activate!() # hide


f = Figure()
ax = Axis(f[1, 1])
limits!(ax, -10, 10, -10, 10)

scatter!(ax, Point2f(0, 0), markersize = 20, markerspace = :data,
    marker = '✈', label = "markerspace = :data")
scatter!(ax, Point2f(0, 0), markersize = 20, markerspace = :pixel,
    marker = '✈', label = "markerspace = :pixel")

axislegend(ax)

f
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_d54171f0_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_d54171f0.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
save(joinpath(@OUTPUT, "example_d54171f0.svg"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
nothing # hide