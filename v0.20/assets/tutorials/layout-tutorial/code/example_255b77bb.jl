# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    for (label, layout) in zip(["A", "B", "C", "D"], [ga, gb, gc, gd])
    Label(layout[1, 1, TopLeft()], label,
        fontsize = 26,
        font = :bold,
        padding = (0, 5, 5, 0),
        halign = :right)
end

f
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_255b77bb_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_255b77bb.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
 # hide
nothing # hide