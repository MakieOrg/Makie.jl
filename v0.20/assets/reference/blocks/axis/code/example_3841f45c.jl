# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    using CairoMakie
CairoMakie.activate!() # hide


f = Figure()

ax1 = Axis(f[1, 1], title = "Axis 1")
ax2 = Axis(f[1, 2], title = "Axis 2")
ax3 = Axis(f[1, 3], title = "Axis 3")

hidedecorations!(ax1)
hidexdecorations!(ax2, grid = false)
hideydecorations!(ax3, ticks = false)

f
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_3841f45c_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_3841f45c.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
save(joinpath(@OUTPUT, "example_3841f45c.svg"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
nothing # hide