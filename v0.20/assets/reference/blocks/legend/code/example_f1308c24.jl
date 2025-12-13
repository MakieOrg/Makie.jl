# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    using CairoMakie
CairoMakie.activate!() # hide

f = Figure()

Axis(f[1, 1])

xs = 0:0.5:10
ys = sin.(xs)
lin = lines!(xs, ys, color = :blue)
sca = scatter!(xs, ys, color = :red)
sca2 = scatter!(xs, ys .+ 0.5, color = 1:length(xs), marker = :rect)

Legend(f[1, 2],
    [lin, sca, [lin, sca], sca2],
    ["a line", "some dots", "both together", "rect markers"])

f
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_f1308c24_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_f1308c24.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
save(joinpath(@OUTPUT, "example_f1308c24.svg"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
nothing # hide