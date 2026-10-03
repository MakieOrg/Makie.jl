# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    using CairoMakie
CairoMakie.activate!() # hide
using Makie.GeometryBasics


f = Figure()
Axis(f[1, 1])

# vector of shapes
poly!(
    [Rect(i, j, 0.75, 0.5) for i in 1:5 for j in 1:3],
    color = 1:15,
    colormap = :heat
)

f
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_0227b98e_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_0227b98e.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
 # hide
nothing # hide