# This file was generated, do not modify it. # hide
__result = begin # hide
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
end # hide
save(joinpath(@OUTPUT, "example_14776298041594337046.png"), __result; ) # hide
save(joinpath(@OUTPUT, "example_14776298041594337046.svg"), __result; ) # hide
nothing # hide