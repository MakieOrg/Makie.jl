# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    yspace = maximum(tight_yticklabel_spacing!, [ax1, ax2])
xspace = maximum(tight_xticklabel_spacing!, [ax2, ax3])

ax1.yticklabelspace = yspace
ax2.yticklabelspace = yspace

ax2.xticklabelspace = xspace
ax3.xticklabelspace = xspace

f
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_5d374104_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_5d374104.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
save(joinpath(@OUTPUT, "example_5d374104.svg"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
nothing # hide