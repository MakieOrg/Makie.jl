# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    using CairoMakie
CairoMakie.activate!() # hide


aligns = [(h, v) for v in [:bottom, :baseline, :center, :top]
                 for h in [:left, :center, :right]]
x = repeat(1:3, 4)
y = repeat(1:4, inner = 3)
scatter(x, y)
text!(x, y, text = string.(aligns), align = aligns)
current_figure()
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_292cc60c_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_292cc60c.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
save(joinpath(@OUTPUT, "example_292cc60c.svg"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
nothing # hide