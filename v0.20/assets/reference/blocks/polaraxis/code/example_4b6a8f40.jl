# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    fig = Figure()
fullaxis(figpos, title) = PolarAxis(figpos;
                                    title,
                                    thetaminorgridvisible=true,
                                    rminorgridvisible=true,
                                    rticklabelrotation=deg2rad(-90),
                                    rticklabelsize=12,
                                    )
ax1 = fullaxis(fig[1, 1][1, 1], "all decorations")
ax2 = fullaxis(fig[1, 1][1, 2], "hide spine")
hidespines!(ax2)
ax3 = fullaxis(fig[2, 1][1, 1], "hide r decorations")
hiderdecorations!(ax3)
ax4 = fullaxis(fig[2, 1][1, 2], "hide theta decorations")
hidethetadecorations!(ax4)
ax5 = fullaxis(fig[2, 1][1, 3], "hide all decorations")
hidedecorations!(ax5)
fig
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_4b6a8f40_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_4b6a8f40.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
save(joinpath(@OUTPUT, "example_4b6a8f40.svg"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
nothing # hide