# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    using CairoMakie
CairoMakie.activate!() # hide

f = Figure()

Label(f[1, 1],
    "Multiline label\nwith\njustification = :left\nand\nlineheight = 0.9",
    justification = :left,
    lineheight = 0.9
)
Label(f[1, 2],
    "Multiline label\nwith\njustification = :center\nand\nlineheight = 1.1",
    justification = :center,
    lineheight = 1.1,
    color = :dodgerblue,
)
Label(f[1, 3],
    "Multiline label\nwith\njustification = :right\nand\nlineheight = 1.3",
    justification = :right,
    lineheight = 1.3,
    color = :firebrick
)

f
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_967886d3_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_967886d3.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
save(joinpath(@OUTPUT, "example_967886d3.svg"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
nothing # hide