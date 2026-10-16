# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str # hide
__result = begin # hide
    using CairoMakie
CairoMakie.activate!() # hide

f, ax, sc = scatter(1:7, fill(1, 7), color = Makie.wong_colors(), markersize = 50)
hidedecorations!(ax)
hidespines!(ax)
text!(ax, 4, 1, text = "Makie.wong_colors()",
    align = (:center, :bottom), offset = (0, 30))
scatter!(range(1, 7, 20), fill(0, 20), color = 1:20, markersize = 50)
text!(ax, 4, 0, text = ":viridis",
    align = (:center, :bottom), offset = (0, 30))
ylims!(ax, -1, 2)
f
end # hide
save(joinpath(@OUTPUT, "example_2662018475627312909.png"), __result; ) # hide
save(joinpath(@OUTPUT, "example_2662018475627312909.svg"), __result; ) # hide
nothing # hide