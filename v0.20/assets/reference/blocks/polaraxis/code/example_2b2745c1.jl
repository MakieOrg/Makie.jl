# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    f = Figure(size = (800, 400))

ax = PolarAxis(f[1, 1], title = "Theta as x")
lineobject = lines!(ax, 0..2pi, sin, color = :red)

ax = PolarAxis(f[1, 2], title = "R as x", theta_as_x = false)
scatobject = scatter!(range(0, 10, length=100), cos, color = :orange)

f
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_2b2745c1_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_2b2745c1.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
save(joinpath(@OUTPUT, "example_2b2745c1.svg"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
nothing # hide