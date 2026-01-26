# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    using CairoMakie
import Makie.SpecApi as S
Makie.inline!(true) # hide
CairoMakie.activate!() # hide

plot(S.GridLayout([
    (1, 1) => S.Axis(),
    (1, 2) => S.Axis(),
    (2, :) => S.GridLayout(fill(S.Axis(), 1, 3)),
]))
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_fc99f0ce_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_fc99f0ce.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
 # hide
nothing # hide