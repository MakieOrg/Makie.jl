# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    using CairoMakie
CairoMakie.activate!() # hide

using Random
Random.seed!(123)

n = 20
angles = range(0, 2pi, length = n+1)[1:end-1]
x = [cos.(angles); 2 .* cos.(angles .+ pi/n)]
y = [sin.(angles); 2 .* sin.(angles .+ pi/n)]
z = (x .- 0.5).^2 + (y .- 0.5).^2 .+ 0.5.*randn.()

triangulation_inner = reduce(hcat, map(i -> [0, 1, n] .+ i, 1:n))
triangulation_outer = reduce(hcat, map(i -> [n-1, n, 0] .+ i, 1:n))
triangulation = hcat(triangulation_inner, triangulation_outer)

f, ax, _ = tricontourf(x, y, z, triangulation = triangulation,
    axis = (; aspect = 1, title = "Manual triangulation"))
scatter!(x, y, color = z, strokewidth = 1, strokecolor = :black)

tricontourf(f[1, 2], x, y, z, triangulation = Makie.DelaunayTriangulation(),
    axis = (; aspect = 1, title = "Delaunay triangulation"))
scatter!(x, y, color = z, strokewidth = 1, strokecolor = :black)

f
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_480fd0da_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_480fd0da.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
save(joinpath(@OUTPUT, "example_480fd0da.svg"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
nothing # hide