# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str # hide
__result = begin # hide
    using CairoMakie
using CairoMakie.Makie # hide
using CairoMakie.Makie.StatsBase # hide
CairoMakie.activate!() # hide

using Random
Random.seed!(1234)

f = Figure(resolution = (800, 800))

x = 1:100
y = 1:100
points = vec(Point2f.(x, y'))

weights = [nothing, rand(length(points)), Makie.StatsBase.eweights(length(points), 0.005), Makie.StatsBase.weights(randn(length(points)))]
weight_labels = ["No weights", "Vector{<: Real}", "Exponential weights (StatsBase.eweights)", "StatesBase.weights(randn(...))"]

for (i, (weight, title)) in enumerate(zip(weights, weight_labels))
    ax = Axis(f[fldmod1(i, 2)...], title = title, aspect = DataAspect())
    hexbin!(ax, points; weights = weight)
    autolimits!(ax)
end

f
end # hide
save(joinpath(@OUTPUT, "example_8363929533384526884.png"), __result; ) # hide
save(joinpath(@OUTPUT, "example_8363929533384526884.svg"), __result; ) # hide
nothing # hide