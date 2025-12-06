# This file was generated, do not modify it. # hide
__result = begin # hide
    using CairoMakie
CairoMakie.activate!() # hide


f = Figure()
Axis(f[1, 1])

vals = -1:0.1:1
lows = zeros(length(vals))
highs = LinRange(0.1, 0.4, length(vals))

rangebars!(vals, lows, highs, color = LinRange(0, 1, length(vals)),
    whiskerwidth = 10, direction = :x)

f
end # hide
save(joinpath(@OUTPUT, "example_11953518998762468277.png"), __result; ) # hide

nothing # hide