# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    f = Figure(size = (600, 600))

ax = PolarAxis(f[1, 1], title = "Default")
lines!(ax, range(0, 8pi, length=300), range(0, 10, length=300))
ax = PolarAxis(f[1, 2], title = "thetalimits", thetalimits = (-pi/6, pi/6))
lines!(ax, range(0, 8pi, length=300), range(0, 10, length=300))

ax = PolarAxis(f[2, 1], title = "rlimits", rlimits = (5, 10))
lines!(ax, range(0, 8pi, length=300), range(0, 10, length=300))
ax = PolarAxis(f[2, 2], title = "both")
lines!(ax, range(0, 8pi, length=300), range(0, 10, length=300))
thetalims!(ax, -pi/6, pi/6)
rlims!(ax, 5, 10)

f
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_36582889_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_36582889.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
save(joinpath(@OUTPUT, "example_36582889.svg"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
nothing # hide