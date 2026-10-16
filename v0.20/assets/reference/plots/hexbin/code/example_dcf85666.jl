# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    using CairoMakie
CairoMakie.activate!() # hide

using DelimitedFiles
CairoMakie.activate!() # hide


a = map(Point2f, eachrow(readdlm(assetpath("airportlocations.csv"))))

f, ax, hb = hexbin(a,
    cellsize = 6,
    axis = (; aspect = DataAspect()),
    threshold = 0,
    colormap = [Makie.to_color(:transparent); Makie.to_colormap(:viridis)],
    strokewidth = 0.5,
    strokecolor = :gray50,
    colorscale = Makie.pseudolog10)

tightlimits!(ax)

Colorbar(f[1, 2], hb,
    label = "Number of airports",
    height = Relative(0.5)
)
f
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_dcf85666_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_dcf85666.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
save(joinpath(@OUTPUT, "example_dcf85666.svg"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
nothing # hide