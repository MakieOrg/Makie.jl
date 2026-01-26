# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    using CairoMakie
using CairoMakie # hide
CairoMakie.activate!() # hide
    fig = Figure(backgroundcolor = :gray97)
    Box(fig[1, 1], strokewidth = 0) # visualizes the layout cell
    ax = Axis3(fig[1, 1], protrusions = (0, 0, 0, 20), viewmode = :stretch,
        title = "protrusions = (0, 0, 0, 20)")
    hidedecorations!(ax)
    fig
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_a78097ce_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_a78097ce.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
save(joinpath(@OUTPUT, "example_a78097ce.svg"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
nothing # hide