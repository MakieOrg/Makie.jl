# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    using CairoMakie
using DelaunayTriangulation
CairoMakie.activate!() # hide

using Random
Random.seed!(1234)

points = rand(2, 50)
tri = triangulate(points)
vorn = voronoi(tri)
f, ax, tr = voronoiplot(vorn)
f
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_7b16492a_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_7b16492a.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
save(joinpath(@OUTPUT, "example_7b16492a.svg"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
nothing # hide