# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    using CairoMakie
using DelaunayTriangulation
CairoMakie.activate!() # hide

using Random
Random.seed!(1234)

z = LinRange(0, 1, 250) .* exp.(LinRange(0, 16pi, 250) .* im)
f, ax, tr = voronoiplot(real(z), imag(z), unbounded_edge_extension_factor = 0.4, markersize = 7)
f
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_c69ee256_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_c69ee256.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
save(joinpath(@OUTPUT, "example_c69ee256.svg"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
nothing # hide