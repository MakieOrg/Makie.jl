# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    using CairoMakie
using DelaunayTriangulation
CairoMakie.activate!() # hide
using Random

Random.seed!(123)

n = 20
angles = range(0, 2pi, length = n+1)[1:end-1]
x = [cos.(angles); 2 .* cos.(angles .+ pi/n)]
y = [sin.(angles); 2 .* sin.(angles .+ pi/n)]
z = (x .- 0.5).^2 + (y .- 0.5).^2 .+ 0.5.*randn.()

inner = [n:-1:1; n] # clockwise inner 
outer = [(n+1):(2n); n+1] # counter-clockwise outer
boundary_nodes = [[outer], [inner]]
points = [x'; y']
tri = triangulate(points; boundary_nodes = boundary_nodes)
f, ax, _ = tricontourf(tri, z;
    axis = (; aspect = 1, title = "Constrained triangulation\nvia DelaunayTriangulation.jl"))
scatter!(x, y, color = z, strokewidth = 1, strokecolor = :black)
f
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_fe94d4a8_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_fe94d4a8.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
save(joinpath(@OUTPUT, "example_fe94d4a8.svg"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
nothing # hide