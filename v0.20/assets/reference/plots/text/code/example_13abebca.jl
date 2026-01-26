# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    using CairoMakie
CairoMakie.activate!() # hide


lines(0.5..20, x -> sin(x) / sqrt(x), color = :black)
text!(7, 0.38, text = L"\frac{\sin(x)}{\sqrt{x}}", color = :black)
current_figure()
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_13abebca_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_13abebca.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
save(joinpath(@OUTPUT, "example_13abebca.svg"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
nothing # hide