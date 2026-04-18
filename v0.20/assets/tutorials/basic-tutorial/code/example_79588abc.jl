# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    x = range(0, 10, length=100)
y = sin.(x)
scatter(x, y;
    figure = (; size = (400, 400)),
    axis = (; title = "Scatter plot", xlabel = "x label")
)
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_79588abc_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_79588abc.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
save(joinpath(@OUTPUT, "example_79588abc.svg"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
nothing # hide