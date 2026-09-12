# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    using CairoMakie
CairoMakie.activate!() # hide


f, ax, l = lines([0, 1], [1, 1], linewidth = 50, color = :gray80)
for (marker, x) in zip(['X', 'x', :circle, :rect, :utriangle, Circle, Rect], range(0.1, 0.9, length = 7))
    scatter!(ax, x, 1, marker = marker, markersize = 50, color = :black)
end
f
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_8fc798b2_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_8fc798b2.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
save(joinpath(@OUTPUT, "example_8fc798b2.svg"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
nothing # hide