# This file was generated, do not modify it. # hide
__result = begin # hide
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
    scale = Makie.pseudolog10)

tightlimits!(ax)

Colorbar(f[1, 2], hb,
    label = "Number of airports",
    ticks = (0:3, ["0", "10", "100", "1000"]),
    height = Relative(0.5)
)
f
end # hide
save(joinpath(@OUTPUT, "example_14727280331027661797.png"), __result; ) # hide
save(joinpath(@OUTPUT, "example_14727280331027661797.svg"), __result; ) # hide
nothing # hide