# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    fig = Figure()
ax = PolarAxis(fig[1, 1], thetalimits = (0, pi))
lines!(ax, range(0, pi, length=100), 10 .+ sin.(0.3 .* (1:100)))
fig
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_f0a6d77c_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_f0a6d77c.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
save(joinpath(@OUTPUT, "example_f0a6d77c.svg"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
nothing # hide