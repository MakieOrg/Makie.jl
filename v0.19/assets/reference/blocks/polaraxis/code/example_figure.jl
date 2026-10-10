# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str # hide
__result = begin # hide
    fig = Figure()
ax = PolarAxis(fig[1, 1], thetalimits = (0, pi), radial_distortion_threshold = 0.2, rlimits = (nothing, nothing))
lines!(ax, range(0, pi, length=100), 10 .+ sin.(0.3 .* (1:100)))
fig
end # hide
save(joinpath(@OUTPUT, "example_11431116003418485086.png"), __result; ) # hide
save(joinpath(@OUTPUT, "example_11431116003418485086.svg"), __result; ) # hide
nothing # hide