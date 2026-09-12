# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str # hide
__result = begin # hide
    fig, ax, pl = barplot(1:3; color=1:3, colormap=Makie.Categorical(:viridis))
Colorbar(fig[1, 2], pl)
fig
end # hide
save(joinpath(@OUTPUT, "example_9369685590253433137.png"), __result; ) # hide

nothing # hide