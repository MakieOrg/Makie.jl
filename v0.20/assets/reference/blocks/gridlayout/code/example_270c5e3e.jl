# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    using CairoMakie

f = Figure()

subgl_left = GridLayout()
subgl_left[1:2, 1:2] = [Axis(f) for i in 1:2, j in 1:2]

subgl_right = GridLayout()
subgl_right[1:3, 1] = [Axis(f) for i in 1:3]

f.layout[1, 1] = subgl_left
f.layout[1, 2] = subgl_right

f
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_270c5e3e_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_270c5e3e.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
save(joinpath(@OUTPUT, "example_270c5e3e.svg"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
nothing # hide