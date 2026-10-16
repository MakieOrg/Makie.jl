# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    using CairoMakie
using DelaunayTriangulation
CairoMakie.activate!() # hide 

using Random
Random.seed!(1234)

θ = [LinRange(0, 2π * (1 - 1/19), 20); 0]
xy = Vector{Vector{Vector{NTuple{2,Float64}}}}()
cx = [0.0, 3.0]
for i in 1:2
    push!(xy, [[(cx[i] + cos(θ), sin(θ)) for θ in θ]])
    push!(xy, [[(cx[i] + 0.5cos(θ), 0.5sin(θ)) for θ in reverse(θ)]])
end
boundary_nodes, points = convert_boundary_points_to_indices(xy)
tri = triangulate(points; boundary_nodes=boundary_nodes)
z = [(x - 3/2)^2 + y^2 for (x, y) in DelaunayTriangulation.each_point(tri)] # note that each_point preserves the index order

f, ax, tr = tricontourf(tri, z, colormap = :matter)
f
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_1e653572_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_1e653572.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
save(joinpath(@OUTPUT, "example_1e653572.svg"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
nothing # hide