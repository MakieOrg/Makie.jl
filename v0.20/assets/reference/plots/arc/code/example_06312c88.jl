# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    using CairoMakie
CairoMakie.activate!() # hide

f = Figure()
Axis(f[1, 1])

for i in 1:4
    radius = 1/(i*2)
    left = 1/(i*2)
    right = (i*2-1)/(i*2)
    arc!(Point2f(left, 0), radius, 0, π)
    arc!(Point2f(right, 0), radius, 0, π)
end
for i in 3:4
    radius = 1/(i*(i-1)*2)
    left = (1/i) + 1/(i*(i-1)*2)
    right = ((i-1)/i) - 1/(i*(i-1)*2)
    arc!(Point2f(left, 0), radius, 0, π)
    arc!(Point2f(right, 0), radius, 0, π)
end

f
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_06312c88_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_06312c88.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
save(joinpath(@OUTPUT, "example_06312c88.svg"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
nothing # hide