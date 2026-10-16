# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    x = range(0, 10, length=100)

scatter(x, sin,
    markersize = range(5, 15, length=100),
    color = range(0, 1, length=100),
    colormap = :thermal
)
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_2fae83cf_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_2fae83cf.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
save(joinpath(@OUTPUT, "example_2fae83cf.svg"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
nothing # hide