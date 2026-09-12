# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    using CairoMakie

x = LinRange(0, 10, 100)
y = sin.(x)

fig = Figure()
lines(fig[1, 1], x, y, color = :red)
lines(fig[1, 2], x, y, color = :blue)
lines(fig[2, 1:2], x, y, color = :green)

fig
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_c9ffcd2a_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_c9ffcd2a.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
save(joinpath(@OUTPUT, "example_c9ffcd2a.svg"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
nothing # hide