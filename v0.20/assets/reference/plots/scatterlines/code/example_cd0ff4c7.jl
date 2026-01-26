# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    using CairoMakie
CairoMakie.activate!() # hide


f = Figure()
Axis(f[1, 1])

xs = LinRange(0, 10, 20)
ys = 0.5 .* sin.(xs)

scatterlines!(xs, ys, color = :red)
scatterlines!(xs, ys .- 1, color = xs, markercolor = :red)
scatterlines!(xs, ys .- 2, markersize = LinRange(5, 30, 20))
scatterlines!(xs, ys .- 3, marker = :cross, strokewidth = 1,
    markersize = 20, color = :orange, strokecolor = :black)

f
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_cd0ff4c7_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_cd0ff4c7.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
save(joinpath(@OUTPUT, "example_cd0ff4c7.svg"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
nothing # hide