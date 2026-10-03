# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    using CairoMakie
CairoMakie.activate!() # hide
using Makie.GeometryBasics


f = Figure()
Axis(f[1, 1])

# polygon with hole
p = Polygon(
    Point2f[(0, 0), (2, 0), (3, 1), (1, 1)],
    [Point2f[(0.75, 0.25), (1.75, 0.25), (2.25, 0.75), (1.25, 0.75)]]
)

poly!(p, color = :blue)

f
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_fb392799_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_fb392799.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
 # hide
nothing # hide