# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    using CairoMakie

set_theme!(backgroundcolor = :gray90)

f = Figure(size = (800, 600))

for i in 1:3, j in 1:3
    ax = Axis(f[i, j], title = "$i, $j", width = 100, height = 100)
    i < 3 && hidexdecorations!(ax, grid = false)
    j > 1 && hideydecorations!(ax, grid = false)
end

Colorbar(f[1:3, 4])

f
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_c36c85c9_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_c36c85c9.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
save(joinpath(@OUTPUT, "example_c36c85c9.svg"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
nothing # hide