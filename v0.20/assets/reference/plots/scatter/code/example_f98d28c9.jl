# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    using CairoMakie
CairoMakie.activate!() # hide


hexagon = Makie.Polygon([Point2f(cos(a), sin(a)) for a in range(1/6 * pi, 13/6 * pi, length = 7)])

points = Point2f[(0, 0), (sqrt(3), 0), (sqrt(3)/2, 1.5)]

scatter(points,
    marker = hexagon,
    markersize = 1,
    markerspace = :data,
    color = 1:3,
    axis = (; aspect = 1, limits = (-2, 4, -2, 4)))
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_f98d28c9_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_f98d28c9.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
save(joinpath(@OUTPUT, "example_f98d28c9.svg"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
nothing # hide