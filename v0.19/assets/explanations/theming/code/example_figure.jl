# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str # hide
__result = begin # hide
    using CairoMakie
CairoMakie.activate!() # hide

set_theme!() # hide

f = Figure(resolution = (800, 800))

Axis(f[1, 1], title = "Default cycle palette")

for i in 1:6
    density!(randn(50) .+ 2i)
end

Axis(f[2, 1],
    title = "Custom cycle palette",
    palette = (patchcolor = [:red, :green, :blue, :yellow, :orange, :pink],))

for i in 1:6
    density!(randn(50) .+ 2i)
end

set_theme!(Density = (cycle = [],))

Axis(f[3, 1], title = "No cycle")

for i in 1:6
    density!(randn(50) .+ 2i)
end

set_theme!() # hide

f
end # hide
save(joinpath(@OUTPUT, "example_7674987383173405816.png"), __result; ) # hide

nothing # hide