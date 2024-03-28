# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    using CairoMakie, GeometryBasics
CairoMakie.activate!() # hide


p_big = decompose(Point2f, Circle(Point2f(0), 1))
p_small = decompose(Point2f, Circle(Point2f(0), 0.5))
scatter(1:4, fill(0, 4), marker=Polygon(p_big, [p_small]), markersize=100, color=1:4, axis=(limits=(0, 5, -1, 1),))
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_fb28de25_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_fb28de25.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
save(joinpath(@OUTPUT, "example_fb28de25.svg"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
nothing # hide