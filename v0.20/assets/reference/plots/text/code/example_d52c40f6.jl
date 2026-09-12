# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    using CairoMakie
CairoMakie.activate!() # hide

f = Figure()

ax1 = Axis(f[1, 1], limits = (1, 2, 3, 4))
ax2 = Axis(f[1, 2], width = 300, limits = (5, 6, 7, 8))
ax3 = Axis(f[2, 1:2], limits = (9, 10, 11, 12))

for (ax, label) in zip([ax1, ax2, ax3], ["A", "B", "C"])
    text!(
        ax, 0, 1,
        text = label,
        font = :bold,
        align = (:left, :top),
        offset = (4, -2),
        space = :relative,
        fontsize = 24
    )
end

f
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_d52c40f6_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_d52c40f6.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
save(joinpath(@OUTPUT, "example_d52c40f6.svg"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
nothing # hide