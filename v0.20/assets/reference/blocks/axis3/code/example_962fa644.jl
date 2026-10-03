# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    using CairoMakie
using CairoMakie # hide
CairoMakie.activate!() # hide
fig = Figure()

for (i, azimuth) in enumerate([0, 0.1, 0.2, 0.3, 0.4, 0.5])
    Axis3(fig[fldmod1(i, 3)...], azimuth = azimuth * pi,
        title = "azimuth = $(azimuth)π", viewmode = :fit)
end

fig
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_962fa644_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_962fa644.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
save(joinpath(@OUTPUT, "example_962fa644.svg"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
nothing # hide