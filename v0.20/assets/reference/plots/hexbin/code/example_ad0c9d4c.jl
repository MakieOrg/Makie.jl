# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    using CairoMakie
CairoMakie.activate!() # hide

using Random
Random.seed!(1234)

f = Figure(size = (800, 800))

x = randn(100000)
y = randn(100000)

for (i, threshold) in enumerate([1, 10, 100, 500])
    ax = Axis(f[fldmod1(i, 2)...], title = "threshold = $threshold", aspect = DataAspect())
    hexbin!(ax, x, y, cellsize = 0.4, threshold = threshold)
end
f
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_ad0c9d4c_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_ad0c9d4c.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
save(joinpath(@OUTPUT, "example_ad0c9d4c.svg"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
nothing # hide