# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    using CairoMakie
CairoMakie.activate!() # hide


f = Figure()

xs = LinRange(0, 4pi, 21)
ys = sin.(xs)

stairs(f[1, 1], xs, ys)
stairs(f[2, 1], xs, ys; step=:post, color=:blue, linestyle=:dash)
stairs(f[3, 1], xs, ys; step=:center, color=:red, linestyle=:dot)

f
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_6ecbcfa7_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_6ecbcfa7.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
 # hide
nothing # hide