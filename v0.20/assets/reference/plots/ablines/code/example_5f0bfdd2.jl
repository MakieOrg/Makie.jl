# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    using CairoMakie
CairoMakie.activate!() # hide

ablines(0, 1)
ablines!([1, 2, 3], [1, 1.5, 2], color = [:red, :orange, :pink], linestyle=:dash, linewidth=2)
current_figure()
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_5f0bfdd2_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_5f0bfdd2.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
save(joinpath(@OUTPUT, "example_5f0bfdd2.svg"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
nothing # hide