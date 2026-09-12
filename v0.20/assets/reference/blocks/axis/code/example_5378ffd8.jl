# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    using CairoMakie
CairoMakie.activate!() # hide


f = Figure()

axs = [Axis(f[1, i]) for i in 1:3]

scatters = map(axs) do ax
    [scatter!(ax, 0:0.1:10, x -> sin(x) + i) for i in 1:3]
end

delete!(axs[2], scatters[2][2])
empty!(axs[3])

f
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_5378ffd8_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_5378ffd8.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
save(joinpath(@OUTPUT, "example_5378ffd8.svg"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
nothing # hide