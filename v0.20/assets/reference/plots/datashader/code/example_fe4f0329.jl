# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    normaldist = randn(Point2f, 1_000_000)
ds1 = normaldist .+ (Point2f(-1, 0),)
ds2 = normaldist .+ (Point2f(1, 0),)
fig, ax, pl = datashader(Dict("a" => ds1, "b" => ds2))
hidedecorations!(ax)
fig
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_fe4f0329_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_fe4f0329.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
 # hide
nothing # hide