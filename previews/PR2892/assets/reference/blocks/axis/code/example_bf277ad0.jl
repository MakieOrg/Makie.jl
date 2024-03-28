# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    using CairoMakie
using CairoMakie # hide
CairoMakie.activate!() # hide
f = Figure()

ax1 = Axis(f[1, 1],
    xscale = Makie.pseudolog10,
    title = "Pseudolog scale",
    xticks = [-100, -10, -1, 0, 1, 10, 100]
)

ax2 = Axis(f[1, 2],
    xscale = Makie.Symlog10(10.0),
    title = "Symlog10 with linear scaling
between -10 and 10",
    xticks = [-100, -10, 0, 10, 100]
)

for ax in [ax1, ax2]
    lines!(ax, -100:0.1:100, -100:0.1:100)
end

f
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_bf277ad0_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_bf277ad0.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
save(joinpath(@OUTPUT, "example_bf277ad0.svg"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
nothing # hide