# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    using CairoMakie
CairoMakie.activate!() # hide


points = [Point2f(x, y) for y in 1:10 for x in 1:10]
rotations = range(0, 2pi, length = length(points))

scatter(points, rotation = rotations, markersize = 20, marker = '↑')
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_09d88690_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_09d88690.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
save(joinpath(@OUTPUT, "example_09d88690.svg"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
nothing # hide