# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    using CairoMakie
CairoMakie.activate!() # hide


f = Figure()
Axis(f[1, 1])

xs = 1:0.2:10
ys = sin.(xs)

linesegments!(xs, ys)
linesegments!(xs, ys .- 1, linewidth = 5)
linesegments!(xs, ys .- 2, linewidth = 5, color = LinRange(1, 5, length(xs)))

f
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_fd97203c_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_fd97203c.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
 # hide
nothing # hide