# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    using CairoMakie
using CairoMakie # hide
CairoMakie.activate!() # hide
using FileIO

fig = Figure()

brain = load(assetpath("brain.stl"))

ax1 = Axis3(fig[1, 1], title = "zreversed = false")
ax2 = Axis3(fig[2, 1], title = "zreversed = true", zreversed = true)
for ax in [ax1, ax2]
    mesh!(ax, brain, color = getindex.(brain.position, 3))
end

fig
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_3cdd3ea7_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_3cdd3ea7.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
save(joinpath(@OUTPUT, "example_3cdd3ea7.svg"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
nothing # hide