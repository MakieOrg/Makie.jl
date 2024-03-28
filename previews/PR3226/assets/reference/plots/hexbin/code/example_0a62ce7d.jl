# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    using CairoMakie
CairoMakie.activate!() # hide

using Random
Random.seed!(1234)

f = Figure(size = (800, 800))

x = rand(300)
y = rand(300)

for i in 2:5
    ax = Axis(f[fldmod1(i-1, 2)...], title = "bins = (3, $i)", aspect = DataAspect())
    hexbin!(ax, x, y, bins = (3, i))
    wireframe!(ax, Rect2f(Point2f.(x, y)), color = :red)
    scatter!(ax, x, y, color = :red, markersize = 5)
end

f
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_0a62ce7d_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_0a62ce7d.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
save(joinpath(@OUTPUT, "example_0a62ce7d.svg"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
nothing # hide