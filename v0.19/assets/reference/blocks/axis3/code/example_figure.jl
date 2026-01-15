# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str # hide
__result = begin # hide
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
end # hide
save(joinpath(@OUTPUT, "example_4385730500384303306.png"), __result; ) # hide
save(joinpath(@OUTPUT, "example_4385730500384303306.svg"), __result; ) # hide
nothing # hide