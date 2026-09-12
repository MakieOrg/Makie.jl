# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    using CairoMakie
using DelaunayTriangulation
CairoMakie.activate!() # hide

using Random
Random.seed!(1234)

angles = range(0, 2pi, length = 251)[1:end-1]
x = cos.(angles)
y = sin.(angles)
points = tuple.(x, y)
tri = triangulate(points)
refine!(tri; max_area = 0.001)
vorn = voronoi(tri, clip = true)
smooth_vorn = centroidal_smooth(vorn)
f, ax, tr = voronoiplot(smooth_vorn, show_generators=false)
f
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_8098c066_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_8098c066.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
save(joinpath(@OUTPUT, "example_8098c066.svg"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
nothing # hide