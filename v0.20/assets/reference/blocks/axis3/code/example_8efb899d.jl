# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    using CairoMakie
using CairoMakie # hide
CairoMakie.activate!() # hide
fig = Figure()

for (i, viewmode) in enumerate([:fit, :fitzoom, :stretch])
    for (j, elevation) in enumerate([0.1, 0.2, 0.3] .* pi)

        Label(fig[i, 1:3, Top()], "viewmode = $(repr(viewmode))", font = :bold)

        # show the extent of each cell using a box
        Box(fig[i, j], strokewidth = 0, color = :gray95)

        ax = Axis3(fig[i, j]; viewmode, elevation, protrusions = 0, aspect = :equal)
        hidedecorations!(ax)

    end
end

fig
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_8efb899d_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_8efb899d.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
save(joinpath(@OUTPUT, "example_8efb899d.svg"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
nothing # hide