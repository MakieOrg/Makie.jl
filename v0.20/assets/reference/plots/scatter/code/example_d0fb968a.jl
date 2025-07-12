# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    using CairoMakie
CairoMakie.activate!() # hide


xs = range(0, 10, length = 30)
ys = 0.5 .* sin.(xs)
points = Point2f.(xs, ys)

scatter(points, color = 1:30, markersize = range(5, 30, length = 30),
    colormap = :thermal)
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_d0fb968a_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_d0fb968a.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
save(joinpath(@OUTPUT, "example_d0fb968a.svg"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
nothing # hide