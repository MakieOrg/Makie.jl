# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    using CairoMakie
CairoMakie.activate!() # hide
colors = Makie.wong_colors()

x = repeat(1:2, inner=5)
y = [6, 4, 2, -8, 3, 5, 1, -2, -3, 7]
group = repeat(1:5, outer=2)

waterfall(x, y, dodge=group, color=colors[group])
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_60424a57_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_60424a57.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
 # hide
nothing # hide