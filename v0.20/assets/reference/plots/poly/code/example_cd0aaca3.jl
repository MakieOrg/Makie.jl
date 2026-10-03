# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    using CairoMakie
CairoMakie.activate!() # hide
using Makie.GeometryBasics


f = Figure()
Axis(f[1, 1]; backgroundcolor = :gray15)

# vector of polygons
ps = [Polygon(rand(Point2f, 3) .+ Point2f(i, j))
    for i in 1:5 for j in 1:10]

poly!(ps, color = rand(RGBf, length(ps)))

f
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_cd0aaca3_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_cd0aaca3.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
 # hide
nothing # hide