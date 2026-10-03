# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    using CairoMakie
CairoMakie.activate!() # hide


f = Figure()
Axis(f[1, 1])

xs = 0:0.01:10
ys = 0.5 .* sin.(xs)

for (i, lw) in enumerate([1, 2, 3])
    lines!(xs, ys .- i/6, linestyle = nothing, linewidth = lw)
    lines!(xs, ys .- i/6 .- 1, linestyle = :dash, linewidth = lw)
    lines!(xs, ys .- i/6 .- 2, linestyle = :dot, linewidth = lw)
    lines!(xs, ys .- i/6 .- 3, linestyle = :dashdot, linewidth = lw)
    lines!(xs, ys .- i/6 .- 4, linestyle = :dashdotdot, linewidth = lw)
    lines!(xs, ys .- i/6 .- 5, linestyle = Linestyle([0.5, 1.0, 1.5, 2.5]), linewidth = lw)
end

f
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_c68d84e3_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_c68d84e3.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
save(joinpath(@OUTPUT, "example_c68d84e3.svg"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
nothing # hide