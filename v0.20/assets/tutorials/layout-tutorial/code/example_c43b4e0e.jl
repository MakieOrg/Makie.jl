# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    xs = LinRange(0.5, 6, 50)
ys = LinRange(0.5, 6, 50)
data1 = [sin(x^1.5) * cos(y^0.5) for x in xs, y in ys] .+ 0.1 .* randn.()
data2 = [sin(x^0.8) * cos(y^1.5) for x in xs, y in ys] .+ 0.1 .* randn.()

ax1, hm = contourf(gb[1, 1], xs, ys, data1,
    levels = 6)
ax1.title = "Histological analysis"
contour!(ax1, xs, ys, data1, levels = 5, color = :black)
hidexdecorations!(ax1)

ax2, hm2 = contourf(gb[2, 1], xs, ys, data2,
    levels = 6)
contour!(ax2, xs, ys, data2, levels = 5, color = :black)

f
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_c43b4e0e_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_c43b4e0e.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
 # hide
nothing # hide